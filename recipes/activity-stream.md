# Recipe: Consolidated Activity Stream

**Status:** Drafted (working pattern; reliable hook-based capture refined from a memory-based approach that fell apart in real use)

## What it does

Maintains a single, consolidated activity log for the project — one timestamped line per event, regardless of source. The Claude harness, git, calendar, and manual logging all feed into the same file. At month-end you have a complete reconstructable record of *what happened, when, in what workstream* — billable or not.

The stream is the primitive. The named use case is **timesheet reconstruction for consulting work** — read the log, look at timestamps to gauge duration, fill in the timesheet. Other consumers come for free:

- **Daily standups** — "what did I do yesterday" is one `grep` away
- **§9.1 status block** updates — the "what changed since last session" portion writes itself
- **§8 retros** — historical context for "when did this surface?"
- **§12 change tracking** — supplements the active-change-block pattern with cross-tool signal

## When it earns its cost

- You bill hourly (or by deliverable tied to time) and reconstructing the month from memory + git + Slack is friction you keep losing to
- Memory-based "Claude, remember to log every turn" has fallen apart in real use (it does — see §0.6 "From now on when X without a hook" anti-pattern)
- You want capture friction near zero so the discipline actually holds week over week
- You have meetings / calls / in-person work that git alone misses, and code work that Slack alone misses, and need both in one place

## When it doesn't earn its cost

- You bill flat-fee per project — hour granularity doesn't matter
- The client requires their own time-tracking tool (Harvest, Toggl, etc.) — use that
- Your work is mostly outside Claude AND outside git — the auto-capture sources give little signal; you'd be writing every entry manually, at which point a notes file is simpler
- You're an employee, not a consultant — HR's time-tracking system is the source of truth

## Prerequisites

- Claude Code (or compatible harness) supporting **PreToolUse / Stop hooks** — capture mechanism depends on it
- Git repository — `post-commit` hook is one of the primary capture sources
- Project committed to a single log location (`logs/activity.md` recommended) — adopters with multi-project setups maintain one log per project

## Architecture

```
                       ┌─────────────────────┐
   every Claude turn → │                     │
                       │                     │
   every git commit  → │  logs/activity.md   │ → month-end:
                       │                     │   human reads log
   /log <description>→ │                     │   + git log
                       │                     │   + calendar
   future MCP sources→ │                     │   → fills timesheet
                       └─────────────────────┘
                              ↑
                         /refine-log
                         (periodic LLM cleanup)
```

**Capture stays dumb and deterministic** — no LLM in the hot path; hooks fire unconditionally and append raw entries. **Refinement is smart and batched** — a `/refine-log` skill runs LLM judgement over a range of entries to fix workstream tags, merge related lines, and remove noise. Reconciliation is the human's job — LLM hour-estimates are unreliable; raw signal + human judgement is better than confident-wrong estimates.

## The recipe

### Step 1: Create the log file with front matter

```bash
mkdir -p logs
cat > logs/activity.md << 'EOF'
---
client: <ClientName>
project: <project-id>
billing_rate_usd: 0
billing_unit: hour
default_workstream: General
---

# Activity Stream

<!-- One line per event. Sources: [claude] [git] [manual]. Format: HH:MM  [source]  Workstream | description -->
EOF
```

Front matter is metadata the month-end reconstruction uses; it's not parsed by the capture hooks. Override `default_workstream` to whatever fits the project (e.g., `Backend`, `Advisory`).

### Step 2: Gitignore the log if it shouldn't ship to the client

```bash
echo "logs/activity.md" >> .gitignore
```

Most consulting projects don't share the activity log with the client. If you're using a wrapper project (umbrella repo across multiple client projects), the log lives in the wrapper and `.gitignore` isn't needed.

### Step 3: Wire the Stop hook for Claude turns

Add to `.claude/settings.json` (or `settings.local.json` for per-developer config):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/activity-log-claude.sh"
          }
        ]
      }
    ]
  }
}
```

Then create `.claude/hooks/activity-log-claude.sh`:

```bash
#!/usr/bin/env bash
# Appends a [claude] entry to logs/activity.md after every Claude turn.
# Reads conversation context from stdin (hook input JSON) per Claude Code hook spec.
set -euo pipefail

LOG="logs/activity.md"
[ -f "$LOG" ] || exit 0  # log not initialized for this project — skip silently

TS=$(date +'%H:%M')
DAY_HEADER="## $(date +'%Y-%m-%d')"

# Ensure today's date header exists (idempotent)
if ! grep -qxF "$DAY_HEADER" "$LOG"; then
  printf '\n%s\n\n' "$DAY_HEADER" >> "$LOG"
fi

# Read last user prompt from hook stdin JSON; fall back to a placeholder.
INPUT=$(cat || true)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.messages[-1].content // empty' 2>/dev/null | head -c 120 | tr '\n' ' ')
[ -z "$PROMPT" ] && PROMPT="(no prompt captured)"

# Read default workstream from front matter (fallback: General)
WORKSTREAM=$(awk '/^default_workstream:/ {print $2; exit}' "$LOG" 2>/dev/null || echo "General")
[ -z "$WORKSTREAM" ] && WORKSTREAM="General"

printf -- '- %s  [claude]    %-12s | %s\n' "$TS" "$WORKSTREAM" "$PROMPT" >> "$LOG"
```

The hook is deliberately dumb: timestamp, fixed source tag, default workstream from front matter, truncated raw prompt. Workstream classification is the periodic `/refine-log` skill's job (Step 5).

### Step 4: Wire the git post-commit hook

Create `.git/hooks/post-commit` (or install via `husky` / equivalent if the team uses managed git hooks):

```bash
#!/usr/bin/env bash
# Appends a [git] entry to logs/activity.md after every commit.
set -euo pipefail

LOG="logs/activity.md"
[ -f "$LOG" ] || exit 0

TS=$(date +'%H:%M')
DAY_HEADER="## $(date +'%Y-%m-%d')"
if ! grep -qxF "$DAY_HEADER" "$LOG"; then
  printf '\n%s\n\n' "$DAY_HEADER" >> "$LOG"
fi

HASH=$(git log -1 --pretty=%h)
SUBJECT=$(git log -1 --pretty=%s | head -c 120)
WORKSTREAM=$(awk '/^default_workstream:/ {print $2; exit}' "$LOG" 2>/dev/null || echo "General")

printf -- '- %s  [git]       %-12s | commit %s: "%s"\n' "$TS" "$WORKSTREAM" "$HASH" "$SUBJECT" >> "$LOG"
```

Mark it executable: `chmod +x .git/hooks/post-commit`.

### Step 5: The `/log` skill for manual entries

Create `.claude/skills/log.md`:

```markdown
---
name: log
description: Append a manual entry to logs/activity.md for activity outside Claude or git — meetings, calls, in-person work, anything not auto-captured.
---

# /log — Append manual activity entry

**Usage:** `/log <description>` or `/log <workstream> | <description>`

Examples:
- `/log Sync call with client re demo feedback`
- `/log Meeting | Sync call with client re demo feedback`
- `/log Travel | Drove to client site, ~45min each way`

## Procedure

1. Open `logs/activity.md`. If it doesn't exist, tell the user the recipe isn't installed and stop.
2. Get current timestamp `HH:MM`.
3. Ensure today's date header (`## YYYY-MM-DD`) exists; create if missing.
4. Parse the input:
   - If the input contains a ` | ` separator, the part before is the workstream, the part after is the description.
   - Otherwise, infer the workstream from the description's content (Meeting, Travel, Admin, Communication, Research, Planning, etc.) — or fall back to the front matter's `default_workstream`.
5. Append: `- HH:MM  [manual]    Workstream | Description`
6. Confirm with one line: `✓ Logged: HH:MM [manual] Workstream | Description`.

## Hard rules

- Read-only against everything else in the project — only `logs/activity.md` is touched.
- Never modify or delete prior entries.
- One entry per invocation. Multiple events get multiple `/log` calls.
```

### Step 6: The `/refine-log` skill for periodic cleanup

Create `.claude/skills/refine-log.md`:

```markdown
---
name: refine-log
description: Periodic LLM cleanup pass over logs/activity.md — fixes workstream tags, merges related entries within a day, removes noise turns.
---

# /refine-log — Periodic LLM cleanup of the activity stream

**Usage:** `/refine-log` (defaults to today + yesterday) or `/refine-log <YYYY-MM-DD>` for a specific day, or `/refine-log <YYYY-MM-DD>..<YYYY-MM-DD>` for a range.

## Procedure

1. Read `logs/activity.md`.
2. For each entry in the target range:
   - **Refine the workstream tag** based on the entry's description (e.g., a `[claude]` entry that says "Implemented user auth middleware" should be tagged `Backend`, not the default `General`).
   - **Drop noise turns** — entries whose description is `(no prompt captured)`, a clarifying question, a single-word prompt, or otherwise carries no billable activity signal.
3. Optionally **merge runs** of entries within the same hour that share a workstream and contiguous activity, into a single summary entry. Keep the earliest timestamp; collapse descriptions into one line. Only merge when the merge is faithful — preserve distinct activities.
4. Show the user a diff of the proposed changes and ask for confirmation before writing (four-option dialog per §0.7: apply all / selective / other / skip).

## Hard rules

- **Never modify entries outside the target range.** A range explicitly given by the user, or default = today + yesterday, is the only scope.
- **Show diff before writing.** The activity log is billing-source-of-truth; silent edits are not allowed.
- **Preserve timestamps.** Refinement changes the workstream tag and description text only; timestamps and the `[source]` tag are immutable.
- **If unsure, don't merge.** Two consecutive `[claude]` entries about different things stay as two entries.
```

### Step 7: Month-end timesheet reconstruction (human workflow)

No script. The reconstruction is a human pass — LLM hour estimates are unreliable, raw signal + judgement is better:

1. Open `logs/activity.md`. Scan the date range you're billing.
2. For each day, look at timestamps to gauge how long each block of activity ran (e.g., `09:14 [claude] Backend ... 10:30 [claude] Frontend ...` ≈ 1h 16m of Backend work).
3. Group by workstream within each day, sum the approximate durations, round to your billing increment (e.g., 0.25h or 0.5h).
4. Cross-check with sources the activity stream doesn't capture:
   - Git log for any commits outside Claude sessions
   - Calendar / Slack / Teams for meetings (or use `/log` retroactively to fill these in)
5. Fill in the timesheet template the client expects.

The coverage matrix from the source-thinking behind this recipe:

| Source | Captures | Misses |
|---|---|---|
| `[claude]` entries | Claude-assisted work: coding, research, planning, proposals, debugging | Work done outside Claude |
| `[git]` entries | Code commits with timestamps | Research, planning, debugging, meetings |
| `[manual]` entries | Everything the user remembers to `/log` | Anything they didn't `/log` |
| Front matter | Client / project / rate metadata | — |

Combined, with the human filling in `[manual]` entries when memory is fresh, the stream is enough to reconstruct a billable month.

## Output format example

```
---
client: AcmeCorp
project: acme-portal
billing_rate_usd: 175
billing_unit: hour
default_workstream: Backend
---

# Activity Stream

## 2026-05-27

- 09:14  [claude]    Backend      | Implemented user auth middleware
- 09:47  [git]       Backend      | commit a3f2: "auth: refresh token rotation"
- 10:30  [claude]    Frontend     | Built settings page form validation
- 11:00  [manual]    Meeting      | Sync call with client re demo feedback
- 13:45  [claude]    Planning     | Wrote architecture proposal section
- 16:20  [git]       Backend      | commit 8b7c: "auth: tests for refresh token rotation"
```

## Future capture sources

The format reserves the `[source]` slot for additional capture mechanisms as MCP and harness integrations mature:

- `[calendar]` — pull meetings from Google Calendar / Outlook via MCP at start-of-day
- `[slack]` — long-form messages the user sent (signals significant communication) via Slack MCP
- `[time]` — focus-timer apps (e.g., Pomodoro app) emitting block-completion events

None of these are in the initial Drafted recipe — adopters wire them in as MCP integrations stabilize. The schema accommodates them without format changes.

## Cross-references

- **§14 Lifecycle Hooks** — this recipe is a worked example of the `Stop` hook pattern; the recipe's reliability advantage over the memory-based predecessor is exactly the §0.6 "From now on when X without a hook" anti-pattern resolved
- **§9.1 Status block** — the activity stream is one of the input sources the status block summarizes ("what's been happening on develop")
- **§12 Lightweight Change Tracking** — pairs naturally; the active-change-block records the *intent*, the activity stream records the *steps taken*
- **§4 Agent Log Discipline** — agent token-cost logs aren't in the activity stream by default (they're a separate concern); but the §4 5-layer logs and this recipe coexist cleanly
- **§9.7 Cost Caps and Budget Gates** — agent cost rolled up per project becomes an "AI-cost line item" the human can add to the timesheet during month-end reconstruction

## Status updates

- **2026-05-27 (Drafted):** Replaces the prior Planned `consulting-timesheet.md` placeholder. Reframed from "session log for billing" to "consolidated activity stream with billing as primary use case" after the memory-based predecessor (single Claude-only source, no hook) proved unreliable in real consulting cycles. Adopters: wire up Steps 1–5 minimum; Steps 6 and 7 add the cleanup + reconstruction workflow.

## Known limitations (validate across projects)

- **Stop hook spec varies by harness.** The bash snippet assumes Claude Code's hook input schema; other harnesses (Cursor, Codex, Goose) expose conversation context differently. Adapt accordingly.
- **LLM workstream inference can mis-tag.** `/refine-log` is the corrective; if it mis-tags consistently, refine the prompt or pre-declare more workstreams in front matter.
- **Manual entries depend on user discipline.** The `[manual]` capture path is inherently aspirational — there's no hook for "the user just had a phone call." Mitigate by `/log`ging at low friction (one short invocation) immediately after the event, while it's fresh.
- **Not yet validated across projects** — see [`audits/gaps.md`](../audits/gaps.md) for the matching entry. Refinements based on adopter feedback land in subsequent drafts.
