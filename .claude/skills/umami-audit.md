---
name: umami-audit
description: Periodic process audit against the Umami framework. Read-only — produces a findings report; user decides what to act on. Audits one tier above the project's current adoption tier; never two.
---

# umami-audit — Process audit against the Umami framework

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

## Hard rules (non-negotiable)

These are not advisory. The skill drifts when constraints are advisory; it holds when they're rules.

- **Read-only.** Never modify code or docs during the audit. Even obvious cleanup belongs in a follow-up, not in the audit itself.
- **Always fetch the spec fresh** from `https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/develop/umami.md` (or `refs/heads/main` for downstream-stable consumers). Never cache locally — the framework evolves; cached copies go stale silently.
- **If the fetch fails, tell the user and stop.** Do not fall back to a stale local copy. An audit against three-month-old guidance produces confident, wrong recommendations.
- **Never recommend more than 5 things.** A wall of recommendations is not actionable.
- **Cite a file path or doc reference for every observation.** "The project lacks ADRs" is an opinion; "no files exist under `docs/decisions/`" is a finding.
- **Don't fetch extension files unless they apply.** A web project doesn't need an audit against `umami-data.md`. Confirm domain relevance before pulling.
- **Audit one tier above current — never two.** Recommendations the project isn't ready for create noise, not value.

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
   - **Changes required:** files created / modified / restructured
   - **Conflict risk:** low / medium / high
2. ...
3. ...
(Maximum 5.)

### Anti-patterns observed (if any)
Cite §0.6's onboarding anti-patterns. Name a watch signal for each flagged item — verdicts without falsifiers become opinion.

### Not yet relevant
Practices checked but not yet applicable, with the trigger that would make them relevant.

### After the audit
Read-only by default. Present three options:
1. Save findings to file (default).
2. Apply all recommendations.
3. Selective walkthrough.
```

## After the audit — describe changes, then ask

Each recommendation must describe the specific changes it would require — which files would be created, modified, or restructured. Then ask whether to save to file (default), apply all, or walk through selectively. Default to save-to-file unless the user explicitly requests otherwise.
