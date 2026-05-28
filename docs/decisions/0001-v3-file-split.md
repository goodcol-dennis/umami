# ADR 0001 — v3 file split: landing + 4 core companions

**Status:** Accepted 2026-05-13
**Authors:** Dennis Portello (project maintainer), Claude (collaborator)
**Related:** [`audits/v3.0-retro.md`](../../audits/v3.0-retro.md), [ADR 0002](0002-v3-folder-reorg.md), [ADR 0004](0004-recipes-directory.md)

## Context

`umami.md` v2.1 was a 2,800-line monolithic markdown document covering §0–§15. Adopters fetching it via `raw.githubusercontent.com` paid ~40K tokens per audit / init. For users on Claude Pro plans (~$20/month, ~45 messages per 5-hour window) or comparable lower-token-budget plans on other providers, a single audit fetch could consume a substantial portion of their window — and the §0.7 protocol mandates fetching fresh on every audit (no caching). The cost was disproportionately painful for Tier 1 adopters who didn't need most of the document.

The monolithic shape also accumulated maintenance friction: section moves required cross-file coordination, contributor edits collided on a single file, and the file's size approached the read-truncation watch threshold tracked in `audits/gaps.md`.

A pre-staged split plan (extract §0 into a `umami-process.md` companion) existed in the gap registry, but that split addressed file-size only — not the cost-tier problem and not the longer-term scalability of the corpus.

## Decision

Split `umami.md` into a **landing document** (Tier 1 + framework + Section Navigation Map) plus **four concern-based companion files** (Tier 2+ practices grouped by concern):

- `umami.md` (landing) — §0, §1, §3b, §6, §13, §15 + Navigation Map + Security Essentials sidebar (~13K tokens)
- `core/umami-quality.md` — §2, §3, §3c, §3d, §3e (specs, testing, decision planning, code review, refactoring)
- `core/umami-runtime.md` — §4, §5, §6b (runtime validation, security disciplines, state recovery, pipeline health)
- `core/umami-process.md` — §7, §8, §10, §12 (documentation, gaps, propagation, change tracking)
- `core/umami-agents.md` — §9, §11, §14 (token efficiency, file size budgets, agent orchestration)

**Section numbers stay stable across files.** Cross-references use plain `§N` notation; file location is metadata declared by the landing's Section Navigation Map. A new top-level *Section Navigation Map* table in the landing tells the agent which file holds each section.

## Consequences

**Positive:**
- Tier 1 / Foundation fetch drops from ~40K tokens to ~13K (67% reduction)
- Tier 2 fetches scale by *concern*, not by *tier*: a testing-heavy project fetches landing + quality (~22K), not landing + everything
- Concern files can grow in their own lanes without forcing another restructure when one cluster expands
- Contributor edits collide less (different concerns → different files)
- Landing carries the navigation engine, making cost-aware adoption discoverable from the entry point

**Negative / accepted trade-offs:**
- File location becomes a stable identifier in addition to section numbers — moving a section between files breaks downstream `CLAUDE.md` references that named the path (vs. those that referenced `umami.md` only)
- Five core files to maintain instead of one; coordination overhead for cross-file changes
- Cross-references now sometimes need a file hint on first occurrence (e.g., "§6b in `core/umami-runtime.md`") for navigation clarity
- A Tier 3 / mature project fetching the full corpus pays comparable token cost to v2 (the split saves bottom-tier adopters more than top-tier ones)

## Alternatives considered

**Option A — Single companion file (`umami-deep.md`):**
- All Tier 2+ content in one file. Simpler restructure; faster execution.
- Rejected because `umami-deep.md` would grow back to today's size within 6–12 months at current pace, forcing the restructure again. v3 sets the long-term shape.

**Option B — Pre-staged §0 split only (the gap-registry default):**
- Extract just §0 into `umami-process.md`; leave §1–§15 in `umami.md`.
- Rejected because it addresses file-size only, not the cost-tier problem. Most adopters need §0 + Tier 1 every fetch; splitting §0 out doesn't reduce the Tier 1 fetch cost meaningfully.

**Option C — Concern-based split with five separate companion files:**
- This decision. Chosen because (1) concern boundaries are discoverable and stable, (2) growth distributes across multiple files instead of concentrating in one, (3) cost scales by concern rather than by tier.

**Option D — Top-down rewrite or renumbering:**
- Never seriously considered. Section numbers were already stable identifiers in v2.1; renumbering breaks every downstream `CLAUDE.md` reference and every cross-file ref simultaneously.

## Concern-boundary rationale

Each section was assigned to a file based on its **primary concern**, not strict tier level:

| Section | File | Primary concern |
|---|---|---|
| §2, §3, §3c, §3d, §3e | quality | Correctness contracts, verification, design correctness |
| §4, §5, §6b | runtime | Production correctness, security, operational survivability |
| §7, §8, §10, §12 | process | Project meta, documentation, gap tracking |
| §9, §11, §14 | agents | Agent-context efficiency, orchestration |

§4 stays whole in `core/umami-runtime.md` (splitting it across files was rejected); instead, a *Security Essentials* sidebar in the landing carries the Tier 1 floor (~30 lines: no secrets, scan deps, parameterize queries, build hygiene) with an explicit pointer to §4 for full treatment.

§6 (Enforced Consistency) and §13 (Dead Code Hygiene) stay in the landing as Tier 1 hygiene practices; §6b (Developer Experience and Pipeline Health) goes to runtime because cycle-time and gate dispositions are operational concerns.

§11 (File Size Budgets) goes to agents (not quality) because its trigger per §0.6 is "files long enough that agents truncate or miss context" — the concern is agent-context-shaped, not code-quality-shaped.

## Validation

The pattern is documented in `audits/gaps.md` as "v3 multi-file architecture not yet validated at scale by external adopters" — this ADR's decision will be revisited if field validation reveals that concern boundaries don't hold up across diverse projects.
