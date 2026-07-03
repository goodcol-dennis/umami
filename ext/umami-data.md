# Data Pipeline Guardrails

**Extension of [Rapid Development Guardrails](../umami.md) — §18**

This extension covers data ingestion, transformation pipelines, warehousing, and analytics systems. The core template assumes application development patterns — test suites run in seconds, changes affect UI or API responses, and the blast radius is a broken page. Data projects have different failure modes: silent corruption, schema drift, stale data, and transforms that produce wrong results without errors.

**Apply this extension when** the §0.2 system shape questionnaire identifies Data Ingestion, Data Pipeline / Transforms, or Data Warehouse / Storage layers.

**Adopt when (§0.9 default-deny):** pipelines feed consumers beyond their author AND a silent data problem — wrong numbers, stale data, duplicates from a re-run — has already occurred or nearly occurred. A one-off analysis script does not warrant this extension.
**Cost profile:** Operator-required · Days initial (quality tests, source registry, observability) + Recurring discipline.
**Kill criterion:** retire any practice below that has produced no finding, no caught data defect, and no consulted artifact across 2 consecutive review cycles (§0.9 retirement pass).

---

## 18.1 Data Quality Testing

Application tests verify behavior: "given input X, the function returns Y." Data tests verify **properties of the data itself**: completeness, freshness, uniqueness, valid ranges, referential integrity.

**Data quality dimensions:**

| Dimension | What it catches | Example test |
|-----------|----------------|-------------|
| **Completeness** | Missing data that should exist | "Every order has at least one line item" |
| **Uniqueness** | Duplicate records | "No duplicate customer IDs in the customers table" |
| **Freshness** | Stale data from failed or delayed ingestion | "The most recent record is less than 24 hours old" |
| **Valid ranges** | Values outside expected boundaries | "No negative quantities; no dates in the future" |
| **Referential integrity** | Broken relationships between tables | "Every order.customer_id exists in customers.id" |
| **Schema conformance** | Columns missing, types changed, new unexpected columns | "The schema matches the declared contract" |

**When to run:**
- **After every pipeline run** — validate output data before downstream consumers see it.
- **On ingestion** — validate source data before loading into the warehouse.
- **Scheduled** — daily data quality reports on production tables.

**Tooling (examples, not prescriptions):** Great Expectations, dbt tests, Soda, custom SQL assertions, pytest with database fixtures.

---

## 18.2 Pipeline Idempotency

A pipeline should produce the same output whether it runs once or five times on the same input. Without idempotency, retries and backfills create duplicates, double-counts, or corrupted state.

**Rules:**
- Every pipeline step should be safe to re-run. If it isn't, document why and what the manual recovery process is.
- Use upsert (INSERT ON CONFLICT UPDATE) instead of bare INSERT for load steps.
- Partition output by run date or batch ID so reruns replace rather than append.
- Track which source data has been processed (high-water marks, checkpoint tables) to prevent reprocessing.

**Anti-patterns:**
- **Append-only loads without dedup** — re-running doubles the data.
- **Transforms that depend on table row count** — re-running changes the count and breaks downstream.
- **DELETE + INSERT without a transaction** — if the insert fails, you've lost data.

---

## 18.3 Schema Evolution Discipline

Production schemas change. Without discipline, schema changes break pipelines, consumers, and reports — often silently.

**Rules:**
- **Schema changes are migrations, not edits.** Use versioned migration files (Alembic, Flyway, dbt migrations, raw SQL scripts with sequence numbers). Never alter production schemas with ad-hoc DDL.
- **Additive changes are safe.** Adding a nullable column doesn't break existing consumers.
- **Destructive changes require a deprecation period.** Renaming or dropping a column should be announced, consumers updated, and the old column kept (as nullable or aliased) until all consumers have migrated.
- **Document the schema contract.** Maintain a data dictionary that lists every table, every column, its type, its nullability, and its business meaning. This is the equivalent of §2 (specs) for data projects.

**Migration checklist:**
- [ ] Migration script tested in dev/staging before prod.
- [ ] Downstream consumers identified and updated (or confirmed compatible).
- [ ] Rollback script prepared for destructive changes.
- [ ] Data dictionary updated to reflect the new schema.

---

## 18.4 Boundary Type Contracts

The core template (§3) covers type assumptions at system boundaries. For data projects, this is where the majority of bugs live — data crossing between tools, formats, or systems.

**Common boundaries in data projects:**

| Boundary | What goes wrong |
|----------|----------------|
| **CSV/Excel → Database** | Encoding issues, type coercion (strings to numbers), sentinel values in typed columns, date format mismatches |
| **API response → Pipeline** | Schema changes upstream, null handling differences, pagination edge cases, rate limiting |
| **Database → Database** | Type precision loss (float vs. decimal), timezone-naive vs. aware datetimes, auto-increment ID conflicts |
| **Pipeline → BI tool** | Column name case sensitivity, type mapping differences, null representation |

**The discipline (from §3, reinforced here):**
- Make every boundary contract explicit — specify column lists, types, and null handling.
- Test with real data samples, not just the happy path. The first 10 rows may look clean; row 10,000 has the encoding issue.
- Validate types before crossing, not after. Catching a bad value before it enters the warehouse is cheap; finding it after reports have been generated is expensive.

---

## 18.5 Source Registry

Data projects ingest from multiple sources. Each source has its own reliability, schema stability, and access patterns. Track them.

| Field | Why it matters |
|-------|---------------|
| **Source name** | Identification |
| **Source type** | API, file drop, database, email, manual entry |
| **Owner / contact** | Who to call when the source breaks or changes |
| **Schema stability** | Stable / changes quarterly / changes without notice |
| **Ingestion frequency** | Real-time, hourly, daily, weekly, ad-hoc |
| **SLA / freshness expectation** | How stale can this data be before it's a problem? |
| **Known quirks** | Encoding issues, sentinel values, historical format changes |
| **Validation rules** | What checks run on ingestion (from §18.1) |

**Maintain this in the project docs** — not in someone's head. When a source changes format without warning (and it will), this registry tells the team what to expect and who to contact.

---

## 18.6 Backfill and Replay

Pipelines fail. Sources deliver late. Schema changes require reprocessing. Backfill — reprocessing historical data through a pipeline — is not an edge case; it's a routine operation.

**Design for it:**
- Every pipeline should accept a date range or batch identifier as input. "Process everything" is not a viable backfill strategy.
- Backfills must be idempotent (§18.2). Re-running for a date range should produce the same result as the original run.
- Log what was backfilled, when, and why. This is audit trail (§5) applied to data.
- Test backfill on a subset before running the full range. A bug in backfill logic applied to 2 years of data is expensive to fix.

**Anti-patterns:**
- **No backfill capability** — "we'd have to rebuild the whole table." This means you can't recover from any failure.
- **Backfill that skips validation** — "we'll just load it fast and check later." The bugs are already in production.
- **Backfill with different code than the forward path** — if the backfill pipeline is a separate script, it will drift from the production pipeline and produce inconsistent results.

---

## 18.7 Data Observability

Application code has logging, metrics, and error tracking. Data pipelines need their own observability layer — not just "did the job succeed?" but "is the data correct?"

**What to monitor:**

| Signal | What it tells you | Alert when |
|--------|-------------------|------------|
| **Row counts** | Volume of data processed per run | Count drops >X% vs. previous run |
| **Null rates** | Data completeness per column | Null rate exceeds historical baseline |
| **Value distributions** | Statistical profile of key columns | Distribution shifts significantly (new categories, range changes) |
| **Freshness** | Time since last successful load | Data is older than SLA threshold |
| **Schema changes** | Source schema differs from expected | New columns, dropped columns, type changes |
| **Pipeline duration** | How long each step takes | Duration exceeds 2x historical average |

**The key insight:** A pipeline can succeed (exit code 0) while producing completely wrong data. Row counts, null rates, and distribution checks catch the failures that exit codes miss.

### Pipeline Run Tracing

In application systems, distributed tracing follows a request through services. In data systems, the equivalent is tracing a pipeline run through stages — from ingestion to final output.

**Every pipeline run should carry a correlation ID** (`run_id`) that appears in every log entry, every metric label, and every checkpoint record for that run. When a downstream consumer reports bad data, the `run_id` lets you trace backward through every stage to find where the problem was introduced.

**Structured pipeline logging:**

Every pipeline log entry should include consistent fields:

| Field | Purpose | Example |
|---|---|---|
| `run_id` | Correlate all events for one pipeline execution | `run-2024-03-15-001` |
| `stage` | Which pipeline step | `extract`, `transform`, `load` |
| `source` | Data source being processed | `api-orders`, `file-inventory` |
| `row_count` | Records processed at this point | `15234` |
| `timestamp` | When (ISO 8601, UTC) | `2024-03-15T14:30:22Z` |
| `duration_ms` | How long this stage took | `4200` |
| `status` | Outcome | `success`, `partial`, `failed` |

Use structured format (JSON) in production. This makes logs searchable and alertable — "show me all runs where the transform stage took >10s" becomes a query, not a grep.

### Alert Thresholds

Set alert thresholds based on historical baselines, not arbitrary numbers. "Row count dropped >50%" is more useful than "row count < 1000" — because the expected count changes as the business grows.

**Rules:**
- Formalize the freshness SLA from your source registry (§18.5) as a measurable target. If the SLA says "data no older than 24 hours," alert at 20 hours — not after the SLA is already breached.
- Alert on rate-of-change, not just absolute values. A null rate that jumps from 2% to 15% in one run is a signal even if 15% is within the "acceptable" range.
- Pipeline duration alerts should use a rolling baseline (e.g., 2x the 30-day average), not a fixed number. Pipelines slow down as data grows.

---

## 18.8 Backward/Forward Compatibility

Schema evolution (§18.3) defines the mechanics of changing schemas. This section defines the **compatibility contracts** that determine whether a change is safe.

**Two directions of compatibility:**
- **Backward compatible** — new code can read old data. Adding a nullable column is backward compatible. Renaming a column is not.
- **Forward compatible** — old code can read new data. Adding a column that old consumers ignore is forward compatible. Changing a column's type is not.

**Why both matter:** In any system where producers and consumers deploy at different times — which is every system with more than one component — you need both. A pipeline that writes a new format before all consumers can read it will break consumers. A consumer that can't read last month's data after a schema change will break backfills.

**Compatibility rules for data formats:**

| Change | Backward? | Forward? | Safe? |
|---|---|---|---|
| Add nullable column | Yes | Yes (if consumers ignore unknown) | Safe |
| Add required column | No | Yes | Unsafe — old data lacks the column |
| Remove column | Yes (if new code doesn't read it) | No | Unsafe — old consumers expect it |
| Rename column | No | No | Unsafe — treat as add + deprecate |
| Widen type (int → bigint) | Yes | Usually yes | Generally safe |
| Narrow type (bigint → int) | No | No | Unsafe — old data may overflow |
| Change encoding (JSON → Avro) | No | No | Requires migration period |

**The discipline:**
- Every schema change should be evaluated against both directions before applying.
- Breaking changes require a migration period: deploy consumers that handle both formats, then change the format, then remove old-format handling.
- For serialization formats (Avro, Protobuf), use schema registries that enforce compatibility checks automatically.
- For databases, this maps directly to the deprecation periods in §18.3 — but extend the thinking to API responses, message queues, file formats, and any other data boundary.

---

## 18.9 Delivery Guarantees

§18.2 covers idempotency — making pipelines safe to re-run. This section addresses the broader question: **how many times will each record be processed, and what does that mean for correctness?**

**Three delivery models:**

| Model | What it means | Risk | When you see it |
|---|---|---|---|
| **At-most-once** | Fire and forget. If processing fails, the record is lost. | Data loss | UDP, fire-and-forget queues, log shipping without acknowledgment |
| **At-least-once** | Retry until acknowledged. Records may be delivered multiple times. | Duplicates | Most message queues (SQS, RabbitMQ, Kafka consumer groups) |
| **Exactly-once** | Each record processed exactly once, even across failures. | Complexity | Kafka transactions, database-backed dedup, idempotent writes |

**The practical reality:** True exactly-once is hard and expensive. Most production systems are at-least-once with idempotent consumers — which is effectively exactly-once from the consumer's perspective.

**What to document:**
- For each pipeline stage, state which delivery guarantee it provides. Don't assume — verify.
- If the guarantee is at-least-once, document how duplicates are handled (upsert, dedup table, idempotent writes from §18.2).
- If the guarantee is at-most-once, document why data loss is acceptable for that stage (e.g., debug logs, non-critical metrics).

**Anti-patterns:**
- **Assuming exactly-once when you have at-least-once.** If your pipeline doesn't deduplicate, re-delivered messages will create duplicates in your warehouse. Aggregations (sums, counts) will be wrong.
- **Acknowledging before processing.** If you ack a message from the queue before completing the work, a crash loses the record — you've turned at-least-once into at-most-once.
- **Ignoring ordering.** Even with at-least-once delivery, messages may arrive out of order. If your pipeline depends on processing events in sequence, you need ordering guarantees or order-independent logic.

---

## 18.10 Derived Data and Source of Truth

Every data system has a **source of truth** — the authoritative record of what happened. Everything else — aggregations, indexes, caches, materialized views, denormalized tables, dashboards — is **derived data** that can be rebuilt from the source.

**Why this distinction matters:**
- If a derived table is wrong, you rebuild it from the source of truth. No data is lost.
- If the source of truth is wrong, you have a real problem.
- Knowing which is which determines your recovery strategy, your backup priorities, and your debugging approach.

**Rules:**
- **Identify the source of truth for every dataset.** Is it the raw event log? The transactional database? The upstream API? Document this in the source registry (§18.5).
- **Derived data should be rebuildable.** If you can't reconstruct a table from its source, it's not derived — it's another source of truth, and it needs the same protection (backups, validation, access control).
- **Keep derivation logic in code, not in ad-hoc queries.** A materialized view created by a one-off SQL script is a time bomb — when it needs updating, nobody knows how it was built. Derivation pipelines should be versioned, tested, and replayable (§18.6).
- **When source and derived disagree, the source wins.** If a dashboard shows different numbers than the raw data, the dashboard is wrong. Investigate the derivation, not the source.

**Common derived data patterns:**

| Pattern | Source | Derived | Rebuild strategy |
|---|---|---|---|
| **Aggregation tables** | Transaction records | Daily/weekly summaries | Re-run aggregation pipeline for affected date range |
| **Search indexes** | Primary database | Elasticsearch / Solr index | Full or incremental reindex |
| **Caches** | API responses / DB queries | Redis / Memcached | Invalidate and repopulate |
| **Materialized views** | Base tables | Denormalized query tables | Refresh from base tables |
| **Data warehouse** | Operational databases | Analytics tables | Backfill from source systems (§18.6) |

**Anti-patterns:**
- **Mutating derived data directly.** If someone manually edits an aggregation table instead of fixing the source data, the next rebuild will overwrite the edit. Fix upstream.
- **Multiple sources of truth for the same fact.** If customer address lives in both the CRM and the billing system and they disagree, you have two sources of truth — pick one and derive the other.
- **No rebuild path.** If the only way to recreate a table is "the person who built it runs the script manually," you don't have a pipeline — you have a dependency on a person.

---

## 18.11 Batch vs Stream Processing

Data processing falls into two fundamental modes. Choosing the wrong one wastes effort; mixing them without discipline creates systems nobody can reason about.

| | Batch | Stream |
|---|---|---|
| **When data arrives** | All at once (file drop, scheduled query, full export) | Continuously (events, messages, change data capture) |
| **Processing model** | Run periodically on accumulated data | Process each record as it arrives |
| **Latency** | Minutes to hours | Seconds to minutes |
| **Complexity** | Lower — easier to reason about, test, and debug | Higher — must handle ordering, late arrivals, failures mid-stream |
| **Error recovery** | Re-run the batch | Replay from offset / checkpoint |
| **Best for** | Reports, aggregations, bulk transforms, backfills | Real-time dashboards, alerts, event-driven workflows |

**When to use batch:**
- Data arrives in bulk (file drops, daily exports, API pulls).
- Consumers don't need results faster than the batch interval.
- The processing logic is complex and benefits from seeing the full dataset (joins, aggregations, dedup across the whole set).
- You need simplicity and testability over low latency.

**When to use stream:**
- Data arrives continuously and consumers need near-real-time results.
- The value of the data degrades quickly (fraud detection, alerting, live dashboards).
- Events need to trigger downstream actions immediately (order placed → fulfillment started).

**When you need both:**
Many systems need batch for historical analysis and stream for real-time. The discipline is keeping them from diverging:
- **Shared logic:** The transformation logic should be the same code path for batch and stream where possible. Two implementations that should produce the same output but are written and maintained separately will drift.
- **Reconciliation:** Periodically compare stream-derived results against batch-recomputed results. Discrepancies reveal bugs in one path or the other.
- **Lambda vs Kappa:** The lambda architecture (separate batch + stream paths) is common but doubles maintenance. The kappa architecture (stream-only, replay for historical) is simpler when the tooling supports it. Choose deliberately, document the decision in an ADR (§7).

---

## Common Data Pipeline Anti-Patterns

Individual sections above include specific anti-patterns (§18.2 idempotency, §18.6 backfill, §18.9 delivery, §18.10 derived data). These are the domain-level traps that span multiple sections.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Schema-on-read without validation** | Trusting that source data matches expectations. The source changes format, adds nulls, or sends duplicates — and you discover it when a dashboard shows wrong numbers, not when the data arrives. | Validate at ingestion (§18.1, §18.4). Define the contract, enforce it at the boundary. Schema-on-read is fine for exploration; it's dangerous for production pipelines. |
| **Dashboard-driven development** | Building dashboards before understanding the data. The dashboard looks right because it shows numbers — but the numbers are wrong because the underlying pipeline has silent quality issues. | Data quality first, then dashboards. A dashboard on top of unchecked data creates false confidence. Validate completeness, uniqueness, and freshness (§18.1) before visualizing. |
| **Over-engineering the pipeline** | Spark cluster for 10MB CSV files. Kafka for 100 events/day. Airflow DAGs for a cron job that runs one script. The overhead of distributed systems outweighs their benefit below a certain scale. | Match the tool to the data volume. A Python script with SQLite handles most early-stage data projects. Scale the tooling when the data volume demands it, not when the architecture diagram looks impressive. |
| **"Just add another table"** | Creating denormalized tables for every new query need without tracking which is derived from what. Eventually nobody knows which table is authoritative and which is stale. | Identify source of truth for every dataset (§18.10). Every denormalized or aggregated table must have a documented derivation path and a rebuild mechanism. |
| **No backfill strategy** | Building pipelines that can only process new data. When a bug corrupts last month's output, there's no way to reprocess without rebuilding everything from scratch. | Design every pipeline to accept a date range or batch identifier from day one (§18.6). The cost of adding backfill capability later is 10x the cost of building it in. |
| **Mixing batch and stream without reconciliation** | Running both a batch and stream path for the same data but never comparing their outputs. They silently diverge until someone notices the real-time dashboard doesn't match the weekly report. | If you run both paths, reconcile them periodically (§18.11). Discrepancies reveal bugs in one path or the other. |

---

## Mapping to Core Guardrail Sections

| Core Section | Data Pipeline Equivalent |
|---|---|
| §2 Specs | §18.3 Schema contracts + §18.5 Source registry (data dictionary) |
| §3 Testing | §18.1 Data quality testing (completeness, uniqueness, freshness, ranges) |
| §3 Type Assumptions | §18.4 Boundary type contracts (expanded for data-specific boundaries) |
| §3b Process Discipline | §18.2 Idempotency + §18.6 Backfill/replay design |
| §4 Runtime Validation | §18.7 Data observability (continuous monitoring, not just test-time checks) |
| §5 State Tracking | §18.6 Backfill logging (what was reprocessed, when, why) |
| §7 Documentation | §18.5 Source registry + §18.3 Data dictionary |
| §2 / §3 Contracts | §18.8 Backward/forward compatibility (safe schema evolution) |
| §3b Process Discipline | §18.9 Delivery guarantees (at-least-once, exactly-once, dedup) |
| §5 State Tracking | §18.10 Derived data — know where truth lives vs. what's rebuildable |
| §7 ADRs | §18.11 Batch vs stream — architecture decision with long-term consequences |

---

## Data Pipeline Checklist (extends §15)

### Before Every Pipeline Change
- [ ] Idempotency preserved — pipeline safe to re-run on the same input.
- [ ] Data quality tests updated for new or changed columns (§18.1).
- [ ] Boundary contracts reviewed if source or target changed (§18.4).
- [ ] Schema migration scripted and tested in non-prod (§18.3).
- [ ] Backward/forward compatibility assessed for schema changes (§18.8).
- [ ] Delivery guarantee documented and dedup strategy verified (§18.9).
- [ ] Pipeline logging includes `run_id`, stage, row counts, and duration (§18.7).

### Before Every Data PR
- [ ] Data quality tests pass on representative sample.
- [ ] Source registry updated if new source added or existing source changed (§18.5).
- [ ] Backfill tested if pipeline logic changed (§18.6).
- [ ] Data dictionary updated for schema changes (§18.3).
- [ ] Source of truth identified for any new dataset; derivation path documented (§18.10).
- [ ] Observability alerts configured for new pipeline stages — row counts, freshness, duration (§18.7).

### Periodic

**This checklist is a menu, not a calendar** — schedule only the items whose §0.9 trigger has fired for this project; an unrun scheduled check is worse than an unscheduled one (it reads as coverage that doesn't exist, per the §22 compliance-theater anti-pattern).

- [ ] Data observability alerts reviewed — thresholds still appropriate vs. historical baselines (weekly) (§18.7).
- [ ] Source registry reviewed — contacts current, quirks documented (quarterly).
- [ ] Orphaned tables/views sweep — unused artifacts removed (quarterly).
- [ ] Batch vs stream reconciliation — compare outputs if both paths exist (monthly) (§18.11).
- [ ] Derived data audit — can every derived table be rebuilt from its source? (quarterly) (§18.10).
