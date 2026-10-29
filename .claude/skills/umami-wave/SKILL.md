---
name: umami-wave
description: Run a pile of buildable, independent work unattended as waves, per recipes/wave-session.md. Fetches the recipe and follows its Run section — plan with a critic, one series of batched prompts, then launches wave 1 as a build → review → finish pipeline under the budget guard and arms the hourly queue check. Opt-in; not the default way to build.
---

# umami-wave — Run a wave session

**Last synced:** 2026-10-29 from `recipes/wave-session.md` *Run* section (2026-10-29: step 2 scaffolds the status view — `./wave-status`, six fixed sections, *The status view*; previously 2026-10-21: plan-before-build with a critic; build → independent review → finish per item; the budget guard and build gate in place of the retired watchdog; the hourly queue check; merge on green after review). Previously 2026-10-11. The procedure lives in the recipe, not here; re-derive this stub when the recipe's *Run* section changes shape.

## Invoke when

The human has a backlog of independent, buildable items with IDs and wants it built unattended — "run these as waves", "run this pile overnight", "start a wave session". Their asking is the decision; do not re-litigate it. For a single change or exploratory work, don't invoke — that is plain §14 delegation.

## Procedure

1. **Fetch the recipe fresh** from `https://raw.githubusercontent.com/goodcol-dennis/umami/<ref>/recipes/wave-session.md`, where `<ref>` is whatever the project's umami URL block uses (`refs/heads/main`, or a pinned `refs/tags/vX.Y`). If that ref 404s (the recipe is newer than the pin or the release), fall back to `refs/heads/develop` and say so in one line. If every fetch fails, stop.
2. **Follow the recipe's `## Run` section exactly.** It is the whole procedure: scan, scaffold, plan (sweep → synthesize → critic), one series of batched prompts, cut the wave, read the build gate, launch, arm the queue check, hand off.
3. **Stop at the hand-off.** Queue checks, between-wave work, the retro and the close follow the recipe's checklists inside the running session.

## Hard rules (non-negotiable)

- The procedure is the recipe's; never improvise from memory of it.
- **No wave launches before the critic returns.** "Most of the queue doesn't depend on the sweep" is the failure, not a reason.
- One series of batched prompts. Never a lone yes/no interruption; fold every question into a batch, recommended option first, priced. Answers go to the numbered rulings file.
- Every wave row is one backlog item; its lane (and base branch), level, owned files and reserved IDs are written into the brief before launch; no agent decides them.
- Every item runs build → independent review (different model, mutant check) → finish; only the finisher merges.
- Read the build gate before launching; on STOP, hand off with the queue in place. Every agent reads the budget level and acts on it.
- Classifier-sensitive acts go in the final manual-mode batch; if refused, report the exact words the human can say — never retry or reroute.
- No agent reads or writes production; the orchestrator reads what a brief needs and hands it in as stated facts. The production dispatch happens only on the human's words in the current turn.
- Every scheduled job is listed with its id, schedule and prompt in the scheduled-jobs file; a wake-up's prompt points at a file, never carries the procedure inline. Polls that need no judgment run on model-free timers.
- Workers never touch the main checkout; worktrees live at a set path outside the repo.
- Arm the queue check in the same minute as the first launch, unasked.
- The status view is the recipe's (*The status view*): `./wave-status` at the project root, its six sections in their order and words, `unknown — <why>` for a missing input. Scaffold it when the project has none; never invent a project-specific layout.
