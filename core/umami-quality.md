# Umami — Quality / Correctness Extension

This file is part of umami v3's concern-based file architecture. The landing document ([umami.md](../umami.md)) contains the framework, Section Navigation Map, and Tier 1 practices. This file collects the *quality / correctness* concern cluster — specs, multi-layer testing, decision planning, code review, refactoring.

**When to fetch this file:** When an audit, init, or implementation task hits a Tier 2+ practice in any of §2 / §3 / §3c / §3d / §3e. The landing document's *Section Navigation Map* maps each section to its file.

**Contents:**

- §2 Specification-First Development
- §3 Multi-Layer Test Infrastructure
- §3c Interactive Decision Planning
- §3d Code Review Discipline
- §3e Refactoring Discipline

**Cross-references** in this file use plain `§N` notation. File location is metadata; section numbers are stable identifiers across all umami files.

---

## 2. Specification-First Development

Every feature starts with a written spec, not code (see *When Not to Specify* below for the exceptions — the rule is conditional, not absolute). Architecture documents and diagrams define system behavior, component contracts, and design constraints before implementation begins. These serve as the source of truth for all contributors. For AI contributors specifically, a written spec replaces inferred intent — fewer clarification questions, fewer wrong-direction implementations.

**This section establishes spec discipline, not a spec framework.** Any format works — RFCs, design docs, shape-up pitches, PRDs, Gherkin. The discipline is *having* a spec process; the format is a team preference. Cost profiles below use the Who [Agent / Operator / Specialist] · Magnitude [Hours / Days / Weeks / Months] · Shape [One-time / Recurring / Architectural / Spend] scheme — full legend in §4 *Reading the cost profiles*.

**Spec-Driven Development (SDD) frameworks.** SDD is an emerging movement around making specs executable or machine-checkable contracts the AI agent works against. Umami doesn't invent an SDD methodology — it provides the process-discipline wrapper around whichever you pick. Options range from open-source CLI methodologies (GitHub Spec Kit) and spec-workflow IDEs (Kiro) to the PRD / RFC / design-doc conventions your team already uses and Gherkin/BDD scenarios; the landscape evolves fast, so check current documentation before adopting any of them — these are pointers, not endorsements. Already using one? Keep it; §2 wraps around it without conflict. Otherwise stay format-agnostic: what matters is *having* the spec discipline (Agent-autonomous · Hours per spec · Recurring), not which framework codifies it — first-time adoption of a structured framework is typically Operator-required · Weeks and only worth it when the team wants the tooling, not just the discipline.

### What to Specify

- **System architecture** — how components connect and communicate.
- **Component contracts** — typed inputs, outputs, and configuration schemas.
- **Design system** — enforced visual language (colors, typography, spacing) so the UI stays consistent regardless of who writes the code.
- **Data contracts** — data shapes validated at design time, catching mismatches before runtime.

### When Not to Specify

Specs have diminishing returns. Over-specifying is its own form of waste — a spec that takes longer to write than the implementation it describes is overhead, not discipline.

**Skip the spec when:**
- The change is trivial — typo fixes, config tweaks, adding a log line, updating a dependency version.
- The implementation is smaller than the spec would be — if describing the work takes more effort than doing the work, just do the work.
- The behavior is already fully specified by an existing test — writing a new spec that restates what the test already captures adds no value.
- You're prototyping to learn — write the spec *after* the prototype clarifies the requirements, not before. Specifying unknowns produces fiction, not contracts.

**The signal:** If you find yourself writing a spec and realizing you can't specify the behavior because you don't understand the problem well enough, stop specifying and start prototyping. A prototype that reveals the right spec is more valuable than a spec that encodes the wrong assumptions.

---

## 2b. Async Channel Contracts

§2's "What to Specify" list covers a module's static interface — exported functions, types, configuration schemas. Modules have a second interface too: the **dynamic / async surface** — events emitted, messages sent, errors raised, worker output streamed. In most codebases that surface is implicit, and that's where leaks happen: a global event bus delivering a message to a subscriber that shouldn't see it, an untyped payload routed by guess, a catch-all UI notification surface that any code can write to, a shared worker-output region where multiple streams interleave. The leak surfaces as *"a message appeared in the wrong part of the app"* — usually long after the code that emitted it was forgotten.

§2b makes the async surface a first-class spec artifact, sitting alongside the data dictionary and source registry that §2 already covers. **Same discipline as static interfaces; different artifact shape.**

**Cost profile:** Agent-with-review · Days per module (first-time migration) / Hours per new channel (steady state) · Architectural + Recurring discipline

**Adopt when (§0.9 default-deny):** the project has async surfaces *and* a wrong-place-message incident (or documented near-miss) has actually occurred. Pre-adoption incident count = 0 means **defer** — record the deferral and move on. Everything below describes the discipline once that trigger has fired; don't migrate a leak-free codebase preemptively.

**§2b vs. §4 untrusted-content boundaries — same shape, different problem.** Both use a four-part pattern (typed wrapper + origin/provenance + allowed-list + audit-on-add), so they are easy to confuse. They are *not* interchangeable:

| | §2b Async Channel Contracts | §4 Untrusted-content boundaries |
|---|---|---|
| **Problem solved** | *Reachability* — which code may receive this message | *Trust* — whether this content is safe to act on |
| **Guards against** | A message surfacing in the wrong part of the app | Injected / malicious external content reaching the model |
| **Applies to** | Internal async surfaces (events, worker output) | Externally-sourced content (web, user input, tool output) |

Apply §2b to internal async surfaces; apply §4 to externally-sourced content. A single channel can need both.

### The four parts

For every async surface (event, message, notification, error stream, worker output), declare:

1. **Typed channel.** Named, typed payload — TypeScript discriminated union, Rust enum, dataclass with `kind:` field, equivalent. Not `string`, not untyped `event`, not `any`. The type discriminator turns "what arrived?" from a runtime question into a compile-time one.

2. **Origin tag.** Which module owns this channel. One owner per channel; co-ownership is a smell that usually means the channel needs splitting. The origin tag travels with the payload so consumers can route on it without inferring from context.

3. **Allowed-consumer list.** Which modules may subscribe. Defaults to "the owning module only" unless the channel is explicitly a cross-module contract. "Anyone may subscribe" is not a default — it's a deliberate design choice with its own justification.

4. **Audit-on-add at code review.** Any new channel, or any new subscriber to an existing channel, gets reviewed against the spec (this is a §3d code-review gate, not a runtime check). The reviewer asks: *"Is this channel in the spec? Is this consumer on the allowed list? If not, why is the spec wrong, or why is this subscriber inappropriate?"* Treat *"I just need to subscribe to this one event from over there"* as a leak indicator — most leaks start as one-off exceptions nobody removed.

The four parts compose. A typed channel without an origin tag tells you the shape but not who's allowed to send it; an origin tag without an allowed-consumer list tells you who sends it but not who may listen; either without audit-on-add lets the spec drift silently the moment delivery pressure rises.

### Fitness function (Tier 3 escalation)

When the practice matures, an architectural fitness function (§3 *Architectural Fitness Functions*) detects cross-module subscribers that aren't on the channel's allowed-consumer list. Approaches vary by stack:

| Stack | Approach |
|---|---|
| TypeScript / JavaScript | Import-direction lints (`eslint-plugin-boundaries`, `dependency-cruiser`) plus a custom rule walking event-bus subscriber registrations |
| Rust | The type system enforces this when channels are module-private (`pub(crate)`); the fitness function checks no channels are leaked through `pub use` against the spec |
| Python | `import-linter` contract layers plus a registry-walker inspecting subscriber bindings |
| Generic | A test that loads the channel spec and asserts every registered subscriber appears on the allowed-consumer list for the channel it subscribes to |

The fitness function turns "we should keep this clean" into "the build fails when it isn't." Don't reach for it on day one — it's the Tier 3 escalation when audit-on-add proves insufficient at the team's pace.

### Anti-patterns

| Anti-pattern | Why it leaks | Remediation |
|---|---|---|
| **Global event bus with no topic scoping** | Every subscriber sees every event; "wrong consumer" is a runtime accident waiting to happen | Replace with per-domain typed channels. A bus is fine as the *transport*; the channels riding on it must be scoped |
| **Untyped message payload (`any`, `Map<String, Object>`, raw JSON, untyped `event`)** | Consumer can't tell what arrived or where it came from; routes by guessing | Discriminated union with a `kind:` discriminator and an `origin:` field. Validate payload at the boundary, not in the consumer |
| **Catch-all UI notification surface** | One toast root receives all messages from all modules; nothing scopes a notification to its originating view | Scoped notification surfaces per view region. The toast root is a fallback for genuinely global events, not the default destination for every async message |
| **Shared worker / stream output display** | Multiple background workers or streams write to one shared output region; messages interleave and lose origin | Per-worker output channel with a typed wrapper indicating which worker / stream produced each line. The display layer routes on the wrapper, not on arrival order |

### Watch signals

| Signal | What it catches |
|---|---|
| Wrong-place-message incidents per quarter | Pre-adoption: count > 0 is the trigger for relevance — the discipline pays for itself only if leaks are happening. Post-adoption: target 0; any non-zero means audit-on-add isn't catching the leak at the boundary |
| Number of subscribers per channel | A channel with 1 origin and 30+ subscribers is a global-bus smell wearing a typed-channel costume; audit whether the wide fan-out is intentional or inertia |
| Number of untyped / `any` channels | Should trend to zero in steady state. Any non-zero count is deferred risk — the leak that hasn't happened yet |
| Subscribers registered far from where their containing module lives | If `modules/billing/` subscribes to a channel owned by `modules/inventory/` and the subscription is in `modules/ui/notifications/`, the wiring is hiding ownership. Move the subscriber to its owning module or split the channel |

### Failure modes

| Failure mode | Symptom | Fix |
|---|---|---|
| Spec lists channels but doesn't list consumers | Specs that record the typed channel and origin but skip the allowed-consumer list — looks complete, fails to catch leaks | Allowed-consumer list is non-optional. If "anyone may consume" is the intent, write that down explicitly — that's a different design choice than "we forgot to specify" |
| Audit-on-add becomes rubber-stamp | New subscribers added in PRs that don't reference the channel spec; reviewers approve without checking | Add a §3d code-review checklist item: *"If this PR adds an async subscriber, did the reviewer verify the consumer is on the allowed list?"* Promote to fitness function when rubber-stamping persists |
| Cross-module channels grow to be the majority | Most channels end up cross-module because everything happened to need to see everything — at which point the spec stops constraining anything | The right per-channel scope is one owning module + a small allowed-consumer list. If most channels are wide-open, the modules are probably too small or the wrong boundaries — surface as a §1 *Preserving Project Structure* concern |
| Discipline applied unevenly | New code uses typed channels; legacy code still posts to a global bus; the leak surface is the legacy edge | Inventory existing async surfaces during initial adoption; migrate the highest-fan-out ones first; track the rest in §8 acknowledged gaps with a removal trigger |

### Cross-references

The four-part pattern is the structural parallel to §4's untrusted-content-boundary discipline — the differentiation table at the top of this section covers the distinction (reachability vs. trust). Cite the parallel, don't merge the disciplines: the failure modes and remediations diverge, and conflating them invites the "Winchester Mansion sprawl" anti-pattern.

- §1 *Preserving Project Structure* — structure-as-contract framing makes "this consumer shouldn't subscribe to that channel" a structural violation, not a style preference
- §3 *Architectural Fitness Functions* — the Tier 3 escalation when audit-on-add isn't enough
- §3d *Code Review Discipline* — the gate where audit-on-add fires; any new channel or subscriber is an audit-on-add trigger
- §4 *Untrusted-Content Boundaries* — the structural parallel (different scope, same four-part shape)
- §8 *Acknowledged Gaps* — track legacy async surfaces awaiting migration; pre-stage the removal trigger

---

## 3. Multi-Layer Test Infrastructure

Testing spans the full stack across complementary layers:

| Layer | Purpose | Catches |
|-------|---------|---------|
| **Unit tests** | Logic correctness | Regressions in parsers, validators, state management, utility functions |
| **Property-based tests** | Invariant correctness across generated inputs | Edge cases you didn't think of — boundary values, empty inputs, unicode, overflow |
| **E2E browser tests** | User flow integrity | Broken interactions, navigation failures, data persistence issues |
| **Visual regression** | Pixel-level UI stability | Unintended cosmetic changes; baselines updated only for intentional changes |
| **API/service tests** | Contract adherence | Protocol violations, serialization errors, edge cases in data handling |

The layers above cover **deterministic** verification. For LLM-feature products, *Tests and Evals* (next sub-section) adds **non-deterministic** (eval) verification, and *Multi-Provider Behavioral Testing* (further below) adds the provider × substrate-level matrix.

Sub-sections below carry **Cost profile** annotations — same Who · Magnitude · Shape scheme as §2 above (full legend in §4 *Reading the cost profiles*). The §0.6 tier table places each practice in Foundation / Structure / Scale; the cost profile tells you what adopting one looks like in time, expertise, and money.

### Tests and Evals — verification's two halves

The test types in the table above cover **deterministic verification**: given a known input, the system produces a known output, and a piece of code checks that. AI-feature products introduce a second verification problem: **non-deterministic agent behavior** — did the agent take the right trajectory, choose the right tools, produce output meeting the quality bar? You can't unit-test "the agent reasoned well." But you can *evaluate* it.

| | Tests | Evals |
|---|---|---|
| **What it verifies** | Deterministic parts: function input → function output | Non-deterministic parts: agent trajectory, tool choice, response quality |
| **Checked by** | Code (assertion libraries, property generators, runtime fixtures) | Labelled datasets, scoring rubrics, LLM judges |
| **Failure shape** | Function returns the wrong value | Agent skipped a step, used the wrong tool, or fluently produced a confident wrong answer that looks right at a glance |
| **CI integration** | Standard test runner; per-commit | Eval suite as a separate job; gate Tier-1 cells per commit, full matrix nightly or per-release (see *Multi-Provider Behavioral Testing* below) |
| **Cost shape** | Hours per test; Days per layer | Days per eval suite + ongoing token cost per run; expect 10–100× the per-run cost of a unit-test suite |

Tests and evals are **complementary, not interchangeable**. A product that ships with only tests verifies the deterministic skeleton but not the AI-driven flesh; a product with only evals catches the agent's behavior but misses correctness regressions in the surrounding code. **Without both, the development posture sits closer to vibe coding regardless of how sophisticated the prompts are** — see §0.6b *AI-Discipline Spectrum* for why this matters for billable / production / compliance-bound work, and Osmani/Saboo/Kartakis 2026 (*The New SDLC with Vibe Coding*) for the original framing.

For LLM-feature products specifically, see *Multi-Provider Behavioral Testing* below for the eval-side discipline (provider × substrate-tier matrix, real-provider RTT, gate cells by tier).

### Property-Based Testing

Example-based tests verify the cases you thought of. Property-based tests find the cases you didn't. Instead of specifying individual inputs and expected outputs, you define *properties* (invariants) that must hold for *any* valid input, and the framework generates hundreds or thousands of test cases automatically.

**Cost profile:** Agent-with-review · Days per area · Recurring discipline

**When to use:**
- **Parsers and serializers** — "parse(serialize(x)) should equal x for any x."
- **Data transforms** — "output row count should equal input row count" or "no nulls in required fields after transform."
- **Business rules** — "discount never exceeds the item price" or "account balance never goes negative."
- **API contracts** — "response schema is valid for any combination of query parameters."

**When not to use:** UI interactions, integration tests with external services, or any test where the property is harder to state than the individual cases.

**Frameworks:** Hypothesis (Python), fast-check (JavaScript/TypeScript), QuickCheck (Haskell/Erlang), Proptest (Rust), jqwik (Java).

**Token impact for AI development:** Property-based tests are especially valuable when agents write code, because agents tend to test the happy path and common edge cases but miss unusual input combinations. A property-based test suite catches bugs the agent (or human) would never think to write example tests for.

### Testing Principles

- **Baselines are version-controlled artifacts** — screenshots and snapshots checked into git, not generated on the fly.
- **Update baselines only for intentional changes** — this prevents cosmetic drift and makes every visual change a deliberate decision.
- **Run tests before committing UI changes** — always. No exceptions.
- **Hard timeouts on all test layers** — per-test timeout, global kill switch, and memory caps prevent runaway processes.
- **Document pre-existing failures** — known failures that aren't your bugs should be listed so contributors don't waste time diagnosing them.

### Test Doubles for External Dependencies

Production code should target production infrastructure. Tests should run without that infrastructure. The solution is a thin adapter in the test suite — not conditional branches in production code.

**Cost profile:** Agent-autonomous · Hours per dependency · One-time setup

**Wrong:** Scattering `if test_mode then ... else ...` throughout production code so it works with both a real service and a test substitute. This doubles maintenance, masks integration issues, and makes production code harder to read.

**Right:** Write production code for the production target only. In `tests/`, create a lightweight adapter that conforms to the same interface but translates to a simpler backend. The adapter is never imported by production code.

**When to use:** Any dependency that requires infrastructure to run — databases, HTTP services, message brokers, file storage, email providers. The adapter pattern lets unit and integration tests run instantly without containers or network access.

**When NOT to use:** Integration tests that are specifically validating the real infrastructure. Mark those tests separately (e.g., `@pytest.mark.integration`) and run them against the real thing in CI or manually.

### Type Assumptions at System Boundaries

When data crosses a boundary between two tools (export → import, API response → client model, serialization → deserialization), type coercion failures are the most common source of integration bugs. Each tool has its own default type representations, and they rarely agree.

**Cost profile:** Agent-with-review · Hours per boundary · Recurring discipline

**The pattern:** Tool A exports data in a format that looks correct to Tool A. Tool B imports it and fails because its type expectations are stricter, looser, or simply different.

**The discipline:** Every time data crosses a tool boundary, audit the type assumptions on both sides. Don't assume that "it worked in Tool A" means it will load cleanly into Tool B. Test the boundary explicitly — ideally with a small representative sample — before running the full pipeline.

Common failure categories:
- **Nullability differences** — one side allows nulls, the other doesn't, or null is represented differently (empty string vs. `NULL` vs. omitted field).
- **Numeric precision** — one side uses integers, the other uses floats, or precision/scale constraints differ.
- **Sentinel values in typed columns** — source data uses human-readable markers (text) in columns the schema declares as numeric or boolean.
- **Auto-generated fields** — one side includes them in exports, the other expects them to be auto-populated on import.
- **Temporal types** — native datetime objects vs. ISO strings vs. Unix timestamps. Timezone-aware vs. naive.

**The fix is always the same:** make the boundary contract explicit. Specify column lists, validate types before crossing, and test with real data samples — not just the happy path.

### Architectural Fitness Functions

§3 above covers tests at unit / integration / E2E / property / boundary layers. **Architectural fitness functions** are a distinct test layer: automated tests that verify *architectural invariants* — the "is the architecture still healthy?" question that unit tests and linters don't answer.

**Cost profile:** Operator-required (define constraints) + Agent-autonomous (implement) · Days–Weeks · Architectural + Recurring discipline

| Test layer | Verifies | Example |
|---|---|---|
| **Unit** | One function's correctness | `add(2, 3) == 5` |
| **Integration** | Components compose correctly | API endpoint returns expected schema |
| **E2E** | Whole user flow works | User logs in, performs action, sees result |
| **Property-based** | Invariants hold across input space | `reverse(reverse(xs)) == xs` |
| **Linter / type checker** | Code style / type correctness | No unused imports; types align |
| **Architectural fitness function** | Architecture invariants hold | No module imports from a layer above its own; service-to-service P99 latency < 200ms |

Distinguishing feature: fitness functions test *structural and quality properties of the architecture itself*, not the behavior of any individual component. Originated in *Building Evolutionary Architectures*; developed further in *Software Architecture: The Hard Parts*.

**Categories:**

| Category | What it tests | Common implementations |
|---|---|---|
| **Structural** | Module / layer boundaries, dependency direction, naming conventions, file location rules | ArchUnit (Java), ts-arch (TypeScript), import-linter (Python), custom AST-walking scripts |
| **Performance** | Latency budgets, memory limits, throughput targets | Benchmark-as-test in CI; alert if P99 > X |
| **Security** | Absence of known anti-patterns (untrusted-content reaching model without wrap, secrets in logs) | Static analysis with custom rules; per-PR security checks |
| **Operational** | Observable signals (every endpoint emits a metric, every error has a trace ID) | Test that probes the running app for required signals |

Fitness functions complement, not duplicate, umami's other gates: §0.6 watch signals detect *process* anti-patterns, §3d Layer 1 checks *correctness*, §4 audit-on-add gates at *review time* — fitness functions are the *architecture* check that runs in CI.

**When to introduce them:**

- The project has clear architectural boundaries (modules / layers / services) you don't want violated
- Linter rules can't express the constraint (most architectural rules can't)
- The team has been bitten before by boundary violations
- The codebase is large enough that humans can't catch all violations in review

**Velocity check.** Fitness functions are Tier 3 / Scale — they pay off in larger codebases where the team has been bitten by boundary violations. Adding them to a prototype, or to a codebase already adequately covered by linter rules, is over-investment. The §0.6 anti-patterns "Cargo-culting practices" and "Adopting everything at once" apply: fitness functions feel rigorous, which makes them easy to over-adopt.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Fitness function added but never fails | Either the constraint is too loose, or the codebase already complies and the test is documenting rather than verifying |
| Fitness function disabled "we'll fix it later" | Constraint isn't being upheld; technical debt accumulating invisibly |
| Fitness functions only added after incidents | Reactive coverage; team isn't proactively encoding constraints |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Fitness functions as documentation | Test exists, asserts something always true; never fails | Change the constraint to actually catch something, or delete the test |
| Linter rules dressed up as fitness functions | The check is "no unused imports" — that's a linter | Reserve the term for genuine architecture constraints; keep style checks in linters |
| Fitness functions blocking CI for unrelated work | A change in module A breaks a coarse fitness function | Scope fitness functions to specific layers / concerns; multiple narrow functions beat one big one |
| Fitness functions never updated | Architecture evolved but tests still encode the old shape; tests pass but mean nothing | Update fitness functions when architecture changes; treat them as architecture documentation |

**Cross-references:**
- §3 above — fitness functions are a test layer alongside unit, integration, E2E, property-based, behavioral
- §6 enforced consistency — fitness functions enforce structural / dependency rules that linters can't express
- §15 pre-commit checklist — fitness functions run in CI as part of the gate

### Multi-Provider Behavioral Testing

For LLM-feature products whose correctness depends on the model's behavior — tool-calling shape, structured-output adherence, instruction-following, refusal behavior — test across the providers you actually serve in production. A test that passes only on one provider is silent regression risk for the product's other code paths.

§3 above covers test layers (unit, integration, E2E, property-based); this sub-section adds the *provider matrix* and *substrate levels* dimensions specific to LLM-feature products. (*Substrate levels* are an axis of test complexity — unrelated to §0.6 *adoption tiers*; see the terminology note in §0.6.)

**Cost profile:** Specialist-required (LLM infra knowledge) · Weeks setup, ongoing per-release · Architectural + Spend (per-run provider API costs)

**Two dimensions of coverage:**

| Dimension | What it covers |
|---|---|
| **Provider matrix** | The set of LLM providers your product serves (Anthropic / OpenAI / Gemini / Ollama-local / etc.). A behavioral test runs against each |
| **Substrate levels** | Progressive complexity. Level 1: single tool call working. Level 2: multi-step workflow with multiple tools. Level 3: full agent workflow with sub-agents and recursive dispatch. Each level exercises more substrate; each surfaces different failure modes |

The substrate-level model above is one product's shape — a tool-using agent harness. **Substitute the substrate categories that fit your product's actual feature surface.** A chat-only product won't have tool-call levels (consider tiering by conversation length / context-window pressure / refusal-rate calibration instead). A RAG product might tier by retrieval-quality vs. generation-quality dimensions. A code-completion product might tier by completion-length and language coverage. The point is *progressive substrate exercise*, not the specific levels below.

Coverage is providers × substrate levels — at scale, dozens of cells. Not every cell needs to run on every change; gate critical cells on every commit, run the full matrix nightly or per-release.

**Velocity check.** Level 1 (single tool call working) on the primary provider is enough until features compose. Building the full provider × substrate matrix before the product ships features that require multi-provider parity is over-investment — bench cost (API spend, infra, engineering hours) doesn't earn back without behavior the bench actually catches. Match bench depth to feature surface; see §0.6 "Security investment outpaces threat model" for the broader pattern (which applies to behavioral verification too).

**What this catches that lib/bin tests don't:**

- Provider-specific tool-schema strictness (one provider rejects schemas another accepts)
- Per-provider pricing defaults (cost calc right for one provider, drastically off for another)
- Tool-calling format differences (native tools vs text-fallback parsing)
- Model-hint threading (whether the right model gets routed through the right provider's adapter)
- UTF-8 boundary safety (some providers handle non-ASCII tool args differently)
- Substrate edge cases that only surface in real provider RTT — timing, streaming, error shapes, rate-limit behavior

These are gaps lib/bin tests structurally can't reach: they mock provider behavior. Once shipping an LLM-feature product, correctness depends on the provider's *actual* output, not on a mock.

**The bench-pays-for-itself observation.** A multi-provider bench is meant to *verify* substrate; in practice the first run is also a substrate-gap *discovery* exercise. Plan for this — bench bring-up is not one-shot validation, it's a discovery cycle. Real bench bring-ups have surfaced and closed 10+ substrate gaps that lib/bin tests didn't reach.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Bench passes on N of M providers your product serves | Behavioral guarantee covers N; the gap between N and M is silent regression risk |
| Substrate gap discovered in production but not in bench | Coverage hole — the cell that should have caught the gap doesn't exist or doesn't exercise the path |
| Bench non-determinism (results vary across runs against same provider) | Bench has timing dependencies, model has temperature > 0, or substrate has a race condition |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| "We test on the cheapest provider" | Bench runs only on the fast/cheap model; production traffic on flagship models has different behavior | Test the providers you actually serve. Cost is real but behavioral parity isn't optional |
| Level 1 only | Bench covers single tool calls; ships break on multi-step workflows once they land | Add Level 2 (multi-step) at minimum once features compose tool calls; Level 3 (sub-agents) when the product dispatches |
| Manual bench runs | Bench runs only when someone remembers; regressions slip in between runs | CI-gate the bench. For full-matrix runs that are slow/expensive, schedule nightly with explicit pre-release gates |
| Provider mocks instead of real provider | Bench uses recorded fixtures; doesn't catch behavioral changes the providers ship | Fixtures sparingly (cost-bounded CI on every PR); full real-provider matrix at known cadence (nightly, per-release) |

**Cross-references:**
- §3 multi-layer testing (above) — multi-provider bench is a layer above E2E for LLM-feature products
- §4 untrusted-content boundaries — bench should include planted-injection cases per provider's spotlighting strategy
- §9.7 measuring efficiency — bench produces ET per provider per substrate level; useful for cost-comparison and regression detection
- §0.5 LLM-feature-product row references this

---

## 3c. Interactive Decision Planning

When designing something with multiple load-bearing decisions, work through them **one at a time**, not in a batched response that asks the user to engage with five forks simultaneously. This prevents the "design got rubber-stamped because I couldn't engage with 7 forks at once" failure mode.

Note that §3c addresses *interactive design with the user*, while §3b's "Surface Ambiguity" addresses *individual unclear requests*. Surfacing one ambiguity is a single round-trip. Stepping through a sequence of compounding decisions is a protocol.

### When to use

Engage the protocol when **all** of these apply:

- The conversation has 3+ load-bearing decisions that compound on each other (the answer to decision 2 changes the options for decision 3).
- Reasonable people would disagree on the answers — there isn't one obvious choice.
- Locking the wrong choice would be expensive to undo.
- The user signals they want care: *"step me through these one by one"*, *"plan this carefully"*, *"let's plan this"*, *"stop blasting me"*.

If those don't all apply, just decide and move on. The protocol is overhead for routine work.

### When NOT to use

- Routine implementation choices ("what should I name this function?" — just decide).
- Time-pressured fixes ("the build is broken, just fix it").
- Decisions with one obviously-correct answer.
- Decisions outside the assistant's domain (web copy, business calls, color choices).

### The cycle (six steps per decision)

1. **Restate the question** in plain language — the underlying choice, not the surface implementation question. ("The real question is whether undo is per-edit or per-session.")
2. **Lay out 2–4 concrete options** — each a real position someone might defend, with what it costs and what it buys. Avoid 7 — that's a brainstorm dump, not a decision.
3. **Recommend one option, with reasoning** — pick a defensible default. The user can override. Refusing to recommend pushes synthesis back to the user and defeats the protocol.
4. **Surface sub-questions** — most decisions are 2–5 micro-decisions stacked. Name them so the user knows what's under the headline question.
5. **Stop.** Wait for the user's response. Resist the urge to provide three more decisions speculatively.
6. **When the user answers, lock cleanly** — restate the locked decision concisely (2–5 sentences), capture in the decisions log if material (§12; write an ADR per §7 if architectural), then move to the next decision in a *separate* turn. Don't combine "lock previous + setup next" in one beat.

### Failure modes to avoid

| Failure mode | Symptom | Fix |
|---|---|---|
| Gigantic batched questions | One response with 5+ headings, each forking. | Pick the next single most-blocking decision; defer the rest. |
| Pre-deciding for the user | "Going with (b) since that's obvious." | Recommend, never act on the recommendation until explicitly locked. |
| Skipping the recommendation | Lay out 4 options, refuse to recommend, ask "what do you think?" | Pick one. Pushing synthesis back to the user defeats the protocol. |
| Restating without locking | Same decision laid out twice across turns without durable capture. | When the user answers, lock it (durable text) before moving on. |
| Combining lock + next-decision setup | Response that says "OK locked sub-1; here's sub-2 with options A/B/C/D." | Separate beats. Lock first, then the next decision in a fresh turn. |
| Made-up time estimates inside decisions | "This option is ~2 weeks of work; the other is ~4 days." | Describe scope (subproblem count, relative size, known-vs-unknown ratio); user does velocity arithmetic. See the §0.6 anti-pattern catalog. |
| Prompt requires scroll-back to make sense | "Which one?" / "Option A or Option B?" rendered in a dialog UI where the user can't see preceding chat. | Make each prompt self-contained — state the decision and its options inline, not via reference to chat history. See §3b "Make each prompt self-contained." |

### Calibration heuristic

You can tell whether the protocol is working from the relative length of the user's responses to yours:

- If the user's previous response is **shorter than your next response by ~5x or more**, you're over-asking. Trim the next round.
- If the user's responses **get shorter** as the conversation proceeds (`yes`, `b`, `c`, `looks good`), the protocol is working — they're trusting your recommendations and confirming with low effort.
- If the user **pushes back on framing or recommendations** ("actually you're missing option D", "the right answer changes if X"), the protocol is *also* working — they're engaging with substance. Lean into those moments.
- If the user says **"you're not stepping through these one by one"** or **"stop blasting me"**, you've drifted. Reset.

The slow path produces better designs *because* it forces engagement — the cost is overhead per decision, the benefit is decisions that were actually decided rather than rubber-stamped.

### Output format discipline

State the output format you want before asking for the answer — markdown decision matrix, ADR-shaped doc, JSON, prose with section headers, table with specific columns. LLMs guess the format if you don't, and often guess wrong. Applies to both interactive decisions (text in chat) and structured-output prompts (a file or artifact). One sentence in the prompt prevents an output-shape rework round-trip.

---

## 3d. Code Review Discipline

In agentic coding, code generation often outpaces human review capacity. The traditional model — humans reading every diff — degrades silently as velocity rises: it either becomes rubber-stamping ("LGTM, didn't really read it") or the bottleneck that defeats the velocity gains. §3d frames code review as **attention management**: a three-layer system that lets mechanical gates and AI pre-screening handle most changes, focusing human attention only where it's earned.

§3d operationalizes the **reviewing mode** of AI use (see §14). The reviewer agents in this system are reviewing-mode agents — read-only critics that produce structured findings, not approval/rejection.

### Why agentic code review is structurally different (not just statistically harder)

The first-pass instinct is to treat AI-authored code like junior-developer code: maybe more bugs, maybe more boilerplate, but reviewed the same way. That instinct misses the structural change. **Traditional review verifies the author's reasoning against visible intent** — the author wrote the code with a goal in mind, that goal is recoverable from the commit message / PR description / inline comments / the author's own answers to "why this way?", and the reviewer's job is to check the reasoning. **Agentic review faces an inverted problem: agents produce reasoning during generation but discard it before submission.** What lands in the PR is the conclusion, with the chain of thought stripped. The reviewer is, in Osmani's framing, *"the first human to ever lay eyes on this code"* — review stops being verification and becomes intent reconstruction.

This is why agent code review takes 3–4× longer than human code review even when the agent's code is competent (Faros AI 2026: review duration up 441.5% as AI adoption rose, with zero-review merges up 31.3% as a coping response). The cost increase isn't because the code is worse on the page — it's because the intent that used to come for free now has to be reconstructed from scratch, and that work is expensive.

**The mitigation has two halves.** First, push intent-capture *upstream* — the agent (or the human prompting the agent) records the goal, the constraints, the alternatives considered, and the rejected paths as part of the PR artifact. Cheap when written, expensive when reconstructed. Second, **don't pretend the reconstruction work is optional** — the rest of §3d is structured around making the reconstruction tractable: mechanical gates filter the cases that don't need it, AI pre-screen surfaces the failure modes a human reviewer should focus on, risk taxonomy decides which reconstructions are worth the time, and spot-check sampling catches the cases where the system trusted wrongly.

**Empirical backdrop for the discipline:** CodeRabbit's 470-PR benchmark (Dec 2025) found AI PRs surface 1.7× more issues than human PRs — logic/correctness +75%, security 1.5–2×, readability 3×+. A 4-reviewer-tool heterogeneity study (146 PRs / 679 findings, 2026) found 93.4% of findings were caught by **exactly one tool**, zero findings by all four — strong evidence that running multiple reviewers with different architectures catches more than running the single "best" reviewer. See *Cross-provider review* below for how umami structures the heterogeneity discipline; see Osmani, A. 2026 *Agentic Code Review* for the full evidence base.

### The three-layer model

| Layer | What it does | When it runs | Decision criterion |
|---|---|---|---|
| **1. Mechanical** | Linters, formatters, type checkers, tests, coverage delta, diff-complexity heuristics | Every change, automatically | Pass / fail gates |
| **2. AI pre-screen** | Reviewer agents that produce a structured **flags document** (non-blocking) | Every non-Trivial change that passes Layer 1 (Trivial-classified changes may auto-merge on the mechanical gate alone — see *Risk taxonomy* below) | Output is findings, not approval |
| **3. Risk-classified human focus** | Human review on changes meeting risk classification OR flagged High by Layer 2 | Only changes that match dimension/signal triggers OR auto-review flagged High | Human reads flags doc + diff |

### Risk classification

Layer 3 routes only the changes that warrant it to humans. Classification has two parts: the *dimensions* of risk (the why) and the *signal categories* that detect them (the how).

**Dimensions** — three universal ones, plus project-specific ones to extend with:

| Dimension | Coverage |
|---|---|
| **Security** | Auth, authorization, secrets, crypto, attack surface |
| **Data integrity** | Database writes, schema changes, financial calc, state transitions |
| **Contract integrity** | Public APIs, breaking changes, exported interfaces |

Most projects also need to extend with *some* of: dependencies (supply chain), infrastructure (CI/build/deploy), observability (logging/metrics), compliance (audit-trail requirements), latency (real-time apps), accessibility, internationalization. Projects with regulated data or unusual constraints often have dimensions that don't appear here at all. The list above is a starting kit, not a fixed schema.

**Signal categories** — universal across projects:

| Signal type | What it matches |
|---|---|
| **Path patterns** | Files / directories that historically map to a risk dimension (`auth/`, `db/migrations/`, `*.sql`, `Dockerfile`) |
| **Diff content** | Strings, identifiers, or patterns within the change (references to `password`/`token`/`secret`, modifications to exported function signatures, new dependency entries) |
| **Change type** | Kind of edit (new dependency added, file deleted, schema migration created, new public method exported) |

A project's risk classification is the mapping between dimensions it cares about and signals that detect them — typically a small table maintained alongside the change-propagation map (§10).

**Three cross-cutting scaling axes** (after Osmani 2026 *Agentic Code Review*): the dimensions above describe *what kind* of risk; these three axes describe *how much*. Apply them across every dimension when deciding the risk level (defined in the next sub-section):

| Axis | What it asks | Lower = lighter review | Higher = deeper review |
|---|---|---|---|
| **Blast radius** | If this is wrong, what's the consequence? | Nothing breaks, a dev-only tool misbehaves | Production users see it, money is at risk, PII leaks, a security boundary moves |
| **Code lifespan** | How long will this code be in service? | Days (one-week experiment, throwaway PoC) | Years (production system, long-lived infrastructure) |
| **Knowledge-sharing scope** | Who has to understand this code to maintain it? | Solo (one person owns it) | Team / many maintainers (review is the knowledge-transfer mechanism) |

**Use:** assign the **risk level** (Trivial → Critical in the next sub-section) to the **maximum** of the three axes for the change, not the average. A "security" change with low blast radius + short lifespan + solo scope is meaningfully different from the same dimension with high blast radius + long lifespan + team scope; flattening them produces over-review on the first and under-review on the second. The three-axis decomposition is what catches the *"prototype that shipped by accident"* failure mode (see §0.6b *AI-Discipline Spectrum* — once a piece of code lives in a higher-stakes context, its risk level needs to graduate with it; quietly keeping it at the original risk level is how vibe-coded prototypes become production fragility).

### Risk taxonomy and auto-merge thresholds

The three-layer model determines *who reviews*; the risk taxonomy determines *what happens after review*. Each change gets classified into a **risk level**; the level determines the default disposition. The taxonomy below is a starting kit — projects extend with their own levels and overrides.

| Risk level | Examples | Default disposition | Required guardrails |
|---|---|---|---|
| **Trivial** | Typo fixes, dependency version bumps in lockfile, formatting-only, generated-file regeneration | Auto-merge if mechanical layer passes | Branch protection requires green CI; spot-check sample applies |
| **Low** | Internal refactor (no public API), test additions, documentation updates, comment cleanup | AI pre-screen + auto-merge if no flags raised | + Cost-cap on reviewer (§9.7); notification to author on merge |
| **Medium** | New feature behind a flag, UI change, performance-sensitive code | AI pre-screen + 1-human spot-check at ≥5% sample | + Flags document required; merge requires human acknowledgment of flags |
| **High** | Auth/authz, payment flows, schema migration, new dependency added (supply chain — see note below), security-relevant boundaries (§4 threat-model surfaces), public API changes | Full human review + AI as second eye + ADR if architectural | + Linked threat-model touchpoint per §4; dual review for compliance-bound projects |
| **Critical** | Production secrets handling, untrusted-content boundary changes (§4), major architecture (§7 ADR territory), regulatory-bound code (§22), changes to the review system itself | Full team review + ADR + linked research doc | + ADR per §7; cross-implementation research per §7 if foundational; compliance check per §22 |

**The principle: more risk → more guardrails.** The auto-merge threshold lives in the project's `CLAUDE.md` (or equivalent process doc) so the team agrees explicitly on what merges without humans. Visibility matters more than the specific cutoff.

**New dependencies default to High, not Medium.** A lockfile version bump of an existing package is Trivial; introducing a *new* package is a supply-chain decision an AI pre-screen reading the diff cannot vet — the risk lives in the package, not in the lockfile line, and typosquats ship working code precisely so the diff looks fine (see §6 *Supply Chain Attack Defenses*). Human eyes verify the exact name, publisher, and registry identity before merge. Downgrade to Medium only when a private-registry allowlist already gates the install path.

**At solo scale, the model degrades gracefully — use the degraded form, don't build the bureaucracy.** For a solo developer, Layer 3's "human review" is you, and the Critical row's "full team review" is you, slower and on a different day. The useful solo mapping: keep Layer 1 mechanical gates absolute, run Layer 2 AI pre-screen on everything non-Trivial, and spend your own attention only on Medium+ changes — flags doc first, diff second. Skip the sampling protocol and the taxonomy file until a second reviewer exists; classify by habit, not by artifact. What survives at every scale is the discipline of asking *what kind of change is this* before deciding how much attention it gets.

**"Tests pass" is not sufficient evidence of safety.** The mechanical layer is necessary but never sufficient. A trivial-risk change with passing tests can still be wrong (a typo can introduce a regression in a string compared elsewhere); the risk taxonomy is the discipline of asking *what kind of change is this*, not just *did the gate pass*.

**Auto-merge for trivial and low changes is the velocity multiplier.** If 60–90% of changes are trivial or low (typical in mature projects), auto-merge with AI pre-screen turns those changes from "open PR, wait for human, get LGTM, merge" into "open PR, AI reviews, merge if clean" — a 10×+ wall-clock reduction. The discipline is *trusting the taxonomy and the reviewer*; spot-check sampling catches the cases where you shouldn't have trusted.

**Cost profile (the taxonomy itself, not its implementation):** Operator-required (taxonomy decision) · Days setup, minutes per change ongoing · Architectural (touches branch protection + CI) + Recurring (taxonomy maintenance)

**Failure modes specific to auto-merge:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Misclassification on the trivial-low boundary | Changes labeled trivial slip in a behavior change that the mechanical layer doesn't catch | Strengthen the trivial-risk definition (e.g., "only changes where AST diff is identical to a known-safe pattern"); raise borderline changes to Low |
| Risk-level inflation | Team labels everything Medium+ to feel safer; auto-merge benefit disappears | Audit recent merges by risk-level distribution; if Trivial+Low is <30% of merges in a mature codebase, classification is over-cautious |
| Stealth promotion | A change marked Low touches a path that should map to Medium; the taxonomy hasn't been updated | Spot-check sampling catches this. Fix the taxonomy mapping, not just the one change |
| Auto-merge without observability | Trivial changes merge fast; nobody knows what was merged when something later breaks | Auto-merge events feed the §4 agent log (per §4 Agent Log Discipline). Every auto-merge is a logged event with the classification and reviewer's flags doc |

### Reviewer agent pattern

The **auto-review** skill is the foundation. It's invoked on every change after Layer 1 passes, does a broad sweep across the project's risk dimensions, and produces the flags document. One skill template lives in this repo (`.claude/skills/umami-auto-review.md`); each project derives its own with project-specific risk dimensions and paths.

**Specialized reviewers** are an *optional escalation* for projects where scale demands it. A separate skill per dimension (security, performance, contract integrity, error-handling) can come off the bench when auto-review flags High in that dimension, producing deeper analysis. Most projects don't need specialized reviewers until repeated High flags on the same dimension justify the focused mandate. Per §14, scoped specialized agents are a measurable cost lever, but only useful when there's enough flagged volume to justify them.

#### Test-change verification

A load-bearing reviewer behavior. When the auto-review skill (or the human reviewer) sees a PR that **modifies tests in ways that aren't pure rename/move**, it should treat that as a HIGH-priority flag, not normal review noise. Agents under pressure to make CI go green frequently rewrite the assertions to match the (broken) code rather than fixing the code to match the (correct) assertions — and the resulting PR passes its own tests by construction. Per §3e *Refactoring Discipline*, "if a 'refactor' commit also modifies tests in ways that aren't pure rename/move, it's not a refactor — it's a rewrite." Apply the same lens to all PRs: an assertion rewrite is a behavior change in disguise; ask explicitly *"why did this assertion need to change, and is the new assertion correct?"* For projects with the budget, **mutation testing** is the strong falsifier — it verifies that the test would actually catch a real regression rather than just passing-by-construction (Osmani 2026 *Agentic Code Review*).

### Cross-provider review

Same-family review (Claude reviewing Claude, GPT reviewing GPT) tends to validate same-shape errors. The reviewer and the author share training data, reasoning patterns, and blind spots; a logical leap the author made invisibly is one the reviewer is statistically more likely to make invisibly too. **Cross-provider review** treats the reviewer as an *adversarial eye* — a model from a different family (different vendor, different training corpus) reviews the code the original model wrote.

**The principle:** model diversity is to AI review what code review is to solo development. The argument isn't that one model is better than another; it's that *two different models look at the same code from different angles*, and the disagreement (or shared concern) is signal.

**Cost profile:** Operator-required (provider selection) + Agent-autonomous (per-review) · Days setup, hours/day ongoing · Architectural + Spend (parallel API costs across providers)

**When this earns its cost:**

- Medium+ risk-level changes where same-family blind spots are most expensive (security, data integrity, contract integrity)
- Projects with API access to multiple providers (Anthropic + OpenAI, Anthropic + Gemini, etc.)
- LLM-feature products where the review system itself shouldn't be single-vendor (otherwise a vendor-specific bug propagates from author to reviewer to production)

**When it doesn't earn its cost:**

- Trivial / Low risk-level changes — cross-provider cost outweighs same-family-bias risk
- Projects on a single-provider budget; revisit when budget allows
- Reviewer disagreements that humans can't adjudicate — if no human is calibrated enough to tell which review is right, the cross-provider signal isn't actionable

**Prerequisites:**

- API access to ≥2 providers in different families (different vendors, ideally different RLHF lineages)
- Cost caps per §9.7 that account for parallel-review token spend
- A protocol for handling disagreement (default: any High-tier disagreement escalates to human; same as auto-review's High flag)
- A record of agreement/disagreement rates per project so the discipline calibrates

**Watch signals (cross-provider specific):**

| Signal | What it catches |
|---|---|
| Cross-provider agreement on every change | Either changes are genuinely uncontroversial, OR both models share the same blind spot. Spot-check sampling catches the second case. |
| Persistent disagreement on the same kind of change | Indicates a recurring blind spot in one (or both) models — codify the pattern as a project-specific risk dimension |
| Cost-cap firing repeatedly on cross-provider review | The pattern may be mis-applied at scale; consider running cross-provider review only on Medium+ risk levels |
| Single-provider review fares better than cross-provider on a specific dimension | The reviewer for that dimension may need specialization more than cross-provider verification — see specialized reviewers above |

**Failure modes (cross-provider specific):**

| Failure mode | Symptom | Fix |
|---|---|---|
| Cross-provider collusion | Both models trained on similar data; reviews are correlated; "two reviewers" is one reviewer with double the cost | Verify provider diversity (different families, different RLHF lineages). Sample disagreement rate; if it's < 5% on Medium+ changes, the providers are too similar to count as adversarial |
| Reviewer-of-the-week | Team rotates which provider reviews based on price/availability; classification map gets retrained for one provider's quirks; consistency degrades | Pick providers deliberately, not opportunistically. Document the choice in an ADR per §7 |
| Cost surprise | Parallel review doubles or triples token spend per PR; cap fires unexpectedly | Pre-allocate budget in §9.7. Cross-provider review is Tier 3 / Scale practice — only adopt when the project's token budget can sustain it |
| Disagreement paralysis | Models disagree often; humans can't adjudicate fast enough; queue backs up | Reduce cross-provider scope to a smaller risk-level band (e.g., only Critical) until the protocol matures, or invest in a tie-breaker (a third model, or a human reviewer with the cross-domain expertise to adjudicate) |

### Flags document

The flags document routes human attention. Qualities of a good one:

- **Scannable in ~30 seconds** — a human reading it should know within seconds whether to look closer
- **Prioritized** into 2–3 risk levels (HIGH / MEDIUM / LOW, or equivalent)
- **`file:line` citation on every item** — no "the auth code has issues"; always the specific location
- **Dimension tag on every item** — security / data / contract / etc., so a human can route to the right specialized reviewer if needed
- **One-line concern per item** — the human drills into the diff if they need detail

Worked example (one project's shape):

```markdown
## Review flags — PR #1234

### Risk level (per the §3d risk taxonomy)
**Medium** — new feature behind flag + data-integrity touch. Default disposition: AI pre-screen + ≥1 human spot-check.

### HIGH (need eyes)
- security: src/api/orders.ts:142 — new validation skips length check (potential XSS via order notes field)
  - **Impact:** closes XSS vector in user-controlled `notes` field reaching admin dashboard. **Effort:** Agent-autonomous · Hours · One-time. **Quick win.**
- data: src/db/migrations/0042.sql — adding NOT NULL without backfill (table size 50M rows)
  - **Impact:** prevents production migration timeout / lock contention. **Effort:** Operator-required · Days · One-time (backfill script + multi-phase migration).

### MEDIUM (consider)
- resilience: src/utils/retry.ts:8 — retry budget not propagated to caller
  - **Impact:** caller can't reason about total wait time; reduces operational debuggability. **Effort:** Agent-autonomous · Hours · One-time.
- observability: src/services/auth.ts — debug log statement includes token
  - **Impact:** closes secret-leak risk in logs (§4 build-output hygiene). **Effort:** Agent-autonomous · Hours · One-time. **Quick win.**

### LOW (note)
- 12 test files updated; no production-code test coverage added for the new branch in orders.ts:142 — **Effort:** Agent-with-review · Hours · One-time.
```

**Impact and Effort on every finding.** Same discipline as §0.7 audit recommendations: Impact names a specific improvement (closes a vector, resolves a watch signal, reduces measurable pain); Effort uses the §4 cost-profile scheme. Quick-win flag only when Impact is concrete and Effort is Hours.

The exact shape (HIGH/MEDIUM/LOW vs. red/yellow/green vs. priority numbers) is a project taste call. The qualities are universal.

### Spot-check sampling — load-bearing

Without random human spot-checks of "low-risk" changes (the ones that don't trigger any human-review signal), the risk classification rots silently. Paths get added without updating the classification map; the auto-review skill drifts and flags less; real issues bypass human eyes forever.

**Sample 5–15% of low-risk changes randomly. Tune to taste.** Lower bound (5%) is meaningful without being disruptive. Upper bound (15%) is heavy enough to keep reviewers calibrated. The exact rate is project-specific — the watch signal below tells you whether you're sampling enough.

If serious issues turn up in spot-checks, the classification is wrong. Fix the *classification* (add the missing path glob, refine the signal rule), not just the one change.

### Watch signals

Three signals detect when the review system is degrading:

| Watch signal | Healthy range | What it catches |
|---|---|---|
| **Spot-check finding rate** (real issues per sampled change) | < 2% | If higher, risk classification is wrong; serious changes are bypassing the human gate. |
| **Auto-review flag rate** (% of changes flagged at any level) | 5–25% | < 2% → reviewer is missing real issues (false confidence). > 25% → noisy / alert fatigue. |
| **Merge-rate ÷ human-engagement-rate** | < 5× | If merges run more than 5× faster than humans engage with flags docs, the human-attention layer is rubber-stamping. |

Treat watch signals as the diagnostic. The system doesn't fix itself — investigate and adjust the classification, the reviewer's prompt, or the team's process when a signal trips.

### Failure modes

| Failure mode | Symptom | Fix |
|---|---|---|
| Rubber-stamping | Humans approve flags docs without engaging; merge rate vastly exceeds engagement rate | Watch signal #3 catches this. Fix is process — slow merge velocity, require evidence of engagement, pair-review high-volume work |
| Classification rot | Risky changes bypass the human gate because path globs are stale | Spot-check sampling catches this if you actually do it. Fix the classification map, not the one change |
| Reviewer agent drift | Same code reviewed at different times produces inconsistent flags | Drift detection per §0.7 hard rules; re-derive the reviewer skill from current §3d |
| Reviewer over-confidence | Reviewer flags a tiny fraction; humans trust it; real issues slip through | Watch signal #2 (flag rate) catches this. Recalibrate the reviewer's prompt or scope |
| Skill rot | Reviewer agents reference deprecated paths or APIs | Periodic skill review per §14; update the canonical template in this repo |

---

## 3e. Refactoring Discipline

§3, §3b, §3c, §3d cover testing, dev process, decision protocol, and code review. §3e covers **refactoring as its own discipline** — the practice of restructuring code without changing behavior, applied at agentic velocity where agents do most of the refactoring and where their patterns differ from human refactoring patterns.

Refactoring is distinct from:
- New feature work (changes behavior)
- Bug fixes (changes behavior to be correct)
- Architectural changes (changes structure at a level that breaks contracts)

§3e is the middle ground — code transformations that preserve behavior and make subsequent work easier.

### The four parts

**1. Tests as the safety net.** Refactoring without tests is rewriting. Either:
- The behavior is already covered by tests; refactoring is safe
- The behavior is not covered; *write the test first* before refactoring

Per Fowler's *Refactoring*, "if the tests don't pass, you're not refactoring; you're changing behavior." This is non-negotiable.

**2. Named transformations.** Use the established refactoring catalog (Extract Method, Inline Variable, Move Method, Replace Conditional with Polymorphism, etc.) rather than ad-hoc rewrites. Named transformations are smaller, more reviewable, and more auditable. Agents can describe what they're doing in vocabulary humans recognize, which makes review tractable at scale.

**3. Small atomic commits.** Each refactoring is its own commit, named for the transformation applied. Don't bundle refactorings with feature work — the diff becomes hard to review and bisect, and reverting a feature drags the unrelated cleanup with it.

**4. Distinguish refactoring from cleanup.** "I noticed this while I was here" is not a refactoring opportunity — it's scope creep. Per §3b, incidental findings get noted but not edited in the same change. Refactoring is opportunistic improvement of code *the change requires touching*; cleanup is opportunistic improvement of unrelated code.

### Agentic-velocity refactoring patterns

Agents tend toward different refactoring patterns than humans, often in ways that look like good practice but aren't:

| Agent tendency | Risk |
|---|---|
| Aggressive Extract Method | Over-extracts; produces tiny files with single 3-line methods that hide rather than reveal logic |
| Cross-file rewrites | Ignores cohesion; spreads concerns thinly across many files |
| "Removing duplication while I'm here" | Premature abstraction; creates the wrong shared code; violates §3b incidental-findings rule |
| Renaming to match training-data conventions | "More idiomatic" name doesn't match project conventions |
| Applying every refactoring in the catalog | Mistakes "I know how to do this transformation" for "this transformation is needed" |

The §3d code-review three-layer model (mechanical / AI pre-screen / human focus) catches some of these — a "refactoring-only" change with a behavior-test diff is a HIGH flag for the human reviewer.

### Watch signals

| Signal | What it catches |
|---|---|
| Refactoring commits routinely touch >5 files *with more than one transformation applied* | Refactorings have grown into rewrites; should have been broken into smaller transformations. **Exception:** a single mechanical transformation (rename, move) legitimately touches every call site — 30 files for one rename is atomic and safe; 6 files for three unrelated extractions is the smell |
| Refactoring commits include "while I was here" changes | §3b incidental-findings rule violated; scope creep into cleanup territory |
| Existing test *assertions* had to be modified alongside the refactoring | Refactoring changed behavior, not just structure. Either it's not a refactoring, or the tests were too coupled to implementation. (Adding missing coverage *before* the refactor, as its own commit per Part 1, is the correct sequence — that's not this signal) |
| Same refactoring done multiple times across sessions | The pattern isn't being captured in change-propagation maps (§10) or codebase understanding (§9.3) |

### Failure modes

| Failure mode | Symptom | Fix |
|---|---|---|
| Refactoring without tests | Behavior changes silently; bugs emerge later | Write the test first; that's the prerequisite. If you can't write a test for the behavior, you can't refactor — you're rewriting |
| Bundling refactoring with feature work | Diff is too large to review; hard to bisect; PR description becomes "refactor X and add Y" | Two commits, two PRs. Refactoring first (no behavior change), feature on top |
| Refactoring as scope creep | Agent "improves" code unrelated to the task; PR description doesn't mention the change | Per §3b, incidental findings get reported, not edited. Refactor only code the task requires touching |
| Premature abstraction during refactoring | Three usages of similar code → extract a base class with hooks → next usage doesn't fit the abstraction | Wait until the third usage shows the pattern. Until then, three similar lines is better than a wrong abstraction |
| Refactoring breaking change-propagation maps | Module renamed; §10 propagation map references the old name; subsequent sessions miss the dependency | Update propagation maps in lockstep with the refactoring. CLAUDE.md change-propagation map gets a row for "rename module" |

### Cross-references
- §3b — Test-first discipline applies to refactoring; "scope creep" rule applies (incidental findings get reported, not edited)
- §3c — Multi-decision refactorings should use the §3c protocol (don't batch refactoring decisions)
- §3d code review — Refactoring commits should be flagged for "behavior unchanged" verification
- §10 change propagation — Refactoring that renames or moves things must update the propagation map in lockstep

---

## 3f. Eval Suite Management

§3 *Tests and Evals* drew the line: tests verify deterministic code (input → output); evals verify non-deterministic agent behavior (trajectory, tool choice, output quality). §3f is the operational half — how to build and maintain the eval suite that the §3 *Multi-Provider Behavioral Testing* matrix runs against.

**Adopt when** (§0.9 default-deny — cite a concrete trigger): the product ships LLM/agent features whose correctness depends on model behavior, **and** at least one of — a behavior regression reached production that no test could have caught; a prompt or model change shipped with no way to tell if quality moved; you are about to rely on agent output in a path with real blast radius. Absent a trigger, **defer** — evals are real recurring cost, not a default.

**Cost profile:** Specialist-required (eval design) · Weeks setup, ongoing per-change token cost · Architectural + Spend (judge/model API per run). Expect 10–100× a unit-suite's per-run cost.

**The parts:**

| Part | What it is |
|---|---|
| **Golden dataset** | A versioned set of inputs + expected behavior (often a rubric or invariants, not an exact string). It grows from real failures — every production miss becomes a case. Version it like code; a changed expected-answer is a reviewed diff (the §3d *test-change check* applies — an assertion quietly weakened to pass is a regression in disguise). |
| **Scoring** | How a run is judged: programmatic assertions where output is checkable; rubric + **LLM-as-judge** where it's qualitative (judge with a *different* model family per §3d cross-provider review, so the system isn't grading its own homework); human spot-check on a sample. State the pass bar per case. |
| **Eval-driven workflow** | Run the suite on every prompt-file, instruction-file, model, or tool-schema change — exactly the changes tests don't cover. A prompt edit shipped with no eval delta is unverified (cross-ref §14b). |
| **Regression evals + CI** | Gate a small critical subset per commit; run the full matrix nightly / per-release (§3 *Multi-Provider Behavioral Testing*). Track scores over time — a downward trend across model versions is drift (§14c). |

**Watch signals:** the eval set hasn't grown after a production miss (failures aren't being captured) · scores are reported but never gate anything · the judge is the same model family as the system under test (correlated blindness, §3d).

**Kill criterion (ledger, §0.9):** demote to per-release-only if no eval has caught a regression in N releases *and* the prompt / model / tool surface is stable; remove if the LLM feature it covered is gone.

**Cross-references:** §3 *Tests and Evals* (the distinction) · §3 *Multi-Provider Behavioral Testing* (the matrix evals run on) · §14b prompt & instruction-file engineering (what the eval-driven workflow gates) · §14c model-version pinning & drift (evals are the drift detector) · §0.6b AI-discipline spectrum (no evals → vibe-coding-adjacent regardless of prompt sophistication) · §9.7 cost caps (eval runs are recurring spend).

---

