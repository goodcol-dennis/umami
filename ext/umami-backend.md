# Backend API Service Guardrails

**Extension of [Rapid Development Guardrails](../umami.md) — §31**

This extension covers the backend API service itself: the authentication boundary, the OLTP datastore that lives under production traffic, transaction and idempotency semantics, ORM query behavior, the contract surface, and the service-level observability minimum. §24 covers how services talk to each other; before this extension, nothing in the corpus covered the failure modes agents produce *inside* a service — endpoints that are insecure by omission, slow by query pattern, and irreversible by migration. §31 is that coverage.

**Apply this extension when** the project exposes a backend API service (REST/GraphQL/gRPC) with its own datastore.

**Adopt when (§0.9 default-deny):** the service handles authenticated mutations against a datastore you cannot regenerate from another source, or has (or will have) more than one consumer. A read-only prototype backed by throwaway data stays on core §3 + §4 alone.

**Cost profile:** Agent-with-review · Days · Architectural — the deny-by-default router, migration pipeline, and error envelope are one-time structural work; the per-endpoint disciplines (auth policy declaration, idempotency key, query-count assertion, pagination) recur at Hours per endpoint.

**Kill criterion:** if two consecutive quarterly reviews find that the §31.1 route-policy fitness function never failed on a real change, no migration needed an expand/contract split, and no idempotency key ever deduplicated a request, the service is too small or too static for the per-endpoint disciplines — retire them through the §0.9 retirement gate and keep only the deny-by-default router.

**Scope boundary with [umami-integration.md](umami-integration.md):** circuit breakers, retries, timeouts, rate limiting, webhooks, API versioning, correlation IDs, and contract testing are §24 — cross-referenced here, never restated. **Scope boundary with [umami-data.md](umami-data.md):** §18 covers analytics pipelines and warehouse schema evolution; §31.3 covers the OLTP side, where live traffic runs during the change and lock behavior decides whether the site stays up. **Scope boundary with [umami-web.md](umami-web.md):** §17 covers the frontend consuming this API; §31.2 states the credential-storage decision once for both sides.

---

## 31.1 AuthN/AuthZ Boundaries

Agents add endpoints by copying the nearest handler. If auth is a per-handler decorator applied by convention, the new endpoint inherits whatever the copied handler had — and if the nearest example was public, the new mutation is public. Convention-based auth fails precisely at agentic velocity, because the agent has no memory of the convention, only of the example in context.

**Rules:**

- **The auth check lives in middleware or the gateway, applied by the router — never in individual handlers by convention.** A handler must be unreachable without passing the auth layer, not merely expected to call it.
- **Deny by default.** Every route declares an auth policy at registration; unauthenticated access is an explicit, named opt-in (`policy=public`), never the absence of a decorator. Absence must mean "broken," not "open."
- **Enforce it with a fitness function (§3):** a test enumerates every registered route and fails if any route lacks a declared policy. Falsifiable check: register a route with no policy — the suite must go red before the PR merges.
- **Authorization is a queryable policy surface, not logic scattered through handlers.** "Who can call `DELETE /users/{id}`?" must be answerable by reading one policy module or one table mapping route → required role/scope. If answering requires tracing handler code, an agent editing that handler can silently change the answer.
- **Object-level authorization goes in the query, not after it.** The second-most-common agent failure: the endpoint checks *who you are* but not *what you own* — `GET /orders/{id}` returns any order to any logged-in user (IDOR). Filter by principal in the WHERE clause (`WHERE id = :id AND owner_id = :principal`); a fetch-then-check pattern is one forgotten `if` away from a data leak. See §4 for the general security discipline and §22 if the data is regulated.
- **GraphQL moves the boundary to the resolver layer.** Route-level policy sees one `/graphql` route and passes everything. Declare policies per query/mutation field with the same deny-by-default rule — one public field exposes every object reachable from it through the graph.

---

## 31.2 Session and Token Handling

**The decision, stated once:** browser clients get server-side sessions via `httpOnly`, `Secure`, `SameSite` cookies; non-browser clients (mobile, CLI, service-to-service) get short-lived bearer tokens. Do not invent a hybrid, and never put a bearer token where page scripts can read it.

**The localStorage anti-pattern:** agents default to storing tokens in `localStorage` because most tutorials do. Any XSS then becomes full credential theft — the attacker exfiltrates the token and impersonates the user from anywhere. `httpOnly` cookies make script-side token exfiltration structurally impossible; that property is worth the CSRF handling it requires.

**Cookies reintroduce CSRF — handle it, do not rediscover it.** `SameSite=Lax` blocks the cookie on cross-site POSTs (the classic CSRF vector) but still sends it on top-level cross-site GET navigations — so a state-changing GET is still exploitable, and older clients or a compromised subdomain leak around Lax entirely. Still require an anti-CSRF token on state-changing requests. Watch for the agent shortcut of disabling framework CSRF middleware to make the first curl test pass — that suppression ships if nobody greps for it.

| Credential | Lifetime | Storage | Rotation |
|---|---|---|---|
| Session cookie | Hours–days, sliding | Server-side store; client holds only an opaque ID | Regenerate the session ID on every privilege change (login, role elevation) |
| Access token | ≤ 15–60 minutes | Client memory only — never persisted | Not rotated; expires and is re-issued via refresh |
| Refresh token | Days–weeks | Server side hashed at rest, like a password; on browsers, `httpOnly` cookie if used at all | Rotate on every use; reuse of an already-rotated token means theft — revoke the whole token family |

**Revocation is a design requirement, not a feature request.** If you cannot answer "how do we invalidate a compromised user's credentials in under a minute," the design has none. Stateless JWTs alone cannot be revoked: either keep access-token lifetime short enough that the refresh check *is* the revocation point, or use opaque tokens with a server lookup. Password change and "log out everywhere" must invalidate all outstanding refresh tokens for the principal.

---

## 31.3 OLTP Schema-Migration Discipline

Analytics schemas (§18.3) migrate between pipeline runs. OLTP schemas migrate under live traffic, during rolling deploys, with rollback as a standing possibility — old code and new schema *will* coexist. Expand → migrate → contract is the only shape that survives this:

| Phase | What ships | Deploy |
|---|---|---|
| **Expand** | Additive DDL only: new nullable column, new table, new index. Old and new code both run against the result. | Own deploy |
| **Migrate** | Backfill data in batches; code switches reads/writes to the new shape while tolerating both. | Own deploy(s) |
| **Contract** | Destructive DDL: drop the old column, add the NOT NULL constraint — only after no deployed code path touches the old shape. | Own deploy |

**Rules:**

- **Never bundle destructive DDL with the code deploy that requires it.** A rollback of the code must always land on a schema it can run against. One PR containing both `DROP COLUMN` and the code that stops reading it makes the deploy irreversible by construction.
- **State lock impact in every migration PR.** Which locks, held how long, on production-sized data — not dev-sized. Agents write the naive one-statement version because it is shorter. If the answer is "don't know," the migration is not ready for review. Engines differ — treat this table as the list of what to verify against yours, not a promise:

| Operation | Typical impact on a large table |
|---|---|
| Add nullable column, no default | Safe — metadata-only in mainstream engines |
| Add NOT NULL / volatile-default column in one statement | Table rewrite or long lock — split: add nullable → backfill in batches → add constraint |
| Create index (plain) | Blocks writes for the build — use the `CONCURRENTLY`/`ONLINE` variant |
| Add foreign key or CHECK constraint | Full-table validation scan under lock — add unvalidated first, validate separately where the engine supports it |
| Drop or rename column, narrow a type | Breaks running old code instantly — contract phase only |
- **Migrations are Medium risk minimum on the §3d risk taxonomy — High if destructive or backfilling. Never in the §30 auto-merge lane.** A wrong migration is the one change class where "revert the PR" does not undo the damage.
- **Destructive migrations ship a tested down-migration, or an explicit "irreversible — recovery is restore-from-backup per §5" declaration in review.** Silence on reversibility is the failure mode; either answer is acceptable, unstated is not.

---

## 31.4 Transaction Boundaries and Idempotency

**The transaction protects an invariant, not a request.** Name the invariant at the boundary in a comment ("order total equals the sum of its line items"). If you cannot name one, the boundary is wrong. Agents default to two bad shapes: wrapping the entire handler in one transaction (locks held across work that needs none), or per-statement autocommit (the invariant can be observed half-written).

**Rules:**

- **No network I/O inside a database transaction.** An HTTP or queue call between BEGIN and COMMIT holds row locks for the remote call's timeout (§24.4) — a 30-second third-party hang becomes 30 seconds of blocked writers. Do the call before the transaction or after the commit, never inside.
- **Every mutating endpoint that a §24.3 retry can hit twice dedupes server-side.** §24.3 has the retrying client send an `Idempotency-Key`; this section is the server-side dedupe that makes that key mean something: store key + response atomically with the write, and replay the stored response on a repeated key. Without the server half, the client's careful retry discipline still double-charges the customer. Store the request-payload hash with the key and reject a reused key carrying a different payload (`422`) — otherwise a client bug silently receives another request's stored response.
- **Writes that must also emit an event use the outbox pattern.** Insert the event into an outbox table *in the same transaction* as the domain write; a separate relay publishes from the outbox. The dual-write shape — commit, then publish — loses events whenever the process dies between the two, and agents produce dual-writes by default because it is the obvious two lines. Type the outbox channel per §2b (payload schema, origin tag, allowed-consumer list, audit-on-add at review); downstream delivery guarantees are §18.9.

---

## 31.5 ORM Discipline and N+1

Agents produce N+1 queries by default: fetch a list, touch a lazy relation per row. The code reads correctly, passes tests against 3 seed rows, and falls over at 10,000 — the one failure class that is invisible in review, invisible in small-data tests, and dominant in production latency.

**Rules:**

- **Every list endpoint gets a query-count assertion in its tests.** Seed N=2 rows, then N=50, and assert the query count is identical — query count must be O(1) in rows returned, never O(n). Most ORMs expose a query counter; the assertion is three lines and falsifies the entire N+1 class.
- **Configure lazy loading to raise, not silently query, where the ORM supports strict modes.** An exception in development is cheap; a latency mystery in production is not.
- **Raw SQL is an allowed escape hatch — parameterized only, and routed through §3d review with the data-integrity dimension flagged.** Hand-written SQL bypasses the ORM's escaping and mapping guarantees, so it gets a reviewing eye every time; string-interpolated SQL is rejected outright regardless of the interpolated value's provenance.
- **ORM-autogenerated migrations are proposals, not artifacts.** Review the emitted DDL against §31.3 before it ships — autogenerate happily emits a table-locking NOT NULL or an unprompted DROP, because it diffs models, not production consequences.

---

## 31.6 API Contract Surface

- **Paginate every list endpoint from day one.** Retrofitting pagination is a breaking change: bare-array-to-envelope alters the response shape, forcing a §24.1 version bump and touching every client. Choose cursor or offset once (cursor for growing feeds, offset is acceptable for small bounded admin tables), and declare the default and maximum page size in the contract. An unpaginated list endpoint is a memory and latency time bomb with a fuse equal to the table's growth rate. Make `total_count` optional or estimated — an exact `COUNT(*)` on every page of a large table is a self-inflicted slow query (§31.7).
- **One error envelope, everywhere.** A stable machine-parseable `code` consumers can branch on, a human-readable `message`, and the correlation ID (§24.8):

  ```json
  {"error": {"code": "order_not_found", "message": "No order with that ID", "request_id": "req_7f3b4a2e"}}
  ```

  Never emit stack traces, exception class names, SQL fragments, or internal hostnames in any response body — that is reconnaissance data, and framework debug modes leak all of it by default. The unhandled-exception path returns a generic envelope with a 500 and logs the detail server-side.
- **The contract is the spec (§2).** Schema-first (OpenAPI, GraphQL SDL, proto): the contract file is the reviewed artifact and handlers conform to it, because an agent asked to "add a field" edits whichever is authoritative — make that the contract, not the code. Versioning, deprecation, and compatibility are §24.1; consumer-driven contract testing is §24.9 — apply both, restated nowhere here.

---

## 31.7 Backend Observability

§4 defines the general observability discipline; this is the backend-service minimum below which production debugging is guesswork:

| Signal | Content / threshold | Why it earns its cost |
|---|---|---|
| Structured request log | Method, route template, status, duration, principal ID, correlation ID (§24.8) | One query reconstructs any user-reported failure |
| Per-endpoint latency + error rate | p50/p99 and non-2xx rate keyed by route template — `/users/{id}`, never the raw URL | Raw-URL keying shreds metrics into per-resource noise; agents wire the raw URL by default |
| Slow-query log | Explicit threshold (e.g., 100 ms for OLTP), reviewed on a fixed cadence | Missing indexes and escaped N+1s surface here weeks before they page anyone |
| Connection-pool saturation | In-use vs. max, per pool | Pool exhaustion presents as random request latency; without this metric the root cause is invisible |

**Rules:**

- **Alert per route template, not globally.** A p99 that is healthy for the report-export endpoint is an outage for the login endpoint; one global threshold is wrong for both.
- **Falsifiable completeness check:** take one production request ID and reconstruct, from logs alone, which handler ran, which queries executed, and which outbound calls fired. Any gap in that reconstruction is the observability backlog. Feed pipeline-level signals (deploy health, alert fatigue) into §6b.

---

## Backend Anti-Patterns

| Anti-pattern | How to spot it | Watch signal (falsifiable) | Mitigation |
|---|---|---|---|
| **Auth by handler convention** | Auth is a decorator each handler remembers to add; new endpoints copy whichever neighbor was in context | Route-enumeration test finds ≥1 registered route with no declared policy | Deny-by-default router + route-policy fitness function (§31.1) |
| **Migration bundled with code deploy** | One PR contains destructive DDL and the code that depends on it | Rolling back the latest deploy fails because prior code cannot run against the current schema | Expand → migrate → contract, each phase its own deploy (§31.3) |
| **Unpaginated list endpoint** | List handler returns a bare array with no limit parameter | Seed 10k rows in staging; the endpoint returns all of them in one response | Pagination as contract from day one (§31.6) |
| **ORM lazy-loading in a loop** | Iteration over a result set accesses relations per element | Query count grows with row count in the §31.5 assertion (N=2 vs N=50 differ) | Eager-load declarations + query-count assertion on every list endpoint (§31.5) |
| **Error responses leaking internals** | Stack traces, exception class names, or SQL in non-2xx bodies; debug mode on in production config | Force an unhandled exception in staging; the response body contains anything beyond the standard envelope | Single error envelope + generic 500 path (§31.6) |
| **Network call inside a transaction** | HTTP/queue call between BEGIN and COMMIT | DB lock-wait time correlates with third-party latency spikes | Transaction scope = the invariant; I/O before or after, never inside (§31.4) |

---

## Mapping to Core Guardrail Sections

| Core Section | Backend Equivalent |
|---|---|
| §2 Specs | §31.6 Contract-first API surface (the schema is the spec handlers conform to) |
| §2b Async Channel Contracts | §31.4 Outbox pattern (the outbox is a typed channel: payload schema, origin, consumers) |
| §3 Testing / fitness functions | §31.1 Route-policy fitness function, §31.5 query-count assertions |
| §3d Review + risk taxonomy | §31.3 Migrations as Medium/High risk (never auto-merged), §31.5 raw-SQL review lane |
| §4 Security + runtime validation | §31.1 Deny-by-default auth, §31.2 Credential handling, §31.7 Observability minimum |
| §5 State Recovery | §31.3 Reversibility declarations (down-migration or restore-from-backup) |
| §6b Pipeline Health | §31.7 Per-endpoint signals feeding deploy-health review |
| §12 Change Tracking | §31.3 Lock-impact statements and phase tracking across migration deploys |
| §18 Data Pipelines | §31.3 (OLTP counterpart to §18.3), §31.4 outbox → §18.9 delivery guarantees |
| §24 Systems Integration | §31.4 Server half of §24.3 idempotent retries; §31.6 defers versioning/contract testing to §24.1/§24.9 |

---

## Backend Checklist (extends §15)

### Before Every Backend PR
- [ ] Route-policy fitness function passes — every registered route declares an auth policy, `public` included (§31.1).
- [ ] New resource-scoped routes filter by principal in the query itself — no fetch-then-check ownership logic (§31.1).
- [ ] No tokens written to `localStorage`/`sessionStorage` in any client code touched by this change (§31.2).
- [ ] Migration PRs: no destructive DDL alongside the code that requires it; lock impact stated for production-sized data; Medium/High risk per §3d and excluded from the §30 auto-merge lane (§31.3).
- [ ] New mutating endpoints accept an idempotency key with server-side dedup, or document why a duplicate execution is harmless (§31.4).
- [ ] No network I/O between BEGIN and COMMIT in any touched transaction (§31.4).
- [ ] Every new or changed list endpoint has both a query-count assertion and pagination in the contract (§31.5, §31.6).
- [ ] Error paths return the shared envelope; the unhandled-exception path emits a generic 500 with no internals (§31.6).

### Periodic

**This checklist is a menu, not a calendar** — schedule only the items whose §0.9 trigger has fired for this project; an unrun scheduled check reads as coverage that doesn't exist.

- [ ] Slow-query log reviewed against the declared threshold; new offenders ticketed (§31.7, weekly).
- [ ] Outstanding expand-phase migrations checked for stalled contract phases — half-finished migrations are standing debt (§31.3, monthly).
