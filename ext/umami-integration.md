# Systems Integration Guardrails

**Extension of [Rapid Development Guardrails](../umami.md) — §24**

This extension covers service-to-service communication: API contracts, webhooks, message-based integration, resilience patterns (retry, circuit breakers, timeouts), and the testing discipline required when your system depends on services you don't control. The core template assumes a single application boundary. This extension addresses what happens when your system is one node in a network of services — internal microservices, third-party APIs, webhook providers, and message brokers.

**Apply this extension when** the §0.2 system shape questionnaire identifies an API / service layer or external integrations.

**This extension covers the communication discipline between services, not the services themselves.** How to build an API (routing, authentication, request handling) belongs in the core template and language-specific practices. How to build data pipelines belongs in [umami-data.md](umami-data.md). This extension covers what happens at the boundary — how services talk to each other reliably, how contracts are maintained, and how to fail gracefully when a dependency is unavailable.

**Scope boundary with [umami-data.md](umami-data.md):** Data pipeline concerns (delivery guarantees, schema evolution, batch vs stream, idempotent pipeline steps) are covered in §18. This extension cross-references §18 where relevant and adds the request/response and resilience patterns that §18 doesn't cover. If your system has both APIs and data pipelines, use both extensions.

---

## 24.1 API Versioning

APIs are contracts. When you change the contract, every consumer must adapt or break. Versioning makes contract changes explicit and gives consumers time to migrate. An unversioned API is an API where every change is potentially breaking and every consumer is one deploy away from an outage.

For backward/forward compatibility rules (which changes are safe, which require deprecation periods), see §18.8 — those rules apply to APIs with the same force as to data schemas.

**Rules:**

- **Choose a versioning scheme and stick with it.** The three common approaches:

| Scheme | Example | Pros | Cons |
|---|---|---|---|
| URL path | `/v1/users`, `/v2/users` | Obvious, easy to route, easy to test | URL changes break bookmarks/hardcoded links; can't version individual endpoints |
| Header | `Accept: application/vnd.api+json;version=2` | URL stays clean, can version per-endpoint | Hidden from browser/curl inspection, harder to cache |
| Query parameter | `/users?version=2` | Simple to add, visible in URL | Pollutes query string, caching complications |

URL path versioning is the most common and the easiest to operate. Use it unless you have a specific reason for header-based versioning. Do not mix schemes within the same API.

- **Version at the contract level, not the implementation level.** A version bump means the request/response shape changed in a way consumers must handle. Internal refactoring, performance improvements, and bug fixes that don't change the contract do not warrant a version bump.

- **Deprecate before removing.** When retiring a version:
  1. Announce deprecation with a timeline (minimum 3 months for external APIs, 1 month for internal).
  2. Add a `Sunset` header to responses from the deprecated version: `Sunset: Sat, 01 Nov 2025 00:00:00 GMT`.
  3. Add a `Deprecation` header: `Deprecation: true`.
  4. Log which consumers are still calling the deprecated version — reach out directly if possible.
  5. Remove only after the deadline passes and traffic drops to zero (or near-zero with explicit communication to remaining consumers).

- **Maintain a changelog.** Every API version change gets a dated entry: what changed, why, what consumers need to do. The changelog is the contract's audit trail. Without it, consumers discover changes through breakage.

---

## 24.2 Circuit Breakers and Bulkhead Isolation

When a downstream service fails, the worst thing your system can do is keep sending requests. Requests pile up, threads block, connection pools exhaust, and the failure cascades upstream — one slow dependency takes down the entire system. Circuit breakers stop this cascade by detecting failure and short-circuiting requests to a failing dependency.

For infrastructure-level reliability patterns (fault tolerance, RTO/RPO, failure testing), see §16.12. This section covers application-level circuit breaking.

**Rules:**

- **Implement circuit breakers on every external dependency.** Not just third-party APIs — internal services fail too. The circuit breaker state machine:

| State | Behavior | Transition |
|---|---|---|
| **Closed** (normal) | Requests pass through; failures are counted | → Open when failure count exceeds threshold within window |
| **Open** (tripped) | Requests fail immediately without calling the dependency; return fallback | → Half-open after cooldown period |
| **Half-open** (testing) | A limited number of requests pass through to test recovery | → Closed if requests succeed; → Open if they fail |

- **Configure thresholds per dependency.** A payment gateway that fails 3 times in 30 seconds is a different signal than a logging service that fails 3 times. Critical dependencies should have tighter thresholds (trip faster) and longer cooldowns (recover more cautiously).

- **Always define a fallback.** When the circuit is open, what happens? Options:
  - **Return cached/stale data** — acceptable for read operations where freshness isn't critical.
  - **Return a default response** — e.g., "recommendations unavailable" instead of crashing the page.
  - **Queue for retry** — for write operations that can be deferred.
  - **Fail fast with a clear error** — when there's no reasonable fallback, return an error immediately rather than hanging.

- **Use bulkhead isolation.** Give each dependency its own connection pool, thread pool, or rate limit. A dependency that consumes all available connections should not starve unrelated dependencies. The bulkhead pattern is a ship design metaphor — a leak in one compartment doesn't sink the entire ship.

```
# Pseudocode: separate connection pools per dependency
payment_pool = ConnectionPool(max=10, timeout=5s)
inventory_pool = ConnectionPool(max=20, timeout=10s)
analytics_pool = ConnectionPool(max=5, timeout=3s)
```

- **Monitor circuit state.** Expose circuit breaker state as a metric. A circuit that trips frequently signals a dependency that needs attention — not just a retry.

---

## 24.3 Retry and Backoff Discipline

Retries are the first instinct when a request fails. But undisciplined retries amplify failures — a failing service getting 3x the normal traffic (original + 2 retries from every caller) fails harder, not softer. This is the "retry storm" that turns a partial outage into a full one.

For delivery guarantee semantics (at-least-once, exactly-once), see §18.9. This section covers the mechanics of retrying safely.

**Rules:**

- **Use exponential backoff with jitter.** The retry interval should increase with each attempt, and each client should add random jitter to avoid synchronized retry waves.

```
# Exponential backoff with full jitter
delay = min(base * 2^attempt, max_delay)
sleep(random(0, delay))
```

Without jitter, all clients retry at the same time (thundering herd). Without backoff, retries hit the failing service at full speed.

- **Set a retry budget, not just a retry count.** A retry budget limits the percentage of requests that are retries (e.g., "no more than 20% of traffic to this dependency should be retries"). This adapts to load — under light traffic, 3 retries per request is fine; under heavy traffic, 3 retries per request triples the load on an already struggling service.

- **Distinguish retryable from non-retryable errors.** Not every failure deserves a retry:

| Status / Error | Retryable? | Why |
|---|---|---|
| 500 Internal Server Error | Yes | Transient server issue |
| 502 Bad Gateway | Yes | Upstream temporarily unavailable |
| 503 Service Unavailable | Yes (respect `Retry-After`) | Server overloaded |
| 429 Too Many Requests | Yes (respect `Retry-After`) | Rate limited — back off |
| 408 Request Timeout | Yes | Request took too long, may succeed on retry |
| 400 Bad Request | No | Your request is wrong — retrying sends the same bad request |
| 401 Unauthorized | No | Credentials are wrong — retry after refreshing token |
| 403 Forbidden | No | Permission denied — retrying won't help |
| 404 Not Found | No | Resource doesn't exist |
| Connection refused | Maybe | Server may be restarting, but could also be misconfigured |
| DNS resolution failure | Maybe | Transient if DNS is flaky, permanent if hostname is wrong |

- **Use idempotency keys for safe retries on write operations.** When retrying a POST/PUT that creates or modifies a resource, include a client-generated idempotency key (UUID) in the request header. The server uses this key to deduplicate — if the first request succeeded but the response was lost, the retry returns the original result instead of creating a duplicate.

```
POST /payments HTTP/1.1
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{"amount": 100, "currency": "USD"}
```

- **Log every retry.** Include the attempt number, delay, and reason. A spike in retry logs is an early warning that a dependency is degrading — often before the circuit breaker trips.

---

## 24.4 Timeout Discipline

A missing timeout is an infinite timeout. A request without a timeout will block a thread, connection, or goroutine forever when the downstream service hangs. Multiply that by concurrent requests, and the caller exhausts its resources waiting for responses that never arrive.

**Rules:**

- **Set explicit timeouts on every outbound call.** Never rely on library or framework defaults — they are often too high (30s, 60s, or infinite). Every HTTP client, database connection, queue consumer, and gRPC call should have a configured timeout.

- **Distinguish timeout types.** Each serves a different purpose:

| Timeout type | What it limits | Typical range |
|---|---|---|
| **Connect timeout** | Time to establish a TCP connection | 1–5 seconds |
| **Read timeout** | Time to receive the first byte of response | 5–30 seconds (depends on operation) |
| **Total timeout** | End-to-end time including connect, send, and receive | Read timeout + buffer |
| **Idle timeout** | Time a connection can sit unused in a pool | 30–90 seconds |

- **Timeouts must respect the dependency chain.** If Service A calls Service B, which calls Service C, the timeouts must nest:
  - Service C timeout: 2s
  - Service B timeout for calling C: 3s (2s + buffer)
  - Service A timeout for calling B: 5s (3s + buffer)

If Service A's timeout is shorter than the sum of its downstream timeouts, requests will time out at A before B has a chance to respond — even when the downstream services are healthy.

- **Use deadline propagation in service chains.** Pass a deadline (absolute timestamp) rather than a timeout (relative duration) across service boundaries. Each service checks the remaining time before making downstream calls. If the deadline has already passed, fail immediately instead of making a call that will be cancelled.

```
# gRPC-style deadline propagation
deadline = request.metadata["grpc-timeout"]  # absolute time
remaining = deadline - now()
if remaining <= 0:
    return error("deadline exceeded")
response = downstream.call(timeout=remaining - buffer)
```

- **Timeout < retry interval < circuit breaker window.** These three mechanisms must be ordered: a single request times out quickly (seconds), retries space out over longer intervals (seconds to minutes), and the circuit breaker evaluates failure patterns over the longest window (minutes).

---

## 24.5 Rate Limiting and Throttling

Rate limiting protects services from being overwhelmed — whether by a misbehaving client, a traffic spike, or a retry storm (§24.3). Without rate limiting, a single caller can consume all capacity, starving other consumers.

**Rules:**

- **Implement server-side rate limiting on every public API.** Common algorithms:

| Algorithm | Behavior | Best for |
|---|---|---|
| **Token bucket** | Allows bursts up to bucket size, refills at steady rate | APIs with bursty traffic patterns |
| **Sliding window** | Counts requests in a rolling time window | Smooth, predictable rate enforcement |
| **Fixed window** | Counts requests per clock-aligned window (e.g., per minute) | Simple implementation, but allows double-burst at window boundary |
| **Leaky bucket** | Processes requests at a constant rate, queuing excess | Smoothing traffic to a downstream dependency |

- **Return standard rate limit headers.** Clients need to know their limits and remaining quota:

```
HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1672531260
```

- **Handle 429 responses as a client.** When calling a rate-limited API:
  1. Read the `Retry-After` header and wait that long before retrying.
  2. If no `Retry-After`, use exponential backoff (§24.3).
  3. Never retry 429s immediately — that makes the problem worse.
  4. Log rate limit hits. Frequent 429s mean your usage pattern doesn't fit the API's limits — talk to the provider about a higher tier, or batch/cache your requests.

- **Manage third-party API quotas deliberately.** Track your quota usage per billing period. Set internal limits below the provider's limit to leave headroom. Alert when usage reaches 80% of quota. A rate limit hit at 2 AM because you didn't track monthly usage is a preventable incident.

- **Use backpressure, not just rejection.** When a system is under load, slowing down callers is often better than rejecting them outright. Return `503 Service Unavailable` with a `Retry-After` header, or use queue-based load leveling to absorb bursts and process at a sustainable rate.

---

## 24.6 Graceful Degradation

When a dependency fails, the user experience should degrade proportionally — not catastrophically. A failed recommendation engine should not crash the checkout page. A slow analytics service should not make the entire dashboard unusable. Graceful degradation requires knowing which dependencies are critical and what to do when each one is unavailable.

**Rules:**

- **Classify every dependency by criticality.**

| Tier | Definition | Example | On failure |
|---|---|---|---|
| **Critical** | Feature cannot function without it | Payment gateway for checkout | Block the operation, show clear error, alert immediately |
| **Degraded** | Feature works with reduced functionality | Recommendation engine for product page | Show fallback (cached, default, or empty state), alert |
| **Optional** | Feature works fine without it | Analytics tracking, A/B testing | Silently skip, log, no user-visible impact |

- **Design fallbacks before you need them.** For each degraded-tier dependency, decide in advance:
  - What cached/stale data can you serve? How stale is acceptable?
  - What default response makes sense? ("Recommendations unavailable" vs. showing popular items)
  - Can the operation be queued and completed later? (Write operations that aren't time-critical)
  - Should the feature be hidden entirely? (Feature flag that disables the UI element when the backing service is down)

- **Use feature flags at integration points.** A feature flag that disables a dependency-backed feature is a circuit breaker for the user experience. When the recommendation service is failing, flip the flag to hide the recommendation widget rather than showing error states or loading spinners that never resolve.

- **Communicate degradation to users.** When a feature is degraded, tell the user:
  - What's affected: "Search results may be slower than usual"
  - What still works: "You can still browse by category"
  - When to expect resolution (if known): "We're working on it — check status.example.com"

  Silence during degradation is worse than a brief, honest status message.

- **Test degradation paths.** If you've never tested what happens when the recommendation service is down, your first test is the next production outage. Regularly disable non-critical dependencies in staging and verify the fallback behavior works as designed. See §24.10 for integration testing strategies including fault injection.

---

## 24.7 Webhook Reliability

Webhooks invert the request/response pattern — instead of polling for changes, the producer pushes events to a consumer-provided URL. This creates reliability challenges on both sides: the producer must deliver events despite consumer failures, and the consumer must handle events that may arrive late, out of order, or more than once.

For security validation of webhook payloads (treating them as untrusted input), see §4. For delivery guarantee semantics (at-least-once, exactly-once), see §18.9 — webhooks are almost always at-least-once.

**Rules — producing webhooks:**

- **Respond to the trigger immediately, deliver asynchronously.** The operation that triggers a webhook (e.g., "order created") should not block on webhook delivery. Enqueue the webhook event and return. A slow or unreachable consumer URL should never delay the triggering operation.

- **Retry with exponential backoff.** When delivery fails (consumer returns non-2xx or connection fails), retry with increasing delays: 1 min, 5 min, 30 min, 2 hours, 24 hours. After a maximum number of retries, stop and flag the webhook as failed.

- **Sign payloads.** Include an HMAC signature (e.g., `X-Signature-256: sha256=<hash>`) so consumers can verify the payload came from you and wasn't tampered with. Use a shared secret per consumer, not a global one.

- **Include a timestamp and event ID.** The timestamp enables replay attack prevention (reject events older than N minutes). The event ID enables deduplication (§18.9 — idempotent consumers).

```
POST /webhooks/orders HTTP/1.1
X-Webhook-Id: evt_abc123
X-Webhook-Timestamp: 1672531200
X-Webhook-Signature: sha256=5257a869e7ecebeda32af...
Content-Type: application/json

{"event": "order.created", "data": {"order_id": "ord_456"}}
```

- **Provide a dead-letter mechanism.** After retries are exhausted, store the failed event and provide a way for the consumer to retrieve missed events — a replay endpoint, an event log API, or a dashboard showing failed deliveries.

**Rules — consuming webhooks:**

- **Return 2xx immediately, process asynchronously.** Acknowledge receipt before doing any work. If processing takes more than a few seconds, the producer will time out and retry — creating duplicates.

- **Verify the signature.** Compute the HMAC of the raw request body using the shared secret and compare with the signature header. Reject requests with invalid or missing signatures. Also reject events with timestamps older than your tolerance window (e.g., 5 minutes) to prevent replay attacks.

- **Handle duplicates.** Webhooks are at-least-once. The same event may arrive multiple times (producer retry after a timeout, network retry). Use the event ID to deduplicate — track processed event IDs and skip any you've already seen.

- **Don't assume ordering.** Events may arrive out of order, especially during retries. Use the event timestamp or a sequence number to detect and handle out-of-order delivery. If ordering matters, process events idempotently so that replaying them in any order produces the same result.

---

## 24.8 Correlation IDs and Distributed Tracing

When a user request touches 5 services, and one of them returns an error, correlating the failure across service boundaries requires a shared identifier. Without correlation IDs, debugging a production issue means searching logs in 5 different services for matching timestamps and hoping you find the right request.

For OTEL instrumentation infrastructure (collector setup, exporters, dashboards), see §16.15. This section covers the application-level discipline of propagating trace context across integration points.

**Rules:**

- **Generate a correlation ID at the edge.** The first service to receive a user request (API gateway, load balancer, or edge service) generates a unique request ID. Every subsequent service call includes this ID in headers.

```
# At the edge — generate if not present
X-Request-Id: req_7f3b4a2e-1234-5678-9abc-def012345678

# Propagated through every downstream call
GET /inventory/check HTTP/1.1
X-Request-Id: req_7f3b4a2e-1234-5678-9abc-def012345678
```

- **Use W3C Trace Context for distributed tracing.** The `traceparent` and `tracestate` headers are the standard for propagating trace context. Libraries (OpenTelemetry SDKs) handle this automatically — your job is to ensure every service in the chain has instrumentation enabled and that context isn't dropped at integration boundaries.

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
```

- **Include the correlation ID in every log line.** Structured logging (§4) with the request ID means you can filter all logs from all services for a single user request in one query.

```json
{"timestamp": "2025-01-15T10:30:00Z", "level": "error", "request_id": "req_7f3b4a2e", "service": "inventory", "message": "Stock check failed", "error": "connection timeout to warehouse-db"}
```

- **Create spans at integration boundaries.** Every outbound HTTP call, queue publish, and webhook delivery should create a trace span. Include: the target service, the operation, the duration, and the result (success/failure/timeout). This makes the service dependency graph visible in your tracing tool and shows exactly where latency or errors occur.

- **Don't drop context at async boundaries.** When a request enqueues a message for later processing, include the trace context in the message metadata. The consumer extracts the context and continues the trace. Without this, the trace ends at the queue and the async processing is invisible.

---

## 24.9 Contract Testing

Integration tests verify that services work together. Contract tests verify that services *agree on the shape of their communication* — without running the services together. A contract test catches "Service A expects field X but Service B stopped sending it" before deployment, not during a production outage.

For the general testing framework and test layers, see §3. For boundary type contracts, see §3 (Type Assumptions at System Boundaries). This section covers contract testing as a discipline for multi-service systems.

**Rules:**

- **Use consumer-driven contracts.** The consumer defines the contract — "I expect this endpoint to return these fields with these types." The provider verifies that it satisfies the contract. This ensures the provider doesn't accidentally break what consumers actually depend on.

| Step | Who | What |
|---|---|---|
| 1. Define contract | Consumer | "I call `GET /users/123` and expect `{id: int, name: string, email: string}`" |
| 2. Publish contract | Consumer | Contract stored in a shared registry (Pact Broker, schema registry, or git repo) |
| 3. Verify contract | Provider | Provider's CI runs the contract against the real implementation |
| 4. Deploy | Both | Both sides deploy independently, confident the contract holds |

- **Run contract verification in CI.** Contract tests should run on every provider build. A failing contract test means a deploy would break a consumer — block the deploy.

- **Detect breaking changes before they ship.** Compare the current contract against the previous version. Flag additions (safe), removals (breaking), and type changes (breaking). For API contracts, this means validating that the response schema is a superset of what consumers expect. Tools: Pact, Spectral, openapi-diff, or custom schema comparison.

- **Contract tests are not integration tests.** Contract tests verify shape (fields, types, status codes). They don't verify behavior ("when I create a user, an email is sent"). Use contract tests for fast, isolated validation of the interface; use integration tests (§24.10) for end-to-end behavior.

- **Version your contracts alongside your API versions.** When you introduce API v2 (§24.1), create v2 contracts. Maintain v1 contracts until v1 is sunset. The contract registry should show which consumers depend on which version — this is your migration tracker.

---

## 24.10 Integration Testing Strategies

Integration tests verify that services work together correctly — not just that they agree on shapes (§24.9), but that the behavior is right. Testing integrations is harder than testing isolated code because you need running services, network calls, state management, and async behavior.

For the general testing framework and test doubles, see §3. This section covers strategies specific to multi-service integration.

**Rules:**

- **Use test doubles for dependencies you don't control.** Third-party APIs can't be called freely in tests — they have rate limits, cost money, and return non-deterministic data. Replace them with service stubs that return canned responses.

| Approach | What it is | When to use |
|---|---|---|
| **Stub/mock server** | A lightweight HTTP server returning canned responses (WireMock, MockServer, nock) | Testing against third-party APIs you can't call in CI |
| **Service virtualization** | Recorded real responses replayed in tests (Mountebank, Hoverfly) | Testing against complex APIs where writing stubs is impractical |
| **Contract stubs** | Stubs auto-generated from contracts (Pact stub server) | When you already have consumer-driven contracts (§24.9) |
| **Sandbox environments** | Provider offers a test environment with test data (Stripe test mode, Twilio test credentials) | When the provider supports it — most realistic option |

- **Test failure modes, not just happy paths.** Integration tests that only test successful responses miss the majority of production incidents. Test:
  - Timeout responses (verify your timeout handling — §24.4)
  - 500 errors (verify your circuit breaker trips — §24.2)
  - 429 rate limit responses (verify your backoff works — §24.3, §24.5)
  - Malformed responses (verify your validation catches them — §3)
  - Slow responses (verify your timeout fires before the thread blocks)

- **Test async workflows end-to-end.** For queue-based integrations:
  1. Publish a message to the queue.
  2. Wait for the consumer to process it (with a timeout).
  3. Assert the expected side effect (database record, API call, event emitted).

  Use a real queue in integration tests (not a mock) — queue-specific behavior (visibility timeouts, dead-letter routing, ordering) can't be simulated accurately.

- **Isolate integration test environments.** Integration tests that share state with other tests or environments produce flaky results. Use:
  - Dedicated test databases reset between suites
  - Unique queue names or topics per test run
  - Test-specific API keys and credentials
  - Container-based environments (Docker Compose, Testcontainers) spun up per suite

- **Separate integration tests from unit tests.** Integration tests are slower, flakier, and require infrastructure. Run them in a separate CI stage. Tag them (`@integration`, `@slow`, `pytest.mark.integration`) so developers can run unit tests quickly and integration tests deliberately.

---

## Common Integration Anti-Patterns

Discipline failures that turn a distributed system into a distributed problem. Flag these during architecture reviews and code review.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Distributed monolith** | Services that must be deployed together, share databases, or can't function independently. You have the complexity of distributed systems with none of the benefits. | Each service owns its data and can be deployed independently. If two services always change together, they should be one service. |
| **Chatty services** | Service A makes 50 HTTP calls to Service B to render a single page. Network latency multiplied by call count creates unacceptable response times. | Batch requests, use a BFF (Backend for Frontend) pattern, or redesign the API to return aggregated data. If two services talk constantly, question whether they should be separate. |
| **Shared database integration** | Service A reads directly from Service B's database. The database schema becomes an implicit, unversioned API. Any schema change in B breaks A with no contract test to catch it. | Services communicate through explicit APIs or events, not shared databases. The database is an implementation detail owned by one service. |
| **"Just add a retry"** | Adding retries without backoff, jitter, or retry budgets. Turns a partial outage into a retry storm that makes the outage worse and harder to recover from. | Exponential backoff with jitter, retry budgets, idempotency keys, and circuit breakers (§24.2, §24.3). Retries are a discipline, not a band-aid. |
| **No timeout = infinite timeout** | Relying on default timeouts (which are often 30s, 60s, or infinite). A hanging dependency blocks threads until the caller itself becomes unresponsive. | Explicit timeouts on every outbound call — connect, read, and total (§24.4). |
| **Testing only the happy path** | Integration tests that only verify successful responses. Production incidents are almost always failure cases — timeouts, 500s, rate limits, malformed data. | Test failure modes explicitly: timeouts, errors, rate limits, malformed responses, slow responses (§24.10). |
| **Webhook fire-and-forget** | Producing webhooks with no retry, no signature, no dead-letter mechanism. Consumers miss events silently and data falls out of sync. | Signed payloads, exponential retry, dead-letter storage, event replay capability (§24.7). |
| **Invisible dependencies** | Service A calls Service B, but there's no documentation, no circuit breaker, no monitoring. The dependency is discovered during an outage. | Document every external dependency, instrument with tracing (§24.8), wrap with circuit breakers (§24.2), and test the failure path (§24.10). |

---

## Mapping to Core Guardrail Sections

This extension does not replace core guardrails — it extends them for the systems integration context:

| Core Section | Integration Equivalent |
|---|---|
| §2 Specs | §24.1 API versioning (API as a versioned contract), §24.9 Contract testing (consumer-driven contract specs) |
| §3 Testing | §24.9 Contract testing (shape verification), §24.10 Integration testing (behavior verification across boundaries) |
| §3 Type Assumptions | §24.9 Contract testing (explicit type contracts between services) |
| §3b Process Discipline | §24.3 Retry discipline (systematic failure handling), §24.4 Timeout discipline |
| §4 Security | §24.7 Webhook reliability (signature verification, replay prevention) |
| §4 Observability | §24.8 Correlation IDs and distributed tracing (cross-service visibility) |
| §5 State Tracking | §24.7 Webhook reliability (event deduplication, idempotent processing) |
| §8 Acknowledged Gaps | §24.6 Graceful degradation (knowing which dependencies are critical vs optional) |
| §12 Change Tracking | §24.1 API versioning (deprecation timelines, sunset headers, changelogs) |

---

## Integration Checklist (extends §15)

### Before Every Integration Change
- [ ] Contract compatibility verified — new changes don't break existing consumers (§24.1, §24.9).
- [ ] Timeout configured — explicit connect, read, and total timeouts on new outbound calls (§24.4).
- [ ] Retry strategy defined — backoff, jitter, retry budget, retryable vs non-retryable errors identified (§24.3).
- [ ] Correlation ID propagated — trace context included in new outbound calls (§24.8).

### Before Every Integration PR
- [ ] Contract tests pass — consumer-driven contracts verified against implementation (§24.9).
- [ ] Failure modes tested — timeout, error, and rate limit responses handled correctly (§24.10).
- [ ] Circuit breaker configured for new external dependencies (§24.2).
- [ ] Fallback behavior defined for non-critical dependencies (§24.6).

### Before Every New External Dependency
- [ ] Dependency classified by criticality tier — critical, degraded, or optional (§24.6).
- [ ] Rate limits documented — provider's limits known, internal limits set below provider's (§24.5).
- [ ] Authentication and secrets handled per §4 — no hardcoded API keys.
- [ ] Webhook contracts defined (if applicable) — signature verification, event format, retry policy (§24.7).
- [ ] Monitoring configured — circuit breaker state, error rate, latency, and quota usage visible (§24.2, §24.8).

### Periodic
- [ ] API deprecation review — deprecated versions approaching sunset, consumers notified (§24.1, quarterly).
- [ ] Contract health — all consumer contracts still passing provider verification (§24.9, monthly).
- [ ] Dependency health — circuit breaker trip frequency, error rates, latency trends reviewed (§24.2, monthly).
- [ ] Rate limit quota review — usage vs limits, approaching thresholds flagged (§24.5, monthly).
- [ ] Dead-letter review — failed webhooks and undelivered events investigated and resolved (§24.7, weekly).
