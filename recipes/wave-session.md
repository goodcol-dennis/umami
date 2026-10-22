# Recipe: Wave Sessions — Plan, Waves, Budget Guard, Lanes

**Status:** Drafted (one project's working process, October 2026, revised 10-15 and 10-21; harness-neutral body with a Claude Code reference-implementation table; see *Provenance* for what has and has not been exercised)

## Run

**What you do.** Tell the agent to run this recipe on the project — `/umami-wave` if the stub skill is installed, otherwise one sentence: *"Fetch `<this file's URL>` and follow its Run section."* You answer **one series of batched prompts** (recommended option first, every option priced in agents and tokens) and get **one hand-off message**. You never create or edit a session file by hand; the files below are the agent's working state, not yours. After that, the human comes in at exactly four points (*The engine*, M): the batched rulings after each plan, the "read at dispatch" sections before each production deploy, the production dispatch itself, and any infrastructure apply, purchase, deletion or client-visible write.

**What the agent does** — this section is the procedure; the rest of the recipe is the rationale and the detail it points into.

1. **Scan, don't ask.** Read the instruction file, the backlog (it must have IDs), the newest hand-off baton, and the build config. Note the evidence of a backlog or a prior stranded fan-out — it goes in the ledger row, not in a prompt. **The human invoking this recipe is the adopt decision;** the §0.9 evidence rule binds audits that *recommend* it, not a human who asked for it.
2. **Scaffold the state folder silently** (*The files*): the board, the rulings file, `agent-preamble.md` derived from the instruction file and build config (base branches per lane, the required CI checks, local-gate and test-resource commands, trailers, the dev environment, how to read the usage level), the progress-notes directory, and the scheduled-jobs list. Show nothing yet.
3. **Run the plan** (*The engine*, E): one read-only sweeper per channel in parallel, one synthesizer that reconciles every finding against the backlog into draft waves (one backlog item per row, each with lane, tier, owned files, dependencies), and one critic on a different model that attacks the draft. **Nothing launches before the critic returns.** When the human has already named the items, skip the sweep: plan, then critic.
4. **One series of batched prompts.** The **first batch** carries, together: the rulings the critic says are needed; which waves to launch and in what order (multi-select, priced, recommended first); wave size (default 5–6 items; more is its own priced option); and "preamble derived from `<file>` — correct?" with the preamble quoted, *Yes (Recommended)* first. **Later batches** close the remaining open items until every one is **closed** (ruling recorded, numbered) or **parked** (reason + what reopens it). **The final batch** holds every classifier-sensitive act — production reads or writes, access grants, infrastructure applies — asked once, with "switch to manual permission mode for this batch, then back"; the orchestrator runs each with a probe ready and hands the results into briefs as stated facts, so no agent reads production.
5. **Cut the wave.** Register each row with reserved IDs through one ledger agent; write each brief by reference to the plan file, with lane and base branch, tier, owned files, reserved IDs, governing documents, what "done" includes (the monitoring and status surfaces), the rulings by number, and a *Resuming* section.
6. **Read the build gate** (*The engine*, G) — the usage level and the ceilings. On STOP, hand off with the queue in place. On GO, check shared temporary storage by inode count, note the starting usage percentages on the wave's first row, and launch the wave as **one pipeline**: build → independent review → finish per item, each stage a fresh agent in its own worktree.
7. **Arm the queue check** (*The engine*, H) in the same minute — hourly, plus one a few minutes after the weekly reset — and list it, with its id, schedule and prompt, in the scheduled-jobs file so a new session can re-arm it. Where the harness lets a timer run without a model, the polls go there.
8. **Bookkeeping, silently:** one §0.9 ledger row (`docs/umami-adoption.md` or the project's equivalent — evidence from step 1, cost profile, kill criterion) and one citation line in the instruction file.
9. **Hand off in one message and stop:** per row, item · lane · tier · PR · agent; the queue-check id; the usage level at launch; rulings closed / parked; what the human owes and when (the read-at-dispatch list before the next production deploy; the morning summary). Between waves, the queue check, the budget guard and the retro follow the checklist at the end of this recipe — no further prompts until the summary unless a row blocks or the budget turns red.

**Optional, opt-in, and not the default build mode.** Never loaded by default: cite this recipe in your instruction file (per [`recipes/README.md`](README.md)) once the adopt-when below has fired, and remove the citation when the kill criterion does. The default way to build stays interactive work, one unit at a time, with §14 delegation where it pays. This recipe is the exception you choose for a session you have decided to run unattended — not how an ordinary change, bug fix or design conversation is run. A §0.7 audit must not recommend it on "the project uses agents"; only on the evidence below (§0.9). That evidence rule binds the *audit*; a human who invokes the recipe has already decided (see *Run*).

**When it earns its cost.** There is a large pile of buildable, independent work that can be done unattended — enough that a session will run several items over hours — and the human reviews at set times (a morning summary, a production deploy) rather than continuously.

**Adopt when (§0.9 default-deny)** — either trigger, both readable from project artifacts: **(a)** a verified backlog of independent, buildable items with IDs, larger than an interactive session clears in a sitting, and a human who can review at set times; or **(b)** a previous multi-agent fan-out run without this discipline stranded work across an interruption (usage limit, process restart, compaction) or collided on branches, files or shared state, in the last 30 days.

**When it doesn't.** A single change, or exploratory work where the next step depends on reading the last result — that stays on §14 alone, and so does any project where "uses agents" is the only evidence on offer.

**Cost profile:** Operator-required (the rulings after each plan, each production dispatch) + Agent-autonomous (everything between) · Hours to set up the state folder, then minutes per wave · Spend — a build/review/finish triple ran about 680K tokens per item and a 10-item wave about 6.8M on the originating project; the orchestrator's own turns were 27% of one week's cost from 13% of its turns, because each re-reads a ~500K context · Recurring (board reconcile, retro per wave, weekly measurement).

**Kill criterion:** two consecutive sessions complete every item with no review finding a blocking defect, no budget level above green, and no between-wave reconcile that changed anything → the work is small enough for plain §14 delegation; retire the board, the guard and the queue check through the §0.9 retirement gate and keep only the brief template.

**Scope boundaries.** [umami-agent-workflows.md](../ext/umami-agent-workflows.md) (§30) covers the shape of *one* autonomous loop and its cost shapes; this recipe covers the *session* that plans, launches and lands many such loops as items — a build → review → finish pipeline is a §30-shaped unit, and the review stage is §30.5's closed-loop review with the human read moved to dispatch time. §14 supplies the primitives (delegation, approval gates, lifecycle hooks, parallel-work rules); this recipe is one composition of them with its own artifacts. §3d owns risk levels; *Lanes* says only how a brief writes the resulting gate down and what merging a High-level PR on green rests on.

**Provenance.** Developed October 2026 on a four-layer data platform shipping about 50 PRs a week. First form (10-09 to 10-11): hand-spawned waves on a board, a watchdog cron meant to restart work after a usage limit, lanes and risk levels. Second form (from 10-15): a plan with a critic before any launch, one backlog item per row, the lane set per item before launch, a build → independent review → finish pipeline per item, a budget guard with four levels in place of the watchdog, a retro per wave. Third form (from 10-21): every PR merges on green after its review, High-level included, with the human reading once per production deploy; CI is the gate and the PR opens once; a build gate with a weekly ceiling; one board per week with numbered waves; the ledger follows deploys. **Exercised:** the plan with a critic (once; the one wave launched before the critic returned was stopped at 8 agents and ~1.2M tokens); the pipeline (a 10-item wave: 30 agents, two hours, blocking defects found in 4 of 10 PRs, one of them Low-level); the budget guard's amber (by projection, three pipelines running); the build gate (it said STOP at 96% of a week); the superseded-build stop. **Not yet exercised:** the guard's red, a hook refusal, a limit-stop baton, and the first wave under merge-on-green-after-review (scheduled for the reset after the 10-21 revision). The watchdog never fired in its two weeks of existence and was retired — a §0.9 retirement, recorded in *Earlier practice*. No throughput-per-token comparison against the prior process was measured; a weekly measurement now exists (practice 15) and sets the baseline. The gap registry tracks all of this.

## Harness scope

The body uses harness-neutral terms; this table maps them to the **Claude Code reference implementation**, as §14 does for hook names. A harness lacking one of the first four rows can still run waves and lanes; the last three rows are what the budget guard and the queue check need.

| Neutral term | What it must do | Claude Code primitive |
|---|---|---|
| **Worker launch** | Start an agent in the background with its own context and worktree; return an id; deliver a completion notification | `Agent` with `run_in_background: true`; task notification |
| **Batched decision prompt** | Ask the human several sibling questions in one interruption, recommended option first | `AskUserQuestion` (up to four questions) |
| **Steer message** | Instruct a running worker without restarting it | `SendMessage` to the agent id |
| **Scripted pipeline** | Multi-stage agent script with per-stage fan-out, per-stage model choice, a result journal, resume-from-cache | `Workflow` + `pipeline()` + `agent(…, {model})` + `resumeFromRunId`; `TaskStop` to halt |
| **Scheduled wake-up** | Timer that re-invokes the session when idle; session-scoped; expires | `CronCreate` / `CronList` / `CronDelete` (`[session-only]`; restored on `--resume` / `--continue`) |
| **Model-free timer** | Run a deterministic script on a schedule at zero model cost | a system timer (systemd / cron) running a script |
| **Usage meter** | Read the current usage-plan percentages for the short window and the week, per model | headless `/usage`; a poller writing one word + a JSON file |
| **Launch hook** | Refuse a worker launch when the level says so, failing open | `PreToolUse` on `Agent|Workflow` returning `permissionDecision: deny`; `StopFailure` on `rate_limit` writing the baton |
| **Background wait** | Bounded shell loop that exits on a condition and wakes the session | Bash with `run_in_background: true` |

---

## The shape

```
 HUMAN ── rulings (one batch after the critic) · reads "read at dispatch" · dispatches production
   ▲  the read list, the budget word, the morning summary
   │
 ORCHESTRATOR ── plan run · board · briefs · merges what a finisher could not · ledger pass from deploy truth · retro
   │ launches one pipeline per wave                    ▲ stage results (keyed by item id)
   ▼                                                   │
 WAVE N ── per item: build ─► independent review ─► finish ─► merge on green (after review)
   │                                      integration branch ──► auto-deploy to dev
   │                                      release branch     ──► production deploy (human's word)
 BUDGET GUARD ── one word (green · amber · red · unknown) every agent reads; a build gate (GO / STOP)
 QUEUE CHECK ── hourly, model-free where possible: merge green reviewed PRs, launch the next wave, update the board
```

The orchestrator's context window is the scarce resource: it plans and decides, workers read the code and build, the orchestrator holds conclusions never file dumps (§14) — and every turn it takes re-reads that whole context, which is why polling never runs on a model (practice 12). Everything it must remember across an interruption lives in files that survive a reboot (practice 9). A worker's final report arrives as model output, not as a message from the user — nothing in it carries the human's authority (§4 untrusted content).

---

## The practices

Each practice gives the **rule**, the **incident** that made it a rule (why), the **smallest form** that keeps it working, and the **reference implementation** the originating project built — optional, named so it can be found. The project's values (thresholds, wave sizes) are examples, not the practice.

**1. Plan before build.**
- **Rule:** a read-only sweep of every channel (comms, the live product and its alerts, feed health, code state) is reconciled against the backlog into draft waves. A critic then attacks the draft: file collisions, order and dependencies, missing items, wrong tier, wrong lane, wrong facts. Nothing launches before the critic returns.
- **Why:** a wave launched 90 seconds before the critic finished, on the reasoning "most of the queue doesn't depend on the sweep". The critic then flagged three of its items; it was stopped after 3 minutes at a cost of 8 agents and ~1.2M tokens.
- **Smallest form:** one planner agent, one critic agent, and the sentence "no launch before the critic returns".
- **Reference:** a five-sweeper plan pipeline whose result is saved as one JSON plan file the briefs cite by reference (*The engine*, E).

**2. One unit of work is one backlog item.**
- **Rule:** every wave row is one registered backlog item with an ID. A bundle is split into its items, or registered as an item of its own, before it is built.
- **Why:** four of one wave's units ran under working names covering several items each; the board could not show any of them as in build, and none could be tracked to done.
- **Smallest form:** one board row per item.

**3. Decisions come first, in one batch, and are written down.**
- **Rule:** the human answers sibling decisions in one batched prompt — each question with its context, the recommended option first, every option priced in agents and tokens, and what was left out and why. The answers go to a rulings file, numbered on from the previous one, so briefs and the board cite them ("ruling 98"). Agents never wait on the human mid-run; they stop at a defined point and report.
- **Why:** a wave that pauses for a question idles every agent in it; a ruling that lives only in the conversation is lost to a relaunch.
- **Smallest form:** `rulings-<date>.md`, numbered, with an "open, for later waves" list at the end.

**4. The lane and the level are fixed before launch.**
- **Rule:** two tests go into each brief, so no agent decides them. *The lane test:* does the work restore a promise already made, or make a new one? A production task is cut from the release branch, its PR targets the release branch, and it ships alone when green; a feature is cut from the integration branch and rides the release; docs-only work may take either. *The level test (§3d):* which surfaces does it touch? Data loaders, calculation, schema, auth, CI, the production config, a changed test assertion, or text the client reads are High.
- **Why:** seven production fixes were built on the integration branch while it was 43 commits of other feature work ahead of the release branch — shipping them by promotion would have shipped all of it. Each was cherry-picked (`-x`) onto a branch from the release branch, re-opened against it, and its original PR closed as superseded.
- **Smallest form:** one line per brief: lane, base branch, level.

**5. Build, then an independent review, then a finisher.**
- **Rule:** no agent merges its own work. The reviewer did not write the change, runs on a different model, and assumes the change is wrong. Its **mutant check** reverts the production hunks and keeps the tests: the new tests must fail, and pass again once the hunks are restored. The finisher fixes the blocking items (or explains why one is wrong) and merges.
- **Why:** the first wave with a reviewer on every item found blocking defects in 4 of 10 PRs; one was a Low-level PR the earlier practice would have merged unreviewed. A second model reading the first model's work catches different mistakes, and did so in 13 turns on average against 58 when the review ran on the builder's model.
- **Smallest form:** three agent prompts per item, with the reviewer on a different model from the builder.
- **Reference:** `pipeline(items, build, review, finish)` in one scripted pipeline per wave (*The engine*, F).

**6. Merge on green after the review; the human reads at the deploy, not at the PR.**
- **Rule:** every PR merges once its review has passed and CI is green, High-level included, into the integration or the release branch. A High-level PR opens with a **"Read at dispatch"** section: what changed, why, the risk, any changed assertion and why the old one was wrong, and every client-visible claim with its source. The human reads those sections once, before the production deploy, which only the human triggers. Merging into the release branch is still not a deploy.
- **Why:** held PRs queued behind the human — six of them behind an approval signal the forge could not even deliver for that identity (*Human gates*). The human wanted dev loaded continuously and tested there: "we need to push and keep going, we will test everything in dev".
- **What it rests on, and is safe only with:** a review stage in front of every merge; a dev environment that deploys on merge and is really tested; a production deploy that is a separate step only the human starts. Without those three, merge-on-green for High-level work is not this practice — it is §3d's auto-merge applied to a level the taxonomy reserves for human review. Expect the project's instruction file to keep saying "a human reads High-level diffs before merge"; the originating project's does, on purpose, and its preamble carries the standing ruling that overrides it for agents. Record the tension rather than rewriting the instruction file.
- **Smallest form:** one sentence in the preamble, one section in High-level PR bodies, and a list of merged High-level PRs handed to the human before each dispatch.

**7. CI is the gate. Open the PR once.**
- **Rule:** the required CI checks decide. Locally an agent runs only lint, types and the tests that reach its change (including real-database ones on its own test database). It pushes work in progress to its branch before a PR exists and opens the PR when the work is complete, so each push to an open PR is a fix. One retry per failed lane; a second failure is real and is fixed with a pushed commit.
- **Why:** every builder, reviewer and finisher ran the full local gate, then CI ran the same lanes on every push — 1.77 gate builds per PR and 19% of the large machines' minutes on builds a newer push had already replaced. A local subset that reads green still proves nothing about the lanes it skipped; that is why the lanes, not the subset, decide.
- **Smallest form:** two preamble lines.
- **Reference:** a cloud rule that stops a PR's older gate builds the moment a newer push starts one; a blocking CI-wait script (*The engine*, J).

**8. Each file has one owner, and IDs are handed out.**
- **Rule:** in a wave, each file belongs to one agent. Sequential IDs (backlog numbers, register numbers) are reserved in the brief, never taken as "the next free one". One ledger agent per wave writes the board and the registers.
- **Why:** two parallel PRs each took the same next register ID; each was green alone, and together they turned the integration branch red. Every PR editing the same roadmap table conflicted on every lane.
- **Smallest form:** a file list and an ID list in each brief.

**9. State lives in files that survive a reboot.**
- **Rule:** the board, the preamble, the rulings, the plan files, the progress notes and the scheduled-jobs list live in a folder that outlives the session and the machine's temporary storage. The conversation holds conclusions only. Durable results (a deferred item, a lineage record, a PR body) go in the repo.
- **Why:** a kernel update rebooted the machine and the scratchpad came back empty — board, preamble, briefs, scripts and an extract gone with it. Separately, a session cron survived that reboot while the file its prompt pointed at did not: after any restart, list scheduled jobs and read what each points at; assume nothing either way.
- **Smallest form:** one folder, and the rule.

**10. Checkpoints make any stop recoverable.**
- **Rule:** an agent pushes its branch after every green step, not only at the end, and keeps a five-line progress note: item · branch · PR · done · next. A cut-off must leave pushed, recoverable work, never an anonymous half-edited worktree.
- **Why:** usage limits, reboots and editor restarts cut agents mid-edit; relaunching from a pushed branch and a note is cheap, reconstructing from a worktree is not.
- **Smallest form:** two preamble lines.

**11. The usage plan is a budget with a ceiling.**
- **Rule:** read the usage level before every launch and every major step. Turn the limits into one word every agent reads: **green** (normal); **amber** (orchestrator: no new waves or agents, finishing and review steps first; agents: finish the current step, commit and push, update the note, start no new long work); **red** (orchestrator: land the plane — launch nothing, spend what is left on reports and comms; agents: commit the WIP, push, write the note, stop and report `stopped-budget`); **unknown** (carry on, and find out why — a broken meter takes away the warning, never the work). Keep a reserve below red for the final reports, the notes and the baton; it is not for "one more fix". Stop *starting* build work at a weekly ceiling and keep the rest for follow-up and docs. Note each wave's starting and ending percentages on the board, so a wave's cost is learned, not guessed.
- **Why:** seven builders launched after one meeting transcript ran into the weekly limit mid-flight and left half-built branches. A watchdog cron meant to restart work after the reset never fired once in two weeks. The short window, not the week, is what stops a wave: one plan plus twenty builders used 44% of a 5-hour window in under three hours and 12% of the week.
- **Smallest form:** check the usage meter before launching, and write the ceiling in the preamble.
- **Reference:** a poller on a model-free timer writing the one word + a JSON of levels, burn, projection and pace; a launch hook that refuses new agents at amber and red unless overridden (failing open — a crash lets the call through); a limit-stop hook that writes a hand-off baton listing every worktree, stopped item and unfinished run; a GO/STOP build gate over the same readings (*The engine*, G). Example thresholds from the originating project: amber at 70% of the short window, or projected ≥95% by its reset, or the week ≥20% and 15 points ahead of pace (that last amber shrinks the next wave rather than stopping build); red at 85% of the window or 90% of the week; build ceiling 85% of the week. **The gap:** agents a running pipeline starts are not tool calls, so the hook never sees them — the per-agent budget flag in the preamble is what stops those.

**12. Waiting costs nothing only when no model does it.**
- **Rule:** waits run in a script or a timer: polling CI, polling for merges, waiting for a deploy. A model wakes only on a result. Route models by role: build and finish on the session's strongest model; review, critic and anything read-only on a second model; mechanical doc, ledger and board passes on a cheaper model; polling on no model at all.
- **Why:** a model tick re-reads the whole orchestrator context — 113 watcher ticks cost 115M tokens, about 1M each, mostly to print "no open PRs". A week's accounting put the orchestrator at 27% of cost from 13% of turns at ~500K context per turn; builders at 48%.
- **Smallest form:** a blocking wait command in the preamble, and the role table in the pipeline script.
- **Reference:** `wait_for_cb.py <PR>` — one blocking call that prints a red lane's failing log lines and its build id so the agent can retry that lane once (*The engine*, J); system timers for the pollers.

**13. Done means live in production.**
- **Rule:** the board marks an item done only when its work is deployed to production. "Merged" and "on dev since <date>" are separate states, read from the deploy record and never inferred. Infrastructure applied straight to production counts as live at its apply time, from the action journal.
- **Why:** two ledger passes closed three items as done when they merged; none was in production, which had last been deployed two days earlier.
- **Smallest form:** before a ledger pass, check whether each merged commit is an ancestor of the last successful production deploy's commit.
- **Reference:** `deploy_truth.py --since <date>`: reads the newest successful dev and prod deploys and runs `git merge-base --is-ancestor` per PR; the ledger writer is handed its table (*The engine*, I).

**14. Observability changes in the same PR as the behaviour.**
- **Rule:** a change to a feed, cron, route or schedule — and, once the rule had bitten, any build or fix — updates the monitoring and status surfaces in the same PR, never later. The brief lists the surfaces; the file-ownership map gives them to one agent. A production data change is checked against what the client-facing page shows before it is called done.
- **Why:** three of the project's own changes left the client-facing feed-health page wrong on a morning the client looked at it.
- **Smallest form:** the list of surfaces, written into the brief.

**15. A retro per wave, and a weekly measurement.**
- **Rule:** after each wave, about five lines: scope, agents, tokens, what shipped, what slipped, which reviews found blocking defects, the budget at start and end, what to change. Once a week, measure throughput against a fixed baseline — merged PRs by kind and lane, merge-to-production lead time by git ancestry against each deploy's head, tokens by role and model, cost and plan-percent per merged PR — and commit the totals as a small file, because transcripts expire.
- **Why:** without the retro the process turns into a to-do list that keeps growing; without the measurement nobody knows whether a change helped. The originating project's retro has slipped since the second wave — the practice is stated with its own failure.
- **Smallest form:** one retro file per wave, and one small JSON file per week.
- **Reference:** a `throughput` skill joining the forge, the harness transcripts (tokens per message by role and model, roles from the pipeline journals) and the usage meter; `docs/metrics/throughput/<ISO-week>.json`.

**16. One board per week, waves numbered.**
- **Rule:** at the weekly usage reset, archive last week's board whole. The new board runs `Wave 1 … Wave N` in launch order — live breakage and feed issues, then production fixes, then features — plus `Ops` (steps waiting on a window or on the human's word) and `Later` (parked rows, with the reason). The next wave starts when the budget allows and the previous one has free slots. Production fixes ship as soon as they are green; only features wait for the weekly review.
- **Why:** one board had grown across a week with names like `1b`, `2a` and `Next`; the human asked for it cleaned up and numbered.
- **Smallest form:** one TSV or Markdown table per week; a one-shot wake-up a few minutes after the reset that launches the lowest wave if the gate says GO.

**What stays judgment, not code:** cutting waves; the lane and level tests; the review itself; which decisions to batch for the human; whether a finding is new or already known. None was automated; the critic stage exists to check them.

**What a project can skip** (built because the originating project wanted to watch or measure; none changes what an agent does): a live status page with ETAs and token accounting; an approval watcher; the system timers; a PDF of the weekly measurement.

**What the practices lean on:** a CI gate whose checks are required; a dev environment that deploys on merge; a production deploy that only the human starts; a backlog with IDs; a way to read the usage plan.

**Measured but not adopted** (one week's accounting, offered to the human as candidate cuts, unmeasured): a small, short-lived orchestrator started fresh each day from the board and the rulings file, never building inline; "finish" as a script, with an agent only when a lane goes red; no docs-only PRs for bookkeeping (lineage, board rows and status text ride the PR they describe; one ledger PR per day for the rest); slots instead of wave barriers (keep N builders running whenever the gate says GO; waves become priority labels); a lean instruction file for agents and a governing-context hook that prints once per file per agent. Listed so an adopter measures before copying.

---

## The engine

Thirteen components, described so a project can build its own from the text. A–H are needed to run waves; I–M complete it. How a project implements a component — a script, a skill, a prompt, a habit — is its own choice. "Reference" names the originating project's version; there is no package to install.

| | Component | Job | Reads / writes | Rules | Reference |
|---|---|---|---|---|---|
| **A** | **The board** | the one list of what is queued, running and finished this week | one row per backlog item: wave · item ID · title · branch · PR · status · note | statuses `queued` · `running` · `open` (PR open, nothing running) · `held` (needs the human's word) · `paused` (resume step in the note) · `blocked` / `failed` · `merged` / `done`; groups `Wave 1 … N`, `Ops`, `Later`; only the orchestrator writes it (agents keep progress notes); archived whole at the weekly reset; the note carries lane, level, rulings, run id and the budget at wave start | `waves.tsv` |
| **B** | **The rulings file** | the human's decisions, in their words, numbered | one file per week, numbered on from the last | each ruling: date, question, answer verbatim, what it changes; open decisions listed at the end | `rulings-<date>.md` |
| **C** | **The preamble** | the standing rules every agent reads before its brief — the version of the process agents actually obey | — | changes in the same sitting as the process docs; a contradiction between them is a defect (contents under *The files*) | `agent-preamble.md` |
| **D** | **The brief** | one item's instructions | points to the plan file rather than restating it | fields under *The files*; if the code shows the item is already done, the agent reports that and opens nothing | the plan JSON + a short per-item prompt |
| **E** | **The plan run** | settle what the waves are before anything builds | reads the backlog, the newest baton and every channel; writes one plan file | **sweep** (one read-only sweeper per channel, in parallel; each returns actions with evidence, owner, urgency, known-or-new) → **synthesize** (reconcile every finding against the backlog as new, known or closable; draft waves with each item's lane, level, owned files, dependencies; list the rulings needed; items needing a client-visible write flagged) → **criticize** (a critic on a different model attacks the draft and returns corrected waves — the corrected cut *is* the launch order). No wave launches before the critic returns; the rulings are then asked in one batch; a short plan from a named list (plan → critic, no sweep) is allowed when the human names the items | a five-sweeper pipeline; `wave<N>-plan-<date>.json` |
| **F** | **The wave run** | build a wave's items in parallel | one multi-agent run per wave; three fresh agents per item, each in its own worktree | **build** (test-first; opens the PR when complete; waits for green; stops — returns item, PR, branch, head SHA, CI state, already-done, level, tests, changed assertions) → **review** (read-only, different model, detached worktree at the PR head; assumes the change is wrong; mutant check; checks every call site, regressions, the "why the old assertion was wrong" answer, unflagged High-level surfaces, every client-visible claim against its artifact — returns verdict, mutant result, blocking items with file/line/fix, non-blocking items) → **finish** (fixes every blocking item or explains why one is wrong; fixes cheap non-blocking ones and lists the rest as follow-ups; merges the base in on conflict keeping the base's design; waits for green; for a High-level PR writes "Read at dispatch" first; checks for child PRs and retargets them; merges; removes branch, worktree and test databases — returns status, merge SHA, follow-ups). A stage that returns nothing marks its item `no-pr` or `blocked`; the wave carries on. Results keyed by the item ID the script assigned, never by name. Models by role (practice 12) | `pipeline(items, build, review, finish)` |
| **G** | **The build gate** | one GO or STOP for starting build work | the usage meter: short-window percent and its projection at reset, weekly percent, per-model weekly percent | STOP when the week is at or above the build ceiling, the short window is at red or projected past 100% by its reset, a per-model cap is at its ceiling, or the guard says red; otherwise GO. Agents already running act on the budget level separately (practice 11) | `build_gate.py`; `claude_budget.py` (poller, levels, hooks) |
| **H** | **The queue check** | keep work moving without the human | the gate, the board, open PRs | every hour, and once a few minutes after the weekly reset: read the gate — on STOP only make sure agents in flight have checkpointed; on GO merge every PR whose review passed and whose CI is green; if the lowest unfinished wave has free slots and queued rows, launch the next rows (5–6 at a time; lowest wave first, production lane before features); update the board; report one line only when something changed. Never dispatch production. `Ops` rows are not idle work. GO with nothing running and rows queued is an alarm: *queue idle while green*. Every scheduled job is listed with id, schedule and prompt in a file, because jobs inside a session die with it; jobs needing no judgment run as system timers | an hourly session cron + system timers; `scheduled-jobs.md` |
| **I** | **Deploy truth** | the facts a ledger pass needs | the newest successful production and dev deploy commits; the PRs merged since a date | per PR: is its merge commit an ancestor of each → live in prod, on dev, or merged with the deploy pending; the ledger writer is handed this table and never infers | `deploy_truth.py` |
| **J** | **The CI wait** | one blocking call per PR, so no model turn is spent polling | the required statuses on the head commit | poll until all succeed or any fails; on failure print the failing lane's last log lines and its build id so the agent can retry that lane once; a second failure is real | `wait_for_cb.py` |
| **K** | **The retro and the weekly measurement** | learn, with numbers | — | practice 15 | `wave-N-retro.md`; the `throughput` skill |
| **L** | **The status page** (optional) | what the human watches | the board, live PR state, the meter, the pipeline journals | only reads; blocks: plan limits and level · tokens since the reset · recent runs with each agent's last action · open rows with live CI and ETAs from stage medians (build ≈ 50 min, review ≈ 13, finish ≈ 22 on the originating project) · open PRs with their lane · commits not yet in production | `wave_status.py` |
| **M** | **Where the human comes in** | — | — | one batched question for rulings after the plan's critic; the "Read at dispatch" sections once per production deploy; their word for the production dispatch, an infrastructure apply, a purchase or an irreversible deletion, and any write the client can see. Nothing else waits on them | — |

---

## The files

All in a **state folder that survives a reboot** (practice 9) — never the harness scratchpad. The one exception is a two-line launcher for the status page, if there is one.

| File | Holds | Written by |
|---|---|---|
| `agent-preamble.md` | the standing rules every agent reads first (below) | orchestrator; amended the hour a lesson lands |
| `waves.tsv` (+ `waves-archive-<ISO week>.tsv`) | the board, one row per backlog item (engine A) | orchestrator only |
| `rulings-<date>.md` | the week's numbered rulings (engine B) | orchestrator |
| `wave<N>-plan-<date>.json` | the plan: per item its verified state, lane, level, size, owned files, reserved IDs, rulings needed, brief and acceptance; the critic's problems and corrected waves (engine E) | the plan run |
| `prompts/<item>.md` | a short brief by reference to the plan file (engine D) | orchestrator |
| `progress/<item>.md` | the five-line progress note: item · branch · PR · done · next | the agent |
| `scheduled-jobs.md` | every scheduled job: id, schedule, prompt | orchestrator |
| `BATCH/wave-N-retro.md` | the retro (practice 15) | orchestrator |
| `HANDOFF-BUDGET-<stamp>.md` (repo root) | the baton a limit stop writes: every worktree with branch, uncommitted-file count and unpushed commits; each stopped item; each unfinished run with its script path; the reset time | the limit-stop hook |

**The preamble** — about 30 lines; the agents' version of the process:

| Covers | Rule |
|---|---|
| Where to work | a fresh worktree from the freshly fetched base branch, at a set path outside the shared checkout; never `git stash` / `git reset` / checkout in the main checkout; never touch another worktree; a real dependency install in the worktree; a private test database by exact name, dropped by exact name |
| The two tests | the lane test (production task → release branch; feature → integration branch; docs-only either) sets the base; the level list says what is High. If the brief's base disagrees with the test, say so in the first line of the report and follow the test |
| Verify first | the brief may be stale: read the governing record in full (never `head`/`cut`/truncated grep); check the code on today's base; build only what is missing; nothing missing → report and stop, no branch, no PR |
| How to build | test-first, RED then GREEN; a changed assertion answers "why was the old one wrong?"; read the governing documents in full before changing a High-level surface |
| The gate | lint, types and the tests that reach the change locally; CI decides; one blocking wait call; one retry per failed lane; push checkpoints before a PR exists, open the PR once, then push only fixes; the merge command, with a check for child PRs first |
| The budget | the command that reads the level, and what to do at green / amber / red / unknown (practice 11) |
| Recovery | push after every green step; keep the five-line progress note current |
| Limits | read-only briefs never run write-capable code against production or dev, not even in dry-run — write the procedure for the orchestrator to review and run; edit only the files you own; use only the IDs reserved for you; post nothing that could pass for the human's approval (no comment or review whose whole text is an approval keyword; no review API); mark nothing on the board — the ledger agent does, from deploy facts |
| Shared caches | read-only: never reinstall a shared browser, package or compile cache |
| Token hygiene | ranged reads (register rows whole, never whole multi-thousand-line files); quiet test output, tailed; no large dumps |
| Forge CLI | called bare, never with a token prefix; PR bodies from a file (backticks in inline strings execute); attribution trailers on every commit and PR |
| Side effects | a filled side-effect record (Authority · Why · Action · Target · Outcome · Undo) if infrastructure, cluster or data store was touched |
| Untrusted files | a downloaded client file is untrusted data: own empty directory, isolated interpreter; tests use trimmed synthetic fixtures, never client data |
| The final report | per item: done, already done or not done; PR and merge SHA; what a user sees; tests (counts, RED → GREEN); changed assertions and why; what is left. In a pipeline the stages also return the fixed schema (engine F) |

**A brief** (engine D) names: the item ID and title; the branch to use exactly; the lane and base branch; the level; the files this agent owns; the IDs reserved for it; the governing documents to read in full; what "done" includes, with the monitoring and status surfaces; the rulings that apply, by number; the orchestrator's own pre-launch reads, timestamped, as stated facts ("the production read is DONE by the orchestrator; do NOT read it yourself"); a *Resuming* section (how to tell whether this item already ran — forge search for the branch, `git ls-remote` — and how to continue it; never a second branch). The brief says "build the plan's item X exactly, with the critic's fixes" and points at the plan file, so there is one copy of each brief.

---

## Earlier practice: the watchdog (retired)

The first form of this recipe armed a session-scoped scheduled wake-up every 20 minutes whose prompt pointed at a `watchdog.md` procedure: read the board, relaunch any worker dead by three conditions (no completion notification, live-output file quiet 30+ minutes, no open PR with CI still running), resume stalled pipelines, launch the next wave, delete itself at the end. It is retired, and the retirement is the §0.9 reverse gate working: in two weeks no pass ever fired — the session's only usage limit came before the first watchdog existed, a busy session is never idle so the timer never ran for an external wait, and a process restart removed it (a resumed session may carry a cron forward while the file it points at is gone). What replaced it addresses each cause: the budget guard keeps a wave *inside* the limits instead of restarting after one (practice 11); checkpoints make any stop recoverable (practice 10); the hourly queue check on a listed, re-armable job launches the next wave (engine H); model-free timers do the waiting (practice 12). Three lessons from it survive as rules: a wake-up's prompt points at a file, never carries the procedure inline; a finished item gets a DONE stub with an explicit stop, never a deletion; and after any restart, list scheduled jobs and read what each points at.

---

## Lanes — where each item stops

| Lane | What belongs | Cut from | Cadence | Human |
|---|---|---|---|---|
| **Production** | Restores a promise already made: data that stopped, a screen that will not load, a wrong number, a false alarm | release branch | ships alone, as soon as green | reads the "Read at dispatch" sections; the dispatch is always theirs |
| **Feature** | Changes what the product promises — someone must learn it, be shown it or told | integration branch | the weekly release | reviewed on dev; one promotion and dispatch, with release notes |

Docs, roadmap, register and side-effect-record-only changes take neither lane: they merge on green and ride the next promotion. **The line is the promise,** not the file path or urgency. **Never ship a production fix by promoting the integration branch.** A production task built on the wrong base is recovered by cherry-pick (`-x`) onto a branch from the release branch, a PR into it carrying exactly the reviewed commits, and the original closed as superseded; if a file has already diverged on the integration branch, a twin PR there keeps the back-merge clean.

**Level decides what the human reads, not whether the PR merges** (practice 6; §3d's five levels collapsed to two for brief-writing):

| Level | §3d levels | What the brief says | PR body |
|---|---|---|---|
| **Low** | Trivial, Low — and Medium when the standing ruling says so | merge on green after the review; delete branch and worktree | — |
| **High** | High, Critical — and **any change to an existing test assertion** (§3d) | merge on green after the review; the finisher writes "Read at dispatch" first; report "merged, read at dispatch" | opens with **Read at dispatch**: what, why, risk, changed assertions with why the old one was wrong, client-visible claims with their sources; the hunks that matter (DDL, workflow files, deploy config, authorization lists) at the top |

Steps that genuinely need the human's word keep the `held` status and the "waiting on you" mark: a production dispatch, an infrastructure apply (plan before and after, compared against an explicit expected-change list, "APPLY NEEDS THE HUMAN'S WORD" at the top, saved plans deleted after — §16), a purchase, a deletion, a client-visible production write.

**The merge gate as agents meet it.** A fixed set of required statuses on the release branch, named in the preamble; green-before-merge on the integration branch is convention. Each status tests the merge result, not the branch tip, so a conflict turns every status red at once — merge the base in, resolve keeping the base's design, re-push. Poll the latest state per status context with one blocking call (engine J). Merging to the integration branch auto-deploys to dev: verify the deployed result — a sweep reads the last deploy's job conclusions, and a **timed-out job counts as failed** (a post-deploy verify that timed out five deploys in a row read as *cancelled*, alarmed nothing, and the PR gate never ran that suite). After a merged PR changes a generated contract source, the next branch merges the base in and runs the generated-artifact check before pushing.

**The production dispatch happens only on the human's explicit words *in that turn*** — never a brief, a baton or an earlier approval. Before dispatching, state the payload (commits since the last deployed SHA; what a client would notice) and hand over the read-at-dispatch list; once asked, post-deploy production writes the human already ruled on run the same night. After a production operation (a path switch, a grant, a fallback), the first served figure is reconciled to the source's own total before the row closes — one such reconciliation accounted for a 7,991-case shortfall as two unlisted codes plus rounding, and queued the latent gap it exposed as a row.

---

## Human gates and guardrails

The §14 Agent Approval Gates table as a wave session fills it in (agent users: the harness's permission system; agent-product builders: code):

| Action class | Gate | Rule |
|---|---|---|
| Dev operations (cluster commands on the dev namespace, dev jobs and loads) | SOFT, standing | one plain command per call matching an allow rule — no `cd`/`&&`/loop chains, or the permission classifier intercepts it |
| Merges after the review on green, High-level included | SOFT, standing (ruling quoted in the preamble) | the review stage is what makes this safe; a classifier refusal of "merge without review" does not apply to a reviewed PR under a standing ruling |
| Production writes, infrastructure applies, purchases, deletions, client-visible writes | HARD, per act | the human's word for that act; may be given ahead for a named act ("the backfill, right after the next promotion") |
| The production deploy dispatch | HARD, in the current turn | never a baton or brief |
| Anything the classifier refused although authorized | HARD | stop and ask; never route around |

**A denial is a human decision.** Report BLOCKED with the probe ready; a blocked item records where it stopped and the ready-to-run next step and does not retry. A refused dev operation is retried once as a plain command citing the standing authorization, then reported; a refused production read, write or grant is never retried or rerouted. **No agent reads or writes production.** The critic lists the production facts a brief needs; the orchestrator reads them itself, timestamped, and hands them in as stated facts. **Read-only means read-only:** under a read-only or planning brief, no write-capable code against production or dev, not even in dry-run mode (an ops planner once ran DELETE-capable scripts in dry-run against production; nothing changed, the safety check flagged it) — the agent writes the procedure, the orchestrator reads it in full and runs it, dev first, then production, as one script whose docstring quotes the ruling, prints BEFORE and AFTER rows, writes through the audited service functions with actor and notes, and records both timestamps. **Outward text** goes out as paste-ready drafts the orchestrator never sends. **Every external side effect is recorded** before acting, outcome after — Authority (the human's words, quoted) · Why · Action · Target · Outcome · Undo — committed with its PR; a test fails the build on an unfilled line (§4 Agent Log Discipline's decisions layer in file form).

**The approval signal must be one the identity can give.** When agents open PRs through the human's own forge account, the forge disables Approve on your own PR — so a watcher waiting for an approval review waited for a signal that could not exist, and six held PRs sat until the human said "approved" in chat. Check that the signal you watch for can actually be given by that identity before relying on it. The route that worked was a comment whose whole text is an approval keyword, newer than the PR's last commit, with a forgery guard in the preamble (no agent posts such a comment or uses the review API); the better long-term shape is a separate identity for agent PRs (a forge app or machine user) so the human's native approval works and an agent can never impersonate it. Under merge-on-green-after-review (practice 6) the watcher has nothing to release and was deprecated — its last job is the budget-and-queue line the hourly check reads.

**Shared-machine hygiene.** Workers work only in their worktree, cut from a freshly fetched base at a set path outside the repo; never `git stash`, `git reset` or a checkout in the main checkout (stash is global to the tree); the branch check in the same `&&` chain as the commit; never force-push a branch another live session uses; never reinstall a shared cache. **One window per conversation:** a conversation resumed in a second editor window is a second process driving the same workers — after any resume, or when the agent list shows an unexpected peer, check the process list and the transcript's session id; if it is a twin, stop all writes and relaunches until the human closes one window. **Launch pipelines from the main checkout:** launched from a worktree, the harness saved the script under that worktree's project folder, so the status page showed the run by id only and a baton would have lacked its script path.

---

## Failure modes encountered

Every rule above came from one of these. Add to the table the hour a new one lands.

| What happened | Rule |
|---|---|
| Workers picked their own branch names; the board, keyed on the briefed branch, showed merged items as quiet for 9–10 hours | Briefs name the branch "(exactly) — the board tracks it"; the Resuming section checks the forge and `git ls-remote` first |
| A brief written from a truncated read of a backlog row sent a worker to build something already in production | Verify-first in every brief; governing records read in full |
| Writes under shared temporary storage failed with ENOSPC while bytes were free: inode cap hit by a per-file compile cache from many parallel workers | Prune caches older than two hours and finished scratch dirs; check `df -i` before `df -h` on ENOSPC, before a wave, before any restart |
| Two workers ran the heaviest production build on the shared workstation | Lint, types and the tests that reach the change locally; CI owns the production build; big batch jobs run in the cloud build service |
| A worker's browser reinstall deleted another project's browser build | Workers never reinstall shared caches |
| Six workers shared one scratch area; one ran another's same-named script, which dropped every test database matching a prefix | Scratch only under the item's own directory; never run a scratch script you did not write this sitting; create and drop resources by exact name |
| A worker's read-only production probe was refused by the classifier | Not retried or rerouted; BLOCKED with the probe saved; "measure on dev" in the preamble; from the second week, no agent reads production at all — the orchestrator reads and hands in facts |
| A worker's High-level merge under a relaxed ruling was refused by the classifier ("merge without review") | Reported, not retried; the human merged on their word. Under the current rule every merge follows a review, which the refusal does not apply to |
| Every item edited the roadmap table; every status failed on conflicts | One ledger agent per wave writes the board and registers; builders never touch them |
| Seven builders launched after one meeting transcript exhausted the weekly limit mid-flight; half-finished PRs | Intake registers and stops; building needs the human's word; the budget levels, the guard and per-agent checkpoints |
| The watchdog never fired: for an external wait the session was never idle; after a restart it was gone or pointed at files that were gone | Retired (above). Model-free timers do the waiting; every scheduled job is listed in a file; after any restart, list jobs and read what each points at |
| The whole watchdog procedure inline in the wake-up prompt; re-armed three times in 45 minutes; still behind the board | A wake-up's prompt points at a file; rules are file edits |
| A pipeline matched verifier results by free text; a restated name counted an item as refuted | Key by a script-assigned id; a missing match is an error |
| Two parallel PRs registered the same next id and merged 35 seconds apart; each green alone; the integration branch failed uniqueness | IDs reserved in the brief; only the ledger agent registers |
| Two green PRs merged the same afternoon left a generated contract list one entry short | Merge the base in and run the generated-artifact check before pushing after a contract change |
| Two unfilled side-effect records failed a lane for every code PR until completed | Fill every line; run the record test before committing |
| `git stash` in the shared tree reverted eight files of other workers' work while verify reported green; a peer's checkout between two calls put a commit on another session's branch | Never stash/reset/checkout in the shared tree; branch check in the commit chain; worktrees at a set path outside the repo |
| A conversation resumed in a second window ran as a twin; two copies of one worker wiped each other's test databases | One window per conversation; check the process list and transcript session id after any resume |
| An attack agent left an inert permission guard that skipped every gate while a static check reported all routes guarded | After any deliberate inert build: diff production files, grep for sabotage markers, require the revert in the report, prove guards at runtime with a real low-privilege identity |
| A kernel update rebooted the machine; the scratchpad came back empty — board, preamble, briefs, scripts, an extract | Everything a long session needs lives in a state folder that survives a reboot; the scratchpad is for throwaway output |
| "Check comms" ran only part of the sweep; one answered question was reported "unprocessed" for five days | "Check comms" is the whole sweep; an answered item is processed the same turn; a second sighting of the same action line is fixed or given an owner, never re-listed |
| Three of the project's own changes left the client-facing status page stale on a morning the client looked at it | A feed, cron, route or schedule change — then any build or fix — updates every observability surface in the same PR |
| Low-level agents merged their own PRs unreviewed; the first reviewed wave found blocking defects in 4 of 10 PRs, one of them Low-level | Build → review (mutant check, different model) → finish for every item; only the finisher merges |
| A wave of 8 builders launched while the plan's critic was still running; the critic flagged three of its items; stopped after 3 minutes, ~1.2M tokens for nothing | No wave launches until the sweep, the synthesis and the critic have all returned |
| Four units of one wave were bundles under working names; the board could not show them as in build | Every unit of a wave is one backlog item; a bundle is split or registered before it is built |
| Briefs defaulted every item to the integration branch, so seven production fixes were PR'd there while it was 43 commits of feature work ahead of the release branch | The lane set per item before launch: the synthesizer sets it, the critic checks it, it becomes the brief's base, the agent checks it against the preamble's lane test; recovery by cherry-pick |
| A read-only ops planner ran DELETE/UPDATE-capable scripts in dry-run mode against production | Read-only means read-only; the agent writes the script, the orchestrator reads it in full and runs it, dev first |
| A post-deploy verify timed out on five dev deploys in a row and read as *cancelled*; nothing alarmed; the PR gate never ran that suite | A sweep reads the last deploy's job conclusions, and `cancelled` counts as failed; the alarm gap registered High-level |
| A pipeline launched while the orchestrator's working directory was a worktree; its script was saved under that worktree's folder, invisible to the status page and the baton | Launch pipelines from the main checkout, or record the script path on the board row |
| Asked to update the exported process document "with more details", the orchestrator re-scoped the request twice — into moving code and into a shared kit — and was corrected both times | Do what was asked, in the place asked; a structural change is offered as a question, never folded into the plan |
| An approval watcher waited for an approval review the forge cannot accept on your own PR; six PRs sat held until the human said "approved" in chat | Check that the approval signal can be given by that identity; prefer a separate identity for agent PRs; under merge-on-green-after-review nothing waits for an approval |
| Watcher ticks on a model cost ~1M tokens each — 115M for 113 ticks — mostly to print "no open PRs"; the queue then sat idle for hours on a green budget because the ticks never read it | Polling on model-free timers; the hourly check reads the budget first and alarms *queue idle while green* |
| Two ledger passes closed three items as done when they merged; none was in production, last deployed two days earlier | Done means live in production; the ledger writer is handed deploy truth and never infers |
| Every builder, reviewer and finisher ran the full local gate, then CI ran the same lanes on every push — 1.77 builds per PR, 19% of large-machine minutes superseded | CI is the gate; locally only what reaches the change; open the PR once; stop superseded builds |
| The orchestrator's own time estimates in the board and procedure file ran about 13 minutes late against the tool-call record | Record times from the tool call or journal, not memory |

---

## Anti-patterns specific to long-running sessions

Extends §30.4 and the §0.6 catalog (`core/umami-anti-patterns.md`).

| Anti-pattern | Watch signal | Mitigation |
|---|---|---|
| **Launch before the critic** — "most of the queue doesn't depend on the sweep" | A wave stopped minutes after launch; a critic finding that names a running item | No wave launches until the critic returns; the right answer to "haven't we started yet?" is when the critic will return |
| **Bundle rows** — a wave unit covering several backlog items under a working name | A row the board cannot show as in build; a retro that cannot say what shipped | One backlog item per row; split or register before building |
| **Wrong base** — a production fix built on the integration branch | The status page flags a fix heading for the integration branch; a promotion would carry unrelated work | The lane test in every brief and in the preamble; cherry-pick recovery |
| **Self-merge** — a builder merges its own Low-level PR | A merged PR with no review record | Build → review → finish; only the finisher merges |
| **Human-held queue** — PRs waiting on a read that happens whenever | Held PRs that outlive a sitting; "waiting on you" rows nobody is reading | Merge on green after review; the human reads once, at dispatch, with the three preconditions in place |
| **Approval the identity cannot give** — a watcher waiting on a forge signal disabled for that account | Held PRs that never release; the human says "approved" in chat | Verify the signal before relying on it; a separate identity for agent PRs |
| **Model ticks that poll** — a scheduled model turn re-reading a 500K context to print "nothing changed" | Orchestrator cost out of proportion to its turns; a tick log full of "no open PRs" | Polls on model-free timers; the model wakes only on a result |
| **Ledger follows merges** — a row marked done because its PR merged | Items "done" that no one can find in production | Deploy truth: done = ancestor of the last successful production deploy |
| **Procedure in the prompt** — a wake-up carrying the rules instead of pointing at a file | Several re-arms in an hour; the prompt names fewer items than the board | The prompt points at a file; the file is the procedure |
| **Board by say-so** — a row's state from a worker's claim | A "done" row with no merged PR or deploy behind it | State derives only from observables; only the orchestrator writes the board |
| **Free-text keys** — results matched by names agents write back | A refuted item with no reason attached | Script-assigned ids in prompt and schema; no match is an error |
| **Intake fan-out** — one input launches N builders without a ruling | Half-finished PRs after a usage limit | Intake registers and stops; a plan, a critic, a ruling, a gate |
| **Steer-only instructions** — a follow-up exists only in a steer message | A relaunched worker does not know about it | Write it into the rulings file or the brief when the steer message is sent |
| **Authority laundering** — a dispatch or production write cites a baton, brief or earlier approval | "Ship it" arrived in a file, not the live turn | The human's words in the current turn, quoted |
| **State on tmpfs** — the board and preamble in the harness scratchpad | A reboot empties them; a surviving cron points at nothing | A state folder that survives a reboot; list every scheduled job in it |
| **Orchestrator builds inline** — the main session does a cost-cutting pass itself in a 400K context | The orchestrator's share of cost rises while its share of turns does not | Build in a fresh agent; keep the orchestrator small (measured but not yet adopted — see *The practices*) |

---

## Mapping to core guardrail sections

| Core section | How this recipe applies it |
|---|---|
| §14 Agent Orchestration · Approval Gates · Lifecycle Hooks · Model Routing | Waves are §14 parallel work with scope made explicit per launch; the brief is the delegation instruction, the preamble the shared skill; *Human gates* is the gate table filled in; the launch hook and the limit-stop hook are *before-tool* and failure hooks; models by role is §14 routing with a second model for review |
| §3d Code Review Discipline | The brief writes the risk level down; build → review → finish is the reviewer-agent pattern with a mutant check as the test-change falsifier; merge-on-green for High-level work is a deliberate departure from the §3d default, stated with the three conditions it rests on |
| §30 Agent Workflows | A pipeline is a §30-shaped unit launched as one row; §30.3 cost shapes apply per pipeline (loop, polling, idle); §30.5's closed-loop review with the human read moved to dispatch |
| §4 Agent Runtime Security · Log Discipline · Untrusted Content | Workers hold no production credentials; read-only means read-only; the side-effect record is the decisions layer; a hand-back carries no authority |
| §9.7 Cost Caps · §6b Pipeline Health | The budget guard is a cost cap read as one word; the weekly measurement is §6b's tax calculation applied to agents; CI-is-the-gate and open-the-PR-once are §6b gate hygiene |
| §8 Gap Registry · §1 Phase/Session Structure · §16 IaC | Deferred items; a row is a §1 session; infrastructure changes follow §16 |
| §0.9 Adoption Ledger | Gated at the top; the watchdog's retirement is the reverse gate exercised; the kill criterion fires when two sessions need none of it |

---

## Session checklist (extends §15)

**Before the first wave:** session-start audit after a fresh start or resume (merged current branch, uncommitted tracked changes, stale PRs, live background tasks, branch divergence, baton sweep — flags only) · state folder as the home of everything durable · preamble written from the project's rules, with the budget flag, checkpoint discipline, the lane test and read-only-means-read-only · the usage meter readable before anything launches · plan run: sweep → synthesize → critic, and **wait for the critic** · process-now items processed the same turn · rulings asked once, batched, priced, recommended first, written to the rulings file · the wave cut: one backlog item per row, IDs reserved through the ledger agent, lane and level per row, files owned, no two rows sharing a file · build gate GO · shared temporary storage checked by inode count · launched as one pipeline, build → review → finish per row; starting usage percentages on the wave's first row · queue check armed and listed in the scheduled-jobs file.

**Each queue check:** read the gate — STOP: confirm in-flight agents have checkpointed, end · GO: merge every reviewed, green PR; launch the next rows of the lowest unfinished wave if it has free slots; update the board; one line only if something changed · *queue idle while green* is an alarm.

**Between waves:** check every open PR's base against its lane · ledger pass from deploy truth, never from merges · the read-at-dispatch list for the human before the next production deploy · the retro, with the ending usage percentages · post-wave observability sweep (every build or fix updated the status surfaces) · clean worktrees of completed rows removed.

**After a limit stop:** read the guard's status and wait for the reset · read the baton(s) · `git worktree list` and the progress notes · commit and push the WIP in every worktree with uncommitted files or unpushed commits · resume each listed run from its script path in the same session, or relaunch agents from their pushed branches · delete the baton. **After a reboot or restart:** check uptime · list scheduled jobs and read what each points at · read each stopped run's journal before assuming it needs resuming · rescue any uncommitted agent work to a `rescue/<branch>` remote branch.

**Closing the session:** every PR merged or closed, or `held` only for a step that needs the human's word · every open PR's base matches its lane · release branch == integration branch, or the gap stated · the board matches the forge and the deploy record · each wave has its retro · no agent left mid-step without a pushed branch and a progress note · no orphan branches or worktrees (delete local branches explicitly) · scheduled jobs that should not outlive the session deleted; the rest listed · a summary given unasked: what shipped, what is live, what needs the read at dispatch, decisions owed, "still open / pending".

---

## Cross-references

- §14 Agent Orchestration — delegation, approval gates, lifecycle hooks, model routing, parallel-work rules
- §30 Agent Workflows — the single-loop units a wave launches; §30.3 cost shapes; §30.4 anti-patterns this file extends; §30.5 closed-loop review
- §3d Code Review Discipline — risk levels, test-change verification, the reviewer-agent pattern
- §4 Agent Runtime Security, Agent Log Discipline, Untrusted Content — the substrate every worker runs on
- §9.7 Cost Caps and Budget Gates · §6b Pipeline Health — the budget guard and the weekly measurement
- §16 IaC / DevOps — infrastructure changes from a wave
- §8 Gap Registry — deferred items; the validation entry for this recipe
- §1 Phase / Session Structure — the unit hierarchy a row sits in
- §0.9 The Adoption Ledger — the gate at the top of this file, and the watchdog's retirement
