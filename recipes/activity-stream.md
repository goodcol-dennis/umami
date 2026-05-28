# Recipe: Consolidated Activity Stream

**Status:** Drafted (working pattern; reliable hook-based capture refined from a memory-based approach that fell apart in real use)

## What it does

Maintains a single, consolidated activity log for the project — one timestamped line per event, regardless of source. The AI coding harness (via a turn-end hook), git (via `post-commit`), and manual logging (via a harness command/skill) all feed into the same file. At month-end you have a complete reconstructable record of *what happened, when, in what workstream* — billable or not.

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
- Your work is mostly outside both the AI harness AND git — the auto-capture sources give little signal; you'd be writing every entry manually, at which point a notes file is simpler
- You're an employee, not a consultant — HR's time-tracking system is the source of truth

## Harness scope

This recipe ships a **working Claude Code reference implementation** of a more general pattern. The pattern (see *The pattern (harness-neutral)* below) applies to any AI coding harness with two primitives:

1. A *turn-end* hook (per §14 lifecycle hooks; called `Stop` in Claude Code, varies elsewhere)
2. A way to define custom commands or skills the user can invoke (slash commands, custom commands, MCP tools, rules — varies by harness)

The bash snippets in Steps 3, 5, and 6 below assume Claude Code's hook input schema and `.claude/` directory layout. The other steps (front matter, gitignore, `post-commit` git hook, month-end reconstruction) are universal — git is git regardless of which AI harness you use, and the log file format is plain markdown.

**If you're on a different harness** (Cursor, Aider, Codex CLI, Goose, etc.), read *The pattern* below for the universal shape, then jump to *Adapting for other harnesses* near the end of this recipe for pointers on substituting your harness's equivalent primitives. None of the alternative harness implementations are field-tested in this repo yet; the gap-registry tracks this as ["`recipes/activity-stream.md` not yet validated across projects"](../audits/gaps.md).

## Prerequisites

- AI coding harness with a *turn-end* hook category (§14) and a custom-command / skill / rule mechanism. Examples: Claude Code (`Stop` hook + `.claude/skills/`); Aider (post-turn hook in `.aider.conf.yml` + `/commands`); Cursor (rules + commands — consult current docs); Goose (MCP-layer extension hooks). See §14's per-harness mapping table for the canonical event names
- Git repository — `post-commit` hook is one of the primary capture sources (universal, no harness dependency)
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

**Capture stays dumb and deterministic** — no LLM in the hot path; hooks fire unconditionally and append raw entries. **Refinement is smart and batched** — a periodic cleanup skill/command runs LLM judgement over a range of entries to fix workstream tags, merge related lines, and remove noise. Reconciliation is the human's job — LLM hour-estimates are unreliable; raw signal + human judgement is better than confident-wrong estimates.

## The pattern (harness-neutral)

The recipe below is one implementation of a four-part pattern that any AI coding harness with turn-end hooks and custom-command primitives can support:

1. **A single canonical log file.** Plain markdown, one event per line, timestamped. Format: `- HH:MM  [source]  Workstream | description`. Date headers (`## YYYY-MM-DD`) group entries by day. YAML front matter at the top carries billing metadata.
2. **Multiple capture sources** feeding the same file with the same format:
   - `[claude]` (or `[ai]`, `[agent]`, `[cursor]` — whatever names the AI source): emitted by the harness's *turn-end* hook (§14)
   - `[git]`: emitted by git's `post-commit` hook (universal, no harness dependency)
   - `[manual]`: emitted when the user invokes a small log-this-thing command from the harness (slash command, custom command, MCP tool — depending on what the harness exposes)
3. **Deterministic capture, batched refinement.** Hooks are dumb and unconditional; cleanup is smart and periodic. The capture hook never calls an LLM (no latency cost, no failure mode); a separate command runs LLM judgement in batch to fix workstream tags and remove noise.
4. **Human-driven reconciliation** at month-end. Open the log, look at timestamps and entries to gauge approximate durations per workstream, fill in the timesheet template the client expects. No LLM hour estimates — they're unreliable, and the cost-of-being-confidently-wrong on a billable hour exceeds the savings.

The Claude Code reference implementation in *The recipe* below wires these four parts together. The *Adapting for other harnesses* subsection further down maps the harness-specific bits (Steps 3, 5, 6) onto Cursor, Aider, Codex CLI, and Goose equivalents.

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

### Step 3: Wire the turn-end hook for AI-harness turns

> **Harness scope:** Steps 3, 5, and 6 are the Claude Code reference implementation. See *Adapting for other harnesses* below for equivalents in Cursor / Aider / Codex CLI / Goose. The hook semantics are identical (a turn-end hook appends a `[claude]` entry to the log); only the configuration mechanism varies.

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

> **Harness scope:** Claude Code skill format. For Cursor, Aider, Codex CLI, or Goose, port the procedure text below into your harness's custom-command / rule / MCP-tool format — the operations (append a line to the log) are identical. See *Adapting for other harnesses* below.

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

> **Harness scope:** Claude Code skill format, same adaptation note as Step 5.

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

## Adapting for other harnesses

Steps 3, 5, and 6 of *The recipe* use Claude Code identifiers. The pattern is harness-neutral — every mainstream AI coding harness exposes equivalent primitives, just under different names and in different config locations. The table below is a starting point; **none of the non-Claude-Code rows have been field-tested in this repo** — they're pointers for adopters on those harnesses to fill in and refine.

| Capture | Claude Code (field-tested) | Cursor | Aider | Codex CLI | Goose |
|---|---|---|---|---|---|
| **Turn-end hook** (Step 3) | `Stop` hook in `.claude/settings.json` calling `.claude/hooks/activity-log-claude.sh` | Check current Cursor docs for the turn-end equivalent (rules + hooks system); place the bash logic in the harness's hook-script location | Post-turn shell hook in `.aider.conf.yml` (`post_response: bash logs/activity-log-aider.sh`) | Consult Codex CLI documentation for the turn-end event; bash logic ports as-is | Define an extension that fires on `on_complete` and runs the append-to-log command |
| **Source tag in entries** | `[claude]` | `[cursor]` | `[aider]` | `[codex]` | `[goose]` |
| **Manual log command** (Step 5) | `.claude/skills/log.md` — invoked as `/log <description>` | Cursor command / rule in `.cursorrules` or `.cursor/rules/` | `/log` defined in `.aider.conf.yml` or as an alias | Codex CLI custom command | Custom MCP tool exposed by an extension |
| **Refine-log command** (Step 6) | `.claude/skills/refine-log.md` — invoked as `/refine-log` | Same as Manual log, different command body | Same — Aider command | Same — Codex custom command | Same — MCP tool |
| **AI-instruction file** (the project's primary AI doc) | `CLAUDE.md` | `.cursorrules` or `.cursor/rules/` | `CONVENTIONS.md` / aider.conf-referenced | (varies) | `AGENTS.md` or harness-specific |

**Adaptation procedure:**

1. **Port the bash hook script first** (Step 3). The script's core operations — read prompt text from stdin JSON, write a timestamped line to `logs/activity.md` — don't change. What changes is how the JSON arrives (which field carries the user prompt; how `default_workstream` is read; what env vars are set). Read your harness's hook-input spec and adjust the `jq` query and any env-var references.
2. **Translate the skill procedure text** (Steps 5–6) into your harness's command format. The procedures are short and prose-driven (read file → infer workstream → append entry). Most harness command formats can express them directly.
3. **Keep the source tag stable across harnesses if you ever switch**. If you migrate from `[claude]` to `[cursor]` mid-project, prior log entries stay `[claude]` — that's correct, the entries record what produced them at the time. Switch the tag in the hook script going forward; don't rewrite history.
4. **Test the turn-end hook deliberately** before relying on it. Start a session, end it, verify a new entry shows up in `logs/activity.md`. The pattern's whole reliability claim rests on the hook firing every turn; verify that before you bill against it.

If you adapt the recipe for a harness not yet listed, contributions back are welcome — see the gap-registry entry on this recipe for the validation criteria.

## Cross-references

- **§14 Lifecycle Hooks** — this recipe is a worked example of the `Stop` hook pattern; the recipe's reliability advantage over the memory-based predecessor is exactly the §0.6 "From now on when X without a hook" anti-pattern resolved
- **§9.1 Status block** — the activity stream is one of the input sources the status block summarizes ("what's been happening on develop")
- **§12 Lightweight Change Tracking** — pairs naturally; the active-change-block records the *intent*, the activity stream records the *steps taken*
- **§4 Agent Log Discipline** — agent token-cost logs aren't in the activity stream by default (they're a separate concern); but the §4 5-layer logs and this recipe coexist cleanly
- **§9.7 Cost Caps and Budget Gates** — agent cost rolled up per project becomes an "AI-cost line item" the human can add to the timesheet during month-end reconstruction

## Status updates

- **2026-05-27 (Drafted):** Replaces the prior Planned `consulting-timesheet.md` placeholder. Reframed from "session log for billing" to "consolidated activity stream with billing as primary use case" after the memory-based predecessor (single Claude-only source, no hook) proved unreliable in real consulting cycles. Adopters: wire up Steps 1–5 minimum; Steps 6 and 7 add the cleanup + reconstruction workflow.

## Known limitations (validate across projects)

- **LLM workstream inference can mis-tag.** The `/refine-log` cleanup is the corrective; if it mis-tags consistently, refine its prompt body or pre-declare more workstreams in front matter so the LLM has a constrained set to choose from.
- **Manual entries depend on user discipline.** The `[manual]` capture path is inherently aspirational — there's no hook for "the user just had a phone call." Mitigate by `/log`ging at low friction (one short invocation) immediately after the event, while it's fresh.
- **Harness portability is partially aspirational.** Steps 3, 5, 6 ship working Claude Code wiring; the *Adapting for other harnesses* table maps the equivalents for Cursor, Aider, Codex CLI, Goose but those rows are pointers, not field-tested implementations.
- **Not yet validated across projects** — see [`audits/gaps.md`](../audits/gaps.md) for the matching entry. Refinements (including non-Claude-Code adaptations) land in subsequent drafts.
