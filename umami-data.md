# Data Pipeline Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §18**

This extension covers data ingestion, transformation pipelines, warehousing, and analytics systems. The core template assumes application development patterns — test suites run in seconds, changes affect UI or API responses, and the blast radius is a broken page. Data projects have different failure modes: silent corruption, schema drift, stale data, and transforms that produce wrong results without errors.

**Apply this extension when** the §0.2 system shape questionnaire identifies Data Ingestion, Data Pipeline / Transforms, or Data Warehouse / Storage layers.

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

---

## Data Pipeline Checklist (extends §15)

### Before Every Pipeline Change
- [ ] Idempotency preserved — pipeline safe to re-run on the same input.
- [ ] Data quality tests updated for new or changed columns (§18.1).
- [ ] Boundary contracts reviewed if source or target changed (§18.4).
- [ ] Schema migration scripted and tested in non-prod (§18.3).

### Before Every Data PR
- [ ] Data quality tests pass on representative sample.
- [ ] Source registry updated if new source added or existing source changed (§18.5).
- [ ] Backfill tested if pipeline logic changed (§18.6).
- [ ] Data dictionary updated for schema changes (§18.3).

### Periodic
- [ ] Data observability alerts reviewed — no ignored or noisy alerts (weekly).
- [ ] Source registry reviewed — contacts current, quirks documented (quarterly).
- [ ] Orphaned tables/views sweep — unused artifacts removed (quarterly).
