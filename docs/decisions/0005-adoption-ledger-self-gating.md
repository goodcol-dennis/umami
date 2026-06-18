# ADR 0005 — The Adoption Ledger: active self-gating against over-application

**Status:** Accepted 2026-06-18
**Authors:** Dennis Portello, Claude
**Related:** [§0.9](../../umami.md), [§0.6 anti-patterns](../../umami.md), [§0.7 audit protocol](../../umami.md), [`audits/gaps.md`](../../audits/gaps.md); decision informed by a four-model evaluation panel (Claude Opus / GPT-5 / Grok-4.3 / Gemini-2.5-pro)

## Context

A multi-model evaluation of the full corpus (four frontier models, different vendors, reviewing umami's agent-readability and then its genuine helpfulness) produced one **unanimous** finding: umami's single biggest risk is **over-application**. A framework that warns against process theater is itself a large body of process; its mere existence pulls readers — and especially autonomous agents, which "default to including everything referenced" — toward adopting more than a project needs. The maintainer confirmed this from lived experience: processes have been applied that added no value and slowed a project down.

umami already had defenses — adoption tiers (§0.6), per-practice "adopt when…" triggers, anti-pattern watch signals, §4 cost profiles, and "adapt the process, don't serve it." The panel's diagnosis was that all of these are **advisory and passive**: they describe when a practice is worth adopting but nothing *enforces* the call, so they fail exactly when discipline is scarce (deadline pressure, an eager agent). Three structural gaps were named and corroborated across all four models:

1. **No default-deny.** Nothing makes "don't adopt" the default; absence of a practice reads as a reason to add it.
2. **The audit is expansion-biased.** §0.7 audits "one tier above current" — it can only ever *add* practices, never review whether existing ones still earn their cost.
3. **No retirement mechanism.** Every "adopt when" lacks a paired "remove when." §8 catches dropped *designs*, §13 catches dead *code*; neither catches dead *process*. The corpus was monotonically additive.

A second sweep posed the gating question directly to the panel ("how should umami make itself self-gating?"). All four **converged on the same mechanism** — default-deny + a per-practice ledger recording why-adopted / cost / falsifiable kill-criterion / last-payoff + a retirement gate + an anti-overhead litmus + agent-executable pain-evidence. The convergence (four independent estimators landing on the same artifact) was treated as the signal, per the maintainer's "trend toward truth" framing and umami's own §3d heterogeneity principle.

The maintainer added two constraints: the decision is **never binary** ("evaluating a number of spectrums to find where they overlap and trend toward truth"), and the goal is to **ease the caveat, not eliminate it** (a framework about process discipline carries irreducible process weight).

## Decision

Add **§0.9 The Adoption Ledger** to the landing document (`umami.md`, Tier 1 / Foundation — a meta-gate that applies always):

- **Default-deny.** A practice is not adopted until it has a ledger entry. "This project doesn't have §X yet" is not a finding — this single rule breaks the §0.7 expansion bias.
- **The adopt decision is a multi-spectrum convergence read**, not a binary trigger: score a candidate against pain · lifespan · blast radius · cost-to-carry · reversibility, and adopt where several axes *converge*. One axis alone is noise; convergence gives a confidence gradient, which is the honest shape of the decision (and matches the §3d three-axis and §0.6b spectrum precedents).
- **A light ledger artifact** — one small markdown table, one row per Tier-2+ practice (triggering evidence · cost profile · falsifiable kill-criterion · last payoff). The machine-readable+scripted variant (proposed by one model) is an *optional Tier-3 escalation*, deliberately not mandated.
- **An agent-executable evidence rule** — the agent must cite a concrete project artifact (gap entry, retro line, commit/PR, co-change cluster, CI gap) as evidence of pain before recommending adoption.
- **A reverse/retirement gate** — a retirement pass runs alongside each §0.7 audit; every ledger row gets Keep / Deprecate / Remove / Re-justify, defaulting to **Deprecate** when ambiguous.
- **A 30-day anti-overhead litmus** placed at the top of the landing: name a value event in the last 30 days for 3 active practices, or you're carrying process you shouldn't.

Supporting changes: §0.7 audit becomes **bidirectional** (adopt + retire); §0.7b **seeds the ledger** on init; both audit/init skills were mirrored (`Last synced: 2026-06-18`); a new §0.6 anti-pattern *Monotonic process accretion* names the failure the reverse gate exists to catch.

Concurrently (same disposition, governed by the new gate): four agentic-lifecycle coverage sections the opinion sweep surfaced were added, each shipped **already gated** to dog-food §0.9 — §3f Eval Suite Management, §14b Prompt & Instruction-File Engineering, §14c Model-Version Pinning & Drift Detection, §14d Agent-Failure Debugging.

## Consequences

**Positive:**
- Converts the advisory machinery (tiers / triggers / watch signals / cost profiles) into something enforceable, with a single forcing function (the ledger entry).
- Closes the monotonic-accretion gap — the corpus is no longer one-way; process can now be retired by a scheduled, social-cost-lowering pass rather than heroics.
- Agent-executable: an autonomous agent can populate, audit, and retire from project-state evidence without "feeling pain."
- The convergence-read encodes the decision's real shape (a gradient, not a binary), consistent with §0.6b and §3d.
- The four new coverage sections demonstrate the gate in action rather than violating it.

**Negative / accepted trade-offs:**
- **The ledger is itself process.** If it stops being cheap or becomes rubber-stamped, it becomes the overhead it fights. The section says so explicitly and keeps the artifact minimal; whether it holds is unproven.
- **Default-deny can be over-applied** — a team could under-adopt practices that would genuinely help. The convergence-read and the agent-evidence rule are the counterweights, but the balance is judgment, not a formula.
- This pass *added* five sections (§0.9 + four coverage) to a corpus whose chief flaw is size. The mitigation is that §0.9 is the gate for exactly this, and the four coverage sections are all gated Tier-2/3 — but the irony is real and noted.
- The mechanism eases the over-application pull; it does **not** eliminate it. The tension is structural.

## Alternatives considered

**Option A — Leave gating advisory; sharpen the existing language.** Rejected: the maintainer's failure (process applied, no value, slowed the project) happened *despite* all five existing advisory defenses. More advisory text doesn't fix a discipline-at-scarce-moments problem.

**Option B — A binary trigger gate (`if !trigger then skip`).** This was the panel's first-instinct form. Rejected in favor of the multi-spectrum convergence read: adoption is genuinely not black-and-white, a single self-assessed predicate is gameable, and a binary pretends the caveat is gone (it isn't).

**Option C — Mandate a heavy machine-readable `gates.yaml` with embedded measurement scripts** (one model's proposal). Deferred to an optional Tier-3 escalation: mandating a scripted gate on every project would make the anti-overhead mechanism its own overhead — exactly the failure mode under discussion.

**Option D — Reduce corpus size instead (extract the anti-pattern table / sections to separate files).** Rejected as the primary move: size is a symptom; the disease is *adoption at decision time*. A smaller corpus that still over-applies hasn't solved anything. (Lightweight grouping was done separately in the readability pass.)

## Validation

Tracked in [`audits/gaps.md`](../../audits/gaps.md) — "§0.9 self-gating mechanism not yet validated across projects." The mechanism is internally consistent and convergent across four models, but **no project has yet run a ledger, a retirement pass, or the litmus.** Resolves when ≥2 projects maintain a §0.9 ledger for ≥1 release cycle and report whether default-deny + the convergence-read measurably reduce over-adoption, whether the retirement pass ever actually retires anything (vs. being add-only in practice), whether the ledger stays cheap enough to not become overhead, and whether an agent can populate it from project state unaided. Refine the spectrum axes, litmus thresholds, and ledger schema based on what surfaces. If the ledger proves to be net overhead in practice, this ADR is superseded and the mechanism demoted to advisory.
