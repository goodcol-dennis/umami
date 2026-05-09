# Gap Registry

Rolling state of open items, acknowledged asymmetries, and pending decisions in this repo. Distinct from per-release retros (which freeze the world at a tag) — this file is mutable; entries get added, statuses change, items close.

When an item closes, mark it ~~strikethrough~~ rather than delete — the closing matters as much as the opening.

| Item | Severity | Status | Trigger to resolve |
|---|---|---|---|
| **CMS sub-extensions §20 + §21 fold-in to §25** | Low (planned, not blocking) | Banner notes added 2026-05-08 ([cms/umami-wordpress.md](../cms/umami-wordpress.md), [cms/umami-drupal.md](../cms/umami-drupal.md), [umami-cms.md](../umami-cms.md)). Actual fold-in pending. | When §25 absorbs enough platform-specific surface area that §20/§21 become thin appendices, or when contributor capacity allows the merge. |
| **Linux is the only OS-specific desktop sub-extension under §27** | Acknowledged asymmetry | Scope-note banner added 2026-05-08 ([desktop/umami-linux.md](../desktop/umami-linux.md)) owning that the asymmetry reflects contributor experience, not principle. | When a contributor adds a macOS or Windows sibling sub-extension (PR welcome). |
| **§29 (SPA wrapper) is the narrowest extension in the corpus** | Acknowledged narrow-scope | Status banner added 2026-05-08 ([desktop/umami-spa-wrapper.md](../desktop/umami-spa-wrapper.md)) framing it as a worked example of §27 + §28 rather than a domain peer. | If §29 stops being maintained, or another wrapping pattern (Tauri, Wails, Electron-via-portal) emerges with comparable demand — at that point, retire, generalize, or fork. |
| ~~**[umami.md](../umami.md) at 1481 lines — past typical design-doc length**~~ | ~~Open question~~ | ~~**CLOSED 2026-05-08:** Path (a) chosen — §11 amended to acknowledge that documents whose section IDs are external contracts are exempt from the file-size budget. Renumber-or-split risk is documented; growth signal (read truncation) deferred to gap registry watch.~~ | ~~Original trigger superseded; new watch is "growth becomes untenable" tracked as a fresh entry below.~~ |
| **[umami.md](../umami.md) read-truncation watch** | Active monitoring | Successor to the closed entry above. §11 acknowledges the spec-ID-as-external-contract exemption but commits to revisiting if agents truncate the file on read or humans can't scan it. | If a contributor reports an agent truncating `umami.md` on a normal Read, or if the file grows past ~2500 lines without a clean orthogonal seam identified, escalate to extraction. Identify the candidate seam in this registry *before* the split becomes urgent. |
| **Watch-signal on commit `d039c7e` (2026-05-08)** | Active monitoring | Eight practices added in one commit — borderline "adopting everything at once" by this repo's own §0.6 doctrine. The audit on 2026-05-08 named the watch signal: *if the next 5 substantive commits don't reference any of the new sections (in commit messages, PRs, or follow-up edits), the additions were write-only and constitute documentation theater on this repo's own terms.* | Resolves naturally if subsequent commits cite §3c / watch signals / status block / retros / phase-session / multi-surface. Confirms anti-pattern if 5 commits pass without reference. Reassess at commit count `develop@d039c7e + 5`. |
| **No `v2.0` tag despite "v2.0 release" merge commit** | Historical artifact (cosmetic) | Noted in [audits/v2.1-retro.md](v2.1-retro.md). Merge commit `c04e58f` (2026-04-01) says "Merge develop into main for v2.0 release" but no annotated tag was created; v2.1 followed the next day. | Optional backfill (`git tag -a v2.0 c04e58f`) or leave as record. Low priority — affects release archaeology only. |
| **Production agentic-CI domain coverage** | Open question | A deliberate gap. The MCP-bloat work (commit forthcoming) covers progressive disclosure / cost measurement for interactive agent use. It does *not* cover production agentic CI workflows: token-usage logging, daily auditing, episode-level analysis, portfolio-level optimization across workflows, misconfiguration / fallback-loop detection. Two paths discussed: light-touch sub-section in §14, or a new §30 `umami-agentic-workflows.md` extension. | Resolves when (a) a contributor's projects exercise production agentic CI enough to motivate one of the two paths, or (b) demand surfaces from external adopters. Until then, deferred. |
| **ECC comparison numbers in README will drift** | Low (cosmetic / staleness) | [README.md](../README.md) cites specific ECC feature counts as of last update (170+ skills, 46 specialized subagents, 76 slash commands, language-specific rules for 13+ ecosystems). ECC is actively maintained; counts will change without notice. The comparative claim ("ECC is more comprehensive") survives drift, but specific numbers do not. | Re-verify annually against [the ECC repo](https://github.com/affaan-m/everything-claude-code), or when a contributor flags drift. Update README in lockstep, or soften to approximate forms ("~170+", "~45") if the maintenance burden is undesirable. |

## Adding entries

When opening a new gap, capture:

- **Item** — one-line description.
- **Severity** — Low / Medium / High, or qualitative ("acknowledged asymmetry", "open question", "active monitoring").
- **Status** — current state with date and file pointers if any.
- **Trigger to resolve** — the specific event or condition that closes the gap. Without a trigger, gaps accumulate without ever closing.

## Closing entries

Mark the row ~~strikethrough~~ and prepend `**CLOSED YYYY-MM-DD:**` to the Status cell. Don't delete — the historical record of *what was once open and how it closed* is part of the file's value.
