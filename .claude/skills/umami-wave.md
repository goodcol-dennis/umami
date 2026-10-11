---
name: umami-wave
description: Run a pile of buildable, independent work unattended as waves, per recipes/wave-session.md. Fetches the recipe and follows its Run section — one series of batched prompts, then launches wave 1 and arms the watchdog. Opt-in; not the default way to build.
---

# umami-wave — Run a wave session

**Last synced:** 2026-10-11 from `recipes/wave-session.md` *Run* section. The procedure lives in the recipe, not here; re-derive this stub when the recipe's *Run* section changes shape.

## Invoke when

The human has a backlog of independent, buildable units and wants it built unattended — "run these as waves", "run this pile overnight", "start a wave session". Their asking is the decision; do not re-litigate it. For a single change or exploratory work, don't invoke — that is plain §14 delegation.

## Procedure

1. **Fetch the recipe fresh** from `https://raw.githubusercontent.com/goodcol-dennis/umami/<ref>/recipes/wave-session.md`, where `<ref>` is whatever the project's umami URL block uses (`refs/heads/main`, or a pinned `refs/tags/vX.Y`). If that ref 404s (the recipe is newer than the pin or the release), fall back to `refs/heads/develop` and say so in one line. If every fetch fails, stop.
2. **Follow the recipe's `## Run` section exactly.** It is the whole procedure: scan, scaffold, one series of batched prompts, launch, arm, hand off.
3. **Stop at the hand-off.** Between-wave work, watchdog passes and the close follow the recipe's checklists inside the running session.

## Hard rules (non-negotiable)

- The procedure is the recipe's; never improvise from memory of it.
- One series of batched prompts. Never a lone yes/no interruption; fold every question into a batch, recommended option first, priced.
- The gate is written into every brief before launch; no worker decides whether it merges.
- Default wave size is one or two; five or more only on the human's explicit, priced choice.
- The wake-up prompt points at `watchdog.md`; never inline the procedure.
- Classifier-sensitive acts go in the final manual-mode batch; if refused, report the exact words the human can say — never retry or reroute.
- Nothing reaches production, the customer or infrastructure from this skill or the watchdog it arms, except a named exception written into `watchdog.md`.
- Workers never touch the main checkout.
- Arm the watchdog in the same minute as the first launch, unasked.
