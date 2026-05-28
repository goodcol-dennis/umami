# ADR 0003 — Deprecation stub strategy for pre-v3 paths

**Status:** Accepted 2026-05-13
**Authors:** Dennis Portello, Claude
**Related:** [ADR 0002](0002-v3-folder-reorg.md), [`audits/v3.0-retro.md`](../../audits/v3.0-retro.md)

## Context

[ADR 0002](0002-v3-folder-reorg.md) moved 14 markdown files from their v2.1 paths to new v3 paths under `ext/` and `ext/{domain}/`. Every adopter's project `CLAUDE.md` that referenced a non-landing path (e.g., `umami-web.md` at the root, `cms/umami-wordpress.md`) would 404 on its next fetch unless updated.

The §0.7 audit protocol requires fetching umami fresh on every run (no caching). The §0.7b init protocol fetches the spec to bootstrap new projects. Either flow hitting a 404 produces silent failure or confusing errors — the agent has no signal about *why* the URL is wrong or where to find the new location.

The framework's own §0.6 "Aesthetic restructure" anti-pattern explicitly warns about breaking downstream URL contracts without enumerating the breakage. The v3 restructure was substantive (not aesthetic), but the breakage is still real.

## Decision

Leave a **deprecation stub** at every pre-v3 path that was moved. Each stub is a short markdown file (~12 lines) that:

1. Names what happened (file moved as part of v3.0 restructure)
2. Points the reader back to the landing document (`umami.md`) for the current Section Navigation Map
3. States the timeline ("removed in v3.1")
4. Suggests the migration path (the `/umami-init` skill can update legacy paths automatically)
5. Includes the canonical landing URL so an agent fetching via raw URL has a way forward

All 14 stubs are identical in content (differing only in their path location). They live at:
- 10 stubs at the repo root: `umami-{cms,compliance,data,desktop,homelab,iac,integration,mobile,scripting,web}.md`
- 4 stubs in legacy subdirs: `cms/umami-{wordpress,drupal}.md`, `desktop/umami-{linux,spa-wrapper}.md`

**Stubs are explicitly v3.0-only.** v3.1 deletes them. Adopters who haven't migrated by v3.1 hit a 404 — the migration window is one release cycle, not indefinite.

## Consequences

**Positive:**
- Existing project `CLAUDE.md` files don't immediately break on v3.0 release; adopters get a grace period to update paths
- Agents fetching legacy URLs receive a clear migration message rather than a confusing 404 / failure
- The `/umami-init` skill (updated to detect legacy paths) can offer in-place migration to adopters who run it
- The v3.0 → v3.1 timeline is explicit and enforceable; this isn't an indefinite legacy compatibility commitment

**Negative / accepted trade-offs:**
- 14 stub files at pre-v3 locations clutter the repo root during the v3.0 series
- Stubs are technically maintenance burden — if the message text needs to change, all 14 update in lockstep
- v3.1 deletion is a *second* breaking event for adopters who didn't migrate during the v3.0 window
- Adopters who pinned a specific commit hash or older tag get the original content (not the stub) — the deprecation only helps adopters fetching `main` or `develop`

## Alternatives considered

**Option A — No deprecation stubs; break paths immediately:**
- Adopters with project `CLAUDE.md` files pointing at old paths get 404s on first v3.0 fetch.
- Rejected because the silent-failure mode is bad UX and contradicts umami's own velocity-protection framing. The cost of stubs is small; the cost of breaking adopters silently is high.

**Option B — Permanent symlinks or redirects:**
- Keep the old paths working forever via filesystem symlinks or HTTP-level redirects.
- Rejected because (1) `raw.githubusercontent.com` doesn't support symlinks across the filesystem in a way that resolves through raw fetches reliably, (2) permanent redirects accumulate as legacy commitments and undermine the value of restructuring at all.

**Option C — GitHub Pages with redirect HTML:**
- Set up GitHub Pages serving redirect HTML at old paths.
- Rejected because it adds infrastructure (Pages enable, build config) without significant gain over markdown stubs. Markdown stubs are visible in the repo, version-controlled, and a fetching agent gets a human-readable message it can interpret.

**Option D — Stubs that proxy to the new location:**
- Stubs that contain the same content as the new file, kept in sync.
- Rejected because it doubles content storage and creates a drift problem — stubs would inevitably go out of date. Pointing to the landing (which always has the current Navigation Map) avoids the drift.

## Stub content (canonical)

```markdown
# Deprecated — moved in umami v3.0

This file has moved as part of the umami v3.0 restructure (concern-based architecture:
landing document at repo root + core companions in `core/` + domain extensions in `ext/`,
with shared+variant clusters grouped under `ext/{domain}/`).

→ **Fetch the landing document `umami.md`** at the repository root for the current
Section Navigation Map and URL paths. The Map identifies where every section now lives.

Canonical landing URL:

    https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md

(Substitute `main` for your tracking branch — `develop`, a release tag, etc.)

This stub will be **removed in v3.1**. Update any references in your project's `CLAUDE.md`
(or `AGENTS.md` / `.cursorrules` / equivalent) before then. The `/umami-init` skill
detects legacy paths and offers automatic migration.

**For agents:** do not treat this file as the source of truth. The canonical location
is wherever `umami.md`'s Section Navigation Map points to.
```

All 14 stubs are exact copies. Updating them is a search-and-replace across 14 files; tracked centrally in v3.0-retro.md.

## Validation

The stub strategy will be validated when external adopters actually run `/umami-init` or fetch a legacy URL during the v3.0 window. Successful validation:
- Agent fetching a legacy URL surfaces the migration message clearly
- `/umami-init` detects legacy paths in instruction files and offers update
- No silent failures or confusing 404s reported

If validation reveals problems (e.g., agents misinterpret the stub content as authoritative), the stub wording will be tightened in a v3.0.x patch.
