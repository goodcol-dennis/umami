# Recipe: Consulting Timesheet

**Status:** Planned (placeholder — pattern named, full implementation deferred)

## What it does

Inject enough structured tracking into a consulting project that an LLM can generate a billable timesheet at month-end from the project's own artifacts (commits, agent logs, work-session markers) — without the consultant manually tracking hours during the work.

The premise: if you're already producing structured artifacts during work (commit messages, agent session logs, §12 change-tracking entries, §9.1 status block updates), you have most of the data needed for a timesheet. The recipe captures the rest at low marginal cost and gives you a deterministic script to produce the invoice-ready output.

## When it earns its cost

- You're consulting and bill by the hour (or by deliverable tied to time)
- Manually tracking hours is friction you keep losing to
- The cost of forgetting / under-billing exceeds the cost of setting up tracking
- Your work is already structured enough that artifacts capture most of the time (you commit regularly, you note status, you log sessions)
- Clients accept timesheets generated from project artifacts (most do, with the right framing)

## When it doesn't earn its cost

- You bill flat-fee per project; hourly granularity doesn't matter
- Your work is ad-hoc and not artifact-heavy (you do most thinking in person, in meetings, on whiteboards)
- The client requires their own time-tracking tool (Harvest, Toggl, etc.) — use that; this recipe is for project-derived timesheets, not parallel tracking systems
- You're an employee, not a consultant — your employer's HR system is the source of truth

## Prerequisites

This recipe is **Planned** — the full implementation is not yet drafted. The shape will likely include:

- A commit-message convention that includes a client / project / activity tag
- A lightweight session-start / session-end marker (file write, log entry, hook firing)
- A reconciliation script that aggregates artifacts into a timesheet
- A timesheet template (markdown or CSV) the script populates

The recipe will pair with:
- §12 (Lightweight Change Tracking) — the active-change-block pattern provides one of the source signals
- §9.7 (Cost Caps and Budget Gates) — agent-cost rollup feeds the "agent-assisted hours" portion of the timesheet
- §14 Lifecycle Hooks — `SessionStart` and `Stop` hooks can write structured time markers automatically

## The recipe

*To be drafted. The following is the placeholder shape:*

```
# Sketch of what the populated recipe will contain:

1. Commit message format:
   {type}({scope}): {summary}
   --
   Client: {client}
   Project: {project-id}
   Activity: {advisory|implementation|review|meeting|writing}
   Hours: {N}h  (or "auto" if a session marker is being used)

2. Session markers (file or hook-driven):
   docs/sessions/YYYY-MM-DD.md
   - Start: HH:MM
   - End: HH:MM
   - Goal: ...
   - Outcome: ...

3. Reconciliation script:
   bin/timesheet --month YYYY-MM
     - Walks commits matching the format
     - Walks docs/sessions/ markers
     - Walks agent logs (per §4 agent log discipline)
     - Produces docs/timesheets/YYYY-MM.md
```

The actual implementation drafts when the contributor has run it against a real consulting cycle and refined what works.

## Cross-references

- §12 Lightweight Change Tracking — active change blocks and session handoffs are natural data sources for time markers
- §14 Lifecycle Hooks — `SessionStart` / `Stop` hooks emit structured time markers automatically
- §4 Agent Log Discipline — tool-call logs feed the agent-assisted portion of the timesheet
- §9.7 Cost Caps and Budget Gates — agent token cost feeds billable AI-cost line items
- §22 Compliance — if billing under a regulated framework, audit-trail requirements may shape the recipe

## Status updates

- 2026-05-13: Placeholder created as part of v3.0 `recipes/` setup. Full implementation deferred until contributor has run it on a real consulting cycle.
