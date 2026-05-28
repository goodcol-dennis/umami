# ADR 0002 — v3 folder reorganization: core/, ext/, recipes/

**Status:** Accepted 2026-05-13
**Authors:** Dennis Portello, Claude
**Related:** [ADR 0001](0001-v3-file-split.md), [ADR 0003](0003-deprecation-stub-strategy.md), [ADR 0004](0004-recipes-directory.md), [`audits/v3.0-retro.md`](../../audits/v3.0-retro.md)

## Context

After [ADR 0001](0001-v3-file-split.md) split the monolith into a landing + 4 core companions, the repo had ~16 markdown files at the root: 1 landing + 4 companions + 11 domain extensions (`umami-web.md`, `umami-data.md`, etc.), plus ad-hoc subdirs `cms/` and `desktop/` for platform variants.

Problems with the flat root:
1. Core companions and domain extensions were visually indistinguishable at the root — both named `umami-X.md`. New contributors couldn't tell at a glance what was core vs. domain.
2. The repo was already approaching the limit of "still scannable" with 16 markdown files; future extension additions (§31+) would push it past.
3. The `cms/` and `desktop/` subdirs followed a shared+variant pattern that wasn't extended consistently — `umami-cms.md` was at root, `cms/umami-wordpress.md` was in the subdir. The two were related but visually separated.

## Decision

Reorganize the repo into a three-tier filesystem layout that mirrors the conceptual v3 architecture:

```
umami/
├── umami.md                   ← landing (never moves)
├── core/                      ← Tier 2+ core companions
│   └── umami-{quality,runtime,process,agents}.md
├── ext/                       ← domain extensions
│   ├── umami-{web,data,iac,mobile,compliance,scripting,integration,homelab,agent-workflows}.md
│   ├── cms/                   ← shared+variant clusters under their domain
│   │   └── umami-{cms,wordpress,drupal}.md
│   └── desktop/
│       └── umami-{desktop,linux,spa-wrapper}.md
├── audits/                    ← unchanged
├── recipes/                   ← new (ADR 0004)
└── .claude/skills/            ← unchanged
```

**Landing (`umami.md`) stays at the repo root and never moves.** It's the single most-referenced URL across every adopter's `CLAUDE.md`; breaking it cascades widely. All other moves are bounded by deprecation stubs ([ADR 0003](0003-deprecation-stub-strategy.md)) during the v3.0 → v3.1 window.

**The `umami-` prefix is kept** even under subdirs. The argument: file names retain identity when excerpted, pasted in chat, searched globally, or referenced externally. Inside the repo the prefix is mild redundancy; outside it's brand and namespace.

**Shared+variant clusters consolidate under `ext/{domain}/`.** Previously the shared base (`umami-cms.md`) was at root and variants (`cms/umami-wordpress.md`) were in a subdir. Under v3, everything for a domain lives together: `ext/cms/umami-cms.md` + `ext/cms/umami-wordpress.md` + `ext/cms/umami-drupal.md`.

## Consequences

**Positive:**
- Visual separation of core vs. extensions matches the conceptual model (Tier 1 → landing; Tier 2+ core → `core/`; domain → `ext/`)
- Repo root drops to 4 markdown files (README, CLAUDE.md, LICENSE, `umami.md`) — scannable indefinitely
- New extensions land in `ext/` (or `ext/{domain}/`) without re-deciding location
- Shared+variant clusters group all related files together
- File paths are stable for the long term; the next restructure can be deferred indefinitely or executed cheaply (mostly path renames within stable section IDs)

**Negative / accepted trade-offs:**
- Every URL except `umami.md` changes. Adopters with project `CLAUDE.md` files referencing companions or extensions need to update those paths once.
- Filesystem moves are not friction-free: cross-references within markdown files needed to be audited for path-specific references (most use plain `§N` and survived; a few that mentioned specific paths needed updates)
- More moving parts at restructure time — 14 files moved + 14 deprecation stubs + cross-reference updates across landing, README, CLAUDE.md, skill files, gap registry, retro

## Alternatives considered

**Option A — Stay flat:**
- Keep everything at root; no folder structure.
- Rejected because the root was already busy and growth would make it worse. The folder structure has long-term value even if v2.1 was tolerable.

**Option B — Drop the `umami-` prefix in subdirs:**
- Use `core/quality.md` instead of `core/umami-quality.md`, etc.
- Rejected because the prefix has signal value when files are excerpted, pasted, or searched outside the repo context. The folder already signals umami; the prefix is small redundancy with high brand/namespace return.

**Option C — Deeper hierarchy (`framework/core/`, `framework/ext/`):**
- Wrap everything under a `framework/` directory.
- Rejected as unnecessary indirection. `core/` and `ext/` at the root level are already short and clear.

**Option D — Defer to v3.1:**
- Land file split (ADR 0001) in v3.0; defer folder reorg to v3.1.
- Rejected because v3.0 was already a major version that would break URLs for non-landing paths. Combining the file split and folder reorg into one v3.0 breaking-change pass is cheaper than two separate ones.

## Cost / breaking-change scope

Every non-landing URL changes. Specifically:
- `umami-quality.md` → `core/umami-quality.md` (and 3 more companions)
- `umami-web.md` → `ext/umami-web.md` (and 8 more flat extensions)
- `cms/umami-wordpress.md` → `ext/cms/umami-wordpress.md` (and 1 more under cms/)
- `umami-cms.md` → `ext/cms/umami-cms.md` (shared base joins variants)
- `umami-desktop.md` → `ext/desktop/umami-desktop.md` (shared base joins variants)
- `desktop/umami-linux.md` → `ext/desktop/umami-linux.md`
- `desktop/umami-spa-wrapper.md` → `ext/desktop/umami-spa-wrapper.md`

[ADR 0003](0003-deprecation-stub-strategy.md) covers how the breakage is softened — 14 deprecation stubs at pre-v3 paths point readers back to the landing for the current Section Navigation Map. Stubs are removed in v3.1.

## Validation

This decision is bounded by the v3.0 → v3.1 transition window. Once v3.1 removes the deprecation stubs, the folder layout becomes permanent for the v3 series. Future restructures would require another major version. The file-layout convention is documented in `CLAUDE.md` so contributors understand which paths are external contracts.
