# Umami — Protocols: Audit (§0.7) and Initialization (§0.7b)

This file is part of umami v3's concern-based file architecture. The landing document ([umami.md](../umami.md)) contains the framework, Section Navigation Map, and Tier 1 practices. This file holds the two *procedures* an agent follows when it runs an audit or an init — the protocols that `/umami-audit` and `/umami-init` execute. They were extracted verbatim from the landing on 2026-10-11 (ADR-0006) because they are needed only when a protocol *runs*, not on every session that loads the landing, and they are where every skill-family change lands.

**When to fetch this file:** when running a process audit (§0.7) or bootstrapping / upgrading umami in a project (§0.7b). The landing keeps a one-paragraph stub under each heading that points here; the bootstrap one-liner ("fetch `umami.md` and follow §0.7b") still resolves through that stub.

**Contents:**

- §0.7 Audit Protocol — How to Review Efficiently
- §0.7b Initialization Protocol — Bootstrapping Umami in a New Project

**Cross-references** in this file use plain `§N` notation. File location is metadata; section numbers are stable identifiers across all umami files. The adoption tiers (§0.6), the §0.5 mapping, the anti-pattern index and the §0.9 ledger these protocols read are in the landing.

---

### 0.7 Audit Protocol — How to Review Efficiently

Auditing the full document against a project is expensive — both in tokens and in time. A comprehensive audit of every umami file (landing + core companions + relevant extensions) can consume 70,000+ tokens. The umami v3 architecture is designed so most audits don't need that much: a Tier 1 audit needs only the landing document (~25K tokens as of 2026-07) plus the anti-pattern catalog when onboarding an existing codebase; a Tier 2 audit pulls in the one or two companion files that match the audit scope (~40–55K tokens). Use a tiered audit approach.

**For AI assistants performing an audit:**

**Audits are read-only by default.** An umami audit assesses process maturity and identifies gaps — it does not modify code, configuration, or project files. Do not restructure directories, add tests, insert logging, refactor code, or apply recommendations during the audit phase. The audit produces a findings report. The user decides what to act on, when, and how. See "After the audit" below.

1. **Determine the project's current tier.** Read the project's `CLAUDE.md`, test infrastructure, and documentation. Match the project's current state to the adoption tiers (§0.6, in the landing). Most projects are between Tier 1 and Tier 2.

2. **Audit one tier above current.** If the project is solidly at Tier 1, audit against Tier 2 practices. If it's at Tier 2, audit against Tier 3. Don't audit practices two tiers above — they'll create recommendations the project isn't ready to act on.

3. **Focus on gaps, not compliance.** The output should be: "Here are 3-5 specific practices from the next tier that would address problems you're currently experiencing." Not: "Here are 47 recommendations across all sections."

4. **Read selectively. Use the Section Navigation Map.** You do NOT need to fetch every umami file for every audit. Always fetch the landing document (`umami.md`) first — it carries §0 (discovery + framework), the Navigation Map, and Tier 1 practices. Consult the Navigation Map to identify which core companion files apply to the tier you're auditing. Tier 1 audits use landing alone; Tier 2 audits typically fetch one or two companions; Tier 3 audits may fetch more.

5. **Extensions only when relevant.** Only fetch domain extension files if the project has that domain layer AND is at Tier 2+. A Tier 1 web project doesn't need an audit against `umami-web.md` — it needs to get its basic testing and structure right first. The same principle applies to core companions: don't fetch `umami-agents.md` if the project isn't running agents at scale.

6. **For AI-feature projects, assess posture and verification.** Note the project's §0.6b AI-discipline spectrum position (vibe / structured / agentic) and whether verification covers *both* halves per §3 — tests for deterministic code, evals for non-deterministic agent behavior. A project operating in agentic posture with tests but no evals is a gap worth surfacing.

7. **Run the §0.9 retirement pass — the audit is bidirectional.** Auditing one tier above (steps 1–2) is the *adopt* half. The *retire* half reads the §0.9 adoption ledger and, for each adopted practice, checks its kill criterion and the 30-day litmus; practices that have stopped earning their keep get a **Deprecate / Remove** recommendation. An audit that only ever adds practices is itself the *Monotonic process accretion* anti-pattern (§0.6). Adoption recommendations follow default-deny: cite a concrete project artifact as evidence of the pain (per §0.9) — "the project doesn't have §X yet" is not a finding. Retirements use the same findings-disposition dialog as additions.

8. **Check framework freshness — surface what umami gained since this project's setup.** The spec evolves between audits; a project set up in May knows nothing about a skill or recipe added in October. Read what the project *has*: the URL block (files referenced, and the ref — `main` or a pinned tag), the installed `umami-*` skill files with their `Last synced:` dates, and the ledger. Compare against what the freshly fetched spec *offers*: the §16+ extension index and the §0.5 mapping (an extension that now matches the project's shape but isn't in the URL block), the §0.7b step-4 skill list (a skill not installed whose trigger discovery shows applies), and the recipes catalog (`recipes/README.md` — fetch it; it is small) for a recipe whose pointer section's trigger is met, or whose artifacts the project already keeps by hand. List every applicable item under `### New in umami since your setup` with what it is, why it applies *here* (a cited artifact — §0.9 still governs extensions and practices; a skill cites its §0.7b trigger; a recipe cites its pointer section or the latent evidence), and the install action. Items that exist but don't apply go under *Not yet relevant* with their trigger. The section sits outside the ≤5 recommendations. Then, **before the findings dialog**, ask once: a multi-select prompt listing the applicable items, those with cited evidence marked "(Recommended)". Selected items are installed by invoking `/umami-init` in **upgrade mode scoped to that list** (§0.7b — init writes the skill files and URL lines, seeds the ledger rows, and does not chain back into an audit). Nothing is written without that selection; the audit stays read-only.

**Audit output format:**

```markdown
## Process Audit — [Project Name]

**Current tier:** [1/2/3] — [brief justification]
**Auditing against:** Tier [2/3] practices

### What's working well
- [2-3 practices already solid]

### Recommended next practices (priority order)
1. [Practice] (§X) — [why this addresses a current pain point]
   - **Impact:** [specific improvement, tied to a watch signal or measurable signal where possible — e.g., "closes the §3d rubber-stamping watch signal; merge rate currently 8× human engagement", "eliminates ~14 contributor-hours/week per §6b tax", "resolves gap-registry entry X"]
   - **Effort:** Agent-autonomous / Operator-required / Specialist · Hours/Days/Weeks/Months · One-time / Recurring / Architectural / Spend (per §4 *Reading the cost profiles*)
   - **Quick win** *(flag only when Impact is documented anti-pattern / gap-registry entry / measurable pain reduction AND Effort is Hours)*
   - **Changes required:** [which files would be created, modified, or restructured]
   - **Conflict risk:** [low/medium/high — likelihood of affecting concurrent work]
2. [Practice] (§X) — [why this addresses a current pain point]
   - **Impact:** [...]
   - **Effort:** [...]
   - **Changes required:** [...]
   - **Conflict risk:** [low/medium/high]
3. [Practice] (§X) — [why this addresses a current pain point]
   - **Impact:** [...]
   - **Effort:** [...]
   - **Changes required:** [...]
   - **Conflict risk:** [low/medium/high]

### New in umami since your setup
- [Skill / recipe / extension] — what it is · why it applies here: [cited artifact or §0.7b trigger] · install: [files written]. *(Outside the ≤5 limit; omit the section when nothing new applies.)*

### Latent practices observed
- [Practice X] — evidence: [hook / script / file / pattern showing the team exercises this]. Currently uncodified in [target doc / spec section]. Recommendation: codify in [the project's CLAUDE.md / a process doc / surface for umami contribution if universally applicable].

### Not yet relevant
- [Practices that were checked but don't apply yet, with the trigger that would make them relevant]
```

This format keeps the audit focused and actionable. A project should come away with 3-5 concrete next steps, not a wall of recommendations.

**After the audit — describe changes, then present a four-option dialog:**

Each recommendation in the audit report must describe the specific changes it would require — which files would be created, modified, or restructured, and what the modification involves. This lets the team assess impact, spot conflicts with in-progress work, and make informed decisions before any code is touched.

If step 8 found applicable new options, ask about them first — one multi-select prompt, evidence-backed items marked "(Recommended)"; selections install through scoped `/umami-init`. Then present the findings dialog below. Once the report is complete, present a structured dialog asking how to proceed. Use the harness's structured-prompt mechanism (e.g., `AskUserQuestion` or equivalent) so the question is self-contained in its UI surface without requiring chat scroll-back — see §3b "Make each prompt self-contained."

| Option | What happens |
|---|---|
| **Apply all recommendations** | Execute every finding without further dialog. Appropriate when the user has sole ownership or has coordinated with their team. |
| **Selective walkthrough** | Step through each finding one at a time per §3c (Interactive Decision Planning). For each: present the recommendation, let the user choose apply / skip / defer / modify, lock the disposition before moving on. |
| **Do something else** (free-text prompt) | The user describes a different action — save findings to a file for team review, branch and apply, escalate to a teammate, defer to a specific date, narrow the scope, etc. The catch-all when none of the structured options fit. |
| **Skip** | Discard the findings without action. The audit was informational. |

The four options compose: *all / selective / other / none*. They cover the full disposition space without forcing a default the audit cannot know is right — *"save findings to a file"* is now an instance of "do something else," not a built-in default, because the right disposition depends on the user's situation (solo vs. team, urgency, branch state, coordination needs).

If the user chooses **Apply all** or **Selective walkthrough**, ask about active branches and in-progress work first. Use a dedicated branch for remediation. Prefer small, focused changes over sweeping refactors.

**This dialog pattern applies beyond audits.** Any workflow that produces a list of recommendations (code review, security review, pruning passes, dependency audits) should end with the same four-option dialog. The pattern is the standard disposition affordance for "here are N findings" reports.

**Standardize the invocation.** Create an `umami-audit` skill in your project's skill library (§14) so the audit is always triggered the same way — `/umami-audit` or equivalent — regardless of who runs it or which agent tool they use. The skill should embed the raw URLs and reference this protocol so the agent doesn't improvise the process.

**Skill drift detection.** The audit skill is a snapshot of this protocol frozen at skill-creation time; the canonical source is whatever §0.7 says when freshly fetched. To prevent silent drift between snapshot and source, every audit run performs two checks before finalizing the report:

- **Structural drift.** Compare the skill's embedded bootstrap against the freshly-fetched §0.7. Specifically: number of disposition options in the four-option dialog, number of hard rules, shape of the output-format block. If any differ, structural drift is present — the skill is mechanically out of sync with the published protocol.
- **Calendar drift.** Skill bodies should include a `**Last synced:** YYYY-MM-DD` line near the top, recording when the skill was last derived from §0.7. If that date is older than ~3 months, calendar drift is present — the skill may be substantively current, but the date warrants a sync check.

When either check trips, append a single non-blocking line to the audit report under a `### Skill drift` heading:

> *"Audit skill body diverges from §0.7 ({structural / calendar / both}). Re-sync recommended — derive a fresh `umami-audit.md` from the current §0.7."*

This callout sits **outside** the priority-ordered recommendations list and does **not** count against the ≤5 recommendations rule. It's a maintenance signal about the audit infrastructure itself, separate from process findings about the project.

**Hard rules for the audit skill** — encode these as non-negotiable constraints in the skill body, not just as suggestions in the audit text. Skills drift when their constraints are advisory; they hold when constraints are stated as rules:

- **Read-only.** Never modify code or docs during the audit. Even obvious cleanup belongs in a follow-up, not in the audit itself.
- **Always fetch the landing document fresh from the canonical URL** (`https://raw.githubusercontent.com/.../umami.md`). Never cache locally. The framework evolves; cached copies go stale silently. Projects that pin a release tag (see *Pinning a version* near the top of the landing document) substitute `refs/tags/vX.Y` for `refs/heads/main` — honor the pin, fetch that tag fresh, and note the pinned version in the report. If the project pins a release tag (`refs/tags/vX.Y` — see the pinning note under the landing's URL block), honor the pin: fetch the pinned tag, note the pinned version in the report, and flag — don't silently override — when the pin is more than one release behind.
- **Consult the Section Navigation Map.** Identify which core companion files (`umami-quality.md`, `umami-runtime.md`, `umami-process.md`, `umami-agents.md`, plus `umami-anti-patterns.md` when onboarding an existing codebase) and which domain extensions apply before fetching anything beyond the landing document. Fetch only what the audit scope requires.
- **If the fetch fails, tell the user and stop.** Do not fall back to a stale local copy. An audit against three-month-old guidance is worse than no audit — it produces confident, wrong recommendations.
- **Never recommend more than 5 things.** A wall of recommendations is not actionable. Prioritize ruthlessly.
- **Cite a file path or doc reference for every observation.** "The project lacks ADRs" is an opinion; "no files exist under `docs/decisions/`" is a finding.
- **Don't fetch companion or extension files unless they apply.** A Tier 1 audit doesn't need any companion file. A web project doesn't need `umami-data.md`. Confirm scope relevance before pulling.
- **Audit one tier above current — never two.** Recommendations the project isn't ready for create noise, not value.
- **Every recommendation cites Impact and Effort.** Impact names a specific improvement (anti-pattern closed, gap-registry entry resolved, measurable pain reduced — ideally with a falsifiable signal). Effort uses the §4 *Reading the cost profiles* scheme (Who · Magnitude · Shape). Both are required; vague impact ("improves quality") and vague effort ("not too bad") defeat prioritization. **Flag Quick win** only when Impact is concrete AND Effort is Hours; the flag dilutes if applied to medium-effort items. Unflagged recommendations are still actionable — readers prioritize from the Impact/Effort dimensions themselves.
- **Surface latent practices.** Beyond tier-gap recommendations, look for practices the team is *already exercising* that aren't yet codified — either in the project's own `CLAUDE.md` / process docs, or in umami's spec. Evidence: hooks doing something the docs don't describe, scripts doing operations not captured in process, conventions visible across commits but not in `CLAUDE.md`, gap-registry entries pre-staging work that isn't reflected in any tier-table practice. When found, recommend codification.
- **Check framework freshness every run** (step 8). An audit that reports on the project's practices but never on what umami itself gained since the project's setup leaves adopters on a frozen snapshot. The `### New in umami since your setup` section and its multi-select prompt are part of every audit; "nothing new applies" is a valid one-line outcome.

When the audit flags an anti-pattern, name the watch signal that would confirm or refute the verdict (see §0.6). Verdicts without falsifiers become opinion.

**Latent-practice findings are often the highest-leverage recommendations** because the team is *already paying the cost* of the discipline without getting the *benefit* of having it named — cross-referenceable in code review, teachable to new contributors, encodable as §3 fitness functions, citeable in commit messages, durable when contributors rotate. Codifying makes tacit knowledge into a contract.

### 0.7b Initialization Protocol — Bootstrapping Umami in a New Project

§0.7 covers recurring audits. This section covers the first-time setup — bringing umami into a project that doesn't yet reference it, or upgrading a partial setup.

**Bootstrap entrypoint (self-installing).** A project with no umami presence pastes one instruction into their agent:

> *"Set up umami in this project. Fetch https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md and follow §0.7b."*

The agent fetches the spec, follows this section, and during the apply phase installs `umami-init` and `umami-audit` skills locally. Subsequent runs use slash commands.

**This is a lightweight setup, not a framework install.** Init writes only URL references and small invocation-aid skill files. There is no framework copy, no runtime dependency, no library to keep updated. The umami spec stays at its canonical URL and is fetched fresh on every run; the local artifacts are just a way to make access to umami consistent and harness-recognized as commands.

**Harness note (reference implementation).** The paths below — `.claude/skills/…`, `.claude/settings.json` — are Claude Code's layout, used here as one concrete reference. On another harness, substitute its command/skill directory and config file (e.g., Cursor's `.cursor/`, Aider's config, a Codex/Goose equivalent). The skill *content* and the URL references are harness-neutral; only where they live changes. See §14 for the per-harness mapping.

**What gets stored locally vs. fetched fresh:**

- **Stored locally:** URL *references* to the canonical umami spec (in instruction files like `CLAUDE.md`) and *skill files* (`.claude/skills/umami-init.md`, `.claude/skills/umami-audit.md`) that describe *how to invoke* the protocol.
- **Never stored locally:** the umami spec itself. Always fetched fresh from the canonical URL on every audit/init run.

Skill files are invocation aids — they encode procedure shape, hard rules, and bootstrap text so the harness recognizes `/umami-init` and `/umami-audit` as commands. They do **not** contain a copy of umami.md. Drift between an installed skill and the canonical spec is detected per §0.7 (structural + calendar drift checks).

**Procedure for AI assistants performing initialization:**

1. **Detect current state.** Grep instruction file(s) (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.) for umami raw-fetch URLs (`raw.githubusercontent.com/…/umami`) — repo-page links or prose mentions of umami don't count as an installation. Determine starting state:
   - **None** — first-time setup.
   - **Partial** — some umami URLs present; missing relevant companion files, missing relevant domain extensions, or referencing extensions for layers the project doesn't have.
   - **Complete** — references match the project shape; recommend `/umami-audit` instead.
   - **Upgrade (scoped)** — invoked by `/umami-audit`'s framework-freshness step (§0.7 step 8) with the list of new options the user selected. Skip discovery; compute the diff for exactly those items; apply on approval; do not auto-chain back into an audit.

2. **Run §0.1–§0.4 discovery** interactively, one decision at a time per §3c when answers compound.

3. **Derive recommended URL set** via §0.5 mapping. The URL block always includes the **landing document** (`umami.md`). Core companion files (`umami-quality.md`, `umami-runtime.md`, `umami-process.md`, `umami-agents.md`; `umami-anti-patterns.md` is fetched during onboarding/audits rather than listed per-tier) and domain extensions are added based on the tier the project is targeting and which concerns apply. For Tier 1 / first-pass adoption, the URL block may legitimately list only the landing document plus relevant domain extensions — companion files can be added when the project escalates to Tier 2.

4. **Compute the diff:** adds (companion files + domain extensions to add to URL list), removes (rare; usually flag-only), and skill installations (`.claude/skills/umami-init.md` and `.claude/skills/umami-audit.md`, each with `**Last synced:** YYYY-MM-DD` set to today). The other four skills (`umami-auto-review`, `umami-pipeline-audit`, `umami-drift-audit`, `umami-wave`) install **on demand, not by default** — offer each only when discovery shows its protocol applies (§3d review at agentic velocity, §6b when the project has a CI pipeline, §8 when a backlog of designs/decisions exists, `recipes/wave-session.md` when a backlog of independent buildable units exceeds what a sitting clears and the human wants it run unattended) and include any accepted ones in the same diff.

5. **Show the user the proposed changes, then present the four-option dialog.** Enumerate every file that would be modified or created — paths, line counts, the exact URL block that would land in each instruction file, which skill files would be created or updated and at what `Last synced:` date. The user must be able to read the diff before deciding. Then surface the dialog (apply all / selective walkthrough / do something else / skip) per §0.7. Self-contained prompt per §3b.

6. **Apply on approval.** Update all detected instruction files in lockstep (a project with both `CLAUDE.md` and `AGENTS.md` gets identical URL lists in both). Write the skill files. Don't overwrite existing skill files without diffing first. **Seed the §0.9 adoption ledger** (`docs/umami-adoption.md` or equivalent): one row per Tier-2+ practice this init adopts, each with its triggering evidence (the concrete artifact found during discovery) and a falsifiable kill criterion. Adopt under default-deny — only practices a discovery artifact justifies; a bare URL-list entry is not an adoption.

7. **On apply, auto-chain into the first audit.** When step 6 actually wrote files, immediately invoke `/umami-audit` to produce a baseline process audit against the freshly-installed configuration. Announce the transition (*"Init complete — wrote {file list}. Running first process audit now…"*) and proceed without further confirmation; the user already consented to the workflow at the four-option dialog. The audit runs its full §0.7 procedure — read-only fetch, findings report, and its own four-option findings-disposition dialog at the end — so the user still chooses interactively what to act on. Init's job isn't done when the skills are on disk; it's done when the user has seen where they stand. If init was skipped at the dialog (no files written), do not auto-chain; hand off with *"Init skipped — re-invoke `/umami-init` when you're ready."* In **scoped upgrade mode** (invoked from an audit), never auto-chain — the audit is already running; return to it with the list of files written.

**Hard rules** mirror §0.7:

- Read-only by default. The four-option dialog gates every write; no destructive changes without explicit approval.
- Always fetch the landing document (`umami.md`) fresh from the canonical URL. Never cache locally. If the project pins a release tag, fetch that tag and preserve the pin in the URL block init writes.
- For Tier 2+ scope, fetch the companion files identified by the Section Navigation Map. Don't fetch companions speculatively.
- If the fetch fails, tell the user and stop. Don't fall back to a stale local copy.
- Cite a file path or doc reference for every observation.
- Drift detection applies to installed skills (see §0.7).
- **Auto-chain into `/umami-audit` on successful apply** (step 7). Printing a hand-off message and stopping leaves the user with installed skills but no view of their baseline; the bootstrap one-liner ends in a finding-bearing audit, not a confirmation message. Auto-chain only when files were written — skip the audit if the user chose **Skip** at the four-option dialog.

