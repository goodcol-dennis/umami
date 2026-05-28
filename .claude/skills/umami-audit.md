---
name: umami-audit
description: Periodic process audit against the Umami framework. Read-only — produces a findings report; user decides what to act on. Audits one tier above the project's current adoption tier; never two.
---

# umami-audit — Process audit against the Umami framework

**Last synced:** 2026-05-16 from §0.7 (umami v3 multi-file architecture; Impact + Effort + Quick-win annotations on recommendations). Re-derive this skill from the current §0.7 when this date is >3 months old or when an audit reports structural drift.

## What this skill does

Audits the project's development PROCESS against the Umami framework — testing discipline, ADR/spec hygiene, change tracking, dead-code budgets, security habits, agent orchestration practices. **Not a code-quality audit. Process maturity only.**

## When to invoke

- User says "umami audit" / "process audit" / "kick off the audit"
- After a milestone or release ships
- Long stretch (~2+ weeks) without a process check-in
- Before onboarding a new contributor — gives them a current snapshot

## When NOT to invoke

- Code-quality review on a specific module — use a different skill
- UI/UX review — not this skill's job
- Active design session — audits interrupt; finish the design pass first

## Procedure

1. **Determine current tier** from project artifacts (CLAUDE.md, ROADMAP, audits/, tier-relevant practices already in place).
2. **Audit one tier above current** — never two. Read only the relevant practice sections.
3. **Cite a file path or doc reference for every observation.** Findings without citations are opinion.
4. **Produce 3–5 actionable recommendations** — never more — using the §0.7 output format.
5. **Name watch signals** for any flagged anti-patterns. Verdicts without falsifiers become opinion.
6. **Audit is read-only** — do not modify code or docs during the audit phase.
7. **Check for skill drift before finalizing.** Compare this skill's embedded shape against the freshly-fetched §0.7: count of disposition options in the four-option dialog, count of hard rules below, shape of the output-format block. Also check the `**Last synced:**` header against today. If structural drift OR `Last synced` is >3 months old, append a non-blocking `### Skill drift` callout to the report (one line, doesn't count toward the ≤5 limit).

## Hard rules (non-negotiable)

These are not advisory. The skill drifts when constraints are advisory; it holds when they're rules.

- **Read-only.** Never modify code or docs during the audit. Even obvious cleanup belongs in a follow-up, not in the audit itself.
- **Always fetch the landing document fresh** from the canonical URL `https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md` (use `refs/heads/develop` only for bleeding-edge, not-yet-released practices). Never cache locally — the framework evolves; cached copies go stale silently.
- **Consult the Section Navigation Map.** The landing carries §0, framework, and Tier 1 practices. Tier 2+ practices live in core companion files under `core/` (`core/umami-quality.md`, `core/umami-runtime.md`, `core/umami-process.md`, `core/umami-agents.md`). Domain extensions live under `ext/` (with shared+variant clusters under `ext/{domain}/`). Use the Navigation Map in the landing to identify which companions match the audit scope. Tier 1 audits typically don't need any companion file.
- **If any fetch fails, tell the user and stop.** Do not fall back to a stale local copy. An audit against three-month-old guidance produces confident, wrong recommendations.
- **Never recommend more than 5 things.** A wall of recommendations is not actionable.
- **Cite a file path or doc reference for every observation.** "The project lacks ADRs" is an opinion; "no files exist under `docs/decisions/`" is a finding.
- **Don't fetch companion or extension files unless they apply.** A Tier 1 audit needs no companion files. A web project doesn't need an audit against `ext/umami-data.md`. Confirm scope relevance before pulling.
- **Detect dead legacy URLs.** If a project's `CLAUDE.md` references a pre-v3 path (e.g., `umami-web.md` at the root, or `cms/umami-wordpress.md`), **the fetch will 404 as of v3.1** — the deprecation stubs were removed. Surface this prominently in the audit output as a HIGH-priority migration item, not a "next practice" suggestion: the project is currently fetching dead URLs and any agent reading their `CLAUDE.md` is getting nothing from those links. The migration target is the `ext/` paths (`ext/umami-web.md`, `ext/cms/umami-wordpress.md`, `ext/desktop/umami-linux.md`, etc.); the landing `umami.md` at repo root is unchanged.
- **Audit one tier above current — never two.** Recommendations the project isn't ready for create noise, not value.
- **Every recommendation cites Impact and Effort.** Impact names a specific improvement (anti-pattern closed, gap entry resolved, measurable pain reduced — ideally falsifiable). Effort uses the §4 cost-profile scheme. Flag **Quick win** only when Impact is concrete and Effort is Hours.
- **Surface latent practices.** Beyond tier-gap recommendations, look for practices the team is *already exercising* that aren't yet codified — either in the project's own CLAUDE.md / process docs, or in umami's spec. Evidence: hooks doing something the docs don't describe, scripts doing operations not captured in process, conventions visible across commits but not in CLAUDE.md, gap-registry entries pre-staging work that isn't reflected in any tier-table practice. When found, surface them in the "Latent practices observed" section of the report and recommend codification — either in the project's docs or, if universally applicable, as a contribution to umami itself.

## Self-audit special case

When auditing **this repo itself** (the canonical umami source), the local working tree IS the source of truth. The "fetch fresh from URL" rule doesn't apply — fetching from `develop` would be reading the already-loaded current branch with extra steps and risks confusing local-uncommitted changes with the published spec.

For self-audit:
- Use the local files directly.
- State this explicitly in the audit's Scope line: *"No URL fetch — this repo IS the canonical source."*
- All other hard rules still apply (read-only, ≤5 recommendations, cite paths, etc.).

## Output format

Use the §0.7 audit output format:

```markdown
## Process Audit — [Project Name]

**Date:** YYYY-MM-DD
**Current tier:** Tier N — brief justification
**Auditing against:** Tier N+1 practices (plus self-application of recently-added practices, if applicable)
**Scope:** Core framework + [extension files if applicable]
**Last audit:** [date if known]

### What's working well
- 2–4 bullets — practices already solid at the tier-above level

### Recommended next practices (priority order)
1. [Practice] (§X) — why this addresses a current pain point
   - **Impact:** specific improvement, tied to a watch signal or measurable signal where possible
   - **Effort:** Agent-autonomous / Operator-required / Specialist · Hours/Days/Weeks/Months · One-time / Recurring / Architectural / Spend (per §4 *Reading the cost profiles*)
   - **Quick win** *(only when Impact is documented anti-pattern / gap entry / measurable pain reduction AND Effort is Hours)*
   - **Changes required:** files created / modified / restructured
   - **Conflict risk:** low / medium / high
2. ...
3. ...
(Maximum 5.)

### Anti-patterns observed (if any)
Cite §0.6's onboarding anti-patterns. Name a watch signal for each flagged item — verdicts without falsifiers become opinion.

### Not yet relevant
Practices checked but not yet applicable, with the trigger that would make them relevant.

### Skill drift (only if detected)
*One line, non-blocking, outside the priority list.*

### After the audit
Read-only. Present a four-option dialog using `AskUserQuestion` (or equivalent structured prompt) so the choice is self-contained in the UI:

1. **Apply all recommendations** — execute every finding.
2. **Selective walkthrough** — one at a time per §3c.
3. **Do something else** (free-text prompt) — save to file, branch first, defer, narrow scope, etc.
4. **Skip** — discard without action.
```

## After the audit — describe changes, then present the four-option dialog

Each recommendation must describe the specific changes it would require — which files would be created, modified, or restructured. Then present the four-option dialog (apply all / selective / other / skip). No default — the right disposition depends on the user's situation, not the audit's. *"Save findings to a file"* is one example of an "Other" action, not a built-in default.
