---
name: umami-drift-audit
description: Periodic dropped-item audit. Surfaces designs, explorations, POCs, and deferred decisions that fell off the radar — not in the gap registry, not in retros, not actively worked on. Read-only — produces a findings report with proposed dispositions; user decides what to act on.
---

# umami-drift-audit — Periodic dropped-item audit

**Last synced:** 2026-05-16 from §8 (umami v3 multi-file architecture; shipped-features scan-location; Impact + Effort + Quick-win on dispositions). Re-derive this skill from the current §8 when this date is >3 months old or when an audit reports structural drift.

## What this skill does

Scans the project for **dropped intent** — items that quietly fell off attention. Sister to `umami-audit` (process maturity), `umami-init` (first-time setup), and `umami-auto-review` (code review). Reviewing mode (§14): produces structured findings; users decide what to act on.

The gap registry tracks items everyone *knows* are open. This audit catches items that *quietly fell off attention* — designs proposed but never decided, explorations that surfaced findings the team never captured, POCs nobody can explain, "decide later" deferrals that nobody returns to, ADRs stuck in "Proposed" state.

## When to invoke

- Quarterly is a reasonable default
- After major-version releases (catches what was deferred during the push)
- When the team feels "what happened to..." about an old proposal
- When `docs/designs/`, `docs/research/`, or `poc/` directories feel cluttered

## When NOT to invoke

- For active work-in-progress (those items belong in the gap registry or phase backlog)
- For code review — use `/umami-auto-review`
- For process-maturity audits — use `/umami-audit`
- More frequently than quarterly without specific cause (audit fatigue produces low-quality dispositions)

## Hard rules

- **Read-only.** Never delete, archive, or restructure files during the audit. The output is a findings report with proposed dispositions; the user decides.
- **Always fetch the landing document fresh** from the canonical URL `https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md` (use `refs/heads/develop` only for bleeding-edge, not-yet-released practices). Never cache locally.
- **Consult the Section Navigation Map** in the landing to identify §8's home (`core/umami-process.md`). Fetch that companion for the full audit protocol (scan-location categories, disposition options, post-ship shipped-features extension). Drift-audit scope always requires the process companion.
- **If any fetch fails, tell the user and stop.** Do not fall back to a stale local copy.
- **Each item gets a proposed disposition.** Findings without dispositions are theater. Disposition options: Revive / Archive / Delete / Re-decide (pre-ship items); Keep / Deprecate / Remove (post-ship features).
- **Default disposition: archive unless revival is justified (pre-ship); Deprecate-or-Remove unless active use is confirmed (post-ship shipped features).** Items at rest stay at rest; the audit's job is to force motion. Shipped features carry operational cost while they exist, so the default tilts away from "keep."
- **Cite file paths and last-touched dates** for every finding. "Some old designs exist" is opinion; "`docs/designs/agent-chat-v2.md` last edited 2025-11-04; no implementation activity since" is a finding.
- **Never recommend more than ~15 dispositions per audit run.** Larger lists overwhelm; batch into subsequent runs.
- **Audit one disposition path at a time when working through dispositions interactively** — per §3c, walk through findings rather than batching.

## Procedure

1. **Determine scan scope** based on the project's documented forward-design, research, and POC locations (per §0 discovery + project's CLAUDE.md). Typical locations: `docs/designs/`, `docs/research/`, `poc/`, decisions log file, ADR directory, phase backlog (if separate), grep for code TODOs referencing unbuilt designs.

2. **For each scanned location**, identify items meeting "dropped" criteria:
   - Not modified in the last 3+ months
   - No implementation activity (no commits referencing it in that window)
   - Not explicitly archived (not in `_archive/` or marked deprecated)
   - Not in the gap registry (those are tracked already)

3. **For each dropped item, gather context**:
   - File path
   - Last-modified date
   - Original purpose (1-line summary from the file's content)
   - Recent activity (commits, related decisions log entries)
   - Why it might still be relevant or might not be

4. **Propose a disposition** per item:
   - **Revive** if the item is still relevant; schedule into next phase, add to gap registry if blocking
   - **Archive** if it was relevant but isn't blocking; move to `_archive/` with a note
   - **Delete** if no longer relevant; git history preserves it
   - **Re-decide** if it's a "decide later" decision that needs to actually be decided now (Yes / No / Pivot)

5. **Present the findings** using the four-option dialog (per §0.7): apply all dispositions / selective walkthrough / do something else / skip. Self-contained prompt per §3b.

6. **Check for skill drift before finalizing.** Compare this skill's embedded shape against freshly-fetched §8 (scan-location categories, disposition options, default-disposition rule). Also check `Last synced:` against today. If structurally drifted OR `Last synced` is >3 months old, append a non-blocking `### Skill drift` callout to the report.

## Output format

```markdown
## Drift Audit — [Project Name]

**Date:** YYYY-MM-DD
**Last audit:** [date if known]
**Scope:** Locations scanned: [list]
**Items found:** [count]

### Findings — proposed dispositions

Each disposition cites **Impact** and **Effort** per the §0.7 audit-recommendation format. Flag **Quick win** when Impact is concrete (gap-registry entry closed, operational cost retired, decision unblocked) and Effort is Hours.

**Revive (N items)**
- [file:path] — last touched [date]. [1-line purpose]. Proposed: revive because [reason]. Action: [schedule into phase X / add to gap registry].
  - **Impact:** [specific value of reviving — e.g., "unblocks Phase 12 feature work"]
  - **Effort:** [Agent-autonomous / Operator-required / Specialist · Hours/Days/Weeks/Months · One-time]

**Archive (N items)**
- [file:path] — last touched [date]. [1-line purpose]. Proposed: archive — [reason it's not blocking but worth preserving].
  - **Impact:** [reduces mental load; preserves historical context]
  - **Effort:** Agent-autonomous · Hours · One-time **Quick win**

**Delete (N items)**
- [file:path] — last touched [date]. [1-line purpose]. Proposed: delete — [reason it's truly dead].
  - **Impact:** [retires operational cost — e.g., "removes feature flag with N monitoring rules"]
  - **Effort:** [Agent-with-review / Operator-required · Hours/Days · One-time]

**Re-decide (N items)**
- [decision entry / ADR] — deferred [date]. [1-line summary]. Proposed: decide now — options [A / B / Pivot].
  - **Impact:** [unblocks downstream work; resolves a deferred-decisions gap]
  - **Effort:** [Operator-required (the decision itself) · Hours · One-time; implementation of the chosen option is separate]

**Post-ship features — Keep / Deprecate / Remove (N items)**
- [feature name] — README/marketing claim. Production-exercise: [last seen / never]. Proposed: [Keep / Deprecate / Remove].
  - **Impact:** [for Remove: "retires N support tickets per month, M monitoring rules, K lines of dead code"; for Deprecate: "begins migration window for users on legacy path"]
  - **Effort:** [Operator-required · Days/Weeks · One-time + recurring during deprecation window]

### Skill drift (only if detected)
- [one-line drift callout]

### After the audit
Read-only. Four-option dialog: apply all / selective walkthrough / do something else / skip.
```

## After the audit — describe changes, then present the four-option dialog

Each disposition describes the specific change (move file to `_archive/`, delete from `poc/`, schedule into phase N, add gap-registry entry, decide the deferred question). Then surface the dialog per §0.7. Default to selective walkthrough for first-time runs; large lists benefit from per-item decisions rather than blanket approvals.
