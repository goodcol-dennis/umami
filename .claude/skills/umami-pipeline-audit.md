---
name: umami-pipeline-audit
description: Periodic CI/CD pipeline audit. Measures cycle time, inventories gates, audits per-gate purpose, calculates the contributor-hour tax, and assesses whether the pipeline's guardrails match the team's size, risk profile, deployment model, and velocity expectations. Read-only — produces a findings report with proposed dispositions; user decides what to act on.
---

# umami-pipeline-audit — Periodic CI/CD pipeline audit

**Last synced:** 2026-05-16 from §6b (umami v3 multi-file architecture; guardrails-vs-needs fit; Impact + Effort + Quick-win on dispositions). Re-derive this skill from the current §6b when this date is >3 months old or when an audit reports structural drift.

## What this skill does

Audits the project's CI/CD pipeline (and inner-loop feedback budgets) against the §6b Pipeline Audit protocol. Two dimensions:

1. **Technical health** — cycle time, gate purposes, last-caught-something, inner-loop budgets, contributor-hour tax
2. **Guardrails-vs-needs fit** — whether the gate set as a whole is appropriately sized for the team's size, risk profile, deployment model, and velocity expectations

Sister to `umami-audit` (process maturity), `umami-init` (first-time setup), `umami-auto-review` (PR code review), and `umami-drift-audit` (dropped-item audit). Reviewing mode (§14): produces structured findings; users decide what to act on.

The pipeline is the operational substrate that runs every change. When it's healthy, it earns its cost in catches and confidence. When it drifts, it taxes every contribution silently — slow CI normalized, gates added per-incident and never removed, configs cargo-culted across projects regardless of context.

## When to invoke

- Quarterly is a reasonable default cadence
- After a team-size change (grew or shrank by 2× or more) — guardrail fit likely drifted
- After a risk-profile change (started handling secrets, payments, PHI; shipped a compliance-bound feature; gained authenticated users)
- After a deployment-model change (moved to continuous deploy, added canary, added staging environment)
- When contributors start skipping local CI ("works on my machine" reports increasing)
- When CI cycle time has been creeping up over consecutive months without anyone owning the trend

## When NOT to invoke

- For PR code review — use `/umami-auto-review`
- For process-maturity audits — use `/umami-audit`
- For surfacing forgotten designs / decisions — use `/umami-drift-audit`
- When the team is mid-incident or mid-release crunch (audit adds noise; wait for the next quiet window)
- More frequently than quarterly without specific cause (audit fatigue produces low-quality dispositions)

## Hard rules

- **Read-only.** Never modify pipeline configs, branch protection rules, or gate definitions during the audit. The output is a findings report with proposed dispositions; the user decides.
- **Cite specific gate names, file paths, and last-caught dates for every observation.** "The pipeline is slow" is opinion; "P99 CI duration is 28 minutes; `integration-tests` job accounts for 12 of those 28 minutes; no failure has been a real regression in the last 90 days" is a finding.
- **Each gate finding gets a proposed disposition.** Findings without dispositions are theater. Disposition options: Keep / Move local / Demote nightly / Remove / Add.
- **Both dimensions matter.** Don't skip the guardrails-vs-needs fit check just because the technical health looks fine. A pipeline can be fast and clean but mismatched to the team.
- **Default disposition leans against keeping debt.** If a gate has caught nothing meaningful in N months and the team can't name its purpose, default is Remove or Demote nightly — not Keep.
- **Never recommend more than 5 dispositions per audit run.** Larger lists overwhelm; batch the rest into the next quarterly run.
- **Always fetch the landing document fresh** from the canonical URL `https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md` (use `refs/heads/develop` only for bleeding-edge, not-yet-released practices). Never cache locally.
- **Consult the Section Navigation Map** in the landing to identify §6b's home (`core/umami-runtime.md`). Fetch that companion for the full audit protocol. Tier 1 / discovery only needs the landing; pipeline-audit scope requires the runtime companion.
- **If any fetch fails, tell the user and stop.** Do not fall back to a stale local copy.

## Procedure

1. **Measure cycle time** — gather P50 / P99 of pipeline duration over the last 30 days. Include queue time. Get the same numbers for any deploy or release pipeline that runs after merge. Note the trend over the prior 90 days (creeping up? flat? recently optimized?).

2. **Inventory gates** — enumerate every gate that runs as part of the pipeline. For each: name, what it checks, duration contribution to P99, last-caught-something date (if known), owner. Include manual approval gates, security scans, deploy gates, smoke tests post-deploy.

3. **Audit per-gate purpose** — for each gate, attempt to name (a) the specific failure mode it catches and (b) a recent example. If the answer is "we've always had it" or "for compliance" without naming the specific control, the gate is unmoored from its purpose. Flag for disposition.

4. **Calculate the tax** — cycle time × commits per day × contributors = contributor-hours per week spent waiting. Surface this as a concrete number; the team usually hasn't done this math and the number is often surprising.

5. **Check guardrails-vs-needs fit** — evaluate the gate set as a whole against the team's actual context, not just per-gate purpose:
   - **Team structure** — size, distribution, on-call coverage. A 2-person team rarely needs the same approval gates as a 30-person team.
   - **Risk profile** — regulated? user-facing? handles secrets, payments, PHI? Pipeline depth should match the §3d risk taxonomy the project actually carries.
   - **Deployment model** — continuous deploy vs. periodic releases vs. canary. Each implies different gate priorities.
   - **Velocity expectations** — does the team need fast inner loop for prototyping or strict outer loop for compliance evidence?
   Surface mismatches as findings: "under-guardrailed for current risk profile" (add gates), or "over-guardrailed for team size and risk surface" (remove gates).

6. **Check inner-loop feedback budgets** — measure local test runner, type checker, linter, full local build times against the §6b heuristics (5s / 3s / 1s / 30s). If any exceeds budget, the inner loop is taxing every iteration, not every push — often worse than slow CI.

7. **Propose dispositions** per gate: Keep / Move local / Demote nightly / Remove / Add. Each disposition includes the specific change required.

8. **Present findings** using the four-option dialog (per §0.7): apply all / selective walkthrough / do something else / skip. Self-contained prompt per §3b.

9. **Check for skill drift before finalizing.** Compare this skill's embedded shape against the freshly-fetched §6b protocol: count of audit steps, fit-check dimensions (4: team / risk / deploy / velocity), disposition options (5: Keep / Move / Demote / Remove / Add). Also check `Last synced:` against today. If structural drift OR `Last synced` is >3 months old, append a non-blocking `### Skill drift` callout to the report.

## Self-audit special case

When auditing **this repo itself** (the canonical umami source), umami has no CI pipeline — it's a documentation repo. State this explicitly in the audit's Scope line: *"No CI pipeline — this repo is a documentation framework. Pipeline audit not applicable."* The skill should exit early with that one-line note rather than fabricating findings.

## Output format

```markdown
## Pipeline Audit — [Project Name]

**Date:** YYYY-MM-DD
**Last audit:** [date if known]
**Scope:** CI/CD pipeline + inner-loop feedback budgets
**Cycle time:** P50 = Xm, P99 = Ym (over last 30 days)
**Contributor-hour tax:** ~N hours/week across the team

### Cycle-time trend
- 30-day P99: [number]
- 90-day P99 trend: [increasing / flat / improving]

### Gate inventory
| Gate | Duration share of P99 | Last-caught-something | Owner | Stated purpose |
|---|---|---|---|---|
| [name] | Xm | [date or "unknown"] | [team] | [1-line purpose or "we've always had it"] |

### Findings — proposed dispositions
1. [Gate name] (§ref) — [proposed disposition: Keep / Move local / Demote nightly / Remove / Add] — [why this addresses a real concern]
   - **Impact:** [specific improvement — cycle-time reduction, gate-mismatch closed, missing-coverage filled, gap-registry entry resolved]
   - **Effort:** [Agent-autonomous / Operator-required / Specialist · Hours/Days/Weeks/Months · One-time / Recurring / Architectural / Spend (per §4 *Reading the cost profiles*)]
   - **Quick win** *(only when concrete Impact AND Effort is Hours)*
   - **Changes required:** [config file lines / branch protection settings to adjust]
   - **Conflict risk:** [low / medium / high]
2. ...
(Maximum 5.)

### Guardrails-vs-needs fit assessment
| Dimension | Current state | Fit | Recommendation if mismatched |
|---|---|---|---|
| Team structure | [size, distribution] | [match / under / over] | [adjustments] |
| Risk profile | [regulated, secrets, etc.] | [match / under / over] | [adjustments] |
| Deployment model | [CD / release / canary] | [match / under / over] | [adjustments] |
| Velocity expectations | [fast-inner / strict-outer] | [match / over / under] | [adjustments] |

### Inner-loop budgets
| Signal | Measured | Budget | Status |
|---|---|---|---|
| Test runner (per-file watch) | Xs | < 5s | [in / over budget] |
| Type checker (incremental) | Xs | < 3s | [in / over budget] |
| Linter (on-save) | Xs | < 1s | [in / over budget] |
| Full local build | Xs | < 30s | [in / over budget] |

### Anti-patterns observed (if any)
Cite §0.6 "Pipeline cargo cult" or "Cargo-culting practices" if applicable. Name watch signals.

### Skill drift (only if detected)
*One line, non-blocking, outside the priority list.*

### After the audit
Read-only. Present a four-option dialog using `AskUserQuestion`:
1. **Apply all dispositions** — execute every gate change.
2. **Selective walkthrough** — one gate at a time per §3c.
3. **Do something else** — save to file, branch first, defer, narrow scope.
4. **Skip** — discard without action.
```

## After the audit — describe changes, then present the four-option dialog

Each disposition must describe the specific change required (which config file lines move; which branch protection settings adjust; which gate gets demoted to a nightly job; which gate gets added to address a now-real risk). Then surface the dialog per §0.7. Default to selective walkthrough for first-time runs — gate changes have operational consequences and benefit from per-item decisions rather than blanket approvals.
