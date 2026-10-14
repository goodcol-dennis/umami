---
name: umami-auto-review
description: Pre-screen reviewer agent for code changes. Reviewing mode — produces a structured flags document, not approval/rejection. Single-pass sweep across the project's risk dimensions; output routes human attention.
---

# umami-auto-review — Auto-review pre-screen agent

**Last synced:** 2026-07-03 from §3d (added the test-change verification rule — non-rename/move test modifications flag HIGH — which shipped in §3d on 2026-05-27 but was not mirrored here until now; added the CI/lint/coverage/type-check-config HIGH flag per §0.6 *Rewriting CI to make AI pass*; new-dependency additions now classify High by default per the §3d risk taxonomy; "Change tier" renamed to "Risk level" per the §0.6 terminology note. Previously 2026-05-16: umami v3 multi-file architecture; risk taxonomy + cross-provider review; Impact + Effort + Quick-win on flags). Re-derive this skill from the current §3d when this date is >3 months old or when an audit reports structural drift.

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
- **Always fetch the landing document fresh** from the canonical URL `https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md` (use `refs/heads/develop` only for bleeding-edge, not-yet-released practices). Never cache locally.
- **Consult the Section Navigation Map** in the landing to identify §3d's home (`core/umami-quality.md`). Fetch that companion for the full review discipline (risk taxonomy, cross-provider review, three-layer model, output format). Auto-review scope always requires the quality companion.
- **If any fetch fails, tell the user and stop.** Do not fall back to a stale local copy.
- **Cite `file:line` for every finding.** "The auth code has issues" is opinion; "src/auth/middleware.ts:42 — token validation skipped before lookup" is a finding.
- **Tag every finding with a dimension** (security / data / contract / infra / etc.) so a human can route to a specialized reviewer if depth is needed.
- **Prioritize ruthlessly into 2–3 levels.** A wall of MEDIUM findings is alert fatigue. If everything is medium, nothing is.
- **One-line concerns.** The human drills into the diff if they want detail; the flags doc is for routing attention.
- **Don't flag style or formatting.** Layer 1 (mechanical) handles those. The flags document is for issues a linter wouldn't catch.
- **Classify the change against the §3d risk taxonomy** (Trivial / Low / Medium / High / Critical) and surface the risk level in the flags document — the disposition depends on it (Trivial may auto-merge with no flags; Critical requires full team review). New dependency additions classify **High by default** — the supply-chain risk lives in the package, not the diff, so an AI pre-screen cannot clear it alone (§3d, §6 *Supply Chain Attack Defenses*).
- **Test modifications that aren't pure rename/move flag HIGH — always.** Agents under make-CI-green pressure rewrite assertions to match broken code; the PR then passes its own tests by construction. Every assertion-content change must answer *"why did this assertion need to change, and is the new assertion correct?"* Per §3d *Test-change verification* and §3e ("a 'refactor' that modifies test content is a rewrite").
- **Changes touching CI / lint / coverage / type-check configuration flag HIGH — always.** Classify whether the change *strengthens* or *weakens* the gate; a weakening with no documented justification is the §0.6 *Rewriting CI to make AI pass* anti-pattern and must not auto-merge.

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

### Risk level (per the §3d risk taxonomy)
{Trivial / Low / Medium / High / Critical} — {one-line justification}. Default disposition: {auto-merge / auto-merge with notification / require human ack / full human review / full team review}.

### HIGH (need eyes)
- {dimension}: {file:line} — {one-line concern}
  - **Impact:** {specific improvement when addressed; falsifiable where possible}
  - **Effort:** {Agent-autonomous / Operator-required / Specialist · Hours/Days/Weeks/Months · One-time / Recurring / Architectural / Spend}
  - **Quick win** *(only when concrete Impact AND Effort is Hours)*

### MEDIUM (consider)
- {dimension}: {file:line} — {one-line concern}
  - **Impact:** {...}
  - **Effort:** {...}

### LOW (note)
- {one-line note} — **Effort:** {...}

### Skill drift (only if detected)
- {one-line drift callout}
```

Projects can adapt the shape (HIGH/MEDIUM/LOW vs. red/yellow/green vs. priority numbers); the qualities — `file:line` citation, dimension tag, Impact, Effort, risk level — are what matter.

## Specialized reviewer escalation

If a HIGH finding warrants depth that an auto-review sweep can't give, recommend the matching specialized reviewer. Example escalation lines (appended after the flags doc):

> **Recommended escalation:** `/security-review` for the HIGH finding in `src/auth/middleware.ts:42` — auth boundary work benefits from a dedicated security-mode review.

Auto-review never invokes specialized reviewers itself; it surfaces the recommendation, the human decides.

## What this skill is NOT

- Not approval/rejection. The human decides.
- Not blocking. Layer 1 (mechanical) blocks; Layer 2 (this) reports.
- Not a code-quality audit. Style, naming, formatting belong in linters and code-review etiquette docs.
- Not for design discussion. That's thinking mode (§14) — different skill.
