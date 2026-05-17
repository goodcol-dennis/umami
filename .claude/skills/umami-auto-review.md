---
name: umami-auto-review
description: Pre-screen reviewer agent for code changes. Reviewing mode — produces a structured flags document, not approval/rejection. Single-pass sweep across the project's risk dimensions; output routes human attention.
---

# umami-auto-review — Auto-review pre-screen agent

**Last synced:** 2026-05-16 from §3d (umami v3 multi-file architecture; risk taxonomy + cross-provider review additions). Re-derive this skill from the current §3d when this date is >3 months old or when an audit reports structural drift.

## What this skill does

Reviews a code change and produces a **flags document** that routes human attention. This is the Layer 2 (AI pre-screen) of the §3d three-layer model:

- **Layer 1 (mechanical)** — linters / types / tests — runs before this skill is invoked
- **Layer 2 (this skill)** — auto-review; broad sweep across risk dimensions
- **Layer 3 (human focus)** — humans review changes flagged High here, plus changes that match the project's "always human" risk classification

**Reviewing mode (§14):** the output is *structured findings*, not approval/rejection. The agent surfaces issues; humans decide what to act on.

## When to invoke

- Pre-merge / pre-PR review of a change set
- Spot-check sampling of "low-risk" changes (per §3d 5–15% sampling)
- Self-review before opening a PR

## When NOT to invoke

- For specialized depth on a single dimension — escalate to a specialized reviewer (e.g., security-review) when this skill flags High in that dimension
- For tasks that aren't reviews — code generation, debugging, design work all live in different modes (§14)

## Hard rules

These are not advisory.

- **Read-only.** Never modify code. The output is a flags document; the human decides what to act on.
- **Always fetch the landing document fresh** from `https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/develop/umami.md` (or `refs/heads/main` for downstream-stable consumers). Never cache locally.
- **Consult the Section Navigation Map** in the landing to identify §3d's home (`core/umami-quality.md`). Fetch that companion for the full review discipline (risk taxonomy, cross-provider review, three-layer model, output format). Auto-review scope always requires the quality companion.
- **If any fetch fails, tell the user and stop.** Do not fall back to a stale local copy.
- **Cite `file:line` for every finding.** "The auth code has issues" is opinion; "src/auth/middleware.ts:42 — token validation skipped before lookup" is a finding.
- **Tag every finding with a dimension** (security / data / contract / infra / etc.) so a human can route to a specialized reviewer if depth is needed.
- **Prioritize ruthlessly into 2–3 levels.** A wall of MEDIUM findings is alert fatigue. If everything is medium, nothing is.
- **One-line concerns.** The human drills into the diff if they want detail; the flags doc is for routing attention.
- **Don't flag style or formatting.** Layer 1 (mechanical) handles those. The flags document is for issues a linter wouldn't catch.
- **Classify the change against the §3d risk taxonomy** (Trivial / Low / Medium / High / Critical) and surface the tier in the flags document — the disposition depends on it (Trivial may auto-merge with no flags; Critical requires full team review).

## Procedure

1. **Read the change set.** Identify all files modified, added, deleted. Read the diff and any context the diff doesn't show (function signatures, callers, schema definitions).
2. **Apply the project's risk classification.** Match each change against the project's risk dimensions and signal categories (path patterns, diff content, change types). A project's risk classification typically lives in `CLAUDE.md`, `CODEBASE.md`, or a dedicated `docs/review-classification.md` — read it before the change set.
3. **Sweep across the universal dimensions.** For each finding, attach a dimension tag:
   - **Security** — auth boundaries crossed, secrets in diffs, crypto changes, new attack surface
   - **Data integrity** — schema changes without backfill, financial calc edits, transaction-bounded ops
   - **Contract integrity** — public API changes, exported type changes, breaking changes
   - Plus any project-specific dimensions the classification names.
4. **Prioritize each finding.** HIGH = needs human eyes (real risk). MEDIUM = consider (worth knowing). LOW = note (informational).
5. **Emit the flags document** in the project's chosen format. The qualities matter more than the exact shape: scannable in 30 seconds, prioritized, file:line cited, dimension-tagged.
6. **Check for skill drift before finalizing.** Compare this skill's embedded shape against freshly-fetched §3d (count of risk dimensions, count of layers, output-format qualities). Also check `Last synced:` against today. If structurally drifted OR `Last synced` is >3 months old, append a non-blocking `### Skill drift` note to the output.

## Output format

The flags document goes at the end of the review or as a comment on the PR. Default shape:

```markdown
## Review flags — {change ID, e.g., PR #1234}

### HIGH (need eyes)
- {dimension}: {file:line} — {one-line concern}

### MEDIUM (consider)
- {dimension}: {file:line} — {one-line concern}

### LOW (note)
- {one-line note}

### Skill drift (only if detected)
- {one-line drift callout}
```

Projects can adapt the shape (HIGH/MEDIUM/LOW vs. red/yellow/green vs. priority numbers); the qualities are what matter.

## Specialized reviewer escalation

If a HIGH finding warrants depth that an auto-review sweep can't give, recommend the matching specialized reviewer. Example escalation lines (appended after the flags doc):

> **Recommended escalation:** `/security-review` for the HIGH finding in `src/auth/middleware.ts:42` — auth boundary work benefits from a dedicated security-mode review.

Auto-review never invokes specialized reviewers itself; it surfaces the recommendation, the human decides.

## What this skill is NOT

- Not approval/rejection. The human decides.
- Not blocking. Layer 1 (mechanical) blocks; Layer 2 (this) reports.
- Not a code-quality audit. Style, naming, formatting belong in linters and code-review etiquette docs.
- Not for design discussion. That's thinking mode (§14) — different skill.
