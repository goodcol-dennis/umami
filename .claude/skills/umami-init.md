---
name: umami-init
description: First-time umami setup or upgrade-existing-setup. Discovers project shape, proposes core + extensions, updates instruction files, installs skills. Read-only by default; the four-option dialog gates every file write.
---

# umami-init — Initialization protocol

**Last synced:** 2026-05-09 from §0.7b. Re-derive this skill from the current §0.7b when this date is >3 months old or when an audit reports structural drift.

## What this skill does

Bootstrap or upgrade umami in a project. Three jobs:

1. Discover the project's shape (run §0.1–§0.4 from the canonical spec).
2. Propose the right core + extension set per §0.5 mapping.
3. Apply changes (with explicit user approval) — update instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.) and install the `umami-init` and `umami-audit` skills locally.

**Not an audit. Not a code-quality review.** For ongoing process review use `/umami-audit`.

## When to invoke

- Project has no umami presence (first-time setup).
- Project shape has changed (added a frontend, added a data layer, became multi-layer, added compliance requirements).
- Cloning or onboarding to a project that references umami URLs but has no skills installed.

## When NOT to invoke

- Routine process review — use `/umami-audit` instead.
- Project shape is stable and umami is correctly configured (init has nothing to do).
- Active design session — finish the design pass first; init writes files.

## What gets stored locally vs. fetched fresh

- **Stored locally:** URL *references* to the canonical umami spec (in instruction files like `CLAUDE.md`) and *skill files* (`.claude/skills/umami-init.md`, `.claude/skills/umami-audit.md`) that describe how to invoke the protocols.
- **Never stored locally:** the umami spec itself. The agent fetches `umami.md` (and any extension files) fresh from the canonical URL on every audit/init run.

Skill files are invocation aids. They contain procedure shape and hard rules so the harness recognizes `/umami-init` and `/umami-audit` as commands. They do **not** contain a copy of the spec.

## Procedure

1. **Detect current state.** Grep instruction file(s) (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.cursor/rules/`, etc.) for umami URL references. Catalog which extensions (if any) are loaded. Determine starting state: **none** / **partial** / **complete**.

2. **Run §0.1–§0.4 discovery** from freshly-fetched `umami.md`. Walk the questionnaire interactively, one decision at a time per §3c when answers compound.

3. **Derive the recommended set** of core + extensions via §0.5's "if the project has..." mapping.

4. **Compute the diff** against current state:
   - **Adds:** extensions to add to the URL list.
   - **Removes:** extensions referenced but not relevant (rare; usually keep, just flag).
   - **Skill installations:** `.claude/skills/umami-init.md` and `.claude/skills/umami-audit.md` with `**Last synced:** YYYY-MM-DD` set to today.

5. **Present the four-option dialog** (apply all / selective walkthrough / do something else / skip) per §0.7. Use the harness's structured-prompt mechanism so the question is self-contained per §3b.

6. **Apply on approval.** Update all detected instruction files in lockstep (a project with both `CLAUDE.md` and `AGENTS.md` gets identical URL lists in both). Write the skill files. Don't overwrite existing skill files without diffing first; if the existing skill has a newer or different `Last synced` date, surface the conflict before resolving.

7. **Check for skill drift before finalizing.** Compare this skill's embedded shape against the freshly-fetched §0.7b: count of disposition options in the four-option dialog, count of hard rules below, structure of the procedure. Also check the `**Last synced:**` header against today. If structural drift OR `Last synced` is >3 months old, append a non-blocking `### Skill drift` callout to the report (one line, doesn't count toward the ≤5 limit).

8. **Hand off:** *"Initialization complete. Run `/umami-audit` for a first process audit, or invoke it periodically as the project grows."*

## Hard rules (non-negotiable)

These are not advisory. The skill drifts when constraints are advisory; it holds when they're rules.

- **Read-only by default.** The four-option dialog gates every write; no destructive changes without explicit approval.
- **Always fetch the spec fresh** from the canonical URL (`https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/develop/umami.md`). Never cache the spec locally. Skill files don't count — they're invocation aids, not copies.
- **If the fetch fails, tell the user and stop.** Do not fall back to a stale local copy. Init against three-month-old guidance produces wrong recommendations.
- **Cite a file path or doc reference for every observation.** "The project lacks the data extension" is an opinion; "no `umami-data.md` URL is referenced in `CLAUDE.md` despite the project containing `lib/pipeline/`" is a finding.
- **Don't fetch extension files unless they apply.** Confirm relevance via §0.2 system shape answers before pulling.
- **Drift detection always runs** before finalizing the report. See step 7.
