# Architecture Decision Records (ADRs)

This directory holds Architecture Decision Records for umami itself — individual records of significant decisions made during the framework's evolution, distinct from per-release retros in [`../../audits/`](../../audits/).

## How ADRs differ from retros

Per §7 / §8 in the umami framework:

| | ADR | Retro |
|---|---|---|
| **Scope** | One decision | A release window |
| **When written** | At decision time (or retroactively for important historical decisions) | After a release ships |
| **Lifetime** | Permanent record of *what was decided and why* | Frozen snapshot of *what shipped and what slipped* |
| **Status** | Proposed / Accepted / Superseded / Deprecated | Always frozen at the tag |
| **Cross-referenced from** | Future ADRs that revisit the decision; commit messages; sometimes retros | Future releases; status blocks |

## ADR format

Adapted from Michael Nygard's template:

- **Status** — Proposed / Accepted / Superseded by ADR-NNNN / Deprecated
- **Context** — what forces are at play; what problem we're solving
- **Decision** — the change we're proposing or have agreed to
- **Consequences** — what becomes easier / harder; what trade-offs we're accepting
- **Alternatives considered** — other options evaluated and why we didn't pick them

ADRs reference cross-implementation research docs (per §7) when foundational; for less foundational decisions, the "Alternatives considered" section captures the comparison inline.

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](0001-v3-file-split.md) | v3 file split — landing + 4 core companions | Accepted (2026-05-13) |
| [0002](0002-v3-folder-reorg.md) | v3 folder reorganization — core/, ext/, recipes/ | Accepted (2026-05-13) |
| [0003](0003-deprecation-stub-strategy.md) | v3.0 → v3.1 deprecation stubs for pre-v3 paths | Accepted (2026-05-13) |
| [0004](0004-recipes-directory.md) | Recipes directory as a fourth content category | Accepted (2026-05-13) |
| [0005](0005-adoption-ledger-self-gating.md) | The Adoption Ledger — active self-gating against over-application (§0.9) | Accepted (2026-06-18) |

For decisions that span multiple ADRs or that have broader architectural impact, see also [`../../audits/v3.0-retro.md`](../../audits/v3.0-retro.md) which integrates these into the full v3 architectural narrative.
