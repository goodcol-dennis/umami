# Umami — Project Instructions

This repository contains `umami.md` (a development guardrails template) and its domain-specific extensions. The content is consumed by both humans and LLM coding agents. Every file is a Markdown document — there is no application code.

## What this repo is

A **process template**, not a software project. There are no tests, no builds, no dependencies. Quality is measured by clarity, internal consistency, and correct cross-references — not by CI passing.

## Status

`v2.1` is the current released tag. **v3.0 is being prepared on the `v3-restructure` branch** — a major architectural reframe that splits the monolithic `umami.md` into a landing document + 4 concern-based companion files. Section numbers are stable across files; the landing's *Section Navigation Map* tells the agent which file holds each section. Tier 1 / Foundation fetches now use the landing alone (~13K tokens), down from ~40K for the v2 monolith.

After v3.0 merges, develop will carry the multi-file architecture; main will be tagged v3.0 when the user is ready.

**v3 file architecture:**
- `umami.md` — Landing (framework + Section Navigation Map + §0 + §1 + §3b + §6 + §13 + §15 + Security Essentials sidebar)
- `umami-quality.md` — §2 · §3 · §3c · §3d · §3e (specs, testing, decisions, review, refactoring)
- `umami-runtime.md` — §4 · §5 · §6b (runtime validation, security disciplines, state recovery, pipeline health)
- `umami-process.md` — §7 · §8 · §10 · §12 (docs, gaps, propagation, change tracking)
- `umami-agents.md` — §9 · §11 · §14 (token efficiency, file budgets, orchestration)

**In-flight rollups:**
- CMS sub-extensions §20 (WordPress) and §21 (Drupal) are marked for fold-in to §25 (general CMS) — banner notes added but rollup not yet executed.
- §29 (SPA wrapper) repositioned as a worked example of §27 + §28, not a domain peer; content otherwise unchanged.

**Next available extension section:** §31.

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
| **Update §0.7 (audit), §0.7b (init), §3d (code review), §6b (pipeline audit), or §8 (drift audit) protocol** | 1. The file that holds the protocol (`umami.md` for §0.7/§0.7b; `umami-quality.md` for §3d; `core/umami-runtime.md` for §6b; `umami-process.md` for §8) → 2. corresponding skill template in `.claude/skills/` (`umami-audit.md` / `umami-init.md` / `umami-auto-review.md` / `umami-pipeline-audit.md` / `umami-drift-audit.md`) — mirror the change and bump `**Last synced:**` to today's date → 3. `README.md` "Get started" section if the bootstrap one-liner or invocation language changes |

## Writing conventions

- **Voice:** Direct, imperative, second-person ("Document the boundary," not "One should document the boundary").
- **Audience:** The primary reader is an LLM coding agent. The secondary reader is a human developer. Write for both — clear enough that an agent follows it without ambiguity, readable enough that a human skims it efficiently.
- **No fluff:** Every sentence should either define a practice, explain why it matters, or provide a concrete example. If a sentence does none of these, delete it.
- **Cross-references:** Use `§N` notation (e.g., "see §4 for runtime validation"). Never use page numbers or vague references like "see above."
- **Tables over prose:** When listing practices, requirements, or mappings, prefer tables. They're faster to scan for both humans and agents.

## Branching

- `main` — released, tagged versions (currently v1.0)
- `develop` — active work, merged to main for releases

## What NOT to do

- Do not add application code, tests, or CI pipelines — this is a documentation repo.
- Do not renumber existing sections — cross-references across all files and downstream projects depend on stable numbers.
- Do not duplicate guidance between core and extensions — put it in one place and cross-reference.
- Do not add speculative sections ("we might need this someday") — only add practices that address a demonstrated need.
