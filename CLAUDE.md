# Umami — Project Instructions

This repository contains `umami.md` (a development guardrails template) and its domain-specific extensions. The content is consumed by both humans and LLM coding agents. Every file is a Markdown document — there is no application code.

## What this repo is

A **process template**, not a software project. There are no tests, no builds, no dependencies. Quality is measured by clarity, internal consistency, and correct cross-references — not by CI passing.

## Status

`v3.0` merged into `develop` 2026-05-13 (architectural reframe: landing + 4 core companions + repo reorg into `core/`, `ext/`, `recipes/`). **Currently shipping on `develop`; `main` tag pending validation against external projects.** Last updated: 2026-05-16.

**Just shipped (v3.0 → develop):**
- Landing-doc-as-index architecture; Tier 1 fetch now ~13K tokens (was ~40K monolithic)
- 5-skill audit family: `umami-init`, `umami-audit`, `umami-auto-review`, `umami-pipeline-audit` (new 2026-05-16), `umami-drift-audit`
- Trust Posture sub-section (§4); §6b Developer Experience and Pipeline Health (new section); §30 agent-workflows extension
- Risk taxonomy with auto-merge thresholds + Cross-provider review (§3d, 2026-05-16); Closed-Loop PR Review workflow (§30.5, 2026-05-16)
- Velocity-balance anti-patterns: "Security investment outpaces threat model", "Pipeline cargo cult", "Winchester Mansion sprawl"
- `recipes/` directory seeded with `consulting-timesheet.md` and `closed-loop-pr-review.md` placeholders
- 14 deprecation stubs at pre-v3 paths (removed in v3.1)

**Active gaps** (tracked in [`audits/gaps.md`](audits/gaps.md)):
- `v3 multi-file architecture not yet validated at scale by external adopters` — closes on first external adopter completing the bootstrap flow
- `§3d risk taxonomy + cross-provider review + §30.5 closed-loop PR review not yet validated across projects` — closes when ≥2 projects run the full pattern for ≥1 release cycle
- Plus ~15 "not yet validated across projects" entries for individual v3.0 practices (Trust Posture, §6b, untrusted-content boundaries, etc.) — same shape, awaiting field validation

**v3.1 scheduled work** (per `audits/v3.0-retro.md`):
- Remove all 14 deprecation stubs at pre-v3 paths
- Roll up §20 (WordPress) and §21 (Drupal) content into §25 (CMS); delete `ext/cms/umami-wordpress.md` and `ext/cms/umami-drupal.md` entirely (section numbers stay reserved)
- Refine v3.0 practices based on external-adopter feedback

**Next planned tag:** v3.1 — CMS rollup + stub removal + first-pass external-adopter refinements.

**v3 file architecture:**
- `umami.md` — Landing (framework + Section Navigation Map + §0 + §1 + §3b + §6 + §13 + §15 + Security Essentials sidebar)
- `core/umami-quality.md` — §2 · §3 · §3c · §3d · §3e (specs, testing, decisions, review, refactoring)
- `core/umami-runtime.md` — §4 · §5 · §6b (runtime validation, security disciplines, state recovery, pipeline health)
- `core/umami-process.md` — §7 · §8 · §10 · §12 (docs, gaps, propagation, change tracking)
- `core/umami-agents.md` — §9 · §11 · §14 (token efficiency, file budgets, orchestration)

**Next available extension section:** §31.

See [`audits/v3.0-retro.md`](audits/v3.0-retro.md) for the v3 architectural decision record and [`docs/decisions/`](docs/decisions/) for individual ADRs.

## Files

| File | Role |
|------|------|
| `umami.md` | Landing document — framework, Section Navigation Map, §0, §1, §3b, §6, §13, §15, Security Essentials sidebar. **Lives at repo root and never moves** (single stable URL across the entire framework). |
| `core/umami-quality.md` | Core companion — §2 specs, §3 testing, §3c decisions, §3d review, §3e refactoring |
| `core/umami-runtime.md` | Core companion — §4 runtime + security disciplines, §5 state recovery, §6b pipeline health |
| `core/umami-process.md` | Core companion — §7 docs, §8 gaps, §10 propagation, §12 change tracking |
| `core/umami-agents.md` | Core companion — §9 token efficiency, §11 file budgets, §14 orchestration |
| `ext/umami-web.md` | Web frontend extension — §17 |
| `ext/umami-data.md` | Data pipelines extension — §18 |
| `ext/umami-iac.md` | IaC / DevOps extension — §16 |
| `ext/umami-mobile.md` | Mobile extension — §19 |
| `ext/cms/umami-cms.md` | CMS shared extension — §25 |
| `ext/cms/umami-wordpress.md` | WordPress extension — §20 (loads with §25). **Planned rollup into §25 in v3.1** — file will be removed; content folds into `ext/cms/umami-cms.md`. |
| `ext/cms/umami-drupal.md` | Drupal extension — §21 (loads with §25). **Planned rollup into §25 in v3.1** — file will be removed; content folds into `ext/cms/umami-cms.md`. |
| `ext/umami-compliance.md` | Compliance / regulated industries extension — §22 |
| `ext/umami-scripting.md` | Scripting / CLI automation extension — §23 |
| `ext/umami-integration.md` | Systems integration extension — §24 |
| `ext/umami-homelab.md` | Homelab infrastructure extension — §26 |
| `ext/desktop/umami-desktop.md` | Desktop application shared extension — §27 |
| `ext/desktop/umami-linux.md` | Desktop Linux extension — §28 (loads with §27) |
| `ext/desktop/umami-spa-wrapper.md` | SPA wrapper extension — §29 (loads with §27 + §28) |
| `ext/umami-agent-workflows.md` | Agent workflows extension — §30 (closed-loop auto-remediation, production agentic CI, workflow cost patterns, anti-patterns, closed-loop PR review with risk-tiered auto-merge) |
| Deprecation stubs at pre-v3 paths | Short markdown files at the old root-level / `cms/` / `desktop/` locations that point readers back to `umami.md`. **Removed in v3.1.** Exist to keep legacy URL fetches from returning 404 during the v3.0 grace period. |
| `recipes/` | Drop-in implementation artifacts (cross-cutting features). Distinct from extensions: extensions guide *what to think about*, recipes provide *what to type / copy*. Independent of §0–§30 numbering. See [`recipes/README.md`](recipes/README.md). |
| `docs/decisions/` | Architecture Decision Records (ADRs) — individual records of significant architectural decisions. Distinct from `audits/` retros: ADRs cover one decision; retros cover a release window. See [`docs/decisions/README.md`](docs/decisions/README.md). |
| `tools/check-refs.sh` | Architectural fitness function (§3) — verifies every `§N` cross-reference resolves to a defined section. Run before commits per the pre-commit checklist below. |
| `README.md` | Public-facing documentation, adoption guide, comparison tables |
| `LICENSE` | CC BY-SA 4.0 |
| `audits/` | Per-release retros (`v1.0-retro.md`, `v2.1-retro.md`, `v3.0-retro.md`) and rolling [`gaps.md`](audits/gaps.md) — see §8 for the retro/registry distinction |

## Section numbering

Core sections are §0–§15. Extensions use §16+ (assigned per extension, see table above). New extensions get the next available number. Section numbers are **stable identifiers** — they are cross-referenced across files and must never be renumbered.

## File layout conventions (v3.0+)

The repo follows a three-tier layout:

- **Landing at the repo root.** `umami.md` is the single stable entry point. It carries the framework, Section Navigation Map, and Tier 1 practices. **This file never moves.** Every adopter's `CLAUDE.md` points here; breaking this URL cascades to every downstream project.

- **Core companions under `core/`.** `core/umami-{quality,runtime,process,agents}.md` hold the Tier 2+ practices of core sections (§2–§14), grouped by concern. Section numbers stay stable; the file each section lives in is metadata declared by the landing's Section Navigation Map.

- **Domain extensions under `ext/`.** `ext/umami-{web,data,iac,mobile,compliance,scripting,integration,homelab,agent-workflows}.md` hold per-domain guardrails. Each extension is a self-contained Tier-2+ practice catalog for that domain.

- **Shared+variant extension clusters under `ext/{domain}/`.** When an extension has a shared base + per-platform sub-extensions, group them in a domain subdir. The shared file and variants live together: `ext/cms/umami-{cms,wordpress,drupal}.md`, `ext/desktop/umami-{desktop,linux,spa-wrapper}.md`. New shared+variant domains follow this rule.

**Stability rules:**

- The landing path (`umami.md`) is the single most important URL — never move it.
- `core/` and `ext/` paths are external contracts too: moving a file means breaking every downstream `CLAUDE.md` that references it. Restructure only at major-version boundaries.
- Section numbers (`§N`) are independent of file location. Cross-references use plain `§N`; file is metadata.

**Deprecation stubs (v3.0 → v3.1 transition):** Stubs remain at the pre-v3 paths (root-level extensions, `cms/`, `desktop/`) pointing readers back to the landing. These are deprecated and removed in v3.1.

## Change Propagation Map

When you make changes to this repo, multiple files often need coordinating updates. Consult this map before marking any change as complete.

| Change type | Files touched (in order) |
|---|---|
| **Add a new extension file** | 1. Create `umami-{name}.md` with next available §number → 2. `README.md`: extension table, URL list, CLAUDE.md example block, "What the document covers" extensions table → 3. `umami.md`: Process Audit Reference URL list, §0.5 mapping table if the extension maps to specific core sections → 4. This file (`CLAUDE.md`): Files table above |
| **Add a new core section** | 1. **Decide which file the section belongs in** (landing, quality, runtime, process, or agents) — use the concern boundaries documented in v3.0 retro → 2. Add the section to that file → 3. `umami.md`: update Section Navigation Map (new row); update §0.5 mapping table if applicable → 4. `README.md`: "What the document covers" core table (with **File** column) → 5. `umami.md` §0.6: adoption tier tables → 6. `README.md` tier table → 7. `umami.md` §15 checklist if the section produces a pre-commit artifact |
| **Add a subsection to an existing core section** | 1. Find which file holds the parent section → 2. Add subsection there → 3. `README.md`: update section description if the subsection changes what the section covers → 4. If the subsection is a new practice, add to appropriate tier in §0.6 + README tier tables → 5. If the subsection adds a new Cost profile, follow the §4 *Reading the cost profiles* scheme |
| **Move a section between core files** | 1. Move the section verbatim (preserve all internal cross-refs) → 2. `umami.md`: update Section Navigation Map (change File column for that row) → 3. `README.md`: update "What the document covers" core table (change File column) → 4. Audit cross-refs in all files for the moved section — update any that need file hints → 5. Note in `audits/gaps.md` or commit message that the move happened |
| **Update the Section Navigation Map** | 1. `umami.md` Section Navigation Map → 2. `README.md` "What the document covers" core table — these must mirror each other exactly |
| **Rename or re-describe a section** | 1. The file that holds the section → 2. `umami.md` Section Navigation Map → 3. `README.md` section description tables → 4. Any other files that cross-reference the renamed section |
| **Add cross-references between core files** | 1. Source file (the one adding the reference) → 2. Use plain `§N` notation — file is metadata, section number is the stable identifier. On first occurrence per section, optionally hint *"(in `umami-X.md`)"* for navigation; subsequent occurrences use plain `§N`. |
| **Update adoption tiers** | 1. `umami.md` §0.6 → 2. `umami.md` Section Navigation Map (the Tier column) → 3. `README.md` tier tables → 4. `README.md` "What the document covers" if the tier change reflects a depth shift |
| **Update §0.7 (audit), §0.7b (init), §3d (code review), §6b (pipeline audit), or §8 (drift audit) protocol** | 1. The file that holds the protocol (`umami.md` for §0.7/§0.7b; `core/umami-quality.md` for §3d; `core/umami-runtime.md` for §6b; `core/umami-process.md` for §8) → 2. corresponding skill template in `.claude/skills/` (`umami-audit.md` / `umami-init.md` / `umami-auto-review.md` / `umami-pipeline-audit.md` / `umami-drift-audit.md`) — mirror the change and bump `**Last synced:**` to today's date → 3. `README.md` "Get started" section if the bootstrap one-liner or invocation language changes |

## Writing conventions

- **Voice:** Direct, imperative, second-person ("Document the boundary," not "One should document the boundary").
- **Audience:** The primary reader is an LLM coding agent. The secondary reader is a human developer. Write for both — clear enough that an agent follows it without ambiguity, readable enough that a human skims it efficiently.
- **No fluff:** Every sentence should either define a practice, explain why it matters, or provide a concrete example. If a sentence does none of these, delete it.
- **Cross-references:** Use `§N` notation (e.g., "see §4 for runtime validation"). Never use page numbers or vague references like "see above."
- **Tables over prose:** When listing practices, requirements, or mappings, prefer tables. They're faster to scan for both humans and agents.

## Pre-commit checklist (for changes to umami itself)

Umami applies §15-style checklist discipline to its own commits. Before pushing a substantive change, walk through this checklist — most failures here are recoverable in seconds but expensive if they ship.

**Structural integrity:**
- [ ] If a section was added, moved, or renamed → Section Navigation Map in `umami.md` updated to match
- [ ] If a section was added or moved → Change Propagation Map below was consulted; all listed files for the change type were touched
- [ ] If a new practice was added → §0.6 Tier table (in `umami.md` AND `README.md` — mirrored) has the corresponding row
- [ ] If a new sub-section was added → README.md "What the document covers" core table reflects the change
- [ ] Cross-references audited: `tools/check-refs.sh` exits 0 (no orphan §N references)

**Skill family consistency:**
- [ ] If §0.7 / §0.7b / §3d / §6b / §8 was edited → corresponding skill in `.claude/skills/` was mirrored; `Last synced:` bumped to today's date
- [ ] If a new audit-shaped protocol was introduced → corresponding skill file was created in `.claude/skills/`

**File layout:**
- [ ] Landing (`umami.md`) stays at repo root — never moves
- [ ] New core companion files (rare) land in `core/`; new extensions land in `ext/` (or `ext/{domain}/` for shared+variant clusters)
- [ ] If a file was moved across paths → deprecation stub left at the old path until the next major release; documented in retro

**Documentation and history:**
- [ ] If a major architectural decision was made → ADR added to `docs/decisions/` (separate from per-release retros in `audits/`)
- [ ] Status block in this CLAUDE.md updated if `v3.x` shipped or scheduled work changed
- [ ] If a new practice was added → gap-registry entry created in `audits/gaps.md` for "not yet validated across projects" (the framework's own validation discipline)

**Security:**
- [ ] No `.mcp.json`, `.mcp.local.json`, or other per-developer config staged (gitignored, but verify)
- [ ] No secrets or API tokens in staged content; spot-check with `git diff --cached | grep -iE 'token|password|secret|api[_-]?key'`

**Voice and cross-references:**
- [ ] Voice matches existing umami: direct, imperative, second-person; tables over prose for lists; no emojis unless explicitly requested
- [ ] §N notation used for cross-references (not page numbers, not vague "see above")
- [ ] First reference to a section in another file optionally hints at the file (e.g., "§6b in `core/umami-runtime.md`"); subsequent references use plain `§N`

The checklist isn't a CI gate — there's no CI on this repo. It's a manual discipline the human or agent runs through before committing. If a step finds a gap, fix and re-check. Items that don't apply to a given change can be checked through quickly.

## Branching

- `main` — released, tagged versions (currently v1.0)
- `develop` — active work, merged to main for releases

## What NOT to do

- Do not add application code, tests, or CI pipelines — this is a documentation repo.
- Do not renumber existing sections — cross-references across all files and downstream projects depend on stable numbers.
- Do not duplicate guidance between core and extensions — put it in one place and cross-reference.
- Do not add speculative sections ("we might need this someday") — only add practices that address a demonstrated need.
