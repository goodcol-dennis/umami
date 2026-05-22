---
name: umami-init
description: First-time umami setup or upgrade-existing-setup. Discovers project shape, proposes core + extensions, updates instruction files, installs skills. Read-only by default; the four-option dialog gates every file write.
---

# umami-init — Initialization protocol

**Last synced:** 2026-05-22 from §0.7b (umami v3 multi-file architecture; Impact + Effort + Quick-win annotations on findings — applied where init surfaces process recommendations, not for mechanical URL/skill installation; auto-chain into `/umami-audit` on successful apply added 2026-05-22). Re-derive this skill from the current §0.7b when this date is >3 months old or when an audit reports structural drift.

## What this skill does

Bootstrap or upgrade umami in a project. Three jobs:

1. Discover the project's shape (run §0.1–§0.4 from the canonical spec).
2. Propose the right core + extension set per §0.5 mapping.
3. Apply changes (with explicit user approval, after showing the diff) — update instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.) and install the `umami-init` and `umami-audit` skills locally.

**This is a lightweight setup, not a framework install.** Only URL references and invocation-aid skill files are written. No framework copy, no runtime dependency. The umami spec itself stays at its canonical URL and is fetched fresh on every run; the local artifacts make access to umami consistent and harness-recognized as commands.

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

3. **Derive the recommended set** of URLs via §0.5's "if the project has..." mapping. The URL block always includes the **landing document** (`umami.md` at the repo root). Core companion files (`core/umami-quality.md`, `core/umami-runtime.md`, `core/umami-process.md`, `core/umami-agents.md`) and domain extensions (`ext/umami-{name}.md`, with shared+variant clusters under `ext/{domain}/`) are added based on the tier the project is targeting and which concerns apply. For Tier 1 / first-pass adoption, the URL block may legitimately list only the landing plus relevant domain extensions — companions can be added when the project escalates to Tier 2.

4. **Compute the diff** against current state:
   - **Adds:** companion files (if Tier 2+) and domain extensions to add to the URL list.
   - **Removes:** files referenced but not relevant (rare; usually keep, just flag).
   - **Skill installations:** `.claude/skills/umami-init.md` and `.claude/skills/umami-audit.md` with `**Last synced:** YYYY-MM-DD` set to today.

5. **Show the user the proposed changes, then present the four-option dialog.** Enumerate every file that would be modified or created — paths, line counts, the exact URL block that would land in each instruction file, which skill files would be created or updated and at what `Last synced:` date. The user must be able to read the diff before deciding. Then surface the dialog (apply all / selective walkthrough / do something else / skip) per §0.7. Self-contained prompt per §3b.

6. **Apply on approval.** Update all detected instruction files in lockstep (a project with both `CLAUDE.md` and `AGENTS.md` gets identical URL lists in both). Write the skill files. Don't overwrite existing skill files without diffing first; if the existing skill has a newer or different `Last synced` date, surface the conflict before resolving.

7. **Check for skill drift before finalizing.** Compare this skill's embedded shape against the freshly-fetched §0.7b: count of disposition options in the four-option dialog, count of hard rules below, structure of the procedure. Also check the `**Last synced:**` header against today. If structural drift OR `Last synced` is >3 months old, append a non-blocking `### Skill drift` callout to the report (one line, doesn't count toward the ≤5 limit).

8. **On apply, auto-chain into the first audit.** When step 6 actually wrote files, immediately invoke `/umami-audit` to produce a baseline process audit against the freshly-installed configuration. Announce: *"Init complete — wrote {file list}. Running first process audit now…"* and proceed without further confirmation. The audit runs its full §0.7 procedure — read-only fetch, findings report, its own four-option findings-disposition dialog at the end — so the user still chooses interactively what to act on; auto-chain only removes the manual `/umami-audit` invocation step, not the findings dialog. If init was skipped at the four-option dialog (no files written), do **not** auto-chain; hand off with *"Init skipped — re-invoke `/umami-init` when you're ready."*

## Hard rules (non-negotiable)

These are not advisory. The skill drifts when constraints are advisory; it holds when they're rules.

- **Read-only by default.** The four-option dialog gates every write; no destructive changes without explicit approval.
- **Always fetch the landing document fresh** from the canonical URL (`https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/develop/umami.md`). Never cache locally. Skill files don't count — they're invocation aids, not copies.
- **For Tier 2+ scope, fetch the companion files identified by the landing's Section Navigation Map.** Don't fetch companions speculatively.
- **If any fetch fails, tell the user and stop.** Do not fall back to a stale local copy. Init against three-month-old guidance produces wrong recommendations.
- **Cite a file path or doc reference for every observation.** "The project lacks the data extension" is an opinion; "no `ext/umami-data.md` URL is referenced in `CLAUDE.md` despite the project containing `lib/pipeline/`" is a finding.
- **Detect legacy v2.1 paths and offer migration.** If `CLAUDE.md` references pre-v3 paths (root-level `umami-X.md`, `cms/`, `desktop/`), surface this in the proposed diff. Offer to update the URLs to their v3 paths (`core/`, `ext/`, `ext/cms/`, `ext/desktop/`). Legacy paths still work via deprecation stubs in v3.0 but **will 404 in v3.1** — flag the migration as a priority.
- **Don't fetch companion or extension files unless they apply.** Confirm relevance via §0.2 system shape answers and the §0.6 target tier before pulling.
- **Drift detection always runs** before finalizing the report. See step 7.
- **Auto-chain into `/umami-audit` on successful apply** (step 8). Printing a hand-off message and stopping leaves the user with installed skills but no view of their baseline; the bootstrap one-liner ends in a finding-bearing audit, not a confirmation message. The audit's own four-option findings-disposition dialog still runs — the user remains in control of what to act on. Auto-chain only when files were written; skip the audit when the user chose **Skip** at the init four-option dialog.
