# Rapid Development Guardrails — Project Template

This document is a template for establishing processes, testing strategies, and AI token efficiency practices that enable fast, reliable software development. It is intended to be adapted per-project and consumed by both humans and LLMs.

**This is a general-purpose template.** It must not contain references to any specific project, codebase, brand, or product. All examples should use generic descriptions. If you adapt this template for a specific project, do so in that project's own docs — not here.

**This file lives in the [goodcol-dennis/umami](https://github.com/goodcol-dennis/umami) repo** so it can be shared across projects. Do NOT copy it into a project's `docs/` folder. Instead, keep the URL in each project's `CLAUDE.md` as a reference for on-demand process audits.

> **A note on `CLAUDE.md`:** This template uses `CLAUDE.md` as the instruction file name throughout because it is the most widely recognized convention — Claude Code, Cursor, Windsurf, and other tools all read it. If your toolchain uses a different file (`.cursorrules`, `AGENTS.md`, `CODEBASE.md`, `copilot-instructions.md`), substitute accordingly. The practices are tool-agnostic; only the filename is convention.

```markdown
## Process Audit Reference
- Development guardrails (core): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
- Extension — Web frontend: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-web.md
- Extension — Data pipelines: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-data.md
- Extension — IaC / DevOps: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-iac.md
- Extension — Mobile: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-mobile.md
- Extension — CMS (shared): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-cms.md
- Extension — WordPress: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/cms/umami-wordpress.md
- Extension — Drupal: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/cms/umami-drupal.md
- Extension — Compliance: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-compliance.md
- Extension — Scripting: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-scripting.md
- Extension — Systems integration: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-integration.md
- Extension — Homelab: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-homelab.md
- Extension — Desktop (shared): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-desktop.md
- Extension — Desktop Linux: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/desktop/umami-linux.md
- Extension — SPA Wrapper: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/desktop/umami-spa-wrapper.md
  Do NOT fetch these every session. These are reference URLs for periodic process reviews.
  When the user asks you to audit the development process, fetch the core document and
  follow the tiered audit protocol in §0.7 — determine the project's current adoption tier,
  then audit one tier above. Do NOT read every section or fetch every extension. Focus on
  3-5 actionable recommendations, not comprehensive compliance. Audits are READ-ONLY —
  report findings and describe what changes each recommendation requires, but do not modify
  code or project files until the user explicitly chooses which recommendations to apply.
```

---

## 0. Project Discovery — Onboarding Questionnaire

Before applying any guardrails, establish what the project actually is. This template was originally written for web applications, but many projects are multi-layer systems where the web UI is just one surface. Applying web-centric guardrails to a data pipeline project (or vice versa) wastes effort and creates structural misfits.

**Run this questionnaire at the start of every new project.** The answers determine which sections of this template apply, which need adaptation, and which are irrelevant.

### How to Run This (for AI assistants)

Do NOT present these as blank questions and wait for answers. That wastes the user's time and your tokens. Instead:

1. **Explore first.** Read the project's CLAUDE.md, README, directory structure, existing docs, package files, and a sample of the source code. Most answers are discoverable from the codebase.
2. **Propose answers.** Fill in the questionnaire with your best understanding based on what you found. Be specific — cite file paths, quote config values, reference existing docs.
3. **Present for confirmation.** Show the user your proposed answers and ask them to correct anything wrong. Frame it as: "Here's what I understand about the project — what did I get wrong?"
4. **Capture corrections.** Any corrections from the user are high-value context. Write them into MEMORY.md or the project instruction file immediately.

This "propose-then-confirm" pattern typically costs 2,000-5,000 tokens for the exploration + one round of user confirmation. Asking blank questions and waiting costs the same in tokens but takes 4-6 rounds of back-and-forth and risks the user providing incomplete answers because they don't know what level of detail you need.

### 0.1 Project Identity

| Question | Why It Matters |
|----------|---------------|
| What is the project's name and one-line purpose? | Anchors every decision. A name that says "analysis" implies different guardrails than one that says "platform." |
| Who is the author / owner? | Establishes who makes final calls on architecture and scope. |
| What is the expected lifespan? (prototype / 1-2 years / 3-7 years / indefinite) | A 6-month prototype doesn't need ADRs. A 5-year platform does. |
| Who will maintain this after the initial build? (same team / handoff / unknown) | If handoff is expected, documentation and convention discipline must be higher. |
| Are there compliance or regulatory requirements? (SOC 2 / ISO 27001 / HIPAA / PCI DSS / FDA / none / unknown) | Compliance changes how strictly guardrails are applied. A hobby project can skip ADRs; a SOC 2-scoped service cannot. If compliance applies, ADRs (§7), acknowledged gaps (§8), change tracking (§12), test evidence (§3), and state tracking (§5) shift from "recommended" to "required" — they produce the artifacts auditors ask for. |
| What are the reliability, scalability, and maintainability priorities? | These three pillars frame every architecture trade-off. A system that must be highly reliable (medical, financial) needs redundancy, failover, and SLOs defined upfront. A system that must scale (marketplace, SaaS) needs stateless design and capacity planning. A system that must be maintainable long-term (handed off, multi-team) needs strict conventions, documentation, and modularity. Most systems need all three — but knowing which is the *primary* driver prevents over-engineering the others. |

### 0.2 System Shape — "What Kind of Thing Is This?"

Most projects are not single-layer. Identify all layers that apply:

| Layer | Present? | Description if yes |
|-------|----------|-------------------|
| **Data ingestion** | yes / no | Where does data come from? (APIs, files, databases, email, manual entry) |
| **Data warehouse / storage** | yes / no | What stores the data? (PostgreSQL, SQLite, S3, data lake) |
| **Data pipeline / transforms** | yes / no | Is there calculation or transformation logic between ingestion and consumption? |
| **API / service layer** | yes / no | Does a backend serve data to consumers? (REST, GraphQL, gRPC) |
| **Web frontend** | yes / no | Is there a browser-based UI? |
| **CLI / scripts** | yes / no | Are there operational scripts or CLI tools? |
| **Background jobs / scheduling** | yes / no | Are there scheduled or event-triggered processes? |
| **External integrations** | yes / no | Does the system talk to third-party services? (SharePoint, Slack, ERP, EDI) |
| **Infrastructure / IaC** | yes / no | Is there infrastructure-as-code? (Terraform, Pulumi, CloudFormation, CDK) |
| **Mobile app** | yes / no | Is there a native or cross-platform mobile app? (iOS, Android, React Native, Flutter) |
| **Desktop app** | yes / no | Is there a desktop GUI application? Which toolkit? (GTK4, egui, Qt, Electron alternative) Which platform(s)? (Linux, macOS, Windows) Is it a native app or an SPA wrapper? |
| **CMS** | yes / no | Is the project built on a CMS? Which one? (WordPress, Drupal, other) |

**Observability is a cross-cutting concern**, not a separate layer. Every extension includes domain-specific observability guidance (what to monitor, how to alert, what to log). If the system has components running in production, observability practices apply — you don't need a separate "observability layer" in the system shape.

**Why this matters:** A project with 4 layers needs a change propagation map organized per-layer, test strategies per-layer, and potentially different languages per-layer. A single-layer web app needs none of that.

### 0.3 Current State — "Where Are We?"

| Question | Why It Matters |
|----------|---------------|
| Which layers exist today vs. are planned? | Don't build guardrails for layers that don't exist yet. Add them when the layer starts. |
| Is there existing code, data, or documentation? | Adapting guardrails to existing work is different from greenfield. Don't restructure a working codebase just to match a template. |
| What has already been decided? (tech stack, hosting, patterns) | Settled decisions should be captured in ADRs immediately — not re-evaluated during onboarding. |
| What is explicitly out of scope? | Prevents scope creep. If the project won't have a mobile app, say so. |

### 0.4 Evolution Plan — "Where Is This Going?"

| Question | Why It Matters |
|----------|---------------|
| What is the MVP? Which layers are in the first deliverable? | Determines which guardrails to set up now vs. defer. |
| What's the expected build order? (e.g., data layer first → API → UI) | The change propagation map and test infrastructure should follow the build order, not be set up all at once. |
| Are there hard dependencies between layers? (e.g., "UI can't start until API exists") | Identifies the critical path and where to invest guardrail effort first. |
| What are the known risks or open questions? | Capture these in the technical debt audit immediately. Known unknowns are better than unknown unknowns. |

### 0.5 Applying the Template

Once the questionnaire is complete, use this mapping to determine which core sections and extension files apply:

| If the project has... | Apply these sections | Extension file | Skip or defer |
|-----------------------|---------------------|----------------|---------------|
| Data ingestion / pipelines | §3 (testing — data quality layer), §3b (TDD + debugging), §4 (validation), §5 (state tracking), §10 (change map per-layer) | [umami-data.md](umami-data.md) | §3 visual regression (no UI yet) |
| Database / warehouse | §2 (specs — schema contracts), §3 (test doubles for DB), §6 (strict types), §7 (data dictionary as living doc) | [umami-data.md](umami-data.md) | §7 UX audit (no UI) |
| API / backend | §2 (specs — API contracts), §3 (API/service tests + test doubles), §3b (TDD), §4 (validation), §6 (type checking) | [umami-integration.md](umami-integration.md) | §3 visual regression |
| Web frontend | §2 (design system), §3 (all test layers including visual), §3b (TDD), §7 (UX audit, style audit) | [umami-web.md](umami-web.md) | — (full template applies) |
| Mobile app | §2 (specs), §3 (unit + integration tests), §3b (TDD), §6 (strict types), §12 (release tracking) | [umami-mobile.md](umami-mobile.md) | §3 visual regression (use device matrix testing instead) |
| Infrastructure / IaC | §2 (specs — infra contracts), §6 (pinning), §7 (ADRs — cloud decisions), §8 (acknowledged gaps) | [umami-iac.md](umami-iac.md) | §3 visual/E2E, §4 runtime validation (use drift detection instead) |
| CMS (any) | §3 (testing), §3b (TDD), §6 (consistency — coding standards), §7 (ADRs — extension/architecture decisions), §8 (acknowledged gaps — extension risks) | [umami-cms.md](umami-cms.md) + platform file ([WordPress](cms/umami-wordpress.md), [Drupal](cms/umami-drupal.md)) | — |
| CLI / scripts only | §3 (unit tests), §3b (TDD + debugging), §6 (type checking), §11 (file size budgets) | [umami-scripting.md](umami-scripting.md) | §3 visual/E2E, §4 runtime validation UI, §7 UX audit |
| Multi-layer system | All sections, but **organize §10 (change propagation) per-layer** and **organize §3 (testing) per-layer**. Consider §1 workspace partitioning if discovery/analysis phase exists alongside application code. | All that apply | — |
| Compliance requirements | §2 (specs — contracts as evidence), §3 (test evidence), §5 (state tracking — audit trail), §7 (ADRs — decision traceability), §8 (acknowledged gaps — risk register), §12 (change tracking — change management records), §15 (checklists — process evidence). These shift from "recommended" to **required**. | [umami-compliance.md](umami-compliance.md) | Nothing skipped — compliance adds rigor, it doesn't remove sections. |
| Desktop app (native) | §1 (structure), §3 (unit + E2E tests), §3b (TDD), §6 (strict types, linting), §8 (acknowledged gaps — headless testing limitations), §11 (file size budgets) | [umami-desktop.md](umami-desktop.md) + platform file ([Linux](desktop/umami-linux.md)) | §3 visual regression (use headless E2E instead) |
| Desktop app (SPA wrapper) | §1 (structure), §4 (security — navigation policy, session persistence), §6 (consistency), §8 (acknowledged gaps) | [umami-desktop.md](umami-desktop.md) + [Linux](desktop/umami-linux.md) + [SPA Wrapper](desktop/umami-spa-wrapper.md) | §2 (specs — you don't control the web app), §3 multi-layer testing |
| Homelab / self-hosted infrastructure | §1 (structure — documented topology), §4 (security discipline), §7 (living docs as AI context), §8 (acknowledged gaps), §15 (checklists) | [umami-homelab.md](umami-homelab.md) | §2 (specs), §3 visual/E2E, §11 (file size budgets) |
| AI-assisted development (any project using agents) | §3c (interactive decision planning when designs compound), §3d (code review at agentic velocity), §9 (token efficiency), §14 (agent orchestration — delegation, modes of AI use, skills, parallel review, tool integration) | — | — |
| LLM-feature product (ships features that ingest external content via LLMs) | §4 (untrusted-content boundaries — typed wrapper, provenance, per-provider spotlighting, audit-on-add), §3d (add an "untrusted-content-surface" project-specific risk dimension), §9.6 (MCP and tool context costs apply to product-side LLM features), §14 (modes of AI use — products typically span all three) | — | §15 visual regression unless the product also has a UI |

**Extension files** contain domain-specific guardrails that supplement the core template. Each extension maps back to core sections, adds specialized subsections, and includes its own checklist items that extend §15. Only read the extensions that match your project's system shape — the core template plus relevant extensions is your complete guardrail set.

**Adapt the process, don't serve it.** This template is a starting point, not a compliance checklist. If a section doesn't fit your project, skip it — the "Skip or defer" column exists for this reason. If a recommended practice creates more overhead than value for your specific context, drop it and document why in an ADR (§7). The worst application of these guardrails is treating them as rules to satisfy rather than tools to use. A team that follows 8 sections well will outperform a team that mechanically follows all 15 poorly.

### 0.6 Adoption Tiers — Size the Process to the Project

Not every practice is equally valuable at every stage. Adopting everything at once on a new project adds process weight that outweighs the benefit. Instead, adopt in tiers — start with the foundations, then add practices when specific problems or project growth make them valuable.

**Tier 1 — Foundation** (every project, from day one)

These practices cost almost nothing to adopt and prevent the most common sources of waste — regressions, lost context, and agents working against a disorganized codebase.

| Practice | Section | Why it's foundational |
|----------|---------|----------------------|
| Project discovery | §0 | Know what you're building before applying guardrails |
| Predictable project structure | §1 | Agents and humans find things without searching |
| Phase / Session hierarchy for multi-sitting work | §1 | Gives commits, decisions, and roadmap a unit of work bigger than the commit and smaller than the milestone |
| Development discipline | §3b | TDD and systematic debugging prevent "fix one, break another" cycles |
| Security discipline | §4, §6 | Security bugs are the most expensive bugs — catch them by habit, not by audit |
| Enforced consistency | §6 | Types, linting, formatting, and dependency hygiene catch errors at build time |
| Dead code hygiene | §13 | Less noise means better signal for agents and humans |
| Pre-commit checklist | §15 (partial) | Catches common mistakes before they compound |

**Tier 2 — Structure** (adopt when the project outlives its first sprint)

These pay off when you start maintaining what you built, onboarding contributors, or returning to your own code after a break. Adopt individual practices as pain points emerge — you don't need the whole tier at once.

| Practice | Section | Adopt when... |
|----------|---------|---------------|
| Spec-first development | §2 | Features take more than one session to build |
| Multi-layer testing | §3 | The system has more than one layer (API + UI, pipeline + warehouse) |
| Interactive decision planning | §3c | A design has 3+ load-bearing decisions that compound on each other |
| Runtime validation | §4 | The system handles external input or runs in production |
| Documentation / ADRs | §7 | You make a decision you'll need to explain later (including to future you) |
| Token efficiency | §9 | Agent sessions are re-deriving the same codebase understanding |
| Status block in CLAUDE.md | §9.1 | The project ships in versions and a fresh session needs to know "where are we right now" |
| Progressive disclosure of context | §9.5b | MCP/tool count exceeds ~10, tool metadata > 30% of context, or workflows orchestrate deterministic multi-step tasks |
| Agent approval gate table | §14 | Project has agents taking consequential actions (write files, run commands, network access, sub-agent dispatch) |
| Recovery runbooks per stateful surface | §5 | Project has any persistent state surface that would be hard to reconstruct from scratch (config, credentials, sessions, working trees, indexed memory, etc.) |
| Lifecycle hooks for automated behaviors | §14 | Project has any "from now on when X, do Y" rules that need to fire automatically (memory and process docs cannot enforce these — only hooks can) |
| File size budgets | §11 | Files are long enough that agents truncate or miss context |

**Tier 3 — Scale** (adopt when complexity demands it)

These are heavier practices that solve real problems in larger, longer-lived, or compliance-bound projects. Applying them to a prototype adds drag without payoff.

| Practice | Section | Adopt when... |
|----------|---------|---------------|
| State tracking & recoverability | §5 | Stateful operations need rollback or audit trails |
| Acknowledged gaps + per-release retros | §8 | Tech debt is accumulating faster than it's being addressed, or releases need a frozen "what was true at vX.Y" record |
| Measuring efficiency over time (ET, run-frequency weighting) | §9.7 | You're optimizing across multiple recurring agent workflows or model tiers and need apples-to-apples cost comparison |
| Three-layer code review with AI pre-screen | §3d | Code generation outpaces human review capacity; the team is rubber-stamping or bottlenecking on review |
| Untrusted-content boundary discipline (typed wrapper / provenance / spotlighting / audit-on-add) | §4 | Project ships LLM-powered features that ingest external content (web fetches, user input, tool outputs, file contents) and reaches users in production |
| Multi-provider behavioral testing (provider × substrate-tier matrix) | §3 | LLM-feature product serves multiple providers and correctness depends on model behavior; bench reveals provider-specific quirks lib/bin tests can't reach |
| Agent log discipline (5-layer log + retention + review cadence) | §4 | Project has agents taking consequential actions in production where audit trail matters for incident response, compliance, or operational debugging |
| Cross-implementation research before foundational ADRs | §7 | Project is committing to a foundational architectural approach with meaningful trade-offs (agent loop, edit format, sub-agent model, auth framework, state-management pattern, etc.) |
| Cost caps and budget gates (per-task / per-session / per-day with force-over-cap typed-confirm) | §9.7 | Project runs agents at scale and cost predictability matters; per-task or per-day spend has surprised the team |
| Change propagation maps | §10 | Changes routinely touch 5+ files and contributors miss downstream impacts |
| Change tracking | §12 | Work spans multiple sessions and context is lost between handoffs |
| Agent orchestration | §14 | You're using multi-agent workflows or delegating to specialized agents |

**Extensions** follow the same logic: apply when the domain is present *and* the project has reached the maturity level where that guidance adds value. A WordPress site in its first week needs §20.2 security basics, not §20.8 production monitoring.

**How to move between tiers:** Don't promote the whole project at once. When you hit a specific pain point (regressions, lost context, agents repeating mistakes), check whether a Tier 2 or 3 practice addresses it. Adopt that practice. Periodic audits (§0.7) are designed to surface these moments.

### Onboarding Anti-Patterns

When onboarding a project to umami — especially an existing codebase — watch for these patterns. If you identify any during discovery or an initial audit, flag them and recommend the mitigation.

**Use the "watch signal" column to convert each anti-pattern from a description into a diagnostic.** A symptom describes the steady state once the anti-pattern has set in. A watch signal is a falsifiable check — a specific event that, if it does or doesn't happen by a specific point, confirms or refutes the verdict. Without watch signals, anti-pattern audits become subjective and easy to wave away ("we're not *really* doing documentation theater"). With them, the audit can resolve.

| Anti-pattern | How to spot it | Watch signal (falsifies / confirms) | Mitigation |
|---|---|---|---|
| **Adopting everything at once** | New project gets CLAUDE.md, change propagation maps, ADRs, multi-layer tests, and token efficiency practices before any application code exists. | Tier 2 + Tier 3 practices documented before Tier 1 has been exercised on real code. If the project is still adding process docs after session 5–10 without a runnable artifact, the verdict is confirmed. | Start with Tier 1 only (§0.6). Add higher-tier practices when specific pain points justify them, not preemptively. |
| **Process without product** | Days spent building guardrail infrastructure (instruction files, documentation scaffolding, test harnesses) before writing any application code. | No runnable slice exists past the session count where one would normally appear (typically 3–9 sessions, project-shape-dependent). Pick the threshold up front; past it, the anti-pattern is real. | Build something first. Add structure as the project grows. A working prototype with no CLAUDE.md beats a pristine process scaffold with no code. |
| **Documentation theater** | A heavy planning corpus exists, but subsequent sessions don't *consume* it. Decisions get re-litigated. Specs grow but aren't cited. The corpus exists; the workflow doesn't reference it. | Subsequent sessions re-derive what specs/ADRs/decisions already settle, instead of citing them. If you can't find the doc that drove the last 3 commits' decisions, it's theater. The signal is *consumption*, not volume — front-loaded planning is fine if it gets used. | Every document should be referenced by at least one workflow. Commits, PR descriptions, and session notes should cite the relevant ADR / spec / decision when one applies. If a document isn't being read, either integrate it into the workflow or delete it. |
| **Cargo-culting practices** | Change propagation maps on a 3-file project. Formal specs for a 10-line script. Multi-layer testing on a single function. Agent orchestration for a solo developer with one assistant. | A practice was adopted because it appears in the template, not because a specific pain point surfaced. If you can't name the pain the practice addresses on this project, the trigger hasn't fired. | Every practice in the tier tables has an "adopt when..." trigger. If the trigger hasn't fired, the practice is premature. More process is not inherently better — only process that addresses a real problem earns its cost. |
| **Made-up estimates** | The assistant offers calendar predictions ("this is ~2 weeks of work" / "10 sessions" / "we'll be done by Friday"). | Any time-based estimate appears in chat, commit messages, roadmap entries, or planning docs — sourced from the assistant. Calendar predictions are not the assistant's call. | Describe **scope**, not duration: subproblem count, relative size (S/M/L/XL vs. comparable past work), known-vs-unknown ratio. The user does velocity arithmetic — only they know their schedule, energy, and parallel commitments. Sessions are sized by goal, not by clock. |
| **Treating the template as law** | Rigidly following every recommendation instead of adapting to the project's context. Refusing to skip sections that don't apply. Forcing project structure to match §1 exactly even when it doesn't fit. | Audit findings cite "non-conformance" with sections that don't fit the project shape, instead of recommending adapt or skip. | Umami is a toolkit, not a compliance checklist. Skip what doesn't apply. Adapt what partially applies. The goal is better software, not template conformance. If a recommendation creates friction without solving a problem, it's the wrong recommendation for this project. |
| **MCP tool sprawl** | The agent has 5–10+ MCP tools loaded "just in case." Tool metadata is consuming a large fraction of every turn's context, often without the developer realizing. | Measure tool-metadata-as-percent-of-context on a representative session. If tool schemas exceed ~30% of context, the verdict is confirmed. Most projects need 1–2 core MCP servers, not 10. | Apply §9.6: prune unused tools first, prefer lazy-load architectures (§9.5b), wrap static servers behind a proxy if needed. The cheapest tool schema is the one not loaded this turn. |
| **Treats untrusted content as plain strings** | LLM-feature product reads external content (web pages, user messages, tool outputs, file contents) into untyped strings that flow directly to the model. New code paths frequently forget to sanitize; sanitize-on-read is scattered across the codebase. | If functions consuming external content take plain `String` parameters (rather than a typed `UntrustedContent<T>` wrapper), the verdict is confirmed. Audit-on-add doesn't catch it; the type system needs to make it uncompileable. | Apply §4 untrusted-content-boundary discipline: typed wrapper at every boundary, provenance tagging, per-provider spotlighting, audit-on-add at code review. |
| **No agent-approval gate table** | Project has agents taking consequential actions (write files, run commands, network access, sub-agent dispatch) but no single document codifying which actions are gated, at what severity, with what audit trail. New contributors discover gates by tripping them. | If the project has consequential agent actions but no `docs/agent-approval-gates.md` (or equivalent), the gates are implicit. Even one HARD action without a tabulated gate is a sign. | Maintain a gate table per §14 "Agent Approval Gates": HARD/SOFT/NONE severity, action class, user-visible surface, audit trail location, implementation pointer. Group by category. |
| **Runbooks-as-aspiration** | Per-stateful-surface runbooks exist on disk, but RTO/RPO targets are vague ("soon", "minimal") or restore steps haven't been exercised in >6 months. The runbook reads as policy, not procedure. | Pick the longest-untested runbook and run a recovery drill cold (without coaching). If it fails, the runbook is aspiration. RTO/RPO sections without numbers (just adjectives) are also a confirmed signal. | Apply §5 "Recovery Runbooks per Stateful Surface": numbered restore steps with prerequisites, concrete RTO/RPO numbers, quarterly drills rotating across surfaces. |
| **"From now on when X" without a hook** | Project documents an automated behavior ("we always log Y", "we never let the agent touch Z") in CLAUDE.md or process docs but no hook implements it. The agent doesn't perform the behavior; humans assume it's being done. | Search the project's harness configuration (`settings.json` or equivalent) for the corresponding event and predicate. If the doc says "always do X" but no PreToolUse / PostToolUse / SessionStart / Stop hook fires X, the verdict is confirmed. | Apply §14 "Lifecycle Hooks": wire automated behaviors through the harness's hook layer. Doc-only "always do X" rules are aspiration unless they're hook-implemented. |
| **Single-provider testing for multi-provider product** | LLM-feature product serves multiple providers (Anthropic / OpenAI / Gemini / etc.) but the behavioral bench / E2E suite runs against only one. Production paths through other providers ship without behavioral verification. | Count the providers the product serves vs. the providers covered in the bench matrix. If serves > covered, the gap is silent regression risk. Often surfaces post-incident: "we shipped a tool-schema change; it works on Anthropic but Gemini rejects it because we never tested." | Apply §3 "Multi-Provider Behavioral Testing": matrix of providers × substrate tiers; gate critical cells per commit; full matrix nightly or per-release. Real-provider RTT, not just mocks. |
| **Agent logs without review** | Project ships agent activity logs to a sink (disk, observability platform, S3) but nobody actually reads them. The retention policy looks compliance-shaped; nothing ever gets queried. | Ask when the agent log was last queried for anything other than incident response. If "never" or "I don't know," the log is write-only. If retention is set in months but no review cadence is documented, the log exists for paperwork, not for audit. | Apply §4 "Agent Log Discipline" review-cadence guidance: weekly tool-call scan, per-release error-layer review, per-incident forensic reconstruction, quarterly field-utility review. If review doesn't happen, drop the logging cost. |
| **ADR alternatives without research depth** | ADR has an "alternatives considered" section that names 1–3 alternatives in 1–2 sentences each. Reader can't tell what kind of audit went into the rejection — was it a deep read, a README skim, or just the assistant's training-data summary? | If an ADR doesn't cite a research doc, ask the author when the alternatives were last deep-read and what concrete dimensions were compared. If the answer is "we just knew" or "it's industry consensus," the audit didn't happen. | Apply §7 "Cross-Implementation Research": pair foundational ADRs with a dated research doc, comparison matrix, and tiered steal-list. The research doc gives the ADR's rejection reasoning auditable depth. |
| **Cost caps in policy doc but not in code** | Project documentation states "max $X per day for agent operations" but no enforcement exists in the harness configuration. Cost overruns happen and post-hoc retros say "well we have a policy" — but the policy never blocked anything. | Search the harness configuration (`settings.json`, hook configurations, etc.) for cap enforcement. If the doc says max $X but no hook / setting / runtime check enforces it, the verdict is confirmed. Cap-without-enforcement is aspiration. | Apply §9.7 "Cost Caps and Budget Gates": enforce caps in the harness layer (hooks, settings constraints, runtime checks). Document the policy AND the enforcement, with the audit-trail entry recorded when a cap fires. |

**For AI assistants:** During initial onboarding (§0 discovery), scan for these anti-patterns in the project's existing state. If the project already shows signs of documentation theater or cargo-culted practices from a previous process adoption, call it out. Recommend removing unused process artifacts before adding new ones — reducing noise is as valuable as adding signal.

**When you flag a borderline case, name the watch signal explicitly.** "Borderline documentation theater: 14 specs and 8 ADRs before any application code. Watch signal: if Phase 0 stretches past 9 sessions without code progress, the anti-pattern is real." A verdict without a falsifier becomes opinion; a verdict with one becomes a checkpoint.

### 0.7 Audit Protocol — How to Review Efficiently

Auditing the full document against a project is expensive — both in tokens and in time. A comprehensive audit of the core template plus extensions can consume 50,000+ tokens, most of which is wasted if the project is early-stage and only needs Tier 1 guidance. Use a tiered audit approach instead.

**For AI assistants performing an audit:**

**Audits are read-only by default.** An umami audit assesses process maturity and identifies gaps — it does not modify code, configuration, or project files. Do not restructure directories, add tests, insert logging, refactor code, or apply recommendations during the audit phase. The audit produces a findings report. The user decides what to act on, when, and how. See "After the audit" below.

1. **Determine the project's current tier.** Read the project's `CLAUDE.md`, test infrastructure, and documentation. Match the project's current state to the adoption tiers above. Most projects are between Tier 1 and Tier 2.

2. **Audit one tier above current.** If the project is solidly at Tier 1, audit against Tier 2 practices. If it's at Tier 2, audit against Tier 3. Don't audit practices two tiers above — they'll create recommendations the project isn't ready to act on.

3. **Focus on gaps, not compliance.** The output should be: "Here are 3-5 specific practices from the next tier that would address problems you're currently experiencing." Not: "Here are 47 recommendations across all sections."

4. **Read selectively.** You do NOT need to read the entire document for every audit. Read §0 (discovery) to understand the framework, then read only the sections relevant to the tier you're auditing. The tier tables above tell you which sections to check.

5. **Extensions only when relevant.** Only fetch extension files if the project has that domain layer AND is at Tier 2+. A Tier 1 web project doesn't need an audit against `umami-web.md` — it needs to get its basic testing and structure right first.

**Audit output format:**

```markdown
## Process Audit — [Project Name]

**Current tier:** [1/2/3] — [brief justification]
**Auditing against:** Tier [2/3] practices

### What's working well
- [2-3 practices already solid]

### Recommended next practices (priority order)
1. [Practice] (§X) — [why this addresses a current pain point]
   - **Changes required:** [which files would be created, modified, or restructured]
   - **Conflict risk:** [low/medium/high — likelihood of affecting concurrent work]
2. [Practice] (§X) — [why this addresses a current pain point]
   - **Changes required:** [which files would be created, modified, or restructured]
   - **Conflict risk:** [low/medium/high — likelihood of affecting concurrent work]
3. [Practice] (§X) — [why this addresses a current pain point]
   - **Changes required:** [which files would be created, modified, or restructured]
   - **Conflict risk:** [low/medium/high — likelihood of affecting concurrent work]

### Not yet relevant
- [Practices that were checked but don't apply yet, with the trigger that would make them relevant]
```

This format keeps the audit focused and actionable. A project should come away with 3-5 concrete next steps, not a wall of recommendations.

**After the audit — describe changes, then present a four-option dialog:**

Each recommendation in the audit report must describe the specific changes it would require — which files would be created, modified, or restructured, and what the modification involves. This lets the team assess impact, spot conflicts with in-progress work, and make informed decisions before any code is touched.

Once the report is complete, present a structured dialog asking how to proceed. Use the harness's structured-prompt mechanism (e.g., `AskUserQuestion` or equivalent) so the question is self-contained in its UI surface without requiring chat scroll-back — see §3b "Make each prompt self-contained."

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
- **Always fetch the spec fresh from the canonical URL** (`https://raw.githubusercontent.com/.../umami.md`). Never cache locally. The framework evolves; cached copies go stale silently.
- **If the fetch fails, tell the user and stop.** Do not fall back to a stale local copy. An audit against three-month-old guidance is worse than no audit — it produces confident, wrong recommendations.
- **Never recommend more than 5 things.** A wall of recommendations is not actionable. Prioritize ruthlessly.
- **Cite a file path or doc reference for every observation.** "The project lacks ADRs" is an opinion; "no files exist under `docs/decisions/`" is a finding.
- **Don't fetch extension files unless they apply.** A web project doesn't need an audit against `umami-data.md`. Confirm domain relevance before pulling.
- **Audit one tier above current — never two.** Recommendations the project isn't ready for create noise, not value.

When the audit flags an anti-pattern, name the watch signal that would confirm or refute the verdict (see §0.6). Verdicts without falsifiers become opinion.

### 0.7b Initialization Protocol — Bootstrapping Umami in a New Project

§0.7 covers recurring audits. This section covers the first-time setup — bringing umami into a project that doesn't yet reference it, or upgrading a partial setup.

**Bootstrap entrypoint (self-installing).** A project with no umami presence pastes one instruction into their agent:

> *"Set up umami in this project. Fetch https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/develop/umami.md and follow §0.7b."*

The agent fetches the spec, follows this section, and during the apply phase installs `umami-init` and `umami-audit` skills locally. Subsequent runs use slash commands.

**This is a lightweight setup, not a framework install.** Init writes only URL references and small invocation-aid skill files. There is no framework copy, no runtime dependency, no library to keep updated. The umami spec stays at its canonical URL and is fetched fresh on every run; the local artifacts are just a way to make access to umami consistent and harness-recognized as commands.

**What gets stored locally vs. fetched fresh:**

- **Stored locally:** URL *references* to the canonical umami spec (in instruction files like `CLAUDE.md`) and *skill files* (`.claude/skills/umami-init.md`, `.claude/skills/umami-audit.md`) that describe *how to invoke* the protocol.
- **Never stored locally:** the umami spec itself. Always fetched fresh from the canonical URL on every audit/init run.

Skill files are invocation aids — they encode procedure shape, hard rules, and bootstrap text so the harness recognizes `/umami-init` and `/umami-audit` as commands. They do **not** contain a copy of umami.md. Drift between an installed skill and the canonical spec is detected per §0.7 (structural + calendar drift checks).

**Procedure for AI assistants performing initialization:**

1. **Detect current state.** Grep instruction file(s) (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.) for umami URLs. Determine starting state:
   - **None** — first-time setup.
   - **Partial** — some umami URLs present; missing relevant extensions, or referencing extensions for layers the project doesn't have.
   - **Complete** — references match the project shape; recommend `/umami-audit` instead.

2. **Run §0.1–§0.4 discovery** interactively, one decision at a time per §3c when answers compound.

3. **Derive recommended core + extension set** via §0.5 mapping.

4. **Compute the diff:** adds (extensions to add to URL list), removes (rare; usually flag-only), and skill installations (`.claude/skills/umami-init.md` and `.claude/skills/umami-audit.md`, each with `**Last synced:** YYYY-MM-DD` set to today).

5. **Show the user the proposed changes, then present the four-option dialog.** Enumerate every file that would be modified or created — paths, line counts, the exact URL block that would land in each instruction file, which skill files would be created or updated and at what `Last synced:` date. The user must be able to read the diff before deciding. Then surface the dialog (apply all / selective walkthrough / do something else / skip) per §0.7. Self-contained prompt per §3b.

6. **Apply on approval.** Update all detected instruction files in lockstep (a project with both `CLAUDE.md` and `AGENTS.md` gets identical URL lists in both). Write the skill files. Don't overwrite existing skill files without diffing first.

7. **Hand off:** *"Init complete. Run `/umami-audit` for a first process audit."*

**Hard rules** mirror §0.7:

- Read-only by default. The four-option dialog gates every write; no destructive changes without explicit approval.
- Always fetch the spec fresh from the canonical URL. Never cache locally.
- If the fetch fails, tell the user and stop. Don't fall back to a stale local copy.
- Cite a file path or doc reference for every observation.
- Drift detection applies to installed skills (see §0.7).

### 0.8 Example: Onboarding a Multi-Layer System

Consider a project that has a web dashboard, but the dashboard sits on top of a data ingestion layer, a calculation pipeline, and a data warehouse. The project directory contains `lib/pipeline/` and `lib/extraction/` — not `src/components/`.

If the AI skips discovery and applies this template as-is, it will scaffold `src/components/`, write E2E browser tests, set up visual regression, and create ADRs about frontend stack choices — missing the fact that the data pipeline is the core of the system and the web UI doesn't exist yet.

**After running the questionnaire, the system shape becomes clear:**

```
Layer 4: Web Dashboard        ← NOT YET BUILT
Layer 3: API                  ← NOT YET BUILT
Layer 2: Calculation Pipeline ← OPERATIONAL
Layer 1: Data Ingestion + DB  ← OPERATIONAL
```

**What this changes about template application:**
- §1 (Project structure): Organized around pipeline and extraction modules, not frontend components. Test structure mirrors `lib/`, not a UI tree.
- §2 (Specs): Data dictionary and source registry are the critical specs — not UI component contracts.
- §3 (Testing): First tests cover calculation logic and data transforms — not E2E browser tests. Visual regression is deferred until the UI layer exists.
- §7 (Documentation): ADRs capture data architecture decisions (pipeline approach, ingestion strategy) — not just frontend stack choices.
- §10 (Change propagation): Map is organized into per-layer sections — not a flat table assuming one codebase.

**The propose-then-confirm pattern in action:**

The AI explores the codebase, proposes that it's a web application, and presents its understanding. The user corrects: "this is more than a web project — the web part is the dashboard on top of data ingestion, pipelines, and a warehouse." That single correction restructures the entire guardrail setup — project description, change propagation map, test priorities, ADR scope, and persistent memory framing.

Without the confirmation step, the AI would have silently applied web-centric guardrails and the misfit wouldn't surface until real development starts — after tokens and time had been spent on the wrong structure.

**Key lesson:** The AI should always propose its understanding of the project shape and get confirmation before scaffolding guardrails. A 30-second correction from the user prevents hours of structural rework.

---

## 1. Project Structure

A predictable structure eliminates orientation cost for every new contributor — human or AI.

```
project-root/
├── CLAUDE.md              # AI agent instructions (or .cursorrules, AGENTS.md, etc.)
├── README.md              # Human onboarding
├── .gitignore
│
├── docs/                  # Prescriptive documentation (not descriptive)
│   ├── architecture/      # System design, component contracts, data flow
│   │   ├── README.md      # Index with file paths to every doc
│   │   └── *.svg          # Diagrams (never ASCII art)
│   ├── audits/            # Living audit files with resolution status
│   ├── decisions/         # Architecture Decision Records (ADRs)
│   └── ui/                # UX specs, mockups, design system
│
├── poc/                   # Proof-of-concept experiments (§3b)
│   └── <experiment-name>/ # Each POC in its own directory with a README
│
├── src/ (or per-layer dirs like frontend/, backend/, middleware/)
│   ├── components/        # UI components, grouped by feature
│   ├── tools/             # Domain-specific modules
│   ├── types/             # Shared type definitions
│   ├── utils/             # Pure utility functions
│   └── validation/        # Runtime validation logic
│
├── tests/                 # Test files, mirroring src/ structure
│   ├── unit/
│   ├── e2e/
│   ├── visual/
│   │   └── snapshots/     # Version-controlled baseline images
│   └── conftest or setup  # Shared fixtures, helpers
│
└── config files           # tsconfig, vitest, playwright, pyproject, etc.
```

### Structure Principles

- **Mirror src/ in tests/** — finding the test for a file should never require searching.
- **One index file per doc directory** — a README.md listing every doc with its file path and one-line purpose.
- **Types live together** — shared types in one place, not scattered across modules.
- **Config at the root** — all tool configs (linter, formatter, test runner, build) at project root, not nested.
- **No deep nesting** — if a path exceeds 4 levels, flatten it. Deep trees cost navigation tokens.
- **Orthogonal by default** — changes to one module should not require changes to unrelated modules. If adding a feature requires edits in 6 files that have nothing to do with each other, the structure has coupled things that should be independent. Signs of poor orthogonality: a single change type appears in multiple unrelated rows of the change propagation map (§10), or two modules import from each other.

### Workspace Partitioning

Multi-phase projects often have code with different lifecycles in the same repo. Discovery/analysis scripts that were essential during the research phase become dead weight during application development — cluttering the dependency list, confusing test suites, and inflating the project surface area.

**Partition by lifecycle, not by language:**

```
project-root/
├── analysis/                    ← Discovery phase (own pyproject.toml / package.json)
│   ├── pyproject.toml          # Separate deps (analysis-only libraries)
│   ├── scripts/                # Extraction, migration, exploration scripts
│   ├── lib/                    # Analysis-specific modules
│   └── tests/                  # Analysis tests (run separately)
│
├── infrastructure/              ← IaC, Docker, deployment
│   ├── docker-compose.yml
│   └── docker/                 # Init scripts, seed data
│
├── src/ (or per-layer dirs)     ← Application code (active development)
├── tests/                       ← Application tests
└── pyproject.toml               ← Application deps only
```

**Rules:**
- Each partition has its own dependency manifest. Analysis tools (Excel parsers, data profilers) don't pollute the production dependency list.
- Application code never imports from the analysis partition. The analysis partition may import from application code if needed for validation.
- Tests run independently: `pytest tests/` for the application, `cd analysis && pytest tests/` for analysis.
- Discovery work is done when it's done. Don't restructure it retroactively to match application conventions — just wall it off.

### Phase / Session Structure for Long-Running Effort

Projects that outlive a single sitting need a unit-of-work hierarchy. Without one, work fragments into a stream of commits that have no narrative, scope creeps because nobody can name what was *supposed* to happen, and the assistant has no clean point to stop and re-orient. The discipline is small but pays off across weeks.

```
Project
 └── Milestones    (semantic version bumps: v0.x → v1.0 → v2.0)
      └── Phases   (numbered groups of related work, named by capability)
           └── Sessions (atomic, single-goal, one-or-more-commits)
```

| Unit | What it is | Sizing | Naming |
|------|-----------|--------|--------|
| **Milestone** | A version boundary where the product becomes a different thing. v1.0 is feature-complete baseline; v2.0 is next-generation capability. | Set by *what shipped*, not by a calendar. Don't tag a milestone for incremental work — that's what phase boundaries are for. | Semver tag (`v0.10.0`, `v1.0`). |
| **Phase** | A cohesive group of sessions that delivers one named capability. | Sized to fit a coherent body of work, not a target session count. A small phase is 4 sessions; a large phase is 12. Either is fine. | "Annotations & Markup", "Form Filling", "Save / Export / Reduce" — the capability, not a number alone. |
| **Session** | The atomic unit of work — one focused sitting. Has a single goal stated in one sentence. Produces working, tested code (not scaffolding). Results in one or more commits, each addressing one concern. | Sized by goal, not by clock. "However long it takes to deliver one focused goal." | Globally numbered across phases (S1, S2, S3...) so commits can reference them in git log. "Phase 9 S5d: AcroForm AP regen". |

**Why global session numbering:** a commit message like `Phase 9 S5d-2 + S5d-3: separate-widget-kid AP regen + DR-aware fonts` is searchable, traceable, and survives roadmap renumbering. Per-phase session numbers collide every time you reshuffle.

**One goal per session.** If a tangent emerges, capture it as a TODO or audit gap; don't expand the session. Scope discipline at this layer is what keeps phases honest.

**Sessions can have sub-sessions** when a session's single goal naturally breaks into staged sub-deliverables that share the goal. Number them `S4 Session 1`, `S4 Session 2`, `S4 Session 3a`, `S4 Session 3b`. Don't use sub-sessions to smuggle in extra goals.

**Renumbering is normal, not a failure mode.** Phases get reordered when priorities shift. When you renumber:

1. Document the change in a `## Renumber note (date)` block in the roadmap, explaining what moved and why.
2. Sweep all cross-references in the roadmap for stale phase numbers.
3. Add a decisions-log entry capturing the rationale.

This audit trail is how you avoid "wait, was Phase 5 the search work or the print work?" a year later.

### Multiple Surfaces, One Primitive

When an application exposes multiple interfaces — a GUI, a CLI, an AI tool surface (MCP, function calling, etc.), a public API — the temptation is to implement each interface against the underlying engine independently. Don't. Force every public write operation through a single typed primitive that all surfaces build and submit.

```
GUI ─┐
CLI ─┼──→ Patch (typed) ──→ apply_patches(engine) ──→ result
MCP ─┘
```

**Why this matters:**

- **One test surface.** Test the patch type and `apply_patches`; the surfaces become thin adapters that build patches and forward them. You don't need to re-test "does saving work" three times in three different shapes.
- **Invariants in one place.** Validation, undo/redo, transaction boundaries, security checks live on the primitive. Surfaces can't bypass them, even by accident, because the primitive is the only path.
- **New surfaces are cheap.** Adding a fourth interface (a webhook, a daemon, a scripting bridge) means writing a thin adapter that builds the existing patch type. The engine doesn't change.
- **Inverse / undo for free.** If the primitive defines a forward operation and its inverse, every surface gets undo support without each one implementing it.

**The discipline:** before exposing a new write capability through any surface, define it as a variant of the patch type first. The surface code should never call the engine directly; it should always go through the primitive.

This generalizes beyond write operations. Read operations can also benefit from a single typed query primitive — but the cost-benefit is weaker for reads (they don't have invariants or undo). Apply this rule strictly to writes; selectively to reads when it earns its keep.

---

## 2. Specification-First Development

Every feature starts with a written spec, not code. Architecture documents and diagrams define system behavior, component contracts, and design constraints before implementation begins. These serve as the source of truth for all contributors.

**This section establishes spec discipline, not a spec framework.** Any format works — RFCs, design docs, shape-up pitches, PRDs, Gherkin. The discipline is *having* a spec process; the format is a team preference.

**Relationship to Spec-Driven Development (SDD).** SDD is an emerging movement that pushes spec-first further — specs are written to be *executable* by AI agents, with machine-checkable contracts the agent works against rather than human-readable documents alone. §2 is compatible with SDD: SDD-style specs are one valid format, and the discipline of *having a spec before coding* is the shared foundation. Where they differ: SDD is opinionated about format (executable / machine-checkable); umami is format-agnostic. Teams already going SDD don't need to choose — §2 is the broader process discipline around the practice SDD codifies.

### What to Specify

- **System architecture** — how components connect and communicate.
- **Component contracts** — typed inputs, outputs, and configuration schemas.
- **Design system** — enforced visual language (colors, typography, spacing) so the UI stays consistent regardless of who writes the code.
- **Data contracts** — data shapes validated at design time, catching mismatches before runtime.

### How Specs Prevent Waste

For AI contributors, a written spec replaces inferred intent — fewer clarification questions, fewer wrong-direction implementations.

### When Not to Specify

Specs have diminishing returns. Over-specifying is its own form of waste — a spec that takes longer to write than the implementation it describes is overhead, not discipline.

**Skip the spec when:**
- The change is trivial — typo fixes, config tweaks, adding a log line, updating a dependency version.
- The implementation is smaller than the spec would be — if describing the work takes more effort than doing the work, just do the work.
- The behavior is already fully specified by an existing test — writing a new spec that restates what the test already captures adds no value.
- You're prototyping to learn — write the spec *after* the prototype clarifies the requirements, not before. Specifying unknowns produces fiction, not contracts.

**The signal:** If you find yourself writing a spec and realizing you can't specify the behavior because you don't understand the problem well enough, stop specifying and start prototyping. A prototype that reveals the right spec is more valuable than a spec that encodes the wrong assumptions.

---

## 3. Multi-Layer Test Infrastructure

Testing spans the full stack across complementary layers:

| Layer | Purpose | Catches |
|-------|---------|---------|
| **Unit tests** | Logic correctness | Regressions in parsers, validators, state management, utility functions |
| **Property-based tests** | Invariant correctness across generated inputs | Edge cases you didn't think of — boundary values, empty inputs, unicode, overflow |
| **E2E browser tests** | User flow integrity | Broken interactions, navigation failures, data persistence issues |
| **Visual regression** | Pixel-level UI stability | Unintended cosmetic changes; baselines updated only for intentional changes |
| **API/service tests** | Contract adherence | Protocol violations, serialization errors, edge cases in data handling |

### Property-Based Testing

Example-based tests verify the cases you thought of. Property-based tests find the cases you didn't. Instead of specifying individual inputs and expected outputs, you define *properties* (invariants) that must hold for *any* valid input, and the framework generates hundreds or thousands of test cases automatically.

**When to use:**
- **Parsers and serializers** — "parse(serialize(x)) should equal x for any x."
- **Data transforms** — "output row count should equal input row count" or "no nulls in required fields after transform."
- **Business rules** — "discount never exceeds the item price" or "account balance never goes negative."
- **API contracts** — "response schema is valid for any combination of query parameters."

**When not to use:** UI interactions, integration tests with external services, or any test where the property is harder to state than the individual cases.

**Frameworks:** Hypothesis (Python), fast-check (JavaScript/TypeScript), QuickCheck (Haskell/Erlang), Proptest (Rust), jqwik (Java).

**Token impact for AI development:** Property-based tests are especially valuable when agents write code, because agents tend to test the happy path and common edge cases but miss unusual input combinations. A property-based test suite catches bugs the agent (or human) would never think to write example tests for.

### Testing Principles

- **Baselines are version-controlled artifacts** — screenshots and snapshots checked into git, not generated on the fly.
- **Update baselines only for intentional changes** — this prevents cosmetic drift and makes every visual change a deliberate decision.
- **Run tests before committing UI changes** — always. No exceptions.
- **Hard timeouts on all test layers** — per-test timeout, global kill switch, and memory caps prevent runaway processes.
- **Document pre-existing failures** — known failures that aren't your bugs should be listed so contributors don't waste time diagnosing them.

### Test Doubles for External Dependencies

Production code should target production infrastructure. Tests should run without that infrastructure. The solution is a thin adapter in the test suite — not conditional branches in production code.

**Wrong:** Scattering `if test_mode then ... else ...` throughout production code so it works with both a real service and a test substitute. This doubles maintenance, masks integration issues, and makes production code harder to read.

**Right:** Write production code for the production target only. In `tests/`, create a lightweight adapter that conforms to the same interface but translates to a simpler backend. The adapter is never imported by production code.

**When to use:** Any dependency that requires infrastructure to run — databases, HTTP services, message brokers, file storage, email providers. The adapter pattern lets unit and integration tests run instantly without containers or network access.

**When NOT to use:** Integration tests that are specifically validating the real infrastructure. Mark those tests separately (e.g., `@pytest.mark.integration`) and run them against the real thing in CI or manually.

### Type Assumptions at System Boundaries

When data crosses a boundary between two tools (export → import, API response → client model, serialization → deserialization), type coercion failures are the most common source of integration bugs. Each tool has its own default type representations, and they rarely agree.

**The pattern:** Tool A exports data in a format that looks correct to Tool A. Tool B imports it and fails because its type expectations are stricter, looser, or simply different.

**The discipline:** Every time data crosses a tool boundary, audit the type assumptions on both sides. Don't assume that "it worked in Tool A" means it will load cleanly into Tool B. Test the boundary explicitly — ideally with a small representative sample — before running the full pipeline.

Common failure categories:
- **Nullability differences** — one side allows nulls, the other doesn't, or null is represented differently (empty string vs. `NULL` vs. omitted field).
- **Numeric precision** — one side uses integers, the other uses floats, or precision/scale constraints differ.
- **Sentinel values in typed columns** — source data uses human-readable markers (text) in columns the schema declares as numeric or boolean.
- **Auto-generated fields** — one side includes them in exports, the other expects them to be auto-populated on import.
- **Temporal types** — native datetime objects vs. ISO strings vs. Unix timestamps. Timezone-aware vs. naive.

**The fix is always the same:** make the boundary contract explicit. Specify column lists, validate types before crossing, and test with real data samples — not just the happy path.

### Multi-Provider Behavioral Testing

For LLM-feature products whose correctness depends on the model's behavior — tool-calling shape, structured-output adherence, instruction-following, refusal behavior — test across the providers you actually serve in production. A test that passes only on one provider is silent regression risk for the product's other code paths.

§3 above covers test layers (unit, integration, E2E, property-based); this sub-section adds the *provider matrix* and *substrate tiers* dimensions specific to LLM-feature products.

**Two dimensions of coverage:**

| Dimension | What it covers |
|---|---|
| **Provider matrix** | The set of LLM providers your product serves (Anthropic / OpenAI / Gemini / Ollama-local / etc.). A behavioral test runs against each |
| **Substrate tiers** | Progressive complexity. Tier 1: single tool call working. Tier 2: multi-step workflow with multiple tools. Tier 3: full agent workflow with sub-agents and recursive dispatch. Each tier exercises more substrate; each surfaces different failure modes |

The substrate-tier model above is one product's shape — a tool-using agent harness. **Substitute the substrate categories that fit your product's actual feature surface.** A chat-only product won't have tool-call tiers (consider tiering by conversation length / context-window pressure / refusal-rate calibration instead). A RAG product might tier by retrieval-quality vs. generation-quality dimensions. A code-completion product might tier by completion-length and language coverage. The point is *progressive substrate exercise*, not the specific tiers below.

Coverage is providers × substrate tiers — at scale, dozens of cells. Not every cell needs to run on every change; gate critical cells on every commit, run the full matrix nightly or per-release.

**What this catches that lib/bin tests don't:**

- Provider-specific tool-schema strictness (one provider rejects schemas another accepts)
- Per-provider pricing defaults (cost calc right for one provider, drastically off for another)
- Tool-calling format differences (native tools vs text-fallback parsing)
- Model-hint threading (whether the right model gets routed through the right provider's adapter)
- UTF-8 boundary safety (some providers handle non-ASCII tool args differently)
- Substrate edge cases that only surface in real provider RTT — timing, streaming, error shapes, rate-limit behavior

These are gaps lib/bin tests structurally can't reach: they mock provider behavior. Once shipping an LLM-feature product, correctness depends on the provider's *actual* output, not on a mock.

**The bench-pays-for-itself observation.** A multi-provider bench is meant to *verify* substrate; in practice the first run is also a substrate-gap *discovery* exercise. Plan for this — bench bring-up is not one-shot validation, it's a discovery cycle. Real bench bring-ups have surfaced and closed 10+ substrate gaps that lib/bin tests didn't reach.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Bench passes on N of M providers your product serves | Behavioral guarantee covers N; the gap between N and M is silent regression risk |
| Substrate gap discovered in production but not in bench | Coverage hole — the cell that should have caught the gap doesn't exist or doesn't exercise the path |
| Bench non-determinism (results vary across runs against same provider) | Bench has timing dependencies, model has temperature > 0, or substrate has a race condition |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| "We test on the cheapest provider" | Bench runs only on the fast/cheap model; production traffic on flagship models has different behavior | Test the providers you actually serve. Cost is real but behavioral parity isn't optional |
| Tier 1 only | Bench covers single tool calls; ships break on multi-step workflows once they land | Add Tier 2 (multi-step) at minimum once features compose tool calls; Tier 3 (sub-agents) when the product dispatches |
| Manual bench runs | Bench runs only when someone remembers; regressions slip in between runs | CI-gate the bench. For full-matrix runs that are slow/expensive, schedule nightly with explicit pre-release gates |
| Provider mocks instead of real provider | Bench uses recorded fixtures; doesn't catch behavioral changes the providers ship | Fixtures sparingly (cost-bounded CI on every PR); full real-provider matrix at known cadence (nightly, per-release) |

**Cross-references:**
- §3 multi-layer testing (above) — multi-provider bench is a layer above E2E for LLM-feature products
- §4 untrusted-content boundaries — bench should include planted-injection cases per provider's spotlighting strategy
- §9.7 measuring efficiency — bench produces ET per provider per substrate tier; useful for cost-comparison and regression detection
- §0.5 LLM-feature-product row references this

---

## 3b. Development Process Discipline

§3 defines *what* to test. This section defines *how* to develop — the process that produces tested, correct code.

### Test-First Development (RED-GREEN-REFACTOR)

For new features and bug fixes, write a failing test before writing implementation code:

1. **RED** — Write a test that captures the expected behavior. Run it. It must fail. If it passes, you're not testing anything new.
2. **GREEN** — Write the minimum code to make the test pass. No extra logic, no premature abstractions, no "while I'm here" improvements.
3. **REFACTOR** — Clean up only after green. Extract duplication, improve names, simplify structure — but the tests must stay green throughout.

**Why this order matters:** Writing the test first forces you to think about the interface before the implementation. It also guarantees that every behavior has a test — coverage is a side effect, not a separate task.

**When to skip:** Trivial changes where the test would be more complex than the code (typo fixes, config tweaks, comment edits, adding a log line).

### Surface Ambiguity, Don't Guess

When a request is ambiguous, the wrong response is to pick an interpretation and proceed silently. The right response is to name the ambiguity and let the requester resolve it.

**The protocol:**

1. **Identify the ambiguity explicitly.** Not "I'll assume you meant X" but "this could mean X or Y — which did you intend?"
2. **Present multiple interpretations when they exist.** List 2–3 plausible readings. Briefly note the trade-off for each. Let the user pick.
3. **State confusion rather than guessing.** If the request conflicts with observed code, with an earlier instruction, or with itself, stop and say so. Guessing wastes tokens on rework when the guess is wrong.
4. **Distinguish questions worth asking from questions worth answering.** Trivial ambiguities (variable naming, formatting of a log line) can be decided inline with a quick note. Architectural or scope ambiguities must be surfaced — guessing at scope produces the worst kind of rework.

**Why this matters for token economy:** A 200-token clarification round is cheaper than a 5,000-token misdirected implementation followed by a revert and redo. The cost asymmetry is why surfacing ambiguity early is the dominant strategy.

**Make each prompt self-contained.** When the question is surfaced via an interactive dialog tool (e.g., `AskUserQuestion`-style structured prompts) rather than inline chat, the user may answer without seeing the surrounding conversation — many agent UIs render the dialog in a separate panel from the chat history. Write the question text so the user can answer cold:

- State *what* is being decided in the prompt itself ("Which auth library should we use for the new login flow?"), not just "Which one?" or "What do you think?"
- Carry the relevant context — what was already decided, what depends on this choice, what the trade-off is — into the prompt body, not into the chat that preceded it.
- Give option labels and descriptions enough substance to stand alone. "Option A" / "Option B" forces the user back to the chat to remember what those mean; "PostgreSQL — supports JSON columns natively" / "SQLite — zero-ops, file-based" stands on its own.
- The bar: a user opening the dialog without reading any prior message should be able to answer without re-reading anything.

This applies equally to inline questions in chat — but the cost of getting it wrong is much higher when the prompt is rendered in a separate UI surface, because scroll-back may not even be available without dismissing the dialog.

### Map before proposing changes (brownfield)

When working on existing systems — especially legacy code or systems older than the current contributors — don't let the AI greenfield a brownfield problem. The first step on any non-trivial change in an established codebase is *mapping*: ask the AI to summarize how the affected layer currently works (what calls what, what state lives where, what invariants hold) before proposing what to change. A proposal grounded in actual current behavior is far more useful than a proposal grounded in a generic "what should this look like."

This applies broadly: refactors, migrations, integrations with existing systems, debugging in unfamiliar code. The cost of one mapping pass is small; the cost of a proposal that doesn't account for what's already there is usually a discarded implementation.

### Systematic Debugging

When a test fails or a bug is reported, do not guess. Follow this process:

1. **Reproduce** — Get the exact error. Copy the traceback or error message. Identify the failing input and the expected vs. actual output.
2. **Isolate** — Narrow the scope. Which layer? Which function? Which line? Write the smallest reproducing test case if one doesn't exist.
3. **Root-cause** — Read the code at the failure point. Trace data flow backward from the symptom to the source. Find where actual diverges from expected. The root cause is almost never at the crash site — it's upstream.
4. **Fix and verify** — Fix the root cause, not the symptom. Run the failing test to confirm the fix. Run the full suite to confirm no regressions.

**Anti-patterns to avoid:**
- **Shotgun debugging** — changing multiple things hoping one works. This makes it impossible to know which change fixed the problem, and often introduces new issues.
- **Defensive masking** — wrapping the crash site in try/except or adding a null check to suppress the error. The bug still exists; you've just hidden it.
- **Fix-and-pray** — making a change without running the failing test to confirm it actually works.

### Don't Program by Coincidence

Code that works is not the same as code you understand. If you can't explain *why* a fix works — what was wrong, what the fix changes, and why the change is correct — you haven't found the root cause. You've found a coincidence.

This is especially critical in AI-assisted development. Agents will iterate toward passing tests by changing code until the error disappears. The result often works but for the wrong reason — a side effect, a type coercion, a timing change that masks the real bug. When the next change shifts conditions slightly, the "fix" breaks.

**The discipline:**
- **Before committing a fix, state the root cause.** Not "I changed X and the test passed" but "the bug was caused by Y, and the fix addresses Y by doing Z." If you can't state this, you're programming by coincidence.
- **Be suspicious of fixes you can't explain.** If a one-line change fixes a complex bug and you don't understand why, investigate further. You may have masked the bug, not fixed it.
- **Trace the data flow.** For any non-trivial fix, trace the data from input to the point of failure. Understand each transformation. If a step surprises you, that surprise is either a bug or a gap in your understanding — either way, it needs resolution.

**Anti-pattern — Iteration-until-green:** Changing code repeatedly until tests pass, without understanding what each change does. Each iteration adds a layer of changes whose interactions are unknown. Even if the tests eventually pass, the code is now a stack of guesses — fragile, unmaintainable, and dangerous to modify.

### Proof-of-Concept and Exploratory Code

Not all coding aims at production. POCs prove that a design, technology choice, or integration approach works before committing to full implementation. Exploratory coding builds understanding of a problem space, an API, or a data shape. Both produce artifacts that need lifecycle management — left unmanaged, they become confusing dead weight.

**Types:**
- **Proof of Concept (POC)** — a minimal build to validate a complex design or technology choice. The goal is a go/no-go decision, not a shippable feature.
- **Exploratory coding** — code written to learn. Understanding an unfamiliar API, profiling a data shape, testing a library's behavior under load. The deliverable is knowledge, not code.
- **Spike** — a time-boxed investigation into a specific technical question, usually with a fixed deadline and a narrow scope.

**The workflow:**

1. **Start with a question.** Write down what you're trying to learn. "Can our system handle 10k concurrent WebSocket connections?" is a POC. "How does this payment API handle partial refunds?" is exploration. Vague goals ("let's play with X") produce vague results.
2. **Isolate from the main codebase.** POC code lives in `poc/<experiment-name>/` (see §1 structure) or on a dedicated branch — never mixed into production code. Each experiment gets its own directory with a README stating the question being investigated.
3. **Time-box the work.** POCs without deadlines become zombie projects. Set a boundary ("2 days to prove this works") and evaluate at the end, even if the answer is "needs more investigation."
4. **Document findings.** When done, the README answers: What was the question? What did you build? What did you learn? What's the recommendation (proceed / don't proceed / needs more investigation)?
5. **Bridge to production with a gap analysis.** A working POC is not production-ready code. Before integrating, identify the gaps: error handling, testing, security, performance, observability, edge cases the POC intentionally skipped. The gap analysis becomes the integration spec (§2).

**Artifact lifecycle:**
- **Keep and reference** — the POC documents a useful pattern or a rejected approach. Keep the directory with its README, link to the relevant ADR (§7). This prevents future contributors from re-investigating the same question.
- **Archive** — served its purpose, might provide context later. Tag the branch or note it in an ADR. Remove from the active `poc/` directory.
- **Delete** — fully integrated or approach definitively abandoned. Dead POCs are dead code (§13).

**Rules:**
- **Never copy POC code into production.** POC code cuts corners on purpose — hardcoded values, no error handling, skipped edge cases. Integrating it imports all those shortcuts as tech debt. Rewrite against the integration spec.
- **Review `poc/` periodically.** If nobody can explain why a POC is still there or what question it answered, it's a cleanup candidate.
- **Document negative results.** A POC that proves something *doesn't* work is as valuable as one that proves it does — it prevents the next person (or agent) from repeating the investigation.

### Verification Before Completion

Before marking any task as done — whether it's a feature, a bug fix, or a refactor:

- [ ] All existing tests still pass (full suite, not just the new test)
- [ ] New behavior has test coverage (from the RED step above)
- [ ] No unrelated files were modified (scope discipline)
- [ ] Changes match what was requested — nothing more, nothing less
- [ ] **Every changed line traces directly to the request.** If you can't explain why a specific line exists by pointing to something the user asked for, that line is scope creep — remove it.

This checklist is not bureaucracy. It catches the two most common sources of wasted follow-up work: regressions from untested side effects, and scope creep that the requester didn't ask for.

### Litmus Tests for Self-Correction

Short self-check phrases agents can apply inline without needing a full review pass. These are not a substitute for the checklist above — they're faster filters that catch common failure modes before they compound.

| Litmus test | When to apply | What it catches |
|-------------|---------------|-----------------|
| **"Would a senior engineer say this is overcomplicated?"** | Before finalizing any non-trivial implementation | Premature abstractions, speculative generality, unneeded configuration knobs |
| **"Does every changed line trace to the request?"** | Before marking a task complete | Scope creep, incidental cleanup, "while I was here" edits |
| **"Can I state why this fix works?"** | Before committing a bug fix | Programming by coincidence (see "Don't Program by Coincidence" above) |
| **"If I removed this comment, would anything be lost?"** | Before writing a comment | Noise comments that restate what well-named code already says |
| **"Would this still make sense to a reader who doesn't have the conversation context?"** | Before writing commit messages, PR descriptions, or in-code comments that reference the current task | Task-scoped phrasing that rots as the codebase evolves |

Apply these inline during work, not just at the end. Catching a violation mid-edit costs a few tokens; catching it during review costs a rewrite.

---

## 3c. Interactive Decision Planning

When designing something with multiple load-bearing decisions, work through them **one at a time**, not in a batched response that asks the user to engage with five forks simultaneously. This prevents the "design got rubber-stamped because I couldn't engage with 7 forks at once" failure mode.

Note that §3c addresses *interactive design with the user*, while §3b's "Surface Ambiguity" addresses *individual unclear requests*. Surfacing one ambiguity is a single round-trip. Stepping through a sequence of compounding decisions is a protocol.

### When to use

Engage the protocol when **all** of these apply:

- The conversation has 3+ load-bearing decisions that compound on each other (the answer to decision 2 changes the options for decision 3).
- Reasonable people would disagree on the answers — there isn't one obvious choice.
- Locking the wrong choice would be expensive to undo.
- The user signals they want care: *"step me through these one by one"*, *"plan this carefully"*, *"let's plan this"*, *"stop blasting me"*.

If those don't all apply, just decide and move on. The protocol is overhead for routine work.

### When NOT to use

- Routine implementation choices ("what should I name this function?" — just decide).
- Time-pressured fixes ("the build is broken, just fix it").
- Decisions with one obviously-correct answer.
- Decisions outside the assistant's domain (web copy, business calls, color choices).

### The cycle (six steps per decision)

1. **Restate the question** in plain language — the underlying choice, not the surface implementation question. ("The real question is whether undo is per-edit or per-session.")
2. **Lay out 2–4 concrete options** — each a real position someone might defend, with what it costs and what it buys. Avoid 7 — that's a brainstorm dump, not a decision.
3. **Recommend one option, with reasoning** — pick a defensible default. The user can override. Refusing to recommend pushes synthesis back to the user and defeats the protocol.
4. **Surface sub-questions** — most decisions are 2–5 micro-decisions stacked. Name them so the user knows what's under the headline question.
5. **Stop.** Wait for the user's response. Resist the urge to provide three more decisions speculatively.
6. **When the user answers, lock cleanly** — restate the locked decision concisely (2–5 sentences), capture in the decisions log if material (§7), then move to the next decision in a *separate* turn. Don't combine "lock previous + setup next" in one beat.

### Failure modes to avoid

| Failure mode | Symptom | Fix |
|---|---|---|
| Gigantic batched questions | One response with 5+ headings, each forking. | Pick the next single most-blocking decision; defer the rest. |
| Pre-deciding for the user | "Going with (b) since that's obvious." | Recommend, never act on the recommendation until explicitly locked. |
| Skipping the recommendation | Lay out 4 options, refuse to recommend, ask "what do you think?" | Pick one. Pushing synthesis back to the user defeats the protocol. |
| Restating without locking | Same decision laid out twice across turns without durable capture. | When the user answers, lock it (durable text) before moving on. |
| Combining lock + next-decision setup | Response that says "OK locked sub-1; here's sub-2 with options A/B/C/D." | Separate beats. Lock first, then the next decision in a fresh turn. |
| Made-up time estimates inside decisions | "This option is ~2 weeks of work; the other is ~4 days." | Describe scope (subproblem count, relative size, known-vs-unknown ratio); user does velocity arithmetic. See §0.6 anti-pattern table. |
| Prompt requires scroll-back to make sense | "Which one?" / "Option A or Option B?" rendered in a dialog UI where the user can't see preceding chat. | Make each prompt self-contained — state the decision and its options inline, not via reference to chat history. See §3b "Make each prompt self-contained." |

### Calibration heuristic

You can tell whether the protocol is working from the relative length of the user's responses to yours:

- If the user's previous response is **shorter than your next response by ~5x or more**, you're over-asking. Trim the next round.
- If the user's responses **get shorter** as the conversation proceeds (`yes`, `b`, `c`, `looks good`), the protocol is working — they're trusting your recommendations and confirming with low effort.
- If the user **pushes back on framing or recommendations** ("actually you're missing option D", "the right answer changes if X"), the protocol is *also* working — they're engaging with substance. Lean into those moments.
- If the user says **"you're not stepping through these one by one"** or **"stop blasting me"**, you've drifted. Reset.

The slow path produces better designs *because* it forces engagement — the cost is overhead per decision, the benefit is decisions that were actually decided rather than rubber-stamped.

### Output format discipline

State the output format you want before asking for the answer — markdown decision matrix, ADR-shaped doc, JSON, prose with section headers, table with specific columns. LLMs guess the format if you don't, and often guess wrong. Applies to both interactive decisions (text in chat) and structured-output prompts (a file or artifact). One sentence in the prompt prevents an output-shape rework round-trip.

---

## 3d. Code Review Discipline

In agentic coding, code generation often outpaces human review capacity. The traditional model — humans reading every diff — degrades silently as velocity rises: it either becomes rubber-stamping ("LGTM, didn't really read it") or the bottleneck that defeats the velocity gains. §3d frames code review as **attention management**: a three-layer system that lets mechanical gates and AI pre-screening handle most changes, focusing human attention only where it's earned.

§3d operationalizes the **reviewing mode** of AI use (see §14). The reviewer agents in this system are reviewing-mode agents — read-only critics that produce structured findings, not approval/rejection.

### The three-layer model

| Layer | What it does | When it runs | Decision criterion |
|---|---|---|---|
| **1. Mechanical** | Linters, formatters, type checkers, tests, coverage delta, diff-complexity heuristics | Every change, automatically | Pass / fail gates |
| **2. AI pre-screen** | Reviewer agents that produce a structured **flags document** (non-blocking) | Every change that passes Layer 1 | Output is findings, not approval |
| **3. Risk-classified human focus** | Human review on changes meeting risk classification OR flagged High by Layer 2 | Only changes that match dimension/signal triggers OR omnibus flagged High | Human reads flags doc + diff |

### Risk classification

Layer 3 routes only the changes that warrant it to humans. Classification has two parts: the *dimensions* of risk (the why) and the *signal categories* that detect them (the how).

**Dimensions** — three universal ones, plus project-specific ones to extend with:

| Dimension | Coverage |
|---|---|
| **Security** | Auth, authorization, secrets, crypto, attack surface |
| **Data integrity** | Database writes, schema changes, financial calc, state transitions |
| **Contract integrity** | Public APIs, breaking changes, exported interfaces |

Most projects also need to extend with *some* of: dependencies (supply chain), infrastructure (CI/build/deploy), observability (logging/metrics), compliance (audit-trail requirements), latency (real-time apps), accessibility, internationalization. Projects with regulated data or unusual constraints often have dimensions that don't appear here at all. The list above is a starting kit, not a fixed schema.

**Signal categories** — universal across projects:

| Signal type | What it matches |
|---|---|
| **Path patterns** | Files / directories that historically map to a risk dimension (`auth/`, `db/migrations/`, `*.sql`, `Dockerfile`) |
| **Diff content** | Strings, identifiers, or patterns within the change (references to `password`/`token`/`secret`, modifications to exported function signatures, new dependency entries) |
| **Change type** | Kind of edit (new dependency added, file deleted, schema migration created, new public method exported) |

A project's risk classification is the mapping between dimensions it cares about and signals that detect them — typically a small table maintained alongside the change-propagation map (§10).

### Reviewer agent pattern

The **omnibus reviewer** is the foundation. It's invoked on every change after Layer 1 passes, does a broad sweep across the project's risk dimensions, and produces the flags document. One skill template lives in this repo (`.claude/skills/umami-omnibus-reviewer.md`); each project derives its own with project-specific risk dimensions and paths.

**Specialized reviewers** are an *optional escalation* for projects where scale demands it. A separate skill per dimension (security, performance, contract integrity, error-handling) can come off the bench when the omnibus flags High in that dimension, producing deeper analysis. Most projects don't need specialized reviewers until repeated High flags on the same dimension justify the focused mandate. Per §14, scoped specialized agents are a measurable cost lever, but only useful when there's enough flagged volume to justify them.

### Flags document

The flags document routes human attention. Qualities of a good one:

- **Scannable in ~30 seconds** — a human reading it should know within seconds whether to look closer
- **Prioritized** into 2–3 risk levels (HIGH / MEDIUM / LOW, or equivalent)
- **`file:line` citation on every item** — no "the auth code has issues"; always the specific location
- **Dimension tag on every item** — security / data / contract / etc., so a human can route to the right specialized reviewer if needed
- **One-line concern per item** — the human drills into the diff if they need detail

Worked example (one project's shape):

```markdown
## Review flags — PR #1234

### HIGH (need eyes)
- security: src/api/orders.ts:142 — new validation skips length check (potential XSS via order notes field)
- data: src/db/migrations/0042.sql — adding NOT NULL without backfill (table size 50M rows)

### MEDIUM (consider)
- resilience: src/utils/retry.ts:8 — retry budget not propagated to caller
- observability: src/services/auth.ts — debug log statement includes token

### LOW (note)
- 12 test files updated; no production-code test coverage added for the new branch in orders.ts:142
```

The exact shape (HIGH/MEDIUM/LOW vs. red/yellow/green vs. priority numbers) is a project taste call. The qualities are universal.

### Spot-check sampling — load-bearing

Without random human spot-checks of "low-risk" changes (the ones that don't trigger any human-review signal), the risk classification rots silently. Paths get added without updating the classification map; the omnibus reviewer drifts and flags less; real issues bypass human eyes forever.

**Sample 5–15% of low-risk changes randomly. Tune to taste.** Lower bound (5%) is meaningful without being disruptive. Upper bound (15%) is heavy enough to keep reviewers calibrated. The exact rate is project-specific — the watch signal below tells you whether you're sampling enough.

If serious issues turn up in spot-checks, the classification is wrong. Fix the *classification* (add the missing path glob, refine the signal rule), not just the one change.

### Watch signals

Three signals detect when the review system is degrading:

| Watch signal | Healthy range | What it catches |
|---|---|---|
| **Spot-check finding rate** (real issues per sampled change) | < 2% | If higher, risk classification is wrong; serious changes are bypassing the human gate. |
| **Omnibus reviewer flag rate** (% of changes flagged at any level) | 5–25% | < 2% → reviewer is missing real issues (false confidence). > 25% → noisy / alert fatigue. |
| **Merge-rate ÷ human-engagement-rate** | < 5× | If merges run more than 5× faster than humans engage with flags docs, the human-attention layer is rubber-stamping. |

Treat watch signals as the diagnostic. The system doesn't fix itself — investigate and adjust the classification, the reviewer's prompt, or the team's process when a signal trips.

### Failure modes

| Failure mode | Symptom | Fix |
|---|---|---|
| Rubber-stamping | Humans approve flags docs without engaging; merge rate vastly exceeds engagement rate | Watch signal #3 catches this. Fix is process — slow merge velocity, require evidence of engagement, pair-review high-volume work |
| Classification rot | Risky changes bypass the human gate because path globs are stale | Spot-check sampling catches this if you actually do it. Fix the classification map, not the one change |
| Reviewer agent drift | Same code reviewed at different times produces inconsistent flags | Drift detection per §0.7 hard rules; re-derive the reviewer skill from current §3d |
| Reviewer over-confidence | Reviewer flags a tiny fraction; humans trust it; real issues slip through | Watch signal #2 (flag rate) catches this. Recalibrate the reviewer's prompt or scope |
| Skill rot | Reviewer agents reference deprecated paths or APIs | Periodic skill review per §14; update the canonical template in this repo |

---

## 4. Runtime Validation

The system validates structural correctness on every edit, not just before execution.

### Categories of Checks

- **Missing or excess connections** between components.
- **Unconfigured components** with required fields left empty.
- **Cycle detection** in directed graphs or pipelines.
- **Orphaned components** with no connections.
- **Type mismatches** at connection boundaries.
- **Schema compatibility** — warn on mismatch, block on incompatibility.

### Severity Model

| Level | Behavior |
|-------|----------|
| **Error** | Blocks execution. Must be resolved. |
| **Warning** | Informs the user. Does not block. |
| **Info** | Logged for observability. No user action required. |

Enforcement belongs in the engine, not the UI. The UI reflects validation state; it doesn't own it.

### Production Observability

Testing (§3) and validation (above) catch problems before and during deployment. Observability catches everything that slips through — the slow queries, the cascading failures, the silent data corruption. It's the production-time counterpart to development-time validation.

**Three signals, correlated:**
- **Metrics** tell you *something is wrong* (error rate spiked).
- **Logs** tell you *what went wrong* (specific error with context).
- **Traces** tell you *where it went wrong* (which service in the chain failed).

These only work together if they share correlation identifiers — a trace ID in every log line, service name on every metric. Without correlation, you have three separate piles of data instead of one coherent picture.

**Structured logging rules:**
- Use structured format (JSON) in production. Human-readable format is fine for local development.
- Include trace IDs in every log line — this is the bridge between logs and traces.
- Use consistent log levels across services: DEBUG (never in production by default), INFO (normal operations), WARN (handled unexpected conditions), ERROR (failures needing attention).
- **Never log sensitive data.** Passwords, tokens, PII, credit card numbers. Sanitize before logging. This is not optional.
- Log at boundaries, not everywhere. Log when data enters or leaves your service, when operations complete or fail. Don't log inside tight loops.

**Instrumentation discipline:**
- Instrument inbound requests, outbound calls, and business-critical operations. Capture method, status, and duration.
- Instrumentation is part of the "definition of done" — not a follow-up task. When removing a feature, remove its instrumentation too (§13).
- Don't instrument every function call. Instrumentation has overhead. Excessive instrumentation creates noise and inflates costs.

Each domain extension includes specific observability guidance for its context — what to monitor, what to alert on, and what tools to consider.

### Security Discipline

Security is a cross-cutting concern, like observability. Every project that accepts input, communicates over a network, or manages user data has a threat surface — whether the team thinks about it or not. The goal isn't to become a security expert; it's to build the habit of considering security as part of the development process rather than as an afterthought or a separate phase.

**This section establishes security discipline, not a security framework.** Like spec-first development (§2), the high-value practice is *having* a security thought process. Which tools or frameworks you use matters less than whether you think about security at all.

**Validate at system boundaries, trust internal code.**
- Untrusted data enters at the edges — HTTP requests, file uploads, webhook payloads, user input, external API responses, CSV imports. Validate and sanitize at these entry points.
- Once data has passed boundary validation, internal code can trust it. Don't scatter defensive validation through every function — it adds noise without adding safety.
- Treat deserialized data as untrusted. JSON from an API, data from a queue, objects from a cache — anything that crossed a serialization boundary could have been tampered with or malformed.

**Secrets management:**
- **No secrets in code. Ever.** Not in source files, not in config files committed to git, not in comments, not in variable names that hint at the value. Use environment variables, secret stores, or encrypted config files that are excluded from version control.
- **Scan for leaked secrets.** Use pre-commit hooks or CI checks that detect patterns like API keys, tokens, and passwords in committed code. Tools exist for every ecosystem — the specific tool matters less than having the check in place.
- **Rotate, don't just revoke.** When a secret is exposed, rotating it (issuing a new one) is safer than just revoking the old one, because you can't be sure the old one wasn't already captured.

**Authentication and authorization:**
- If the system has users, authentication (who are you?) and authorization (what can you do?) are not optional features — they're structural requirements. Decide on the approach early and document it in an ADR (§7).
- Apply the principle of least privilege. Users, services, and agents should have the minimum access needed for their function.
- Don't build custom auth unless you have a specific reason. Established libraries and services exist for every platform. Custom auth implementations are a leading source of security vulnerabilities.

**Dependency security:**
- Every dependency is code you don't control. Each one expands your threat surface. Audit new dependencies before adding them — check maintenance status, known vulnerabilities, and how many transitive dependencies they introduce.
- Run automated vulnerability scanning in CI. `npm audit`, `pip-audit`, `cargo audit`, Dependabot, Snyk — the tool matters less than the habit.
- Don't ignore vulnerability alerts. Triage them: patch immediately (critical/high), schedule a fix (medium), or document the acceptance and rationale in acknowledged gaps (§8) if the risk is genuinely low.

**For AI-assisted development:**
- Agents generate code without a security threat model in mind. They'll use `eval()`, concatenate SQL strings, log sensitive data, and disable CORS — not maliciously, but because they optimize for "make it work" unless instructed otherwise.
- Include security constraints in your project instruction file (CLAUDE.md or equivalent): "Never use eval. Always use parameterized queries. Never log PII." These are low-cost instructions that prevent the most common agent-generated vulnerabilities.
- Review agent-generated code for security the same way you review it for correctness. A passing test suite doesn't mean the code is secure.

**Build output hygiene:**

Build processes can silently leak source code, internal architecture, and secrets into production or version control. Source maps are the highest-profile example — they expose the entire original source tree to anyone with browser devtools — but the problem is broader.

| Leak vector | What it exposes | Prevention |
|---|---|---|
| **Source maps in production** | Full original source code, file paths, internal comments | Disable source maps in production builds, or upload them only to your error-tracking service (Sentry, Datadog) and block public access |
| **Debug builds deployed** | Verbose error messages, stack traces, component names, internal state | Enforce `NODE_ENV=production` (or equivalent) in build pipelines; fail the build if debug flags are detected in production config |
| **Secrets baked into client bundles** | API keys, tokens, internal URLs | Never reference secrets in client-side code; use server-side proxies or backend-for-frontend patterns; scan build output for known secret patterns |
| **Internal comments in production** | Architecture hints, TODO notes, developer names, internal URLs | Strip comments during minification (default for most bundlers — verify it's not disabled) |
| **Build output committed to git** | Compiled code, bundles, generated files in repo history | `.gitignore` covers `dist/`, `build/`, `out/`, `*.map`; pre-commit hook rejects commits that add files matching build output patterns |
| **Environment files in build context** | Database credentials, API keys, service URLs | `.dockerignore` and `.gitignore` cover `.env*`; build pipelines inject secrets at runtime, not via committed files |

**Rules:**
- **`.gitignore` is your first line of defense.** At minimum: `dist/`, `build/`, `out/`, `*.map`, `.env*`, `node_modules/`, `__pycache__/`. Audit it when adding new build tools — each tool may produce output in a different directory.
- **Scan build output before deploy.** A CI step that greps the build directory for source maps, `.env` patterns, known secret formats, or unexpectedly large files catches leaks before they reach production.
- **Treat build output like a public artifact.** Anything in the deploy directory should be safe for anyone to read. If it wouldn't be safe on a public CDN, it shouldn't be in the build output.
- **Pre-commit hooks for build artifacts.** Block commits that add files matching `*.map`, `dist/**`, `build/**`, or other build output patterns. Accidental commits are the most common path for build artifacts entering git history — and once in history, they persist even after deletion.

Each domain extension includes specific security guidance for its context — WordPress escaping and nonces (§20.1), Drupal access control and Form API (§21.1), source map discipline for web frontends (§17.9), etc. For projects handling regulated data (PHI, PII, payment cards), the compliance extension covers data classification, handling procedures, and audit readiness (§22.2–22.3).

### Agent Runtime Security

The "For AI-assisted development" guidance above covers code the agent *generates*. This subsection covers risks from the agent *itself* — the runtime environment where the agent operates, the tools it can invoke, and the trust boundaries around its actions.

**Why this matters:** An AI agent with shell access, network access, and filesystem access is a privileged process. If it reads hostile input (a poisoned repo, a malicious PDF, a manipulated MCP tool response), the compromise isn't theoretical — it's shell execution, secret exfiltration, or silent data modification. Treat agent security as infrastructure, not as an afterthought.

**Identity isolation:**
- Do not give agents your personal credentials. Use dedicated bot accounts, scoped tokens, and purpose-specific API keys. If the agent is compromised, the blast radius should be the agent's identity — not yours.
- Short-lived credentials are better than long-lived ones. Prefer tokens that expire (OAuth with short TTLs, temporary STS credentials) over static API keys.
- If the agent connects to external services (Slack, GitHub, email, databases), each connection should use a service account with minimum necessary permissions — not a developer's personal account.

**Sandbox untrusted work:**
- When reviewing untrusted repositories, processing external documents, or working with foreign content, run the agent in an isolated environment — a container, devcontainer, VM, or remote sandbox with no egress by default.
- The principle: if the agent gets compromised, the blast radius must be small. No access to the host filesystem, no access to credentials outside the workspace, no network access unless explicitly allowed.

**Tool and path restrictions:**
- If your agent harness supports permission policies, start with deny rules for sensitive paths: `~/.ssh/`, `~/.aws/`, `**/.env*`, credential stores. Deny outbound network commands (`curl | bash`, `ssh`, `scp`, `nc`) unless the workflow explicitly requires them.
- Restrict the agent's toolset to what the task requires. An agent performing code review doesn't need write access. An agent running tests doesn't need network egress.

**Approval boundaries:**
- The model should not be the final authority on shell execution, network egress, writes outside the workspace, secret access, or deployment. These actions need a human approval boundary — either interactive confirmation or a policy layer between the model and the action.
- This applies especially to autonomous and unattended workflows (see §23.10 for scripting-specific guidance). The more autonomous the agent, the stricter the approval boundaries should be.

**Kill switches:**
- For long-running or autonomous agent sessions, implement a heartbeat mechanism. If the agent stops checking in, terminate the process group — not just the parent process, but all child processes.
- Know the difference between graceful shutdown (the agent finishes its current step) and hard kill (immediate termination). Have both available. Don't rely on a potentially compromised process to stop itself.

**Memory and persistence hygiene:**
- Persistent agent memory is useful but also a vector. A payload that gets written into memory during one session can influence behavior in all future sessions.
- Keep memory narrow — don't store secrets, don't store raw content from untrusted sources. Rotate or reset memory after sessions that involve untrusted content.
- For compliance-bound projects, see §22.11 for additional agent-as-attack-surface guidance.

**Supply chain awareness for agent tooling:**
- Skills, hooks, MCP server configurations, and agent descriptors are supply chain artifacts. A malicious skill can contain prompt injection. A compromised MCP server can exfiltrate data while appearing to provide context.
- Review agent tooling with the same rigor you apply to code dependencies (§6). Don't install skills, hooks, or MCP configurations from untrusted sources without inspection.
- Agents installing software dependencies are vulnerable to typosquatting and dependency confusion — they'll install whatever a tutorial or error message suggests without verifying the package name. See §6 Supply Chain Attack Defenses for the full set of controls.

### Untrusted Content Boundaries and Prompt-Injection Hardening

For products with LLM features that ingest external content (web fetches, user messages, tool outputs, file contents, sub-agent outputs), prompt injection is a real attack surface. The model can't tell instructions from content unless you signal the boundary. Treat anything that crossed a trust boundary as untrusted — wrap it explicitly, tag its origin, and mark the boundary visibly to the model.

The discipline has four parts:

**1. Untrusted-content wrapper.** A typed wrapper (e.g., `UntrustedContent<T>`) around anything from outside the trust boundary. The wrapper makes it *impossible* for untrusted content to reach the model without going through the wrap path — the type system enforces what discipline alone won't. If untrusted content can be plain `String` in your codebase, the type system can't help you.

**2. Provenance tagging.** Every wrapped piece carries a structured tag identifying where it came from — `WebFetch`, `UserMessage`, `ToolOutput`, `SubAgentResult`, `FileRead`, `MCPResponse`, etc. Provenance is an enum or tagged union, not free-text. The tag travels with the content; downstream consumers can apply per-source policy without re-deriving origin.

**3. Per-provider spotlighting.** Different LLM providers respond best to different markers for untrusted content — XML-style tags, fenced blocks, explicit prefix conventions, role-tagged messages. Pick a strategy per provider and apply it consistently. The model needs a *visible* signal that a section is untrusted content rather than instructions; "the system prompt mentions it" isn't enough.

**4. Wrap sites at every boundary.** There should be exactly one entrypoint that produces wrapped content per source (one for tool outputs, one for user input, one for sub-agent results, etc.). New tool surfaces require *audit-on-add* — if a new tool returns externally-sourced content, it must wrap before the result enters the model's context. Project §3d code-review classifications should add an "audit-on-add for untrusted-content surfaces" project-specific dimension.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Plain-string content from outside the trust boundary reaching the model | Wrap-site missing |
| Spotlighting markers appearing verbatim in model output | Model treating untrusted content as instructions; spotlighting strategy needs strengthening |
| Successful prompt injection in a planted-injection regression test | The specific wrap site or spotlighting strategy that the injection bypassed |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| "Just sanitize the strings" | Codebase has scattered sanitize-on-read calls; new code path forgets one | Sanitization is whack-a-mole. Replace with `UntrustedContent<T>` typed boundary; sanitization (if any) lives at unwrap, not at every read site |
| "We'll wrap later" | Untrusted content flows as plain strings while shipping the feature; wrapping retroactively touches every callsite | Wrap before shipping. Once untrusted content is loose in the codebase, retrofitting is expensive and incomplete |
| "Every developer remembers to wrap" | New tool surface ships, doesn't wrap, model gets prompt-injected | The type system should make plain-string-from-untrusted-source uncompileable. Discipline alone is insufficient at agentic velocity |
| "Spotlighting will catch it all" | Strategy works for known injection patterns; novel injection bypasses | Defense-in-depth — spotlighting is the third layer, not the first. Wrapper + provenance + spotlighting + audit-on-add together |

**Cross-references:**
- §4 "Validate at system boundaries" (above) — this is the LLM-content equivalent for products processing external content via agents
- §3d code review — new tool surfaces should be flagged for "audit-on-add" classification under a project-specific dimension
- §0.6 anti-pattern table — "Treats untrusted content as plain strings"

### Agent Log Discipline

For projects where agents take consequential actions, the agent's activity log is the only durable record of what happened. The discipline isn't *log everything* — it's logging the right things at the right granularity, with retention and review baked in. A log that nobody reads is a write-only buffer, not an audit trail.

§4 above covers observability from the production-systems perspective; this sub-section covers the agent-specific log shape that enables incident response, compliance, and operational debugging when the agent does something surprising.

**The five log layers:**

| Layer | What gets logged | Why |
|---|---|---|
| **Tool calls** | Every tool invocation: tool name, args (redacted), result summary, duration, model, cost | Reconstruct what the agent tried; correlate with outcomes |
| **Decisions** | Every gate decision (per §14 HARD-gate response): action, severity, user choice, timestamp, scope | Audit trail for compliance; pattern analysis ("how often is the user approving X?") |
| **Compaction events** | When context compacted; what was preserved vs. dropped (per §9.6 strategic compaction) | Debug "the agent forgot something" reports |
| **Errors** | Tool failures, model errors, retry chains, fallback paths | Find brittle patterns; track provider reliability |
| **Sub-agent dispatches** | Dispatch ID, scope, behavior outcome, cost, parent linkage | Trace cross-agent work; debug recursive loops |

The 5-layer model above assumes a fairly sophisticated harness (one with context compaction and sub-agent dispatch). **Merge layers when your shape doesn't have all of them** — e.g., a single-agent product with no compaction has 3 layers (tool calls / decisions / errors); a chatbot with no agent tool surface has 2 (decisions / errors). The principle is *one layer per natural unit of audit*, not "always 5 layers." Simpler shapes have simpler logs.

Each retained layer has its own retention and review cadence. Don't conflate them — a single "agent log" file is hard to review at any one of the relevant granularities.

**Retention discipline:**

| Layer | Typical retention |
|---|---|
| Tool calls | Until session deleted |
| Decisions / grants | Persistent until user clears |
| Compaction events | Until session deleted (debug-grade) |
| Errors | At least until next release; longer for compliance-bound projects |
| Sub-agent dispatches | Per dispatch-archive policy (often age-encrypted long-term) |

Pin retention with explicit numbers in the project's recovery runbooks (§5). "Permanent" and "indefinite" aren't retention policies — they're handwaves. Concrete numbers force the conversation about acceptable storage cost vs. audit utility.

**Redact at write, not at read.** Secrets, PII, and tokens must never reach the log file in the first place. Redaction lives at log-emit, not log-read. Once unredacted content hits disk, you've created a different problem (encrypted-at-rest concerns, secret-rotation triggers, log-shipping caveats). The cheapest sensitive-data leak is the one not written.

**Review cadence — load-bearing.** A log nobody reads is a write-only buffer. Schedule periodic review:

- **Weekly:** scan tool-call patterns for anomalies (loop-stuck retries, tool-call-count spikes)
- **Per-release:** review error layer for drift (new failure modes, increased provider errors)
- **Per-incident:** pull the relevant time window across all five layers for forensic reconstruction
- **Quarterly:** review whether logged-but-never-queried fields earn their cost

If review never happens, either remove the logging cost or make review part of process.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Log silence (agent active but no log entries) | Emitter broken or downstream sink failing; nobody notices because the log is consulted reactively |
| Log volume spike (sustained N× normal rate) | Loop detected, retry storm, runaway sub-agent dispatch — symptom of a substrate issue |
| Logged-but-never-queried fields | Costs storage and write latency without producing audit value. Either start querying or stop logging |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Log-everything | Every step at full token-grain; haystack obscures needles | Log per-decision and per-tool-call, not per-message-token. Granularity is the work |
| Wrong grain for the layer | Tool calls logged at message-token grain; sub-agent dispatches logged as flat blob | Each layer has its own natural unit. Per-tool-call for tools, per-dispatch for sub-agents, per-error for errors. Don't flatten |
| Debug logs in production retention | DEBUG-level logs accumulate to permanent retention; storage cost balloons; sensitive intermediate state persists | Debug retention ≤ 7 days; promote to longer retention only with explicit justification |
| Retention without review | Logs roll off after N days but no one ever read them; sized for compliance, not used for it | Schedule the review cadence above; if review doesn't happen, drop the retention cost |

**Cross-references:**
- §14 Agent Approval Gates — gate decisions feed the decisions layer; gate table audit-trail column points at this log
- §5 Recovery runbooks — runbook detection signatures should map to log-line patterns; if you can't write the detection from the log, the log is missing the field
- §9.6 strategic compaction — compaction events are a layer worth logging
- §22 compliance — agent logs are evidence-pack components; retention policy must align with regulatory requirements
- §0.6 anti-pattern table — "Agent logs without review"

---

## 5. State Tracking & Recoverability

Every state mutation is tracked through content-addressable hashing or equivalent versioning.

- **Change detection** — diffs computed at field level, not "the whole file changed."
- **Undo/redo** — navigable version history, not a naive stack.
- **Deduplication** — identical states produce identical hashes, no redundant storage.
- **Debounced persistence** — frequent edits batched to avoid write storms, with forced caps to prevent data loss.

The result: every edit is recoverable, and you can always answer "what changed and when."

For production systems, recoverability extends beyond code versioning to disaster recovery and incident response — RTO/RPO targets, backup verification, and restore procedures. The IaC extension covers infrastructure recovery (§16.12). The compliance extension covers the procedural layer — incident response plans, DR testing, and communication plans (§22.4).

### Recovery Runbooks per Stateful Surface

For projects with persistent state — configuration files, credential stores, session databases, agent logs, working trees, on-disk caches, indexed memory — formalize *per-surface restore procedures* before they're needed in an incident. A runbook turns "we have backups somewhere" into "here's exactly what to do in the next 15 minutes."

§5 above describes how state tracking *prevents* loss; runbooks describe how to *recover* when prevention fails.

**Surface inventory.** Each project has a set of stateful surfaces. Catalog them up front:

| Common surface | Typical concerns |
|---|---|
| Configuration files | Corruption, accidental deletion, schema-incompatible upgrades |
| Credential stores (keyring, secret store, env files) | Lockout, key rotation gone wrong, host migration |
| Session / chat databases | Corruption, accidental wipe, schema migration failure |
| Agent logs / activity logs | Disk-full truncation, log rotation gone wrong |
| Working-tree / branch state | Force-push accident, branch deletion, stash loss |
| Persistent caches | Stale invalidation, partial corruption |
| Indexed memory / embeddings | Index corruption, drift from source-of-truth |

Illustrative; project-specific surfaces (license keys, customer-data exports, schema-state files, etc.) extend the list.

**Per-surface runbook — template fields:**

| Field | What it captures |
|---|---|
| **Failure modes** | Concrete ways this surface can fail (corruption, deletion, lock, schema mismatch, etc.) |
| **Detection** | How you find out the surface is broken — error signature, missing data, user report |
| **Restore steps** | Exact commands or procedures to recover. Numbered, copy-paste-ready, with prerequisites named |
| **RTO / RPO targets** | Recovery Time Objective (how fast must we restore?) and Recovery Point Objective (how much data loss is acceptable?). Both as numbers, not "soon" / "minimal" |
| **Prevention** | What reduces the likelihood or blast radius (snapshots, replication, validation, monitoring) |

**Worked example shape (one surface, end-to-end).** Below is one project's runbook for a credential store. Replace the platform-specific pieces (system keyring on Linux, Keychain on macOS, Credential Manager on Windows, Vault / 1Password / a secrets-manager service for cloud environments) with whatever the project actually uses; the template fields stay the same.

```markdown
## Surface: Credential store

### Failure modes
- User logged out of the credential session; agent loses access to API keys
- Credential store corruption (rare; usually after hard shutdown or migration)
- Host migration without credential export (new machine starts with empty store)

### Detection
- Agent operations fail with credential-lookup errors specific to the platform
  (e.g., D-Bus exceptions on Linux, Keychain access denied on macOS, Vault auth
  failure in cloud environments)
- API calls return 401 across all providers simultaneously
- Platform-specific lookup tool returns nothing for known service names

### Restore steps
1. Verify the credential store is reachable / unlocked
2. If reachable but empty: re-import from backup
   (e.g., encrypted JSON at a known backup location)
3. If no backup: re-issue API keys with each provider, store via the platform's
   credential CLI / API
4. Restart agent to pick up restored credentials

### RTO / RPO
- RTO: 15 minutes (from detection to working agent)
- RPO: depends on backup recency; e.g., weekly backups → worst case ~7 days
  of stale keys

### Prevention
- Scheduled backup script writes encrypted credentials to a known location
- Auto-unlock on login configured at the OS or service-account level
- Probe at session start that exercises one credential lookup; alert if it fails
```

The shape carries information density: detection signatures help detect; numbered restore steps work under stress; RTO/RPO numbers are real commitments; prevention closes the loop. The same shape applies to other surfaces — the template doesn't change, the platform specifics do.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Surface drift (project ships a new stateful surface but no runbook) | New surface deployed without lifecycle planning; first incident discovers the gap |
| Untested runbooks (>6 months without exercise) | Restore steps may have rotted (commands changed, paths moved, deps different); first real incident finds out |
| RTO/RPO without numbers ("soon" or "minimal" instead of concrete values) | The runbook is aspiration, not policy; can't be evaluated against incident outcomes |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Runbook-as-aspiration | Runbook exists; no one has tested the restore steps | Run a quarterly recovery drill on at least one surface; rotate which surface |
| Runbooks without RTO/RPO | "Recover when convenient" | Numbers, even rough ones (RTO: 15m / 1h / 1d; RPO: minutes / hours / days). Forces the conversation about acceptable loss |
| Runbooks for surfaces that no longer exist | Stale runbook for an architecture two refactors ago | Audit-on-architecture-change: when removing a stateful surface, remove the runbook in the same change |
| Detection signatures missing | Restore steps documented but readers don't know when to invoke them | Detection is the most-skipped section but the most-needed under incident stress; never write a runbook without it |

**Cross-references:**
- §5 state tracking (above) — runbooks describe recovery from the failures §5's tracking is meant to prevent
- §8 acknowledged gaps — surfaces without runbooks are tracked gaps
- §14 agent approval gates — gates produce audit trails; runbooks restore the state behind them. HARD-gated actions warrant runbooks for the resulting state transitions
- §22 compliance — runbooks are operational-maturity evidence for compliance audits

---

## 6. Enforced Consistency Rules

Discipline is codified, not left to individual discretion.

- **Strict type checking** — no implicit `any`, no unchecked nulls. The type system is a guardrail, not a suggestion.
- **Style rules** — all theming via variables, no hardcoded values, reuse existing patterns. Documented in an audit file with resolution tracking.
- **Environment isolation** — fixed ports, pinned runtime versions, isolated dependency environments (virtualenvs, lockfiles).
- **Resource guardrails** — hard timeouts, memory caps, and global kill switches on test runners and build processes.

### Dependency Hygiene

Every dependency is code you didn't write, don't fully understand, and can't directly control. Each one adds maintenance burden (updates, vulnerability patches, breaking changes) and expands the project's attack surface. The discipline isn't "avoid dependencies" — it's "add them deliberately and maintain them actively."

- **Justify additions.** Before adding a dependency, check: does the standard library already cover this? Is the dependency actively maintained? How many transitive dependencies does it pull in? A package that adds one function but imports 40 sub-packages is a bad trade-off.
- **Pin versions and use lockfiles.** Lockfiles (`package-lock.json`, `poetry.lock`, `Cargo.lock`, etc.) ensure reproducible builds. Commit them. Without a lockfile, the same code can produce different builds on different machines.
- **Keep dependencies current.** Don't let them drift years behind. Set a cadence — monthly or quarterly — for reviewing and updating. Small, frequent updates are less risky than large, infrequent jumps across major versions.
- **Audit for vulnerabilities.** Run automated scanning regularly (§4 Security Discipline covers this in more detail). Don't ignore alerts — triage and act on them.
- **Watch for AI-introduced bloat.** Agents add packages to solve immediate problems without considering whether the project already has a similar dependency or whether the standard library suffices. Review dependency additions in PRs the same way you review code additions — if a new package appeared, ask why.

### Supply Chain Attack Defenses

Typosquatting, dependency confusion, and package compromise are real attack vectors — not theoretical risks. The Axios RAT attack distributed a remote access trojan through packages with names resembling the popular `axios` library (e.g., `axio`, `axio5`). The malicious packages included working HTTP client code so casual testing wouldn't reveal the backdoor. This class of attack exploits the gap between "the package works" and "the package is safe."

- **Review lockfile diffs in PRs.** A new or changed package name in `package-lock.json`, `yarn.lock`, or equivalent is the single most visible signal that something unexpected was installed. Reviewers should verify that every new package name matches what was intended.
- **Block install scripts by default.** Many supply chain payloads execute during `npm install` via postinstall scripts. Use `--ignore-scripts` as the default and explicitly opt in for packages that need them (native modules, build tools). Document the opt-in list so new additions require justification.
- **Verify package identity before installing.** Check the exact package name, publisher, download count, and publication date against the official registry. Typosquats are typically low-download, recently published, and from unfamiliar publishers. A package with 200 downloads that looks like one with 45 million is not the same package.
- **Proxy through a private registry for production projects.** Use a registry proxy (Artifactory, Verdaccio, npm Enterprise) that only allows pre-approved packages. This eliminates typosquatting entirely for the install path — if the package isn't in the allowlist, it can't be installed.
- **Use scoped packages for internal code.** Publishing internal packages under an organization scope (`@org/package-name`) prevents dependency confusion attacks where an attacker publishes a public package with the same name as an internal one.

**For AI-assisted development:** Agents are especially susceptible to supply chain attacks. They'll install whatever package a tutorial, Stack Overflow answer, or error message suggests — without verifying the package name against the official registry. Include this instruction in your project instruction file: *"Before installing any new dependency, verify the exact package name, publisher, and download count on the official registry. Do not install packages from copy-pasted commands without verification. If a package name looks like a popular package but doesn't match exactly, stop and flag it."*

---

## 7. Documentation as Constraint

Documentation is prescriptive, not descriptive. It defines what is allowed, not what exists.

### Living Audit Files

- **Style/CSS audit** — what patterns are allowed, what's banned, what's been fixed. Updated as issues are resolved.
- **UX audit** — inventory of known issues by severity, with resolution status.
- **Critical rules** — mandatory behaviors stated as imperatives: "visually inspect generated assets before reporting success," "read before editing," "run tests before committing UI changes."

### Architecture Decision Records (ADRs)

For every non-obvious choice, document:
- **Context** — what problem prompted the decision.
- **Decision** — what was chosen.
- **Alternatives considered** — what was rejected and why.
- **Consequences** — what this decision makes easier and harder.

This prevents re-litigation of settled decisions by future contributors (including AI).

### Audience targeting

Different docs serve different audiences — senior engineers (deep technical context, library names, version pins), executives or stakeholders (decisions and tradeoffs without jargon), operations / SRE (runbooks, recovery steps, signals), end users (task-oriented guides), AI agents (prescriptive ground truth without ambiguity). Specify the audience in the doc's frontmatter or opening line. Audience determines technical depth, jargon density, and what context the reader is assumed to already have.

When asking the AI to *generate* documentation, name the audience in the prompt — *"target a senior engineering audience"* changes the output significantly from *"write for an executive stakeholder"*. Mode-specific (§14): doc generation is implementation mode; audience is one of the inputs.

**Diátaxis as a complementary lens.** [Diátaxis](https://diataxis.fr/) (Daniele Procida) classifies documentation into four types — tutorials, how-to guides, reference, and explanation — each serving a different reader need and mode of engagement. This decomposition is orthogonal to audience targeting (a single audience often needs all four types) and is rigorous enough to detect when documentation is mixing concerns: a "tutorial" that's actually reference, an "explanation" hiding how-to steps. Audience targeting is the first cut (*who is this for?*); Diátaxis is the second cut (*what kind of content is this?*). Both apply to any doc.

### Cross-Implementation Research

When committing to a foundational architectural approach where alternatives have meaningful trade-offs (an agent loop architecture, an edit-format strategy, a sub-agent model, an authentication framework, a state-management pattern), audit alternatives systematically *before* locking the choice. The audit produces a research doc; the research doc feeds the ADR.

**Research doc structure:**

| Element | What it captures |
|---|---|
| **Alternatives audited** | Named, dated, deep-read (not README-skim). Why each was selected as a comparison anchor — lineage proximity, scale relevance, ideological diversity. 3–5 alternatives is plenty; more is shallowness disguised as thoroughness |
| **Comparison matrix** | Dimensions that matter for *your* specific decision (project-specific axes, not generic checklist). Each cell concrete — "exact + whitespace-normalized + ellipsis-wildcard + fuzzy + cross-file" beats "five-level fallback" |
| **Tiered steal-list** | Tier 1: direct fixes for current pain. Tier 2: patterns to adopt as the project grows. Tier 3: patterns deliberately rejected (and why) |
| **Date and revisit window** | Audit is a snapshot of the world at date X. Note when it should be re-validated (typically 6–12 months) |

**Tie to the ADR.** The research doc and the ADR are paired artifacts. The ADR cites the research doc; the research doc enumerates alternatives in the depth ADRs typically don't. ADR explains *what was chosen and why*; research doc shows the *alternatives considered* with concrete enough depth that "why not X" is answerable. Without the research doc, an ADR's "alternatives considered" section becomes a gesture; with it, the rejection reasoning is auditable.

**Watch signals:**

| Signal | What it catches |
|---|---|
| ADR has "alternatives considered" section but doesn't cite a research doc | Either the research wasn't done, or it lives in someone's head and is lost when they leave |
| Research doc with no date | Can't tell if it's still relevant; alternatives evolve, and the doc may be auditing yesterday's versions |
| Research doc without a comparison matrix (just prose summary) | Reader can't compare across alternatives; the work didn't go deep enough to surface trade-offs at the dimension level |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Research without follow-through | Five competitors audited; no steal-list; ADR makes the choice anyway with no synthesis | The steal-list is the deliverable. Without it, the audit was effort that didn't compound |
| Comparison matrix without depth | "Yes/No" cells across 12 dimensions | "Yes" hides what kind of yes. Each cell concrete enough that a reader sees the trade-off, not just presence/absence |
| Audit N years stale | Research doc cited a version of competitor X from 2 years ago; competitor has shipped major rewrites since | Date the doc. Set a revisit window. When the world has moved, the audit's authority decays |
| Research used to justify the predetermined choice | Comparison matrix conveniently shapes itself toward what was already going to be picked | Audit an alternative the team is *suspicious* of, not just one they want to dismiss. The research is for surfacing surprises, not validating prior decisions |

**Cross-references:**
- §7 ADRs — research doc feeds the ADR's "alternatives considered" section with concrete depth
- §2 specs — research informs which alternatives are worth specifying against
- §0.6 anti-pattern table — "Cargo-culting practices" (one source of cross-impl research is *catching* patterns that look universal but actually aren't)

---

## 8. Acknowledged Gaps

Transparency about what isn't automated yet is itself a guardrail. Document these explicitly:

- CI/CD pipeline status (local-only vs. automated).
- Linting/formatting automation (manual vs. tooled).
- Pre-commit hooks (present, planned, or intentionally absent).
- Coverage thresholds (enforced or aspirational).
- Known technical debt with severity and ownership.

### Living Retros vs. Gap Registry

Two different documents serve two different jobs. Don't conflate them — they decay differently and answer different questions.

| Document | Type | Lifecycle | Answers |
|---------|------|-----------|---------|
| **Gap registry** (`docs/audits/gaps.md` or similar) | Rolling state — current view of open issues. | Mutable. Entries get added, statuses change, items close (mark ~~strikethrough~~ rather than delete — closing matters as much as opening). Always current. | "What's open right now? What's the severity? Who owns it? What triggers addressing it?" |
| **Per-release retro** (`docs/audits/v0.X.Y-retro.md` or `phase-N-retro.md`) | Point-in-time snapshot — frozen at release. | Immutable after the release ships. Never edited; new retros append, old ones stay as-shipped. | "What was true at release T? What shipped, what slipped, what was the budget actually spent on?" |

The retro is what was true *at point T*; the registry is current. A retro that gets edited later loses its value as a frozen reference. A registry that's frozen loses its value as a current-state document.

**Retro template** (one per release / phase / milestone, depending on cadence):

```markdown
# Retrospective — v0.X.Y (Phase N: <Capability>)

**Released:** YYYY-MM-DD
**Sessions:** S<N>–S<M>
**Active gaps remaining:** [list with names, severity, trigger]

## What shipped
- [Concrete deliverables, ideally with file/spec references]

## What slipped
- [Things planned for this release that deferred — with new target if known]

## Where the budget went
- [Surprises, time sinks, things that took longer than expected — useful for sizing future work]

## Decisions made
- [Pointers to decisions.md entries from this release]

## Followups
- [New gaps opened, new ADRs needed, refactors to schedule]
```

The retro stays useful for years as a reference for "what was the state of the world at v0.10.0?" The registry only ever shows the current snapshot. Both are needed; neither replaces the other.

---

## 9. Token Efficiency Practices

AI-assisted development bills by the token. Every search the AI runs, every file it reads to orient itself, every clarification question — that's spend. These practices minimize waste without reducing output quality.

**The cheapest LLM call is the one you don't make.** Every practice in this section is an instance of that principle — pre-load what's known, persist what's been derived, defer what isn't yet needed, summarize what's been used, and delegate deterministic work outside the context window. When deciding whether a practice is worth its overhead, that's the test: does it eliminate a call, shrink the call, or shorten the conversation?

### 9.1 Front-Load Context via Project Instructions

Provide a project instruction file (e.g., `CLAUDE.md`) at the repo root. This is injected into every AI session automatically. It should contain:

| Section | Why It Saves Tokens |
|---------|-------------------|
| **Exact versions** (runtime, package manager, language) | Eliminates "let me check what version" exploration |
| **Common commands** (copy-paste-ready) | No tokens spent figuring out how to run tests or start a dev server |
| **Project structure** (directory tree with one-line descriptions) | AI navigates directly instead of globbing |
| **Critical rules** (non-negotiable constraints) | Stated once, followed everywhere — no re-discovery |
| **Doc index with file paths** (topic → exact path) | AI reads the right doc on the first try instead of searching |
| **Status block** (current version, what just shipped, active gaps with names, files over budget, next phase target) | Fresh sessions know where the work *is* — not just what the project is. Eliminates "let me read the recent commits to figure out what's going on" rounds. |

**Status block specifics.** The Status block is updated *every release*, not when the project is initially set up and then forgotten. Treat it as resumable context: a fresh agent session reads CLAUDE.md and can immediately answer "what's the current version, what just shipped, what's open, where's the work going next?" Without this, every new session re-derives state from git log. Example shape:

```markdown
## Status

`v0.11.0` released — Phase 10 (save / export / reduce). Active gaps: <named-gap-1>,
<named-gap-2>. Files over the §11 budget: `<file-a>` (1002 lines), `<file-b>` (1062).
Next phase tag: **v0.12.0 — <Capability>** (scope summary).
See [ROADMAP.md], [v0.11.0-retro.md], [decisions.md].
```

The Status block is also where the §1 Phase / Session structure surfaces visibly — naming the current phase and the next phase tag. Update it as part of the release workflow; if you forget, the next session will tell you (it'll re-derive everything from scratch and the cost will be obvious).

**Per-send re-walk.** When instruction files (CLAUDE.md / AGENTS.md / skills) can change *during* a session — the team edits CLAUDE.md mid-session, a skill gets updated, AGENTS.md gets refined as you work — re-walk per *send* rather than per *session start*. Loading once at session start means the agent runs against stale instructions for the rest of the conversation, which becomes a real problem when those files are actively maintained. SessionStart hooks (§14) fire only at session start; per-send re-walk is the live-edit alternative. The cost is small (a few hundred tokens per re-walk for short files); the benefit is that edits land instantly without restart. Harness-dependent: support varies. When the harness supports per-send re-walk, prefer it for projects under active CLAUDE.md / skills development.

### 9.2 Persistent Memory Across Sessions

Maintain a memory file that carries learnings between conversations:

- **Known pitfalls** — framework quirks, API limitations, broken assumptions. Without this, the AI rediscovers the same dead ends every session.
- **Selector/API workarounds** — hard-won knowledge about what doesn't work and what to do instead.
- **Architecture patterns** — e.g., "adding a new component type requires updates in these 6 files." Prevents a codebase search every time.
- **Pre-existing failures** — known test failures that aren't your bugs. Prevents the AI from spending tokens diagnosing out-of-scope issues.

### 9.3 Pre-Derived Codebase Understanding

The most expensive repeated cost is not file reads — it's the agent re-deriving the same conclusions about your codebase every session. "This is an Express app, routes go here, services call the db layer, config lives in env vars" — that understanding gets rebuilt from scratch each time unless you write it down as statements of fact.

Maintain a **codebase understanding document** (e.g., `CODEBASE.md` at the repo root). This is not architecture docs, not a directory map — it's the conclusions the agent would reach after exploring, written in advance so it never has to.

**What to capture:**

| Category | Example |
|----------|---------|
| **How to do common tasks** | "To add a new API endpoint: create a route file in `src/api/`, a service in `src/services/`, and a migration in `db/migrations/`. Register the route in `src/api/index.ts`." |
| **Where things live and why** | "All database queries go through `src/db/` — never call the DB directly from a route handler. This is enforced by convention, not tooling." |
| **How components connect** | "Routes call services. Services call db. Services never import from routes. DB functions return plain objects, not ORM models." |
| **Runtime behavior** | "The app reads config from environment variables at startup. No hot-reload for config — restart required." |
| **Non-obvious constraints** | "The `users` table has a unique constraint on email, but the app validates uniqueness in the service layer before hitting the DB to return a friendlier error." |
| **Testing patterns** | "Integration tests use a separate test database, created fresh per suite via `scripts/reset-test-db.sh`. Unit tests mock the db layer." |

**What NOT to capture:**

- Things that change every sprint (use Active Change blocks for that)
- Opinions or aspirations ("we should refactor X") — only capture what IS, not what should be
- Anything already in MEMORY.md — no duplication

**When to update it:**

- After completing a feature that changes how the codebase works (new layer, new pattern, new convention)
- After an agent session where the agent had to re-derive something that should have been pre-written
- As part of the "Before Every PR/Merge" checklist

**The key instruction in CLAUDE.md:**

```
Read CODEBASE.md before starting any task. Treat it as ground truth for how this project works.
Do not re-derive what is already stated there. Only explore files you plan to modify.
```

The goal is zero "let me understand the codebase" processing. The agent reads the document and already understands. When the codebase evolves, the document evolves with it.

### 9.4 Documentation That Replaces Exploration

Every doc the AI doesn't have to search for is tokens saved:

- **Audit files with resolution status** — the AI checks whether an issue is already fixed instead of re-investigating.
- **Convention docs** — the AI follows a documented pattern instead of inferring one from scattered examples.
- **Decision records** — "we chose X over Y because Z." Prevents re-evaluation of settled decisions.

### 9.5 Structural Habits

- **Link docs to specific file paths** — `see [tools/definitions.ts](src/tools/definitions.ts)` not "see the definitions file." Eliminates glob/grep round-trips.
- **Pin environment details** — fixed ports, fixed paths, fixed versions. Each ambiguity resolved costs a tool call.
- **Delegate broad searches to subagents** — use cheaper/smaller models for exploration; keep the primary context focused on implementation.
- **Keep instruction files concise** — a 200-line memory file costs less per session than a 2000-line one. Link to detail files rather than inlining everything.

### 9.5b Progressive Disclosure

The most expensive context is context the agent doesn't currently need. Several practices above (front-loading, pre-derived understanding, structural habits) give the agent what it *will* need; **progressive disclosure** is the inverse — *don't load what it doesn't yet need, and let go of what it's done with.*

This shows up in four domains, all instances of the same pattern:

| Domain | Static (default) | Progressive disclosure |
|---|---|---|
| **Tool schemas** | All MCP/tool schemas live in context every turn — measured at 40–80% of context cost on tool-heavy setups | `search` → `describe` → `execute` pattern: cheap meta-tool to discover what's available, on-demand schema load for the chosen tool, then call it |
| **Tool inventory** | Every available tool's full description is exposed up front | Top-K retrieval over the toolset; load the 3–5 most relevant tools for this turn's task |
| **Data** | Fetch full records, full diffs, full logs into context | Fetch summaries / IDs / row counts first; pull the full record only when the agent needs the detail; summarize what's been used rather than carrying it forward |
| **Workflow** | LLM orchestrates each step in natural language; intermediate state lives in context | Pre-agent CLI work for known-deterministic data gathering; LLM emits code that runs the workflow elsewhere; only the final result returns to context |

**The trade-off.** Progressive disclosure usually costs more *round-trips* (extra search/describe calls, multi-step retrieval) in exchange for fewer *tokens per turn*, and constant — rather than linear — context cost as the toolset grows. On interactive sessions the round-trip cost shows up as latency, often ~50% slower than a static loadout. For high-frequency or large-toolset work, the token reduction is dramatic enough to justify the wait — observed input-token reductions of 90%+ are real once toolsets pass a few dozen tools.

**When to apply:**
- **Tool schemas:** when MCP/tool count exceeds ~10, any single tool's schema exceeds ~1 KB, or measured tool metadata exceeds ~30% of context.
- **Data:** always — preferring summaries-then-detail is rarely wrong, even at small scale.
- **Workflow:** when the workflow is deterministic (no per-step LLM judgment needed) and the intermediate state is large.

**When *not* to apply:**
- One- or two-tool setups where lazy loading adds round-trips without saving meaningful tokens.
- Latency-critical interactive work where the extra round-trips hurt UX more than the tokens cost.
- Workflows where the LLM legitimately needs to see intermediate state to make the next decision.

**Conversation cache as ally.** When a tool's schema has already been loaded earlier in the conversation, the harness's prompt cache typically holds it cheaply for the rest of the session. Lazy loading isn't lazy *forever* — it's lazy on first use, then cached. Design the discovery flow so frequently-used tools end up loaded once and reused.

### 9.6 Context Window Optimization

Beyond reducing per-lookup cost, there are structural strategies for getting more value from the context window itself — the finite budget of tokens the model can hold at once.

**Model routing for subagents:**

Not every task needs your most capable (and most expensive) model. When your tooling supports model selection for delegated tasks, match the model to the task complexity:

| Task type | Model tier | Rationale |
|-----------|-----------|-----------|
| File search, codebase exploration | Lightweight (fast/cheap) | Pattern matching doesn't need deep reasoning |
| Single-file edits, formatting, simple refactors | Lightweight | Clear instructions, bounded scope |
| Multi-file implementation, feature work | Standard | Balances capability with cost for typical coding |
| Complex architecture, cross-cutting refactors | Most capable | Needs to hold multiple subsystems in context simultaneously |
| Security analysis, compliance review | Most capable | Can't afford to miss vulnerabilities or misinterpret requirements |

Default to the standard tier for most coding. Upgrade when the first attempt fails, the task spans 5+ files, or the task involves security or architectural decisions.

**Strategic compaction:**

Most agent harnesses automatically compact conversation history when the context window fills. This is usually better than hitting the limit and losing context abruptly, but automatic compaction can discard context you still need. When your tooling supports it:

- Compact manually at logical boundaries — after completing a feature, after exploration, before switching to a different area of the codebase. This preserves context coherence better than automatic mid-task compaction.
- Before compacting, save important intermediate state to files (session summaries, investigation findings, partial plans). The agent can re-read these cheaply; re-deriving them is expensive.
- If your workflow involves heavy exploration followed by focused implementation, compact between the two phases — the exploration context is no longer needed once you've captured the conclusions.

**MCP and tool context costs:**

External tool integrations (MCP servers, database connections, API integrations) consume context window space for their tool definitions, schemas, and response payloads. This cost is ongoing — every tool's schema is present in context even when not in use, and **measured at scale, tool metadata routinely accounts for 40–80% of total context cost** depending on toolset size. It's the largest single dimension to leave unmanaged.

Three layers of mitigation:

1. **Prune what you don't need.** Enable only the tools required for the current task. An agent doing code review doesn't need database and deployment integrations loaded. Audit the tool list periodically — a single unused tool can account for the majority of tool-call traffic in a workflow.
2. **Lazy-load what you do need.** Prefer MCP servers that follow a `search` → `describe` → `execute` pattern (or equivalent dynamic-toolset architecture) — schemas load on demand rather than at session start. With a dynamic toolset, context cost stays roughly constant in the number of tools available; with a static one, it grows linearly. See §9.5b for the broader principle.
3. **Wrap when you can't redesign.** When the underlying server is static and you can't change it, wrap it: route through a thin proxy, expose only the subset of tools you actually use, or substitute a CLI wrapper bundled into a skill. The skill loads on demand; the MCP server's tool definitions occupy context permanently.

**On tool *design* (when you're building, not consuming):** tools designed for agentic workflows look different from API wrappers. They're single-purpose at the workflow level (one tool per task the agent actually needs to do, not one tool per HTTP endpoint), have clear and constrained inputs, return only what's needed, and bundle related operations (a `manage_X` tool that handles common workflows usually beats separate `create` / `update` / `delete` tools). API wrappers that mirror every endpoint produce the bloat this section is trying to mitigate.

**Tool responses are also progressive.** When a tool's natural response is a large object (a full PR diff, a long log, a complete record), prefer returning a summary or set of IDs by default with a follow-up call for detail. Carrying the full object forward in context every turn is the equivalent of a static schema for response data.

### 9.7 Measuring Efficiency Over Time

Raw token counts mislead when models or workloads shift. Two metrics give you a stable view of efficiency across model tiers and run frequencies.

**Effective Tokens (ET).** Apply model-cost multipliers and token-type weights so a "10% savings" means the same thing regardless of which model ran it:

```
ET = m × (1.0 × input + 0.1 × cache_read + 4.0 × output)
```

Approximate model multipliers (set yours from current pricing): Haiku-class ≈ 0.25×, Sonnet-class ≈ 1.0×, Opus-class ≈ 5.0×. Cache-read tokens are weighted at ~0.1× because they cost roughly an order of magnitude less than fresh inputs. Output tokens are weighted at ~4× because they cost several times more per token than inputs.

A 10% ET reduction means a genuine 10% cost reduction, regardless of the model mix that produced it. A 10% raw-token reduction can be illusion (you switched a workload from Opus to Haiku) or worse-than-it-looks (you switched the other way).

**Weight by run frequency.** When prioritizing efficiency work across multiple recurring agent workflows (CI runs, scheduled audits, daily summaries), multiply the per-run ET savings by run frequency. A 60% reduction on a workflow that runs 7 times per day compounds to far more aggregate savings than the same reduction on a once-weekly task. Optimize the high-frequency runs first.

### Cost Caps and Budget Gates

Measurement (ET formula above) tells you what costs were spent. Cost caps tell the harness when to *stop* spending. For projects running agents at scale — many invocations per day, many sub-agent dispatches, many provider calls — caps are the difference between predictable cost and surprise bills.

**Three layers of cap:**

| Layer | What it caps | When it triggers |
|---|---|---|
| **Per-task** | Cost of one user request from prompt to result | Reaches limit during execution; agent halts and asks |
| **Per-session** | Cost across one chat session / interactive run | Cumulative across a session; cap applies to total session spend |
| **Per-day (or per-period)** | Total spend across a time window — usually per-user-per-day | Caps total window spend; affects new sessions starting |

When a cap is reached, the gate is HARD per §14 — block until user approves continuation. Don't soften to SOFT (auto-continue) on cost caps; the user needs the explicit choice.

**Force-over-cap typed-confirm.** A SOFT "click to continue" gate normalizes blowing through the cap. Use a *typed confirmation* — the user types the cost figure or a phrase like `"continue over $20"` — to override. Typing forces a beat of attention that clicking doesn't. The harness should record the override (action / cost / who-approved / timestamp) in the audit trail (§4 agent log decisions layer).

**Escalation paths:**

| Scenario | Path |
|---|---|
| Per-task cap hit on a typical workload | Likely the cap is set too low; revisit. Don't normalize blowing through |
| Per-session cap hit late in a complex task | Either the task was bigger than estimated, or the agent is looping. Halt and inspect |
| Per-day cap hit early | A workflow is running away. Block subsequent sessions; investigate the per-task pattern |

**Watch signals:**

| Signal | What it catches |
|---|---|
| Caps consistently hit at typical workload | Caps too low; user is fighting the system rather than getting useful gates |
| Force-over-cap fires routinely (>10% of cap-hits) | Either the cap is mis-calibrated or the typed-confirm is being clicked through |
| No cap-hit telemetry over weeks at known agent activity | Caps are set so high they're aspirational; effectively no gate |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Hard caps without escalation | User gets blocked mid-task with no path forward except restart | Force-over-cap typed-confirm gives a real path; don't gate to a dead end |
| Caps without measurement | "We have caps" but no ET tracking; can't tell if caps are calibrated | §9.7 ET measurement is the prerequisite for sane cap calibration |
| Per-day cap without per-task / per-session | One runaway task burns the daily budget; subsequent legitimate work is blocked | Cap at multiple layers; the most-binding fires first |
| Caps in policy doc but not in code | Documentation says "max $X per day" but no enforcement | Caps must be enforced in the harness (a hook, a settings constraint, etc.). Doc-only caps are aspiration |

**Cross-references:**
- §9.7 ET formula (above) — measurement is the prerequisite for cap calibration
- §14 Agent Approval Gates — cost caps are HARD gates; the gate table should include cost-cap rows
- §4 agent log discipline — cap decisions go in the decisions log layer

---

## 10. Change Propagation Maps

For every recurring change type, document which files must be updated and in what order. This is the single highest-value token optimization: without it, the AI rediscovers the dependency chain every session through grep and file reads. With it, zero search cost.

```
| Change type         | Files touched (in order)                              |
|---------------------|-------------------------------------------------------|
| New component type  | types → definitions → renderer → main → i18n → gallery |
| New API endpoint    | backend/routes → middleware/proxy → frontend/api-client |
| New UI element      | component file → styles → main integration             |
| Schema change       | types → validation → affected configs                   |
```

**Maintain this table in the project instruction file** (e.g., CLAUDE.md) or the persistent memory file — wherever the AI reads it at session start.

Update it whenever a new recurring pattern emerges. If you've done the same type of change three times and touched the same files each time, it belongs in the map.

---

## 11. File Size Budgets

Large files are the primary driver of both token cost and technical debt:

- A 500-line file costs ~1,500 tokens per read. If the AI reads it 3 times per session, that's 4,500 tokens on one file.
- A 2,000-line file costs ~6,000 tokens per read. Three reads = 18,000 tokens.
- A 4,000-line file costs ~12,000 tokens per read. Three reads = 36,000 tokens — on a single file.

**Budget: files over 400 lines are candidates for extraction.** Not a hard rule, but a signal to evaluate whether the file has accrued multiple responsibilities.

Signs a file needs splitting:
- It appears in every change propagation map (it does too many things).
- Multiple unrelated functions live in the same file.
- The AI regularly reads the whole file but only modifies 10-20 lines.
- Merge conflicts happen frequently in the file.

Splitting large files also reduces blast radius: a change to one extracted module doesn't require the AI to re-read 3,000 unrelated lines for context.

### Documents whose section IDs are external contracts

The 400-line budget targets *source code* — files that ship as part of an application. It also applies to most design docs, with a typical ceiling of ~800 lines (split when there are clear sub-topics). It does **not** apply to documents whose section identifiers are external contracts.

A canonical example is this very document. Sections of `umami.md` are referenced as `§0.6`, `§3c`, `§9.1`, etc., from extension files, downstream consumers, agent skills, and bookmarks. Renumbering or splitting would break those references silently. The cost of preserving stable IDs outweighs the benefit of staying under a line budget.

For documents in this category:
- The budget is **suspended**, not removed. Track the size as a gap (§8) and revisit if the file grows large enough that agents truncate it on read or that humans can no longer scan it.
- When growth becomes untenable, the right answer is usually **extraction along an orthogonal seam** — split out a coherent subsection that has minimal cross-references *into* the rest of the document. Update every cross-reference in lockstep, version-bump the corpus, and post a renumber note.
- If a file in this category is approaching the size where action is unavoidable, document the candidate seam in the gap registry well before the split — the seam is easier to identify in advance than under pressure.

---

## 12. Lightweight Change Tracking

Per-feature discipline without framework overhead.

### Starting a Feature

Write 5-10 lines in the persistent memory file:

```markdown
## Active Change
Branch: feat/feature-name
Scope: What this change does (one line)
OUT: What is explicitly not in scope
Magnitude: S / M / L / XL
Acceptance:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Tests pass, baselines updated (if UI)
```

**Magnitude estimates** prevent the most common planning failure: starting a "small change" that turns out to touch 15 files across 3 layers. This is not a time estimate — it's a scope estimate.

| Size | Meaning | Signal to stop and re-scope |
|------|---------|----------------------------|
| **S** | 1–3 files, one layer, no new patterns | You're past 5 files |
| **M** | 4–10 files, one layer, or a new pattern within existing architecture | You're past 12 files or touching a second layer |
| **L** | 10+ files, multiple layers, or a new architectural pattern | Scope is growing beyond the original acceptance criteria |
| **XL** | Cross-cutting change affecting most of the codebase | Consider splitting into multiple smaller changes |

If the actual magnitude exceeds the estimate by more than one step (estimated S, actually L), stop and re-scope before continuing. The estimate was wrong, which means the understanding was wrong, which means the acceptance criteria may also be wrong.

The AI sees this at session start and knows the target. No clarification questions, no re-scoping.

### Finishing a Feature

Move one paragraph to a decisions log (`docs/decisions.md`), append-only, reverse chronological:

```markdown
## YYYY-MM-DD — Feature Name (branch → main)
Decision: What was chosen and why.
Rejected: What was considered and why it was rejected.
Files changed: List of key files modified.
```

This is your archival trail. It costs ~50 tokens per entry when the AI scans the file, and it prevents re-litigation of settled decisions.

### Session Handoff

When a session ends mid-work, write a handoff block in the memory file:

```markdown
## Session Handoff
Branch: feat/feature-name
Last completed: What was finished this session
Next: What should happen next (with file paths and line numbers)
Blocked: Any blockers, or "None"
Test status: Which layers have been run, which haven't
```

Remove the handoff block once the next session has picked up the work.

---

## 13. Dead Code Hygiene

Unused code is invisible debt that compounds. It inflates files (increasing token cost per read), creates false grep matches (wasting search tokens), and causes import removal bugs when the AI deletes what it thinks is unused.

### Rules

- **When removing or replacing a function**, grep for all references before deleting. This prevents the class of bug where an import is removed but still referenced as a type cast or in a dynamic context.
- **When extracting shared helpers**, verify every call site is updated in the same commit. Partial migrations — where some code uses the old local helper and some uses the new shared one — are the most common source of subtle bugs.
- **Never leave unused imports or exports for "later"** — the cost of removing dead code only increases as more code accumulates around it.
- **Delete, don't comment out.** Commented-out code is noise that costs tokens to read and never gets uncommented. Git history preserves anything you might need back.
- **POC artifacts have a lifecycle too.** Proof-of-concept and exploratory code (§3b) should be reviewed periodically. If a POC has been fully integrated or the approach was abandoned, delete the directory. If it documents a useful rejected approach, keep it with a README — but don't let `poc/` become a graveyard of unexplained experiments.

### Task-Scoped Deletion vs. Incidental Findings

Dead code discipline does not override scope discipline (§3b). The rule is:

- **Task-scoped deletion:** If your change makes code unused (removed a function's last caller, replaced a helper with a shared utility, deleted a feature), delete the now-dead code in the same commit. That dead code was produced *by your change* — cleaning it up is part of the change, not scope creep.
- **Incidental findings:** If you notice unrelated dead code while working on an unrelated task — a function nobody calls, a commented-out block, an unused import in a file you didn't touch — **mention it, don't delete it.** Report findings in the PR description, a follow-up issue, or a TODO in the audit file (§7). Deleting unrelated dead code inflates the diff, mixes concerns, and makes the PR harder to review.

**The test:** "Did my change make this code dead, or was it already dead?" If already dead, it's a separate task. Both matter; don't conflate them.

---

## 14. Agent Orchestration

When your AI tooling supports multi-agent workflows — a lead agent delegating to specialist workers — the same guardrail principles apply, but the coordination model introduces new opportunities for token efficiency and new risks for waste.

This section is tool-agnostic. The patterns apply whether you're using Claude Code, Cursor, Windsurf, Copilot Workspace, or any agentic framework that supports delegation.

### The Orchestration Model

Most multi-agent systems follow the same pattern:

```
Human
  └─→ Lead Agent (full context, all tools)
        ├─→ Worker A (restricted context, read-only tools)
        ├─→ Worker B (restricted context, specific tools)
        └─→ Worker C (own context, own tools)
```

Each worker gets its own context window, a restricted toolset, and focused instructions. Results are summarized back to the lead. The lead's context stays clean — it never sees the 50 files Worker A read during exploration, only the 3-sentence conclusion.

### Modes of AI Use — Implementation, Thinking, Reviewing

When working with AI agents, distinguish three modes. They have different prompt patterns, different output formats, and different success criteria. Most projects implicitly default to implementation mode; the other two are equally important and often under-used.

| Mode | What you're asking for | Output shape | Examples |
|---|---|---|---|
| **Implementation** | Working code, executed action | Diff, file edits, completed task | "Write the auth middleware", "Fix this bug", "Refactor X" |
| **Thinking** | Clear reasoning, alternatives, tradeoffs | Document, decision matrix, recommendation with rationale | "Help me reason through this design", "Compare these approaches", "What are the tradeoffs of X vs Y?" |
| **Reviewing** | Critique, structured findings, attention routing | Findings report, prioritized callouts, file:line citations | "Audit this for security issues", "Review this PR", "Where does this break the contract?" |

**Implementation mode** is what most of umami covers — working-code outputs. The agent acts.

**Thinking mode** is the agent as thinking partner. The output is *reasoning made visible* — alternatives laid out, tradeoffs named, recommendations with reasoning. The §3c interactive decision planning protocol operationalizes this mode.

**Reviewing mode** is the agent as critic. Output is structured findings, not approval/rejection. The agent surfaces issues; humans decide what to act on. The §0.7 audit protocol and §3d code review operationalize this mode.

**Why this matters:** the three modes have different prompt patterns. An implementation prompt that works ("write a login form using these libraries") often fails in thinking mode — a different shape is needed ("walk me through the tradeoffs of OAuth vs. password-based auth for this app, with at least two recommendations and reasoning"). Specifying mode up-front in the prompt or skill is part of getting good output. Combined with the output-format discipline from §3c, this gives the agent a clear target instead of letting it guess.

**Mode in skills.** The skill library below contains skills in all three modes. Implementation-mode skills (codebase-search, refactor-helper) act. Thinking-mode skills (`/architectural-tradeoff`, `/migration-path-analysis`) elicit structured reasoning visible in the output. Reviewing-mode skills (`/umami-audit`, `/umami-omnibus-reviewer`) produce structured findings.

### Delegation Principles

**Delegate when:**

- The task is **exploratory** — searching, reading, profiling. Worker context is disposable; don't pollute the lead's context with search results.
- Tasks are **independent and parallelizable** — security review, performance review, and test coverage review can run simultaneously.
- The task produces **verbose output** that only needs a summary — test suite runs, linting reports, dependency audits.
- A **cheaper/faster model** can handle it — codebase search and file reading don't need your most capable model.

**Don't delegate when:**

- The task requires **back-and-forth with the user** — delegation adds latency to every exchange.
- The task is **trivially small** — spawning a worker for a single grep adds overhead without savings.
- The task **depends on the lead's accumulated context** — if the worker would need the full conversation history to do its job, delegation doesn't save tokens; it duplicates them.

**Delegation as a token-cost lever.** Beyond context cleanliness, scoping toolsets per specialized subagent is a measurable cost reduction in its own right. A monolithic agent with every tool loaded pays for every tool's schema on every turn; specialized subagents with tool subsets pay only for the tools relevant to their task. Observed token-overhead reductions of ~50–60% are common when a single fat agent is split into purpose-scoped workers. This compounds with the orchestration benefits — it's not a separate technique.

### Model Routing — Delegate to Cheaper Models

Not every sub-task requires your most capable (and most expensive) model. Model routing is the practice of matching task complexity to model cost — sending expensive reasoning to a flagship model and routine work to a cheaper, faster one.

**Why this matters for token budgets:** A flagship model (Opus-class) may cost 10–15x more per token than a fast model (Haiku-class). If 60% of your agent's work is exploration, search, and boilerplate — tasks any competent model handles — you're overspending by 6–9x on that portion. Model routing isn't optimization theater; it's the single highest-leverage token cost reduction available.

#### Routing Decision Table

| Task type | Route to | Why |
|-----------|----------|-----|
| **Codebase exploration** — find files, search symbols, read and summarize code | Fast/cheap model | Read-heavy, low reasoning. The model is a search cursor, not an architect. |
| **Boilerplate generation** — test scaffolds, repetitive CRUD, config files | Fast/cheap model | Pattern-matching, not design. A cheaper model follows a template as well as a flagship. |
| **Lint, format, style fixes** | Fast/cheap model | Mechanical transforms with clear rules. |
| **Code review — surface-level** — style, naming, dead code, obvious bugs | Mid-tier model | Needs some judgment but not deep architectural reasoning. |
| **Architecture decisions** — design trade-offs, API contracts, system boundaries | Flagship model | Requires nuanced reasoning, multi-factor trade-offs, and deep context. |
| **Complex debugging** — multi-file, multi-layer, subtle state bugs | Flagship model | Needs the full reasoning stack — hypothesis generation, evidence gathering, synthesis. |
| **Security review** — vulnerability analysis, threat modeling | Flagship model | False negatives are expensive. Don't economize on security reasoning. |
| **Spec writing and planning** — translating requirements into implementation plans | Flagship model | This is where reasoning quality directly affects downstream token spend. A better plan means fewer false starts. |

#### Implementation Patterns

**Pattern 1: Explicit sub-agent routing.** When your orchestration tool supports model selection per worker, specify the model in the delegation instruction:

```
"Explore the src/auth/ directory and summarize the authentication flow.
 Use the fast model — this is a read-only exploration task."
```

**Pattern 2: Tiered skill definitions.** In your skill library (see below), annotate each skill with the minimum model tier required:

```markdown
## Skill: codebase-search
Model: haiku (fast/cheap)
Purpose: Find files, symbols, and patterns in the codebase.

## Skill: security-review
Model: opus (flagship)
Purpose: Analyze code for security vulnerabilities and threat vectors.
```

**Pattern 3: Escalation.** Start with a cheaper model. If it returns low-confidence results or flags ambiguity, escalate to a more capable model. This is the agent equivalent of "try the easy thing first."

#### What NOT to Route Cheap

Some tasks look routine but have hidden complexity:

- **Refactoring across module boundaries** — cheap models miss cross-file dependencies and break contracts.
- **Error handling design** — choosing what to catch, what to propagate, and what to log requires system-level reasoning.
- **Anything the user will directly read** — commit messages, PR descriptions, documentation. Quality of writing correlates with model capability; cheap models produce generic output.
- **Tasks involving the user's specific project conventions** — if the model needs to internalize CLAUDE.md rules and apply them to novel situations, it needs reasoning capacity.

#### Measuring Model Routing Effectiveness

Track two metrics across sessions:

1. **Cost per completed task** — total token cost (input + output, weighted by model price) divided by tasks completed. This should trend down as you route more work to cheaper models.
2. **Rework rate by model tier** — how often does output from the cheap model get rejected or require the flagship to redo it? If rework exceeds ~15%, you're routing too aggressively — the savings are illusory because you're paying twice.

### Skill Libraries

A **skill** is a reusable set of instructions for a recurring agent task. Different tools call these different things — custom prompts, system instructions, agent templates, slash commands — but the concept is universal: pre-written instructions that replace per-session re-derivation.

```
project-root/
├── .ai/                              # Or .claude/, .cursor/, etc.
│   └── skills/
│       ├── umami-audit/              # Reviewing mode (§0.7) — process audit
│       ├── umami-init/               # Reviewing mode (§0.7b) — first-time setup
│       ├── umami-omnibus-reviewer/   # Reviewing mode (§3d) — code review pre-screen
│       ├── architectural-tradeoff/   # Thinking mode — compare design options
│       ├── migration-path-analysis/  # Thinking mode — map legacy before changes
│       ├── codebase-search/          # Implementation mode — find files/symbols
│       ├── security-review/          # Reviewing mode — vulnerability analysis
│       ├── pr-summary/               # Implementation mode — summarize a PR
│       └── data-migration/           # Implementation mode — pre-flight + rollback
```

Skills come in all three modes from "Modes of AI Use" above. Implementation-mode skills act (write code, make changes, summarize). Thinking-mode skills produce *reasoning visible in output* (alternatives, tradeoffs, recommendations with rationale). Reviewing-mode skills produce *structured findings* (audits, code review flags documents). Tag each skill with its mode so the harness invokes it with the right expectations.

**Standard skills — `umami-audit`, `umami-init`, `umami-omnibus-reviewer`:** Every project using umami should have these three reviewing-mode skills (§0.7, §0.7b, §3d). They share the same architecture: fetch the canonical spec fresh, follow the protocol, output structured findings. Each skill includes the raw URL of the umami spec so the agent doesn't search for it. See `.claude/skills/` in the umami repo for the canonical templates.

**What makes a good skill:**

- Encodes domain knowledge that would otherwise be re-derived every session.
- Defines a clear output format so results are consistent and comparable across runs.
- Specifies which tools the agent needs (and which it doesn't — restricting tools reduces risk and token spend).
- Can inject dynamic context (current git diff, recent errors, open issues) so the agent starts with fresh state, not stale instructions.

**When to create a skill:** You've given the same instructions to an agent 3+ times, or a task requires domain-specific checklists (security review, accessibility audit, compliance check).

**Token impact:** A skill that pre-loads a 200-token instruction set replaces the 2,000–5,000 tokens the agent would spend figuring out the same approach through exploration. Skills stored in the project repo also ensure every team member's agents behave consistently — same review standards, same output format, same checklists.

### Parallel Work Patterns

The highest-value use of multi-agent orchestration is **parallel review and analysis**:

| Pattern | Workers | Output |
|---------|---------|--------|
| **Multi-angle code review** | Security + Performance + Test coverage | Three independent reports, synthesized by lead |
| **Exploratory research** | One per subsystem (auth, database, API) | Each worker maps its subsystem; lead assembles the full picture |
| **Test execution** | One per test layer (unit, integration, E2E) | Parallel test runs; lead aggregates pass/fail |
| **Competing hypotheses** | One per theory for a bug | Each investigates one theory; strongest result wins |

**Coordination rules:**

- Each worker should operate on **non-overlapping scope**. Two agents editing the same file is a merge conflict waiting to happen.
- Workers should report in a **structured format** so the lead can synthesize without re-reading raw output.
- Use a **shared task list** if your tooling supports it — workers claim tasks, preventing duplicate effort.

### External Tool Integration

Most AI development tools support connecting agents to external services — issue trackers, monitoring, databases, CI/CD. The agent equivalent of giving a developer tool access.

**High-value integrations:**

| Integration | Token savings |
|-------------|--------------|
| **Issue tracker** | Agent reads issue directly (~200 tokens) instead of you copy-pasting descriptions + comments (~2,000+ tokens) |
| **Error monitoring** | Agent queries recent errors to prioritize bugs instead of you describing symptoms |
| **Database schema** | Agent queries schema directly instead of you describing table structures |
| **CI/CD pipeline** | Agent reads build logs and test results instead of you pasting terminal output |

**Selecting MCP servers and tool integrations.** Not all integrations carry the same context cost (see §9.6 — tool metadata is 40–80% of context cost on tool-heavy setups). When choosing between equivalent options, prefer ones that:

- Use a **dynamic toolset architecture** (`search` → `describe` → `execute` or equivalent) so schemas load on demand. See §9.5b for the broader principle.
- Expose **purpose-scoped tools** rather than mirroring every API endpoint. One tool per workflow task beats one tool per HTTP endpoint.
- Return **summaries or IDs** by default with detail-on-request, rather than always returning full payloads.
- **Externalize cross-cutting concerns** (auth, rate limiting, error handling, governance) into the runtime/gateway layer rather than embedding them in every tool's response.

When you're *building* an MCP server (rather than consuming one), apply §9.6's tool-design principles: single workflow purpose, lazy schema loading, clear and constrained inputs, bundle related operations into higher-level tools rather than mirroring CRUD.

**Configuration scope matters:**

- **Personal** — your credentials, your preferences. Not committed to the repo.
- **Project** — shared team integrations. Committed to the repo (without secrets) so every team member's agents have the same access.

### Agent Approval Gates

For projects where agents take consequential actions (write files, run commands, reach the network, dispatch sub-agents, modify shared state), formalize *which actions need human approval, what gets logged, and which actions are explicitly autonomy-boundary*. Without this, the harness's defaults silently determine your security posture.

§14 above describes how agents work; this sub-section describes how to gate what they do.

**Severity model:**

| Severity | Meaning |
|---|---|
| **HARD** | Blocks until approved. Agent cannot proceed without explicit user confirmation. |
| **SOFT** | Informs and proceeds unless the user countermands. Default-allow with visibility. |
| **NONE** | No live gate; the action is *structurally restricted* (sandbox path-jail, network namespace, type-system constraint). Free to execute within the structural boundary. |

Three severities are enough. NONE matters: it's the explicit acknowledgment that not every gate needs a live prompt — sometimes structural restriction is stronger than a prompt users will fatigue-approve.

**Gate table — template shape (one row per action class):**

| Column | What it captures |
|---|---|
| **Action** | The action class (e.g., "Read file outside project root", "git push to main") |
| **Gate severity** | HARD / SOFT / NONE |
| **User-visible surface** | Where the user sees the gate (grant prompt, Apply button, decision card, none) |
| **Audit trail location** | Where the disposition is recorded (tool-call log, grants registry, commit log, hooks log) |
| **Implementation pointer** | File path or module implementing the gate |

Group rows by category — filesystem ops, network ops, code-modifying ops, sub-agent dispatch, tool-output handling, hooks layer. Project-specific categories extend (e.g., "telemetry emissions" for products with metrics that include user data, "migration ops" for schema-bearing changes).

**Autonomy boundaries — always HARD regardless of session mode:**

Some actions are HARD-blocked regardless of whether the agent is interactive, scheduled, or autonomous. Policy commitments that don't soften under "trust the agent more in autonomous mode":

- Deploys to production
- `git push --force` to `main` / `master`
- Dependency changes (new package additions)
- Public-API breaking changes
- Access-scope expansion (broader sandbox grants than current)

Document these explicitly in the gate table with a note that the severity is HARD-mode-independent.

**Logging summary — companion table:**

| Log | Location | Retention |
|---|---|---|
| Tool-call log (per-message) | Project-specific (chat sessions storage, etc.) | Until session deleted |
| Grant decisions | Grants registry | Persistent until user clears |
| Commit log (agent-driven commits) | Standard `git log` | Permanent |
| Hook execution log | User-controlled | User-controlled |

Without retention info, "we have an audit trail" means nothing under compliance review (§22).

**Watch signals:**

| Signal | What it catches |
|---|---|
| Gate-table drift (action exists in code but not in table) | New action class shipped without gate-table update; the gate may be implicit or missing |
| Audit-trail gap (action happens but no log location) | Consequential action runs without leaving evidence — the gate may be there but the audit isn't |
| HARD-soften creep (action moves HARD → SOFT silently) | Approval friction is being eroded; a gate is being weakened without explicit decision |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| "We have a gate" without a table | Gates are scattered across code; no single source of truth; new contributors don't know what's gated | Maintain the gate table as source of truth; cite implementation files from the table |
| All-HARD or all-SOFT | Every action is HARD (approval fatigue) or every action is SOFT (no real gate). Neither shape works at scale | The discipline of choosing per-action is the work; uniform severity is a refusal to think |
| Audit trails for "compliance" but no review | Every action is logged to a file nobody reads | If no one reviews the log, the log isn't an audit trail; it's a write-only buffer. Either make review part of process or remove the logging cost |
| Autonomy boundaries that aren't enforced | Doc says "no force-push to main" but the agent has the credentials to do it | Enforce in code where possible (pre-push hook, branch protection); doc-only autonomy boundaries are aspiration, not policy |

**Cross-references:**
- §22 compliance — audit trails feed compliance reviews; gate tables are evidence-pack components
- §3d code review — new tool surfaces should be flagged for "gate-table update" review
- §0.6 anti-pattern table — "No agent-approval gate table"

### Lifecycle Hooks

Most agentic harnesses expose **lifecycle hooks** — user-controlled extension points where a project can insert custom behavior at well-defined moments in the agent's execution. Hooks are how you implement automated behaviors that aren't in the harness's defaults, without modifying harness code, without losing the change on the next harness update.

The four canonical events most harnesses converge on:

| Event | Triggered before | Common uses |
|---|---|---|
| **PreToolUse** | Any tool call about to execute | Block tool calls based on user-defined predicates (deny lists, allow lists, content checks); add custom approval gates beyond the harness's defaults; redact arguments before the call |
| **PostToolUse** | After any tool call completes | Log / audit, redact sensitive results before they reach the model, trigger downstream behavior (notifications, metrics, dispatch chains) |
| **SessionStart** | Chat session begins (or resumes) | Re-walk instruction files (CLAUDE.md / AGENTS.md / skills), refresh project memory, run pre-flight checks. For projects under active instruction-file development, see also §9.1 per-send re-walk |
| **Stop** | Agent loop terminates | Cleanup, summary generation, archival, write-back of session state |

Different harnesses use different names — `before_tool` / `after_tool`, `BeforeRequest` / `AfterRequest`, etc. — but the structural shape is the same: well-known points where user-supplied code runs. Names matter less than the discipline of using them.

**The "from now on when X" insight.** Any automated behavior of the form *"from now on, every time Y happens, do Z"* requires a hook. Memory and process documentation cannot fulfill these — the agent is not the runtime, the harness is. If a user says "remember to log every git push" or "block tool calls that touch /etc," that's a hook configuration, not a memory entry. Process docs that say "we always do X" are aspiration unless wired through hooks.

**Configuration shape.** Hooks are user-controlled — configured via the harness's settings (e.g., `settings.json`, `.claude/settings.json`, per-project YAML). The harness ships sensible defaults; project-specific or developer-specific hooks layer on top. Project hooks live in the repo (committed, shared); personal hooks live in user-scope settings (uncommitted).

**Watch signals:**

| Signal | What it catches |
|---|---|
| Hooks-as-aspiration (configured but never fire) | The hook is mis-targeted — its predicate doesn't match what actually runs, or it's registered for an event the agent doesn't reach |
| Hook drift (rule references deprecated tool, path, or behavior) | Codebase moved on; hook didn't. First incident discovers the gap |
| Hook overhead (slow hook delays every tool call) | Hook is doing too much — fast-path the common case, or move work to PostToolUse where latency is cheaper |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Process doc says "always do X"; no hook implements it | Documentation describes a behavior the agent doesn't perform; humans assume the agent is doing it | Wire X through a hook. If it can't be wired (the behavior depends on human judgment), update the doc to match reality |
| Hook silently swallows errors | A failing hook doesn't fire its intended action; nobody notices because the failure logs at debug level | Hook errors should be loud (write to a known location, surface in agent's session log). Silent failure is worse than no hook |
| Per-developer hooks committed to the repo | Personal preferences end up in the project's shared settings, affecting everyone | Personal hooks in user-scope settings (uncommitted); project hooks in repo-scope settings (committed). The split matters for team coordination |
| Hook proliferation (15+ hooks doing similar things) | Hard to reason about what fires when; rules conflict; debugging "why did this happen?" is expensive | Periodic hook review: consolidate similar predicates, remove dead hooks, document each remaining hook's purpose |

**Cross-references:**
- §14 Agent Approval Gates (above) — hooks are the user-controlled extension point for adding gates beyond what the harness ships. PreToolUse hooks implement custom HARD/SOFT gates
- §0.7 / §0.7b audit and init protocols — skills are SessionStart-time loaded; hooks fire on session start to refresh them
- §9.1 front-load context — SessionStart hooks can re-walk instruction files per session start

### Agent Orchestration Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| **Over-delegation** | Spawning workers for single-grep tasks | Only delegate when overhead (spawn + summarize) < doing it inline |
| **Duplicate exploration** | Lead and worker both searching the same files | Delegate exploration OR do it yourself — never both |
| **Context duplication** | Passing the full conversation to every worker | Workers get focused instructions, not the whole history |
| **Unsupervised destruction** | Worker deletes files or pushes code without review | Restrict worker toolsets; require human approval for destructive actions |
| **Skill rot** | Skills reference outdated file paths or deprecated APIs | Review skills when you update the change propagation map (§10) or codebase understanding doc (§9.3) |

### Team Coordination (Human + Agent)

When multiple developers work with AI agents on the same codebase, coordinate the humans — the agents will follow.

- **Shared conventions file, not per-developer memory.** Project instruction files (CLAUDE.md, CODEBASE.md) are the team's shared understanding. Individual agent memory files hold personal preferences. Don't let critical project knowledge live only in one developer's agent memory — if that developer leaves, the knowledge leaves with them.
- **Review agent-generated code like any other code.** Code review discipline doesn't change because an agent wrote it. The reviewer is responsible for understanding what they approve — "the agent wrote it" is not a justification for merging code no human understands (§3b — Don't Program by Coincidence).
- **Avoid parallel agent edits to the same files.** Two agents editing the same file in separate branches produces merge conflicts that are hard to resolve because neither developer fully understands the other agent's changes. Coordinate scope before starting, not after conflicting.
- **Converge on shared skills.** If two developers create different agent skills for the same task (e.g., two different security review prompts), consolidate them into the project skill library. Inconsistent agent behavior across the team produces inconsistent output.

---

## 15. Putting It Together — Checklist

### Before Starting a Feature

- [ ] Active Change block written in persistent memory (scope, acceptance criteria).
- [ ] Written spec or ADR exists for non-trivial work. If the problem isn't well enough understood to spec, start with a POC (§3b).
- [ ] For complex or unfamiliar designs: POC completed, findings documented, gap analysis done before full implementation.
- [ ] Change propagation map consulted — know which files will be touched.
- [ ] Relevant architecture docs and audits reviewed.
- [ ] Design system consulted (if UI work).
- [ ] Validation rules reviewed (if data/logic work).
- [ ] Existing skills reviewed — are there reusable templates for this type of work? (§14)

### During Development

- [ ] **Test-first:** failing test written before implementation code (§3b).
- [ ] Test passes with minimum implementation (GREEN), then refactor.
- [ ] No file exceeds the size budget without justification.
- [ ] Unused imports/exports removed immediately, not deferred.
- [ ] Grep for all references before deleting or renaming any function.
- [ ] All call sites updated when extracting shared helpers.
- [ ] Bugs investigated systematically: reproduce → isolate → root-cause → fix (§3b). No shotgun fixes.
- [ ] Exploration delegated to worker agents where appropriate (§14) — keep lead context focused on implementation.

### Before Every Commit

- [ ] **Full test suite passes** — not just the new test, the entire suite.
- [ ] No unrelated files were modified (scope discipline).
- [ ] Changes match what was requested — nothing more, nothing less.
- [ ] Generated assets visually inspected (if applicable).
- [ ] Git status reviewed — no unintended files staged.
- [ ] Dependency environment active (virtualenv, correct Node version).
- [ ] Baselines updated only for intentional UI changes.

### At Session End (if work is incomplete)

- [ ] Session handoff block written in persistent memory.
- [ ] Branch pushed so next session has the latest state.

### Before Every PR/Merge

- [ ] All test layers pass.
- [ ] No type errors (strict mode).
- [ ] Active Change acceptance criteria all checked.
- [ ] Documentation updated if architecture changed.
- [ ] CODEBASE.md updated if codebase patterns, conventions, or structure changed.
- [ ] UX/style audit consulted for UI changes.
- [ ] Acknowledged gaps updated if new debt introduced.
- [ ] `poc/` directory reviewed — any completed or abandoned experiments cleaned up (§3b, §13).
- [ ] Decision record written in decisions log.
- [ ] Active Change and Session Handoff blocks removed from memory.
- [ ] Skill library updated if a new reusable agent pattern emerged (§14).
- [ ] Skills reviewed for stale references (file paths, APIs) if codebase structure changed (§14).
- [ ] New services/endpoints have instrumentation — inbound requests, outbound calls, business operations (§4).
- [ ] No sensitive data in logs or telemetry — PII, passwords, tokens (§4).
- [ ] No hardcoded secrets — API keys, tokens, passwords, connection strings not in committed code (§4).
- [ ] No build artifacts committed — source maps, `dist/`, `build/`, compiled output not staged (§4).
- [ ] Build output safe for public access — no source maps, debug flags, or baked-in secrets in deploy directory (§4).
- [ ] New endpoints/inputs have boundary validation — untrusted data sanitized at entry points (§4).
- [ ] New dependencies justified — not duplicating existing packages, actively maintained, vulnerability-free (§6).
- [ ] New dependency names verified against official registry — exact name, publisher, download count match expectations (§6).
- [ ] New agent skills, hooks, or MCP configurations reviewed for prompt injection and over-broad permissions (§4).

---

## Principle

Speed without guardrails is just velocity toward defects. These mechanisms ensure that code — whether written by a human or an AI — is typed, tested, validated at runtime, visually regression-checked, version-tracked, and architecturally constrained before it reaches a user.
