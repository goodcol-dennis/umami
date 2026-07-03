# Umami — Project Instructions

This repository contains `umami.md` (a development guardrails template) and its domain-specific extensions. The content is consumed by both humans and LLM coding agents. Every file is a Markdown document — there is no application code.

## What this repo is

A **process template**, not a software project. There are no tests, no builds, no dependencies. Quality is measured by clarity, internal consistency, and correct cross-references — not by CI passing.

## Corpus vs. tooling boundary

This repo has three categories of content; the agent-agnostic rule applies to one of them. Developing umami with Claude Code is fine — what matters is that the *corpus* (what adopters consume) reads as harness-neutral.

- **Corpus** (`umami.md`, `core/`, `ext/`, `recipes/`) — what adopters fetch. **Must be agent-agnostic.** Substitute conventions (`CLAUDE.md` / `AGENTS.md` / `.cursorrules`), use harness-neutral hook category names (see §14), don't assume one harness's schema. When showing a reference implementation, label it as such (e.g., the activity-stream recipe's "Harness scope" callout) and map known harnesses below.
- **Dev tooling** (`.claude/skills/umami-*.md`, `.claude/settings.local.json`, `tools/`) — what the maintainer uses to *develop* the corpus. Claude-Code-shaped is fine; this never reaches adopters.
- **Installer artifacts** — files an adopter's `/umami-init` writes into their project to wire the corpus into their harness. Necessarily harness-specific (each agent has different config schemas). The current installer is Claude-Code-shaped; a future Cursor/Aider/Codex/Goose installer would be a parallel artifact, not a replacement.

If a corpus file drifts toward Claude-Code-specific assumptions, that's the slip to fix — see commit `b0fed0f` (2026-05-27 neutrality pass on §14 + `recipes/activity-stream.md`) for the worked example.

## Status

`v3.0` released to `main` 2026-05-27 (tag `v3.0`; architectural reframe: landing + 4 core companions + repo reorg into `core/`, `ext/`, `recipes/`). **`main` now carries v3.0; canonical bootstrap + skill-fetch URLs point at `refs/heads/main`.** `develop` is the active branch for v3.1 work. The "not yet validated across projects" gaps below remain open — release doesn't gate on them; they close as external adopters report. Last updated: 2026-07-03.

**Just shipped (v3.0 → develop):**
- Landing-doc-as-index architecture; Tier 1 fetch was ~13K tokens at the v3.0 split (vs ~40K monolithic). **Regrown to ~30K by 2026-07** — stale claims corrected corpus-wide 2026-07-03; slimming pre-staged in `audits/gaps.md`
- 5-skill audit family: `umami-init`, `umami-audit`, `umami-auto-review`, `umami-pipeline-audit` (new 2026-05-16), `umami-drift-audit`
- Trust Posture sub-section (§4); §6b Developer Experience and Pipeline Health (new section); §30 agent-workflows extension
- Risk taxonomy with auto-merge thresholds + Cross-provider review (§3d, 2026-05-16); Closed-Loop PR Review workflow (§30.5, 2026-05-16)
- Velocity-balance anti-patterns: "Security investment outpaces threat model", "Pipeline cargo cult", "Winchester Mansion sprawl"
- `recipes/` directory seeded with `consulting-timesheet.md` and `closed-loop-pr-review.md` placeholders (`consulting-timesheet.md` was reframed and renamed to `activity-stream.md` in v3.1 — see below)
- 14 deprecation stubs at pre-v3 paths (removed in v3.1, see below)
- **Init auto-chains into `/umami-audit` on successful apply** (§0.7b step 7, 2026-05-22) — bootstrap ends with a baseline findings report instead of a "skills installed" hand-off message. Audit's own four-option findings-disposition dialog still runs. Skipped when user picks **Skip** at the init dialog. Surfaced from a real bootstrap where init completed but no audit fired.
- **§2b Async Channel Contracts** (`core/umami-quality.md`, 2026-05-22) — typed channel + origin tag + allowed-consumer list + audit-on-add. Structural parallel to §4 untrusted-content discipline (same four-part pattern, different scope: reachability instead of trust). Addresses four leaky-async failure shapes (global bus / untyped payload / catch-all UI surface / shared worker-output display). Tier 3 escalation = fitness function. New `Leaky async interfaces` anti-pattern in §0.6 with watch signal. Surfaced from an adopter project where async messages surfaced in the wrong part of the app.

**Just shipped (v3.1 → develop):**
- **All 14 v3.0 deprecation stubs removed** (2026-05-27) — root-level extension stubs (`umami-web.md`, `umami-data.md`, etc.) plus `cms/` and `desktop/` subdir stubs are gone. Legacy pre-v3 paths now 404. The §0.5 mapping table in `umami.md` and the URL list in `README.md` were updated to point at `ext/` paths; `/umami-init` still detects legacy paths in adopter `CLAUDE.md` files and offers migration. Also fixed already-broken sibling refs in `ext/cms/` and `ext/desktop/` that shipped in v3.0 (`../umami-cms.md` and `../umami-desktop.md` patterns).
- **`recipes/activity-stream.md` shipped Drafted** (2026-05-27) — consolidated activity stream with multi-source capture: `Stop` hook for Claude turns, `post-commit` git hook for commits, `/log` skill for manual entries, `/refine-log` skill for periodic LLM cleanup. Replaces the prior Planned `consulting-timesheet.md` placeholder, which was reframed from "session log for billing" into the broader "activity stream with billing as primary use case." Surfaced from a real consulting cycle where the memory-based predecessor (single Claude source, no hook) proved unreliable — the recipe is the §14 hook-implemented version of that pattern, resolving §0.6's "From now on when X without a hook" anti-pattern.
- **Three folds from Osmani/Saboo/Kartakis 2026 *The New SDLC with Vibe Coding*** (2026-05-27) — §7 cross-implementation research applied to the corpus itself. (a) New §0.6b *AI-Discipline Spectrum* (vibe coding ↔ structured AI-assisted ↔ agentic engineering) framed as orthogonal-to-tiers — a Tier 3 project still vibe-codes prototypes; a Tier 1 project applies full agentic engineering to its security boundary. Six-dimension table after the paper's Table 1. (b) New §3 *Tests and Evals — verification's two halves* sub-section codifying that tests verify deterministic parts (function in → out) and evals verify non-deterministic agent behavior (trajectory, tool choice, output quality), and without both the posture sits closer to vibe coding regardless of prompt sophistication. (c) New §0.6 anti-pattern *Accepting AI's 80% as 100%* with watch signal (pick 3 PRs, ask author about failure modes / edge cases / integration; vague answers confirm the gap). All three cite the Google paper as source.
- **Five folds from Osmani 2026 *Agentic Code Review*** (2026-05-27) — §7 cross-implementation research applied to §3d. (a) New §3d sub-section *Why agentic code review is structurally different* — review went from "verify author's visible reasoning" to "reconstruct intent the agent generated but discarded," explaining why review takes 3–4× longer even when the code is competent (Faros 2026: review duration +441.5%). (b) Three-axis decomposition (*blast radius / code lifespan / knowledge-sharing scope*) added to §3d Risk classification as cross-cutting scaling factors on top of the existing dimensions — the tier is `max()` of the three axes, not the average. Catches the "prototype that shipped by accident" failure mode (cross-references §0.6b). (c) Empirical data citations (Faros, CodeRabbit, 4-tool heterogeneity study) added to ground §3d's claims. (d) §3d *Reviewer agent pattern* gains an explicit *test-change check*: any test modification not in pure rename/move form is a HIGH flag — agents under "make CI green" pressure rewrite assertions to match broken code; mutation testing is the strong falsifier. (e) Three new §0.6 anti-patterns: *Closed-loop self-review* (no external eye; correlated blind spots; 93.4% of issues caught by exactly one tool empirically), *Rewriting CI to make AI pass* (agents weaken gates rather than comply — gradient descent finds the cheapest path to green), *Accepting agent-rewritten tests uncritically* (assertions changed to match broken behavior; PR passes its own tests by construction). The user surfaced the three anti-patterns from direct recent experience.
- **Multi-model readability sweep + optimization pass** (2026-06-17) — ran the full corpus (~177K tokens) through four frontier models (Claude Opus, GPT-5, Grok-4.3, Gemini-2.5-pro) via a new single-shot fan-out (`b1review`, in the adjacent b1edit repo — dev tooling, reuses b1edit's `send_messages_with_usage`) plus `tools/build-review-corpus.sh`. This applied §3d *cross-provider review* to umami itself. Findings were adversarially verified against the source (2 model claims were false positives, discarded). Applied: **(A)** fixed ~18 broken intra-repo links (`core/`+`ext/` landing links missing `../`, `umami.md` §4 links missing `core/`, stale `audits/gaps.md` desktop links) and the §0.5 `§15`→`§3` visual-regression misref; **extended `tools/check-refs.sh`** with a second invariant — relative markdown links must resolve (the class the §N check couldn't see; found 2 breaks beyond the sweep). **(B)** disambiguated overloaded "tier" (§3d risk column → *Risk level*; §3 *Substrate tiers* → *Substrate levels*; new §0.6 terminology note anchoring all five axes); inlined the §4 cost-profile legend at first use in §2/§3; added a §0.7b harness-agnostic framing note for `.claude/` paths; added a landing **Where to Start** scenario table + init-vs-audit rule (resolved the one comprehension-probe failure all four models hit). **(C)** promoted §3d *test-change verification* to its own H4; added a §3 tests/evals bridge line; front-loaded a §2b-vs-§4 differentiation table; added a §0.7 audit step for spectrum/evals posture; added a grouped navigation index above the §0.6 anti-pattern table; added a §16–§30 extension index to the landing Nav Map. Tier-D single-source items deferred.
- **Self-gating mechanism + agentic-lifecycle coverage** (2026-06-18) — a second multi-model pass turned the four models from critics into *designers* of a gate for umami's own #1 risk (over-application / process bloat). All four converged unanimously on the same mechanism, applied as **§0.9 The Adoption Ledger**: default-deny on new process; the adopt decision as a **multi-spectrum convergence read** (pain · lifespan · blast radius · cost-to-carry · reversibility — adopt where they overlap, not a binary trigger); a light per-practice ledger (triggering evidence · cost · falsifiable kill-criterion · last-payoff); an **agent-executable evidence rule** ("doesn't have §X yet" is not a finding — breaks the §0.7 expansion bias); a **reverse/retirement gate** (Keep/Deprecate/Remove/Re-justify, default Deprecate); and a **30-day anti-overhead litmus** placed at the top of the landing. Framed honestly as *easing* the over-application pull, not eliminating it (the tension is structural). New §0.6 anti-pattern *Monotonic process accretion* (the reverse-gate as a diagnostic). §0.7 audit is now bidirectional (adopt + retire); §0.7b seeds the ledger; both skills mirrored (`Last synced:` 2026-06-18). Plus the four agentic-coverage gaps the opinion sweep surfaced, each shipped **already gated** (adopt-when trigger + cost profile + kill criterion — dog-fooding §0.9): **§3f** Eval Suite Management (`core/umami-quality.md`); **§14b** Prompt & Instruction-File Engineering, **§14c** Model-Version Pinning & Drift Detection, **§14d** Agent-Failure Debugging (all `core/umami-agents.md`). The convergence-as-truth-signal method (multi-model panel, adversarially verified, outliers discarded) is itself §3d's heterogeneity principle generalized from code review to process design.
- **Deep-inspection remediation pass (2026-07-03)** — four parallel critical-reader agents covered the full corpus (core companions / extensions / adoption surface); verified findings applied as fixes. **Correctness:** stale v3 token-cost claims corrected everywhere (~13K → measured ~30K; landing re-bloat gap opened in `gaps.md`); §3d Layer-2-coverage vs. Trivial-row contradiction resolved (Trivial skips pre-screen explicitly); §3c decisions-log misref (§7→§12); §11 "this very document" pre-v3 residue; §3d/flags-doc "tier"→"risk level" remnants; ADR 0005 added to `docs/decisions/README.md` index; `recipes/activity-stream.md` Stop-hook fixed to read the transcript at `transcript_path` (hook stdin carries no `messages` array — the `[claude]` capture path silently produced nothing). **Literal-following hazards:** §9.3 CODEBASE.md gains the reality-wins clause; §3e >5-files watch signal gains the rename/move exception; §29.8 `UserMediaPermissionRequest` auto-grant scoped to app domains (was a blanket mic/camera grant against broad SSO wildcards); §4/§14 retention tables reframed default-vs-policy (they contradicted their own "permanent is a handwave" rule); §6b tax math reframed behaviorally (context-switch/batching, not idle-minutes) and the all-Keep watch signal made honest. **Scale/gating:** §3d gains the solo-scale degradation paragraph; new-dependency risk moved Medium→High (supply chain — AI pre-screen can't vet a package); §2b adopt-when front-loaded; §5 opening gated per §0.9 (git+backups is the default story; content-addressed tracking is the deep end). **Skill sync:** `umami-auto-review.md` re-synced with §3d (test-change + CI-config HIGH rules — the 2026-05-27 mandated mirror that was missed) and §0.7b/init/README now agree that three of the five skills install on demand. Structural recommendations were applied the same day on maintainer approval — see the next bullet.
- **Structural remediation pass (2026-07-03, same day, maintainer-approved "apply all")** — the ten deferred structural recommendations executed. **Landing slimmed ~30K → ~25K tokens** (144KB → 118KB) by extracting the §0.6 anti-pattern catalog to `core/umami-anti-patterns.md` (landing keeps the grouped index; landing size is now a managed budget tracked in `gaps.md`). **`ext/umami-backend.md` shipped (§31**, gated per §0.9): authn/authz boundaries, session/token handling, expand→migrate→contract OLTP migrations, transaction boundaries & idempotency, ORM/N+1 discipline, pagination & error contracts, backend observability — closing the "most common adopter project type falls through every extension" gap. **§16/§24 pedagogy strip**: embedded SRE/integration-textbook tables removed (SLO tiers, golden-signals hierarchies, circuit-breaker state machines, HTTP-retryability and rate-limit-algorithm tables), rules/anti-patterns/checklists kept; §16.16 now points at §6b instead of duplicating it. **All 14 pre-§0.9 extensions retro-gated** (adopt-when trigger + cost profile + kill criterion at top; periodic checklists marked "menu, not a calendar"). **Audience tags** on the product-builder-shaped sections (§4 untrusted-content + agent-log-discipline, §14 approval gates, §9.7 cost caps) so audits stop recommending unbuildable practices to agent *users*; §4 log discipline / §5 runbooks / §6b gained the §0.9 adopt-when gates the newer sections already had. **Tag-pinned distribution** documented (landing *Pinning a version* note; §0.7/§0.7b hard-rule clauses mirrored into both skills: honor `refs/tags/vX.Y` pins — §14c applied to umami's own distribution, closing the fetch-and-obey supply-chain surface). **Dual licensing**: `LICENSE-CODE` (MIT) for code artifacts; prose stays CC BY-SA 4.0. **README restructured**: Quick start on the first screen, legacy-paths notice moved into Manual setup, pinning subsection, Licensing section. **`recipes/claude-md-starter.md` shipped Drafted** (distilled Tier-1 starter block — the zero-ceremony entry point; graduation triggers point into the full framework) plus **`.github/ISSUE_TEMPLATE/validation-report.md`** — the report-back funnel that the gap registry's ~28 "not yet validated across projects" entries resolve through. Quality-file redundancy cuts (§2 SDD survey table → prose, duplicate cost-profile legend, fitness-vs-gates bookkeeping table, §2b duplicate §4-parallel).

**Active gaps** (tracked in [`audits/gaps.md`](audits/gaps.md)):
- `v3 multi-file architecture not yet validated at scale by external adopters` — closes on first external adopter completing the bootstrap flow
- `§3d risk taxonomy + cross-provider review + §30.5 closed-loop PR review not yet validated across projects` — closes when ≥2 projects run the full pattern for ≥1 release cycle
- Plus ~15 "not yet validated across projects" entries for individual v3.0 practices (Trust Posture, §6b, untrusted-content boundaries, etc.) — same shape, awaiting field validation

**v3.1 scheduled work** (remaining; per `audits/v3.0-retro.md`):
- Roll up §20 (WordPress) and §21 (Drupal) content into §25 (CMS); delete `ext/cms/umami-wordpress.md` and `ext/cms/umami-drupal.md` entirely (section numbers stay reserved)
- Refine v3.0 practices based on external-adopter feedback

**Next planned tag:** v3.1 — CMS rollup + first-pass external-adopter refinements (stub removal already landed on develop).

**v3 file architecture:**
- `umami.md` — Landing (framework + Section Navigation Map + §0 + §1 + §3b + §6 + §13 + §15 + Security Essentials sidebar)
- `core/umami-quality.md` — §2 · §2b · §3 · §3c · §3d · §3e · §3f (specs, async channel contracts, testing, decisions, review, refactoring, eval suite management)
- `core/umami-runtime.md` — §4 · §5 · §6b (runtime validation, security disciplines, state recovery, pipeline health)
- `core/umami-process.md` — §7 · §8 · §10 · §12 (docs, gaps, propagation, change tracking)
- `core/umami-agents.md` — §9 · §11 · §14 · §14b · §14c · §14d (token efficiency, file budgets, orchestration, prompt/instruction-file engineering, model pinning & drift, agent-failure debugging)
- `core/umami-anti-patterns.md` — §0.6 anti-pattern catalog (full table; landing keeps the index)

**Next available extension section:** §32.

See [`audits/v3.0-retro.md`](audits/v3.0-retro.md) for the v3 architectural decision record and [`docs/decisions/`](docs/decisions/) for individual ADRs.

## Files

| File | Role |
|------|------|
| `umami.md` | Landing document — framework, Section Navigation Map, §0, §1, §3b, §6, §13, §15, Security Essentials sidebar. **Lives at repo root and never moves** (single stable URL across the entire framework). |
| `core/umami-quality.md` | Core companion — §2 specs, §2b async channel contracts, §3 testing, §3c decisions, §3d review, §3e refactoring, §3f eval suite management |
| `core/umami-runtime.md` | Core companion — §4 runtime + security disciplines, §5 state recovery, §6b pipeline health |
| `core/umami-process.md` | Core companion — §7 docs, §8 gaps, §10 propagation, §12 change tracking |
| `core/umami-agents.md` | Core companion — §9 token efficiency, §11 file budgets, §14 orchestration, §14b prompt/instruction-file engineering, §14c model pinning & drift, §14d agent-failure debugging |
| `core/umami-anti-patterns.md` | Core companion — §0.6 onboarding anti-pattern catalog (full table + watch signals; the landing keeps the grouped index). Fetched for onboarding an existing codebase or §0.7 audits, not every session. Extracted from the landing 2026-07-03 to restore the Tier-1 token budget |
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
| `ext/umami-backend.md` | Backend API services extension — §31 (authn/authz boundaries, session/token handling, OLTP migration discipline, transactions & idempotency, ORM/N+1, pagination & error contracts, backend observability). Complements §24: §31 is the service you own, §24 is the remote calls it makes |
| `recipes/` | Drop-in implementation artifacts (cross-cutting features). Distinct from extensions: extensions guide *what to think about*, recipes provide *what to type / copy*. Independent of §0–§31 numbering. See [`recipes/README.md`](recipes/README.md). |
| `docs/decisions/` | Architecture Decision Records (ADRs) — individual records of significant architectural decisions. Distinct from `audits/` retros: ADRs cover one decision; retros cover a release window. See [`docs/decisions/README.md`](docs/decisions/README.md). |
| `tools/check-refs.sh` | Architectural fitness function (§3) — verifies two invariants: every `§N` cross-reference resolves to a defined section, **and** every relative markdown link resolves to an existing file (the second invariant was added 2026-06-17 after a multi-model readability sweep found ~18 broken intra-repo links the §N check couldn't see). Run before commits per the pre-commit checklist below. |
| `README.md` | Public-facing documentation, adoption guide, comparison tables |
| `LICENSE` | CC BY-SA 4.0 — prose and guidance documents |
| `LICENSE-CODE` | MIT — code artifacts (fenced code blocks, `tools/` scripts, recipe implementation artifacts, skill/installer files), so adopters can embed them in proprietary codebases. Added 2026-07-03 |
| `audits/` | Per-release retros (`v1.0-retro.md`, `v2.1-retro.md`, `v3.0-retro.md`) and rolling [`gaps.md`](audits/gaps.md) — see §8 for the retro/registry distinction |

## Section numbering

Core sections are §0–§15. Extensions use §16+ (assigned per extension, see table above). New extensions get the next available number. Section numbers are **stable identifiers** — they are cross-referenced across files and must never be renumbered.

## File layout conventions (v3.0+)

The repo follows a three-tier layout:

- **Landing at the repo root.** `umami.md` is the single stable entry point. It carries the framework, Section Navigation Map, and Tier 1 practices. **This file never moves.** Every adopter's `CLAUDE.md` points here; breaking this URL cascades to every downstream project.

- **Core companions under `core/`.** `core/umami-{quality,runtime,process,agents}.md` hold the Tier 2+ practices of core sections (§2–§14), grouped by concern; `core/umami-anti-patterns.md` holds the §0.6 anti-pattern catalog (fetched for onboarding/audits — the landing keeps the index). Section numbers stay stable; the file each section lives in is metadata declared by the landing's Section Navigation Map.

- **Domain extensions under `ext/`.** `ext/umami-{web,data,iac,mobile,compliance,scripting,integration,homelab,agent-workflows,backend}.md` hold per-domain guardrails. Each extension is a self-contained Tier-2+ practice catalog for that domain.

- **Shared+variant extension clusters under `ext/{domain}/`.** When an extension has a shared base + per-platform sub-extensions, group them in a domain subdir. The shared file and variants live together: `ext/cms/umami-{cms,wordpress,drupal}.md`, `ext/desktop/umami-{desktop,linux,spa-wrapper}.md`. New shared+variant domains follow this rule.

**Stability rules:**

- The landing path (`umami.md`) is the single most important URL — never move it.
- `core/` and `ext/` paths are external contracts too: moving a file means breaking every downstream `CLAUDE.md` that references it. Restructure only at major-version boundaries.
- Section numbers (`§N`) are independent of file location. Cross-references use plain `§N`; file is metadata.

**Legacy paths (v3.1+):** Pre-v3 paths (root-level extensions, `cms/`, `desktop/`) no longer exist — the v3.0 deprecation stubs were removed in v3.1 and legacy URL fetches now 404. Adopters carrying old `CLAUDE.md` URL lists need to migrate to the `ext/` paths; `/umami-init` detects and offers automatic migration.

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
- [ ] Cross-references audited: `tools/check-refs.sh` exits 0 (no orphan §N references AND no broken relative markdown links)

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

- `main` — released, tagged versions (currently v3.0; tags v1.0, v2.0, v2.1, v3.0)
- `develop` — active work, merged to main for releases

## What NOT to do

- Do not add application code, tests, or CI pipelines — this is a documentation repo.
- Do not renumber existing sections — cross-references across all files and downstream projects depend on stable numbers.
- Do not duplicate guidance between core and extensions — put it in one place and cross-reference.
- Do not add speculative sections ("we might need this someday") — only add practices that address a demonstrated need.
