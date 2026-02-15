# Observability Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §22**

This extension covers system-wide observability — the instrumentation, metrics, logging, tracing, and alerting practices that let you understand what your system is doing in production. The core template covers testing (§3) and runtime validation (§4), which catch problems before and during deployment. Observability catches everything that slips through: the slow queries, the cascading failures, the silent data corruption, the 2 AM pages.

**Apply this extension when** the system has components running in production that need monitoring, or when the §0.1 questionnaire identifies reliability or scalability as a primary concern.

**Relationship to other extensions:**
- §16.14 (IaC — SLOs/SLIs) defines *what* to measure. This extension defines *how* to measure it.
- §18.7 (Data — Data Observability) covers pipeline-specific monitoring. This extension covers system-wide observability.

---

## 22.1 The Three Signals

Observability rests on three complementary signal types. Each answers a different question, and none is sufficient alone.

| Signal | What it tells you | Question it answers | Example |
|--------|-------------------|---------------------|---------|
| **Metrics** | Aggregated numeric measurements over time | "Is the system healthy right now?" | Request rate, error rate, p99 latency, CPU utilization, queue depth |
| **Logs** | Discrete events with context | "What happened during this specific request or operation?" | "User 123 failed login: invalid password", "Pipeline stage 3 completed in 4.2s" |
| **Traces** | The path of a request through multiple services | "Where did the time go? Which service is the bottleneck?" | Request entered API gateway → auth service (12ms) → database (340ms) → response (356ms total) |

**The key insight:** Metrics tell you *something is wrong*. Logs tell you *what went wrong*. Traces tell you *where it went wrong*. You need all three to debug effectively in production.

**How they connect:**
- A metric alert fires (error rate > 5%) → you look at logs filtered to that time window → you find a trace ID in the error log → you follow the trace to the failing service.
- This workflow only works if all three signals share correlation identifiers (trace IDs, request IDs, timestamps). Without correlation, you have three separate piles of data instead of one coherent picture.

---

## 22.2 OpenTelemetry (OTEL) as the Foundation

OpenTelemetry is the vendor-neutral standard for instrumentation. It provides APIs, SDKs, and a collector for generating and exporting metrics, logs, and traces. Using OTEL means your instrumentation code doesn't lock you into any specific observability backend.

**Why OTEL:**
- **Vendor neutrality.** Switch from Datadog to Grafana (or vice versa) without re-instrumenting your code. The instrumentation stays; only the exporter configuration changes.
- **Consistency.** One API for metrics, logs, and traces across all languages. Teams using different languages produce compatible telemetry.
- **Community.** OTEL is a CNCF project with broad industry adoption. Auto-instrumentation libraries exist for most frameworks, reducing the manual work.

**The architecture:**

```
Application code
  → OTEL SDK (generates telemetry)
    → OTEL Collector (receives, processes, exports)
      → Backend (Grafana, Datadog, Jaeger, Prometheus, etc.)
```

**Rules:**
- **Use the OTEL SDK for all new instrumentation.** Don't use vendor-specific SDKs directly — even if you're committed to one vendor today. The switching cost later is significant.
- **Deploy the OTEL Collector as a sidecar or standalone service.** The collector decouples your application from the backend. It handles batching, retry, and routing — your app just emits telemetry.
- **Use auto-instrumentation first, manual instrumentation second.** Most frameworks (Express, Django, Spring, .NET) have OTEL auto-instrumentation libraries that capture HTTP requests, database calls, and external service calls with zero code changes. Start there. Add manual spans and metrics only for business-specific logic that auto-instrumentation can't capture.
- **Pin OTEL SDK versions.** Like any dependency (§6), pin versions and update deliberately. OTEL is still evolving; breaking changes happen.

### OpenMetrics

OpenMetrics is the CNCF standard for metric exposition — it standardizes how applications expose metrics for collection. If OTEL defines how telemetry is generated and transported, OpenMetrics defines the common wire format for metrics specifically.

**Why it matters:**
- **It's what Prometheus speaks.** OpenMetrics evolved from the Prometheus exposition format and is backward compatible with it. If you expose metrics in OpenMetrics format, any Prometheus-compatible scraper can collect them.
- **OTEL supports it natively.** The OTEL Collector can scrape OpenMetrics endpoints and export them to any backend. This means services that expose a `/metrics` endpoint work with both the Prometheus ecosystem and the OTEL pipeline.
- **It's the lingua franca.** Many off-the-shelf components (databases, message brokers, web servers, Kubernetes itself) expose metrics in Prometheus/OpenMetrics format. Your custom instrumentation should speak the same language.

**OpenMetrics metric types:**
| Type | Use for | Example |
|---|---|---|
| **Counter** | Things that only go up — total requests, total errors, bytes sent | `http_requests_total` |
| **Gauge** | Current values that go up and down — temperature, queue depth, active connections | `queue_messages_pending` |
| **Histogram** | Distributions — request duration, response size (bucketed) | `http_request_duration_seconds` |
| **Summary** | Pre-calculated quantiles (p50, p99) — use when you need precise percentiles without server-side aggregation | `http_request_duration_seconds{quantile="0.99"}` |

**Practical guidance:**
- **Prefer histograms over summaries** for new instrumentation. Histograms can be aggregated across instances; summaries cannot. Histograms are more flexible for backend-side analysis.
- **Expose a `/metrics` endpoint** on every service, even if you're using OTEL push-based collection. The pull-based endpoint is useful for debugging, ad-hoc inspection, and as a fallback.
- **Use standard metric names** from the OpenMetrics and OTEL semantic conventions where they exist (e.g., `http.server.request.duration`, `db.client.connections.usage`). Don't invent names when a convention already covers your case.

**What to configure:**
- **Service name and version.** Every service must identify itself in telemetry. Without this, you can't filter or aggregate by service.
- **Environment tag.** dev / staging / prod. Without this, you can't separate test noise from production signals.
- **Sampling rate for traces.** 100% trace sampling is expensive at scale. Start with 100% in dev/staging, and use head-based or tail-based sampling in production to capture a representative sample plus all errors.

---

## 22.3 Instrumentation Discipline

Instrumentation is code. It has the same maintenance cost, the same risk of bugs, and the same need for discipline as any other code. Over-instrumenting is as wasteful as under-instrumenting.

**What to instrument (always):**
- **Inbound requests** — HTTP endpoints, gRPC methods, message consumers. Capture: method, path/operation, status code, duration.
- **Outbound calls** — Database queries, HTTP clients, message producers, cache operations. Capture: target, operation, status, duration.
- **Business-critical operations** — Payment processing, user signup, order fulfillment, data pipeline stages. Capture: operation name, outcome (success/failure/partial), duration, key identifiers.
- **Resource utilization** — CPU, memory, disk, connection pool usage. These are usually provided by runtime metrics (JVM, Node.js, Python runtime) or infrastructure metrics.

**What NOT to instrument:**
- **Every function call.** Instrumentation has overhead. Tracing every internal function creates noise, inflates storage costs, and makes traces unreadable.
- **Sensitive data.** Never include passwords, tokens, PII, or full request/response bodies in telemetry. Sanitize before emitting.
- **High-cardinality labels thoughtlessly.** A metric with a `user_id` label will create a time series per user — millions of series that most backends can't handle affordably. See §22.4.

**Instrumentation as code review:**
- Treat instrumentation changes like any other code change — review them in PRs.
- When adding a new service or endpoint, instrumentation is part of the "definition of done" — not a follow-up task.
- When removing a service or endpoint, remove its instrumentation too. Dead instrumentation is dead code (§13).

---

## 22.4 Metrics Design

Metrics are the most cost-sensitive signal. A poorly designed metric (wrong name, high cardinality, missing labels) is either useless or ruinously expensive. Get the design right before shipping.

### Naming Conventions

Use a consistent naming scheme across all services. OTEL and Prometheus conventions are widely adopted:

```
<namespace>.<target>.<metric_name>
```

Examples:
- `http.server.request.duration` — duration of inbound HTTP requests
- `db.client.query.duration` — duration of database queries
- `orders.created.count` — business metric: orders created
- `queue.messages.pending` — current queue depth

**Rules:**
- Use dots (OTEL) or underscores (Prometheus) consistently — don't mix.
- Use units in the name: `duration` (seconds), `count`, `bytes`, `ratio`.
- Use the same names across services for the same concept. If every service measures request duration differently, cross-service dashboards are impossible.

### Cardinality

Cardinality = the number of unique label combinations for a metric. It's the primary driver of observability cost.

| Label | Cardinality | Safe? |
|---|---|---|
| `method` (GET, POST, PUT, DELETE) | ~5 | Safe |
| `status_code` (200, 404, 500) | ~10 | Safe |
| `endpoint` (/api/users, /api/orders) | ~50-200 | Usually safe |
| `customer_id` | 10,000+ | Dangerous |
| `request_id` | Unbounded | Never use as a metric label |

**The rule:** If a label can take more than ~100 unique values, it should not be a metric label. Put high-cardinality identifiers in logs and traces instead.

### The RED and USE Methods

Two frameworks for deciding what to measure:

**RED (for request-driven services):**
- **R**ate — requests per second
- **E**rrors — failed requests per second
- **D**uration — distribution of request latency (p50, p95, p99)

**USE (for resources — CPU, memory, disk, network):**
- **U**tilization — percentage of resource in use
- **S**aturation — amount of queued/waiting work
- **E**rrors — error events from the resource

**Every service should have RED metrics. Every infrastructure component should have USE metrics.** If you have both, you can answer "is it slow?" (RED) and "why is it slow?" (USE).

---

## 22.5 Distributed Tracing

In a system with more than one service, a single user request may traverse 5, 10, or 50 services. Tracing shows you the full path, with timing for each hop.

### Context Propagation

For tracing to work across services, the trace context (trace ID + span ID) must be propagated in every inter-service call. This is the single most important thing to get right.

**Rules:**
- **Use W3C Trace Context headers** (`traceparent`, `tracestate`) as the propagation format. This is the OTEL default and the industry standard.
- **Propagate context in every inter-service call** — HTTP headers, message queue metadata, gRPC metadata. If context breaks at any hop, the trace is split into disconnected fragments.
- **Verify propagation end-to-end.** After setting up tracing, send a test request and confirm the trace appears as a single connected graph in your tracing backend. Gaps mean a service isn't propagating context.

### Span Design

A span represents a single operation within a trace. Span design determines whether traces are useful or just noise.

**Good spans:**
- Named after the operation: `HTTP GET /api/users`, `db.query SELECT users`, `queue.publish order.created`.
- Include relevant attributes: `http.status_code`, `db.statement` (sanitized), `user.id`.
- Have clear parent-child relationships: an HTTP handler span is the parent of the database query spans within it.

**Bad spans:**
- Generic names: `doWork`, `process`, `handleRequest`. These tell you nothing in a trace view.
- Too granular: a span for every loop iteration or utility function call. This makes traces huge and unreadable.
- Missing attributes: a database span without the query or table name is useless for debugging.

**Span events vs child spans:** Use span events (annotations within a span) for noteworthy moments that don't represent a separate operation — "cache miss," "retry attempt 2," "fallback to default." Use child spans for distinct operations with their own duration.

---

## 22.6 Structured Logging

Unstructured logs (`printf("error: something went wrong")`) are human-readable but machine-hostile. Structured logs (JSON with consistent fields) are searchable, filterable, and correlatable.

**Every log entry should include:**

| Field | Purpose | Example |
|---|---|---|
| `timestamp` | When it happened (ISO 8601, UTC) | `2024-03-15T14:30:22.456Z` |
| `level` | Severity (DEBUG, INFO, WARN, ERROR) | `ERROR` |
| `message` | Human-readable description | `Payment processing failed` |
| `service` | Which service emitted it | `payment-service` |
| `trace_id` | Correlation to distributed trace | `abc123def456` |
| `request_id` | Correlation to specific request | `req-789` |
| `error` | Error type/message if applicable | `TimeoutError: upstream did not respond within 5s` |

**Rules:**
- **Use structured format (JSON) in production.** Human-readable format is fine for local development.
- **Include trace IDs in every log line.** This is the bridge between logs and traces. Without it, you can't jump from a log entry to the full trace.
- **Use consistent log levels across services.**
  - `DEBUG` — detailed diagnostic info, never enabled in production by default.
  - `INFO` — normal operations worth recording (service started, job completed, user logged in).
  - `WARN` — something unexpected that the system handled (retry succeeded, fallback used, approaching threshold).
  - `ERROR` — something failed that needs attention (request failed, data corruption, unhandled exception).
- **Never log sensitive data.** Passwords, tokens, credit card numbers, PII. Sanitize or redact before logging. This is not optional.
- **Log at boundaries, not everywhere.** Log when data enters or leaves your service, when operations complete or fail, when decisions are made. Don't log inside tight loops or for every internal function call.

---

## 22.7 Alerting Discipline

The purpose of an alert is to notify a human that something requires action. An alert that doesn't require action is noise. Noise leads to alert fatigue. Alert fatigue leads to missed real incidents.

### What to Alert On

**Alert on symptoms, not causes.**
- Good: "Error rate > 5% for 5 minutes" (symptom — users are affected).
- Bad: "CPU > 80%" (cause — may or may not affect users).

CPU at 80% might be perfectly normal during a batch job. Error rate at 5% always means users are having a bad time. Alert on what matters to users, then use dashboards to investigate causes.

**Alert tiers:**

| Tier | Urgency | Response | Examples |
|------|---------|----------|---------|
| **Page** (P1) | Immediate — wake someone up | Drop everything, investigate now | Service down, data loss, security breach |
| **Urgent** (P2) | Business hours — address today | Investigate during working hours | Error rate elevated, SLO budget burning fast, disk > 90% |
| **Warning** (P3) | This week — investigate when convenient | Track, investigate if it persists | Latency trending up, certificate expiring in 14 days, queue growing slowly |
| **Info** | Awareness only — no action required | Review in weekly ops review | Deployment completed, config changed, scaling event |

**Rules:**
- **Every alert must have a runbook** (or at least a link to documentation). If the on-call engineer doesn't know what to do when the alert fires, the alert is incomplete.
- **Every alert must have an owner.** Unowned alerts are ignored alerts.
- **Review alerts monthly.** If an alert fires regularly and nobody acts on it, either fix the underlying issue or adjust the threshold. Alerts that are routinely ignored are worse than no alert — they train people to ignore all alerts.
- **Alert on error budget burn rate** (§16.14), not on individual errors. A single 500 is not an incident. Burning 10% of your monthly error budget in one hour is.

### Threshold Design

- **Use percentile-based thresholds over averages.** p99 latency > 500ms catches tail latency. Average latency > 500ms only fires when everything is already on fire.
- **Use sustained thresholds over instantaneous.** "Error rate > 5% for 5 minutes" prevents flapping. "Error rate > 5% right now" fires on every momentary spike.
- **Set thresholds based on SLOs.** If your SLO is 99.9% availability, alert when the burn rate suggests you'll breach the SLO before the end of the window.

---

## 22.8 Dashboards and Golden Signals

Dashboards are for investigation, not decoration. A dashboard that nobody looks at during an incident is wasted work.

### The Four Golden Signals

Every service should have a dashboard showing these four signals (from Google's SRE book):

| Signal | What it measures | Key metric |
|--------|-----------------|------------|
| **Latency** | How long requests take | p50, p95, p99 response time |
| **Traffic** | How much demand the system is handling | Requests per second, messages per second |
| **Errors** | How often requests fail | Error rate (%), error count by type |
| **Saturation** | How full the system is | CPU %, memory %, disk %, queue depth, connection pool usage |

**Dashboard hierarchy:**

1. **Service overview** — one dashboard per service showing the four golden signals. This is where you start during an incident.
2. **Dependency view** — shows latency and error rates for all downstream dependencies (databases, external APIs, caches). Answers "is the problem in my service or downstream?"
3. **Business metrics** — orders per minute, signups per day, pipeline records processed. Answers "is the system doing what it's supposed to do from a business perspective?"
4. **Infrastructure** — resource utilization, scaling events, deployment markers. Answers "what changed in the environment?"

**Rules:**
- **Start with the golden signals dashboard.** Don't build elaborate dashboards before you have the basics.
- **Add deployment markers.** Overlaying deploy events on metric graphs instantly answers "did the last deploy cause this?"
- **Don't build dashboards for metrics you don't have alerts on.** If a metric isn't important enough to alert on, it's probably not important enough to dashboard. Exceptions: business metrics that are reviewed periodically but don't page.
- **Keep dashboards focused.** A dashboard with 50 panels is a wall of noise. Group related metrics, use drill-down links, and split large dashboards by concern.

---

## 22.9 Observability Cost Management

Observability data is high-volume. Unmanaged, it becomes one of the largest line items in your infrastructure bill. Treat observability cost like any other infrastructure cost (§16.4).

**Where cost comes from:**

| Data type | Cost driver | Typical volume |
|-----------|------------|----------------|
| **Metrics** | Cardinality (unique time series) | Each unique label combination = one time series |
| **Logs** | Volume (GB/day ingested) | Verbose logging in high-traffic services adds up fast |
| **Traces** | Span count and retention | 100% trace sampling at scale generates enormous volumes |

**Cost control practices:**
- **Control metric cardinality.** This is the #1 cost lever. Review metrics for high-cardinality labels and remove or aggregate them (§22.4).
- **Sample traces in production.** 100% sampling is rarely necessary. Capture 100% of error traces and a statistical sample of successful traces. Tail-based sampling (decide after the trace completes) captures all interesting traces while discarding routine ones.
- **Set log levels appropriately.** DEBUG in production generates 10-100x more log volume than INFO. Use DEBUG only for targeted troubleshooting, never as a permanent setting.
- **Set retention policies.** Not all data needs to live forever. Typical retention: metrics 13 months (year-over-year comparison), logs 30-90 days, traces 7-14 days.
- **Review observability spend monthly** alongside infrastructure costs (§16.4). If observability is more than 10-15% of your infrastructure bill, investigate whether you're over-collecting.

---

## Mapping to Core Guardrail Sections

| Core Section | Observability Equivalent |
|---|---|
| §3 Testing | §22.3 Instrumentation discipline — treat instrumentation as part of "definition of done" |
| §3b Process Discipline | §22.6 Structured logging — systematic debugging in production, not printf |
| §4 Runtime Validation | §22.1 Three signals — continuous validation that the system is behaving correctly |
| §7 Documentation | §22.7 Alerting — every alert has a runbook, every metric has a purpose |
| §8 Acknowledged Gaps | §22.9 Cost management — make observability blind spots explicit |
| §9 Token Efficiency | §22.2 OTEL — vendor-neutral instrumentation reduces rework when switching tools |
| §13 Dead Code Hygiene | §22.3 Instrumentation — remove telemetry for removed features |
| §16.14 SLOs/SLIs | §22.4 / §22.7 — SLOs define targets, metrics measure them, alerts enforce them |
| §18.7 Data Observability | §22.1 / §22.4 — pipeline monitoring is a specialization of system-wide observability |

---

## Observability Checklist (extends §15)

### Before Every Service/Feature Launch
- [ ] Instrumentation in place — inbound requests, outbound calls, business operations (§22.3).
- [ ] Golden signals dashboard created (latency, traffic, errors, saturation) (§22.8).
- [ ] Alerts configured for SLO-based thresholds with runbooks (§22.7).
- [ ] Structured logging with trace ID correlation (§22.6).
- [ ] Trace context propagation verified end-to-end (§22.5).

### Before Every Instrumentation PR
- [ ] No sensitive data in telemetry (PII, passwords, tokens).
- [ ] Metric cardinality reviewed — no unbounded labels (§22.4).
- [ ] Metric names follow naming conventions (§22.4).
- [ ] Log levels appropriate (no DEBUG in production default).

### Periodic
- [ ] Alert review — silence or fix alerts that fire without action (monthly) (§22.7).
- [ ] Cardinality audit — identify and reduce high-cardinality metrics (monthly) (§22.4).
- [ ] Observability cost review — spend vs. budget, sampling rates appropriate (monthly) (§22.9).
- [ ] Dashboard review — remove stale dashboards, update for new services (quarterly) (§22.8).
- [ ] Trace sampling review — adjust rates based on traffic and budget (quarterly) (§22.9).
