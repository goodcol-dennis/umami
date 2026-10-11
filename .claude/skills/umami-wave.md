---
name: umami-wave
description: Start an unattended wave session per recipes/wave-session.md — checks the adopt-when evidence, scaffolds the session files, runs the gap-closing pass, writes briefs, launches the first wave, arms the watchdog. Opt-in; refuses to start without evidence. Not the default way to build.
---

# umami-wave — Start a wave session

**Last synced:** 2026-10-11 from `recipes/wave-session.md` (first version). Re-derive this skill from the current recipe when this date is >3 months old or when the recipe's *Harness scope* table or gap-closing pass changes shape.

## What this skill does

One command from "I have a pile of buildable, independent work" to "first wave launched, watchdog armed, the human knows what they owe and when." It performs the recipe's *Before the first wave* checklist end to end, asking the human only through batched decision prompts, and stops at the first wave launch — between-wave work, the watchdog passes and the close are the running session's job, per the recipe.

**Not the default way to build.** This is the opt-in exception for a session the human has decided to run unattended. For an ordinary change, a bug fix or a design conversation, do not invoke it.

## When to invoke

- The human says "run these as waves", "start a wave session", "run this pile overnight", or names a backlog they want built unattended.
- A §0.7 audit surfaced board / baton / watchdog-like files as a latent practice and the human chose to codify them.

## When NOT to invoke

- A single change or exploratory work — plain §14 delegation.
- No evidence for the recipe's adopt-when (step 1 below). The skill refuses, it does not scaffold.
- The human is mid-design — finish the design pass first; waves need settled scope.

## Procedure

1. **Fetch the recipe fresh** from the canonical URL (`https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/recipes/wave-session.md`; `refs/heads/develop` until the recipe ships in a tagged release; honor a pinned tag if the project's URL block has one). If the fetch fails, say so and stop.

2. **Gate check — adopt-when evidence, cited to a file.** Read the roadmap / issue tracker / gap registry / `HANDOFF*.md` batons for either trigger: **(a)** a backlog of independent, buildable units larger than one interactive session clears; **(b)** a prior fan-out that stranded work across an interruption or collided on branches or files. Present **one** batched decision prompt: the evidence found (paths quoted), the recipe's cost profile, and the choice *Start a wave session (Recommended when evidence is strong) / Not now*. No evidence → report that in one line and stop. "The project uses agents" is not evidence.

3. **Scaffold the session files** in the harness's scratch area (`<scratch>/wave/`), from the recipe's *The recipe — what to type* section: `slots.tsv` with its header, `prompts/`, `release/`, `watchdog.md` skeleton (header quoting the human's words from step 2, dated), `waves.md` header. **Derive `agent-preamble.md` from the project's own instruction file** — branch workflow, integration and release branches, required CI statuses, local-gate commands discovered from the build config, test-resource commands, trailers, the dev environment name — and show it to the human for a one-shot confirm, because every worker reads it first. Optionally install `wave_status.sh` from the recipe.

4. **Build the candidate list** from the roadmap, a channel sweep (issues, alerts, CI, batons) and the gap registry. Verify each item against today's integration branch (read governing records in full). For each item name its gaps: scope unsettled, ruling needed, dependency unknown, risk level unclear, measurement to take first.

5. **Run the gap-closing pass.** Batched decision prompts, up to four sibling questions each, recommended option first and marked, every option priced in agents and tokens, multi-select where the human picks a group; say what was left out and why; label production writes a customer will see. Loop until every item is **closed** (ruling recorded) or **parked** (reason + what reopens it). **Hold classifier-sensitive acts to one final batch** — production reads or writes, access grants, infrastructure applies: ask the human to switch to manual permission mode, run or approve each with a probe ready, switch back; record them in `watchdog.md` as done. Never launch with an open item.

6. **Write the briefs** from the recipe's template — the human's words quoted with date and how they ruled; the session's own measurements, timestamped; the *Resuming* section with the exact branch name; files other units own; and the **gate**, decided from the §3d risk level (merge on green for Trivial/Low — Medium only when the human has ruled so; stop at green for High/Critical and for any changed test assertion). Reserve any sequential ids the units will allocate.

7. **Ask wave size** in one prompt — default one or two workers; five or more only on the human's explicit pick, priced. Record the ruling in `waves.md`.

8. **Launch and arm, in the same minute.** Launch each worker in the background with the fixed first-launch prompt (*"Read `<scratch>/wave/prompts/<slot>.md` and do exactly what it says. It points you to the shared ground rules file; read that too, in full, before anything else."*), record each id on the board, then arm the scheduled wake-up (every 20 minutes, off the hour) with the fixed watchdog prompt that **points at** `watchdog.md`, and add one section per launched unit to `watchdog.md`. Check shared temporary storage by inode count first. If the harness has no idle-fired session timer, say so and offer the external-scheduler substitute as the human's decision.

9. **Record the adoption.** One §0.9 ledger row (`docs/umami-adoption.md` or the project's equivalent) with the step-2 evidence, the cost profile and the recipe's kill criterion; one citation line in the instruction file ("unattended sessions run per `recipes/wave-session.md`").

10. **Hand off in one message:** what launched (slot · branch · gate), the wake-up id, the board command, the rulings recorded, what the human owes and when (the morning summary; held reads before promotion), and the sentence *"Between waves, watchdog passes and the close follow the recipe's checklist; I will not ask again until the summary unless a unit blocks."*

## Hard rules (non-negotiable)

- **No evidence, no session.** Step 2 cites a file or stops. Never scaffold on "uses agents".
- **The gate is written into every brief before launch.** No worker decides whether it merges.
- **Default wave size is one or two.** Five or more only on the human's explicit, priced choice.
- **The wake-up prompt points at `watchdog.md`.** Never inline the procedure in the prompt.
- **Classifier-sensitive acts go in the final manual-mode batch,** never inline, and are never retried or rerouted if refused — report with the exact words the human can say.
- **Nothing reaches production, the customer or infrastructure** from this skill or from the watchdog it arms, except a named exception written into `watchdog.md` with condition, command, checks and failure rule.
- **Workers never touch the main checkout.** Private worktrees from a freshly fetched integration branch; private scratch; private test resources by exact name.
- **Fetch the recipe fresh; stop on fetch failure.** Never work from memory of the recipe.
- **Arm the watchdog unasked, in the same minute as the first launch.** After any process restart, list scheduled jobs and re-arm.
- **Stop at the first wave.** This skill does not run the session; the recipe's checklists do. Do not keep polling or launching after the hand-off.

## Output format (hand-off)

```markdown
## Wave session started — <project> — <date, UTC>

**Evidence:** <trigger (a)/(b)> — <path(s)>
**Rulings recorded:** <n> closed · <n> parked (see `<scratch>/wave/waves.md`)
**Held to manual mode and done:** <list or none>

| Slot | Branch | Gate | Worker id |
|---|---|---|---|
| … | … | merge on green / stop at green / measure only | … |

**Watchdog:** wake-up `<id>` (<schedule>), procedure at `<scratch>/wave/watchdog.md`
**Board:** `watch -n15 <command>`
**You owe:** <reads before promotion · the morning decisions · any parked item's reopen condition>
**Ledger:** row added to `<path>`; citation added to `<instruction file>`
```
