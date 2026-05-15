# Umami — Agent Workflows Extension

## §30. Agent Workflows

This extension covers **agent-as-substrate workflow patterns** — patterns where an AI agent is not an interactive coding assistant but a longer-running, more autonomous workflow component. Where §14 (Agent Orchestration) covers the *building blocks* (modes of use, approval gates, lifecycle hooks, model routing), this extension covers the *patterns you compose* from those building blocks.

**When this extension applies:**

- Project runs agents as substrate, not just as interactive developer assistants
- Project has agent workflows that operate autonomously (production CI agents, scheduled remote agents, closed-loop auto-remediation, recursive sub-agent dispatch)
- Project has agent workflows that consume meaningful token budgets and need cost discipline beyond §9.7 per-task caps
- Project has agent workflows whose correctness depends on the workflow shape, not just individual prompts

**When this extension doesn't apply yet:**

- Project uses agents only as interactive coding assistants — §14 alone is enough
- Project's agent usage fits in §14's existing model (modes, gates, hooks) without additional workflow-pattern complexity
- Token cost is bounded by §9.7 caps and doesn't require workflow-level patterns

**Relationship to §14.** §14 covers what an agent *can do* (the building blocks). This extension covers patterns of *how to compose those building blocks into workflows* that run beyond a single interactive session. A project can adopt §14 fully without ever needing this extension; this extension assumes §14 is already in place.

---

### §30.1 Closed-Loop Auto-Remediation

*Also known as: Autonomous Remediation Cycle, Full-Cycle Agentic Debugging.*

The agent drives the entire observe → diagnose → fix → verify cycle in a closed loop. The human reads a summary at the end rather than every step. Bug discovery comes from observation (UI, logs, test failure, browser DevTools); fix and verification happen inside the loop; only the final summary surfaces to the human.

**Cost profile:** Agent-autonomous · Hours per loop · Architectural (observation infra) + Spend (per-iteration token cost)

**The trade-off, named up front.** Token spend in exchange for human attention. The pattern earns its cost when contributor attention is the bottleneck (sole dev, small team, debugging burnout, sanity-bound projects). It does not earn its cost when token budgets are tight or when human reasoning is required to resolve the bug. *"It can burn tokens but save your sanity"* is the canonical framing; before adopting, decide which of those is the actual scarce resource on this project.

**When this pattern earns its cost:**

- UI bugs requiring visual observation to confirm (misaligned button, missing icon, broken form submission, console error in DevTools)
- Bug categories where reproduction + verification dominate the human time — the human-driven loop is "run / observe / describe to agent / wait / agent fixes / run again / observe again", with the human paying attention every iteration
- Projects where contributor sanity is the bottleneck, not token cost
- Predictable bug classes the agent has tooling to detect (failing screenshots, console errors, test failures, log signatures)

**When this pattern doesn't earn its cost:**

- Logic bugs that need deep reasoning more than iteration
- Cost-sensitive contexts where the agent might burn through caps before finding the issue
- Production debugging (the agent shouldn't be touching production — see prerequisites)
- Bugs requiring domain knowledge or product judgment the agent doesn't have
- Bugs whose verification gate is human-judgment-bound (e.g., "is this UX good?", "does this match the brand voice?")

**Prerequisites:**

| Prerequisite | Where it lives | Why it's non-negotiable |
|---|---|---|
| Cost caps with per-task and per-session limits | §9.7 Cost Caps and Budget Gates | Auto-loops can burn through token budgets fast; uncapped loops are the most common source of surprise spend |
| Kill switches with heartbeat-driven termination | §4 Agent Runtime Security | The loop has to be terminable from outside; a runaway agent that won't stop on its own is a kernel-level problem |
| Sandboxed environment (container/VM with no production access) | §4 Agent Runtime Security | The agent should not be touching production while iterating; sandboxing makes wrong-fix experiments safe |
| Browser/observation tooling | Project-specific (Playwright, Puppeteer, screenshot+OCR, or harness UI access) | Without observation, the agent has nothing to close the loop against |
| Verification gate that catches the *originally observed* failure | Project-specific | Without verification of the original symptom, the loop "succeeds" on the wrong test; see Failure modes |
| Approval gates at SOFT minimum | §14 Agent Approval Gates | At a minimum, the agent announces what it's doing each cycle; HARD gates for any out-of-sandbox actions |

If any prerequisite is missing, the pattern is unsafe to run. The most common failure on first-attempt adoption is "we set up the loop without all the prerequisites and it ran away."

**The loop protocol:**

1. **Observe** — agent captures the failure state via the observation tool (screenshot, log, test failure, browser DevTools). The captured artifact is the loop's anchor.
2. **Diagnose** — agent forms a hypothesis about cause; logs the hypothesis (both for audit and to detect when the same hypothesis is being repeated)
3. **Fix** — agent makes the smallest change consistent with the hypothesis. No bundled refactoring (see §3e refactoring discipline).
4. **Verify** — agent re-observes; checks against the *original* failure signal, not a proxy. If verification used a different signal than observation, the loop is broken at design time.
5. **Iterate or exit** — if verification fails, loop again up to the iteration cap; if it succeeds, summarize and exit; if the cap is reached without success, escalate to human with the full diagnostic trail.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Agent runs >N minutes on a single auto-remediation task without status update | Likely stuck in loop or cap-bound — investigate before the cap fires |
| Same bug class triggers auto-remediation multiple times in a short window | Either the fix isn't addressing root cause, or the pattern catches the same surface symptom each loop |
| Cost cap fires repeatedly on auto-remediation tasks | Pattern is mis-applied for this bug class — these bugs may need human reasoning rather than iteration |
| Verification passes but humans still see the bug | Verification gate is too narrow; the loop's "success" doesn't match human-meaningful success |
| Loop converges quickly on superficial fixes; same area regresses later | Pattern is patching symptoms not causes; consider mandatory human review at loop exit for that area |
| Iteration cap firing more often than success | Iteration cap is too low, or the pattern is being applied to bugs it can't solve — track the ratio over time |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Infinite loop | Agent fixes the wrong thing; verification fails; agent fixes again; doesn't converge | Per-task iteration cap (e.g., 5 cycles); on exceeding, escalate with full diagnostic trail |
| Wrong-bug fix | Agent observes a symptom but addresses a different one; original bug remains | Verification must include the *originally observed* failure case, not just "tests pass" or "no console errors" |
| Token burn through cap | Agent loops are expensive; cap fires; work abandoned mid-cycle | Pre-allocate budget before starting; cost caps with force-over-cap typed-confirm (§9.7); meta-cap on number of loops per day |
| Plausible-but-wrong fixes | Each iteration produces code that compiles but doesn't fix the actual issue | Require visible, observable, *human-meaningful* verification — not just lint/format/type-check pass |
| Loop hides regression | Auto-remediation fixes the reported bug but introduces a regression elsewhere; only the targeted test is checked | Full test suite must pass at loop exit, not just the targeted test |
| Sanity-savings illusion | Pattern adopted because it sounds appealing; actual contributor time savings never measured | Track time-saved-per-loop vs. token-cost-per-loop over the first 30 days; if savings don't materialize, deprecate the pattern |
| Observation-fix decoupling | Loop's observation captures one signal; fix targets a different signal; verification checks yet a third | All three (observe / fix / verify) must reference the same anchor artifact; the loop is broken at design time if they don't |

**Cross-references:**

- §3b Systematic Debugging — the human-driven version of the same diagnostic loop; this sub-section is its agentic counterpart
- §3 Multi-Layer Test Infrastructure — provides the verification gate
- §3e Refactoring Discipline — fix step must avoid bundled refactoring
- §9.7 Cost Caps and Budget Gates — non-negotiable prerequisite
- §4 Agent Runtime Security — kill switches, sandboxing, identity isolation
- §14 Agent Approval Gates — SOFT minimum; HARD for any out-of-sandbox actions
- §14 Modes of AI Use — the implementation mode is what runs inside each cycle
- §0.6 "Cargo-culting practices" — applies to auto-remediation patterns adopted without first asking whether *this* project's bottleneck is attention or token cost

---

### §30.2 Production Agentic CI *(placeholder — content pre-staged)*

This sub-section is reserved for production agentic-CI workflow patterns — token-usage logging that's distinct from per-session §9.7 cost tracking, daily/episode-level auditing, portfolio-level optimization across multiple workflows, misconfiguration / fallback-loop detection.

The seam is identified; the content awaits demand. Likely scope when populated:

- **Workflow-level token logging** — measure cost at the workflow/episode level (not per-session), with attribution by workflow identifier
- **Episode analysis** — what does a "successful" workflow run cost vs. a "failed" one; do failed runs burn more or less; are there hot workflows that dominate spend
- **Portfolio optimization across workflows** — when multiple workflows run on the same project, the cost-cap framework needs to consider portfolio-level limits, not just per-workflow
- **Misconfiguration detection** — workflows that retry forever, workflows that fall back to expensive models silently, workflows whose output isn't being consumed
- **Fallback-loop detection** — the workflow falls back to a more capable (and expensive) model on failure; the fallback itself fails; the loop continues; cost spikes

This is the autonomous-CI counterpart to §30.1's interactive-debugging pattern. Both burn tokens; both need cost discipline; the specific failure modes differ.

---

### §30.3 Workflow Cost Patterns

Agent workflows have cost shapes that interactive sessions don't. The cost-cap framework in §9.7 covers per-task / per-session / per-day caps — this section covers the *cost shapes* that workflow patterns produce and the containment strategies specific to each shape.

| Cost shape | Where it shows up | Containment strategy |
|---|---|---|
| **Loop cost** | Closed-Loop Auto-Remediation (§30.1); recursive remediation patterns | Per-task iteration cap; pre-allocated budget; meta-cap on loops-per-day |
| **Recursion cost** | Sub-agent dispatch that spawns further sub-agents | Depth cap; per-dispatch budget; cross-link to §14 sub-agent guidance |
| **Fallback chain cost** | Workflow retries through multiple providers/models on failure | Cap on fallback depth; explicit fallback policy (when does the agent stop trying); attribution per fallback step |
| **Polling cost** | Workflow that watches for an external signal and burns tokens on each check | Token cost of "no change" responses accumulates; backoff strategy; meta-cap on poll duration |
| **Bench cost** | §3 Multi-Provider Behavioral Testing matrix | Schedule full matrix nightly; gate critical cells per commit; pre-flight cost estimation |
| **Idle agent cost** | Agent left in a "waiting for input" state across long timeouts | Idle timeouts; sessions that don't end cleanly accumulate cost on heartbeats |

Each shape has a different cost profile and a different containment strategy. The interactive caps in §9.7 apply to all of them; the *shape-specific* containment lives here.

**Cost-shape audit cadence.** Quarterly is reasonable. The audit asks: for each workflow we run, what cost shape does it produce, and is the containment strategy in place? If a workflow produces a shape with no matching containment, the next surprise-spend incident is just a matter of time.

---

### §30.4 Anti-Patterns Specific to Autonomous Workflows

These extend §0.6's anti-pattern table with patterns specific to agent-as-substrate workflows. The §0.6 anti-patterns ("Adopting everything at once", "Cargo-culting practices", etc.) apply universally; these are workflow-specific.

| Anti-pattern | How to spot it | Watch signal | Mitigation |
|---|---|---|---|
| **Observer-fixer drift** | Workflow has separate observe and fix steps; over time, the observation criteria and the fix criteria drift apart — agent fixes something the observer didn't actually flag | Audit recent loop iterations: does each fix correspond to an explicit observed failure? If observe-fix mismatches accumulate, drift is real | Each loop iteration logs both the observed signal and the fix; reconciliation in code review |
| **Verification-too-narrow** | Loop's verification gate checks one signal; agent fixes the signal but breaks something else; loop exits clean despite regression | Verification of "fixed" is single-test or single-screenshot; full suite isn't run at loop exit | Verification at loop exit must include broader regression check, not just the targeted signal |
| **Token-burn-to-failure** | Workflow burns through cost cap without finding a fix; cap fires; work is abandoned; no diagnostic learning captured | Cap fires; the diagnostic trail is discarded along with the failed work | On cap fire, the diagnostic trail (observations + hypotheses + fixes tried) must persist; escalation to human includes the trail so the next attempt builds on it |
| **Sanity-savings illusion** | Pattern adopted because it "saves sanity"; nobody measures whether sanity is actually saved | No data on time-saved-per-loop or token-cost-per-loop; pattern is justified by feel | Track both metrics over the first 30 days; if savings don't materialize, deprecate; if they do, expand carefully |
| **Workflow-level dark debt** | Workflow runs autonomously; results aren't reviewed; failures don't propagate to human attention | Workflow has been running for weeks; nobody can summarize what it did or what it caught | Workflow output must surface to human review on a cadence (per-incident at minimum); §4 agent log discipline applies |
| **Fallback-as-default** | Workflow falls back to expensive model on first failure; over time the fallback becomes the steady state; primary model is never used | Cost shifts toward fallback-model spending without anyone deciding to make that shift | Treat fallback rate as a watch signal; if fallback fires >X% of runs, investigate why the primary fails so often |
| **No idle timeout** | Agent left in waiting state; heartbeat costs accumulate; nobody notices until the bill arrives | Sessions that don't end cleanly; sessions with long quiescent periods between activity | Idle timeouts on long-running workflows; sessions auto-terminate after N minutes of no productive activity |

---

### Cross-references

- §14 Agent Orchestration — the building blocks this extension composes
- §9.7 Cost Caps and Budget Gates — per-task / per-session / per-day caps that bound every workflow
- §4 Agent Runtime Security — kill switches, sandboxing, identity isolation; non-negotiable substrate
- §4 Agent Log Discipline — workflow output must reach human review on some cadence
- §3 Multi-Layer Test Infrastructure — verification gates for closed-loop workflows
- §3b Systematic Debugging — the human-driven counterpart to §30.1
- §0.6 Onboarding Anti-Patterns — universal anti-patterns; §30.4 extends with workflow-specific ones
