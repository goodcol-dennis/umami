---
name: Validation report
about: Report field experience with a umami practice — this is what closes the gap registry's "not yet validated across projects" entries
title: "[validation] <practice §N>: <one line>"
labels: validation-report
---

umami has no telemetry and no other feedback channel. The gap registry ([`audits/gaps.md`](../../audits/gaps.md)) carries a standing list of practices marked "not yet validated across projects," and every one of them resolves only through reports like this. Answer what you can; skip what you can't.

## 1. Which practice

State the practice or section (§N), which file you fetched, and which version — a tag (`v3.0`), branch (`main`), or fetch date.

Example: `§3d risk taxonomy, core/umami-quality.md, main as of 2026-07-01`

## 2. Project shape

Stack, number of layers, team size, and AI harness (Claude Code, Cursor, Aider, Codex CLI, Goose, other). No confidential details needed — "3-layer TypeScript web app, team of 2, Claude Code" is enough.

## 3. Trigger fit

Did the practice's "adopt when..." condition fire at the right time? Pick one and say why:

| Verdict | Meaning |
|---|---|
| Too eager | The trigger fired before the pain existed; the practice cost more than it returned |
| Too late | The pain hit well before the documented trigger said to adopt |
| Clean | The trigger matched the moment the practice started earning its cost |

## 4. What happened

Describe a concrete event: the practice caught or prevented a specific problem, or it demonstrably didn't earn its cost. This is the §0.9 litmus applied in the field — name a specific event where the practice paid off, or state that after N days you can't. Dates and specifics beat general impressions.

## 5. What you'd change

Thresholds that sit wrong, wording an agent misread, failure modes the practice doesn't cover, steps you added or dropped to make it work.

---

Partial reports welcome. A two-line answer to question 4 alone is useful — it is more field signal than the registry has today.
