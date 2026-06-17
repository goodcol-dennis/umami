# Rapid Development Guardrails — Project Template

This document is a template for establishing processes, testing strategies, and AI token efficiency practices that enable fast, reliable software development. It is intended to be adapted per-project and consumed by both humans and LLMs.

**This is a general-purpose template.** It must not contain references to any specific project, codebase, brand, or product. All examples should use generic descriptions. If you adapt this template for a specific project, do so in that project's own docs — not here.

**This file lives in the [goodcol-dennis/umami](https://github.com/goodcol-dennis/umami) repo** so it can be shared across projects. Do NOT copy it into a project's `docs/` folder. Instead, keep the URL in each project's `CLAUDE.md` as a reference for on-demand process audits.

> **A note on `CLAUDE.md`:** This template uses `CLAUDE.md` as the instruction file name throughout because it is the most widely recognized convention — Claude Code, Cursor, Windsurf, and other tools all read it. If your toolchain uses a different file (`.cursorrules`, `AGENTS.md`, `CODEBASE.md`, `copilot-instructions.md`), substitute accordingly. The practices are tool-agnostic; only the filename is convention.

```markdown
## Process Audit Reference
- Development guardrails (landing — start here): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
- Core companion — Quality (specs, testing, decisions, review, refactoring): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/core/umami-quality.md
- Core companion — Runtime (security, threat modeling, trust posture, state, pipeline health): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/core/umami-runtime.md
- Core companion — Process (ADRs, gaps, change propagation, change tracking): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/core/umami-process.md
- Core companion — Agents (token efficiency, file size budgets, orchestration): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/core/umami-agents.md
- Extension — Web frontend: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-web.md
- Extension — Data pipelines: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-data.md
- Extension — IaC / DevOps: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-iac.md
- Extension — Mobile: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-mobile.md
- Extension — CMS (shared): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/cms/umami-cms.md
- Extension — WordPress: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/cms/umami-wordpress.md
- Extension — Drupal: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/cms/umami-drupal.md
- Extension — Compliance: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-compliance.md
- Extension — Scripting: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-scripting.md
- Extension — Systems integration: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-integration.md
- Extension — Homelab: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-homelab.md
- Extension — Desktop (shared): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/desktop/umami-desktop.md
- Extension — Desktop Linux: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/desktop/umami-linux.md
- Extension — SPA Wrapper: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/desktop/umami-spa-wrapper.md
- Extension — Agent Workflows: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/ext/umami-agent-workflows.md
  Do NOT fetch these every session. These are reference URLs for periodic process reviews.
  When the user asks you to audit the development process, fetch the landing document
  (umami.md) first and consult its Section Navigation Map to identify which companion
  files apply. Follow the tiered audit protocol in §0.7 — determine the project's current
  adoption tier, fetch only the companion files needed for the current and next tier,
  then audit one tier above. Tier 1 audits typically don't need any companion file.
  Focus on 3-5 actionable recommendations, not comprehensive compliance. Audits are
  READ-ONLY — report findings and describe what changes each recommendation requires,
  but do not modify code or project files until the user explicitly chooses which
  recommendations to apply.
```

---

## Section Navigation Map

This document is the **landing doc** for umami v3 — it carries the framework, this navigation map, and Tier 1 practices. Tier 2+ practices live in focused companion files grouped by concern. Section numbers (`§N`) are stable identifiers across all files; the file location is metadata.

| § | Topic | File | Tier | Fetch when... |
|---|---|---|---|---|
| §0 | Project Discovery (questionnaire, tiers, AI-discipline spectrum, anti-patterns, audit and init protocols) | `umami.md` | Foundation | Always |
| §1 | Project Structure | `umami.md` | Foundation | Always |
| §2 | Specification-First Development | `core/umami-quality.md` | Structure | Features take more than one session |
| §2b | Async Channel Contracts (typed channel + origin tag + allowed-consumer list + audit-on-add) | `core/umami-quality.md` | Structure | Project has async surfaces (events, messages, worker output) and team has seen wrong-place message incidents |
| §3 | Multi-Layer Test Infrastructure | `core/umami-quality.md` | Structure | System has more than one layer |
| §3b | Development Process Discipline (TDD, debugging, verification) | `umami.md` | Foundation | Always |
| §3c | Interactive Decision Planning | `core/umami-quality.md` | Structure | Design has 3+ load-bearing compounding decisions |
| §3d | Code Review Discipline (three-layer) | `core/umami-quality.md` | Scale | Code generation outpaces human review capacity |
| §3e | Refactoring Discipline | `core/umami-quality.md` | Structure | Agents refactor at velocity |
| §4 | Runtime Validation, observability, threat modeling, trust posture, security disciplines, agent runtime security, untrusted-content boundaries, agent log discipline | `core/umami-runtime.md` | Mixed (Tier 1 floor lives in landing's *Security Essentials* below; full discipline in companion) | Threat-relevant boundaries, security depth beyond day-one floor, LLM-feature products |
| §5 | State Tracking & Recoverability (recovery runbooks per stateful surface) | `core/umami-runtime.md` | Scale | Stateful operations need rollback or audit trails |
| §6 | Enforced Consistency Rules (types, lint, deps, supply-chain defenses) | `umami.md` | Foundation | Always |
| §6b | Developer Experience and Pipeline Health | `core/umami-runtime.md` | Structure | Pipeline cycle time taxing every commit; contributors skipping local CI |
| §7 | Documentation as Constraint (ADRs, cross-impl research, audience targeting) | `core/umami-process.md` | Structure | You make decisions you'll need to explain later |
| §8 | Acknowledged Gaps (rolling registry, per-release retros, periodic dropped-item audit) | `core/umami-process.md` | Scale | Tech debt accumulating; designs / decisions / features falling off the radar |
| §9 | Token Efficiency Practices (front-loading, memory, progressive disclosure, cost caps) | `core/umami-agents.md` | Structure | Agent sessions re-derive the same codebase understanding |
| §10 | Change Propagation Maps | `core/umami-process.md` | Scale | Changes routinely touch 5+ files |
| §11 | File Size Budgets | `core/umami-agents.md` | Structure | Files long enough that agents truncate or miss context |
| §12 | Lightweight Change Tracking | `core/umami-process.md` | Scale | Work spans multiple sessions and context is lost between handoffs |
| §13 | Dead Code Hygiene | `umami.md` | Foundation | Always |
| §14 | Agent Orchestration (modes, delegation, model routing, skills, gates, hooks) | `core/umami-agents.md` | Scale | Multi-agent workflows or specialized agent delegation |
| §15 | Putting It Together — Checklist | `umami.md` | Foundation | Always |

**Companion files (core):**

- [`core/umami-quality.md`](core/umami-quality.md) — §2 · §2b · §3 · §3c · §3d · §3e — specs, async channel contracts, testing, decision planning, code review, refactoring
- [`core/umami-runtime.md`](core/umami-runtime.md) — §4 · §5 · §6b — runtime validation, security disciplines, threat modeling, trust posture, state recovery, pipeline health
- [`core/umami-process.md`](core/umami-process.md) — §7 · §8 · §10 · §12 — documentation, gap registry, change propagation, change tracking
- [`core/umami-agents.md`](core/umami-agents.md) — §9 · §11 · §14 — token efficiency, file size budgets, agent orchestration

**Domain extensions** (§16–§30) live in [`ext/`](ext/), with shared+variant clusters grouped under `ext/{domain}/` (currently `ext/cms/` and `ext/desktop/`). See [README](README.md) for the full extension catalog.

**Legacy paths (v3.1+):** Pre-v3 paths (e.g., `umami-web.md` at the repo root, `cms/umami-wordpress.md` in the old `cms/` directory) **no longer resolve** as of v3.1 — the v3.0 deprecation stubs were removed. Adopter `CLAUDE.md` files still referencing those paths get a 404; update them to the `ext/` paths shown in the Navigation Map above, or run `/umami-init` which detects legacy paths and offers automatic migration.

**Cost-aware adoption:** Tier 1 / foundation work uses `umami.md` alone — no companion file needed. Fetch concern files only when the §0.6 tier table or §0.5 mapping calls for them. On a Pro / lower-token plan, landing-only is a ~13K-token fetch instead of ~40K for the pre-v3 monolithic document.

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
| What is the trust posture? Perimeter-trust within a defined zone, zero-trust between services, or hybrid with documented handoffs? | Foundational decision that sets the depth target for §4 (security discipline, agent runtime, untrusted content), §16 (service-to-service auth, IAM), and §22 (compliance evidence). Two projects with identical layers can have wildly different security postures — and the choice belongs up front, not retrofitted. See §4 *Trust Posture* for the spectrum. |
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
| Data ingestion / pipelines | §3 (testing — data quality layer), §3b (TDD + debugging), §4 (validation), §5 (state tracking), §10 (change map per-layer) | [umami-data.md](ext/umami-data.md) | §3 visual regression (no UI yet) |
| Database / warehouse | §2 (specs — schema contracts), §3 (test doubles for DB), §6 (strict types), §7 (data dictionary as living doc) | [umami-data.md](ext/umami-data.md) | §7 UX audit (no UI) |
| API / backend | §2 (specs — API contracts), §3 (API/service tests + test doubles), §3b (TDD), §4 (validation), §6 (type checking) | [umami-integration.md](ext/umami-integration.md) | §3 visual regression |
| Web frontend | §2 (design system), §3 (all test layers including visual), §3b (TDD), §7 (UX audit, style audit) | [umami-web.md](ext/umami-web.md) | — (full template applies) |
| Mobile app | §2 (specs), §3 (unit + integration tests), §3b (TDD), §6 (strict types), §12 (release tracking) | [umami-mobile.md](ext/umami-mobile.md) | §3 visual regression (use device matrix testing instead) |
| Infrastructure / IaC | §2 (specs — infra contracts), §6 (pinning), §7 (ADRs — cloud decisions), §8 (acknowledged gaps) | [umami-iac.md](ext/umami-iac.md) | §3 visual/E2E, §4 runtime validation (use drift detection instead) |
| CMS (any) | §3 (testing), §3b (TDD), §6 (consistency — coding standards), §7 (ADRs — extension/architecture decisions), §8 (acknowledged gaps — extension risks) | [umami-cms.md](ext/cms/umami-cms.md) + platform file ([WordPress](ext/cms/umami-wordpress.md), [Drupal](ext/cms/umami-drupal.md)) | — |
| CLI / scripts only | §3 (unit tests), §3b (TDD + debugging), §6 (type checking), §11 (file size budgets) | [umami-scripting.md](ext/umami-scripting.md) | §3 visual/E2E, §4 runtime validation UI, §7 UX audit |
| Multi-layer system | All sections, but **organize §10 (change propagation) per-layer** and **organize §3 (testing) per-layer**. Consider §1 workspace partitioning if discovery/analysis phase exists alongside application code. | All that apply | — |
| Compliance requirements | §2 (specs — contracts as evidence), §3 (test evidence), §5 (state tracking — audit trail), §7 (ADRs — decision traceability), §8 (acknowledged gaps — risk register), §12 (change tracking — change management records), §15 (checklists — process evidence). These shift from "recommended" to **required**. | [umami-compliance.md](ext/umami-compliance.md) | Nothing skipped — compliance adds rigor, it doesn't remove sections. |
| Desktop app (native) | §1 (structure), §3 (unit + E2E tests), §3b (TDD), §6 (strict types, linting), §8 (acknowledged gaps — headless testing limitations), §11 (file size budgets) | [umami-desktop.md](ext/desktop/umami-desktop.md) + platform file ([Linux](ext/desktop/umami-linux.md)) | §3 visual regression (use headless E2E instead) |
| Desktop app (SPA wrapper) | §1 (structure), §4 (security — navigation policy, session persistence), §6 (consistency), §8 (acknowledged gaps) | [umami-desktop.md](ext/desktop/umami-desktop.md) + [Linux](ext/desktop/umami-linux.md) + [SPA Wrapper](ext/desktop/umami-spa-wrapper.md) | §2 (specs — you don't control the web app), §3 multi-layer testing |
| Homelab / self-hosted infrastructure | §1 (structure — documented topology), §4 (security discipline), §7 (living docs as AI context), §8 (acknowledged gaps), §15 (checklists) | [umami-homelab.md](ext/umami-homelab.md) | §2 (specs), §3 visual/E2E, §11 (file size budgets) |
| AI-assisted development (any project using agents) | §3c (interactive decision planning when designs compound), §3d (code review at agentic velocity), §9 (token efficiency), §14 (agent orchestration — delegation, modes of AI use, skills, parallel review, tool integration) | — | — |
| LLM-feature product (ships features that ingest external content via LLMs) | §4 (untrusted-content boundaries — typed wrapper, provenance, per-provider spotlighting, audit-on-add), §3d (add an "untrusted-content-surface" project-specific risk dimension), §9.6 (MCP and tool context costs apply to product-side LLM features), §14 (modes of AI use — products typically span all three) | — | §15 visual regression unless the product also has a UI |
| Project runs agents as substrate (autonomous workflows, closed-loop auto-remediation, production agentic CI, scheduled remote agents) | §14 (orchestration building blocks), §9.7 (cost caps non-negotiable for autonomous workflows), §4 (kill switches, sandboxing, identity isolation), §3 (verification gates for closed-loop patterns) | [umami-agent-workflows.md](ext/umami-agent-workflows.md) | — |

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
| Preserving project structure (structure-as-contract discipline) | §1 | Once the project commits to a structure, restructuring it has compounding cost; codify the rule and pre-identify seams before urgency |
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
| Async channel contracts | §2b | Project has async surfaces (events, messages, worker output) and team has seen wrong-place message incidents (or is at risk of them — pre-adoption count = 0 means deferred) |
| Multi-layer testing | §3 | The system has more than one layer (API + UI, pipeline + warehouse) |
| Interactive decision planning | §3c | A design has 3+ load-bearing decisions that compound on each other |
| Refactoring discipline | §3e | Project has agents refactoring code at velocity, or refactoring is bundled with feature work creating reviewability problems |
| Threat modeling | §4 | Project has security-relevant boundaries (external integrations, user input, agent tools touching privileged operations) past prototype phase |
| Trust posture | §4 | Project has multiple services, multiple trust zones, or compliance/insurance requires documented posture |
| DevEx / pipeline audit | §6b | Pipeline cycle time taxing every commit; contributors skipping local CI; identical gate configs across projects without local justification |
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
| Periodic dropped-item audit | §8 | Project has accumulated forward designs / explorations / POCs / "decide later" entries without a discipline for surfacing what's been forgotten |
| Measuring efficiency over time (ET, run-frequency weighting) | §9.7 | You're optimizing across multiple recurring agent workflows or model tiers and need apples-to-apples cost comparison |
| Three-layer code review with AI pre-screen | §3d | Code generation outpaces human review capacity; the team is rubber-stamping or bottlenecking on review |
| Risk taxonomy with auto-merge thresholds | §3d | Auto-merge is on the table; team needs to agree explicitly on what merges without humans (most projects: 60–90% of changes are eligible) |
| Cross-provider code review | §3d | Tier Medium+ changes on LLM-feature products where same-family blind spots are expensive; budget supports parallel review |
| Closed-loop PR review workflow | §30.5 | Project ships at agentic velocity; 60%+ of changes are Trivial/Low; human review is the bottleneck or has become rubber-stamping |
| Untrusted-content boundary discipline (typed wrapper / provenance / spotlighting / audit-on-add) | §4 | Project ships LLM-powered features that ingest external content (web fetches, user input, tool outputs, file contents) and reaches users in production |
| Multi-provider behavioral testing (provider × substrate-tier matrix) | §3 | LLM-feature product serves multiple providers and correctness depends on model behavior; bench reveals provider-specific quirks lib/bin tests can't reach |
| Architectural fitness functions | §3 | Project has clear architectural boundaries that linter rules can't express; team has been bitten by boundary violations |
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
| **Winchester Mansion sprawl** | *The mature-project cousin of "Adopting everything at once" (above) — same underlying failure to prune, different timeline.* The codebase has grown by accretion over many sessions / iterations / contributors. Features were added; few were removed. The result: rooms that don't connect (modules with no callers, endpoints with no consumers), stairs to nowhere (half-implemented features still in main, code paths that lead to dead ends), doors to walls (documented APIs that don't actually work, exports without imports, settings that no longer do anything). The system "works" — current features run — but nobody can hold the whole shape in their head, onboarding is brutal, and refactoring becomes impossible because nobody knows what's safe to touch. | Pick three features documented in README, marketing, or a feature list. For each: when did it last get exercised in production? When did its tests last run? Who owns it? If the answers are "I don't know" / "I don't know" / "no one" for 2+ features, the sprawl is real. Also: ratio of imported-but-never-called functions, dead routes, modules whose only caller is a test, settings keys nobody reads. | Periodic *architectural* pruning, not just code-level pruning. Combine §13 dead code hygiene (per-file) with a higher-level *feature inventory* pass (per-feature, quarterly default). For each feature: Keep (active use) / Deprecate (announce removal) / Remove (no users, no future). Apply §8 dropped-item-audit discipline to *features*, not just designs. Watch §1 Preserving Project Structure as the upstream protection. |
| **Process without product** | Days spent building guardrail infrastructure (instruction files, documentation scaffolding, test harnesses) before writing any application code. | No runnable slice exists past the session count where one would normally appear (typically 3–9 sessions, project-shape-dependent). Pick the threshold up front; past it, the anti-pattern is real. | Build something first. Add structure as the project grows. A working prototype with no CLAUDE.md beats a pristine process scaffold with no code. |
| **Documentation theater** | A heavy planning corpus exists, but subsequent sessions don't *consume* it. Decisions get re-litigated. Specs grow but aren't cited. The corpus exists; the workflow doesn't reference it. | Subsequent sessions re-derive what specs/ADRs/decisions already settle, instead of citing them. If you can't find the doc that drove the last 3 commits' decisions, it's theater. The signal is *consumption*, not volume — front-loaded planning is fine if it gets used. | Every document should be referenced by at least one workflow. Commits, PR descriptions, and session notes should cite the relevant ADR / spec / decision when one applies. If a document isn't being read, either integrate it into the workflow or delete it. |
| **Cargo-culting practices** | Change propagation maps on a 3-file project. Formal specs for a 10-line script. Multi-layer testing on a single function. Agent orchestration for a solo developer with one assistant. | A practice was adopted because it appears in the template, not because a specific pain point surfaced. If you can't name the pain the practice addresses on this project, the trigger hasn't fired. | Every practice in the tier tables has an "adopt when..." trigger. If the trigger hasn't fired, the practice is premature. More process is not inherently better — only process that addresses a real problem earns its cost. |
| **Made-up estimates** | The assistant offers calendar predictions ("this is ~2 weeks of work" / "10 sessions" / "we'll be done by Friday"). | Any time-based estimate appears in chat, commit messages, roadmap entries, or planning docs — sourced from the assistant. Calendar predictions are not the assistant's call. | Describe **scope**, not duration: subproblem count, relative size (S/M/L/XL vs. comparable past work), known-vs-unknown ratio. The user does velocity arithmetic — only they know their schedule, energy, and parallel commitments. Sessions are sized by goal, not by clock. |
| **Treating the template as law** | Rigidly following every recommendation instead of adapting to the project's context. Refusing to skip sections that don't apply. Forcing project structure to match §1 exactly even when it doesn't fit. | Audit findings cite "non-conformance" with sections that don't fit the project shape, instead of recommending adapt or skip. | Umami is a toolkit, not a compliance checklist. Skip what doesn't apply. Adapt what partially applies. The goal is better software, not template conformance. If a recommendation creates friction without solving a problem, it's the wrong recommendation for this project. |
| **MCP tool sprawl** | The agent has 5–10+ MCP tools loaded "just in case." Tool metadata is consuming a large fraction of every turn's context, often without the developer realizing. | Measure tool-metadata-as-percent-of-context on a representative session. If tool schemas exceed ~30% of context, the verdict is confirmed. Most projects need 1–2 core MCP servers, not 10. | Apply §9.6: prune unused tools first, prefer lazy-load architectures (§9.5b), wrap static servers behind a proxy if needed. The cheapest tool schema is the one not loaded this turn. |
| **Treats untrusted content as plain strings** | LLM-feature product reads external content (web pages, user messages, tool outputs, file contents) into untyped strings that flow directly to the model. New code paths frequently forget to sanitize; sanitize-on-read is scattered across the codebase. | If functions consuming external content take plain `String` parameters (rather than a typed `UntrustedContent<T>` wrapper), the verdict is confirmed. Audit-on-add doesn't catch it; the type system needs to make it uncompileable. | Apply §4 untrusted-content-boundary discipline: typed wrapper at every boundary, provenance tagging, per-provider spotlighting, audit-on-add at code review. |
| **Leaky async interfaces** | Project has async surfaces (event bus, message queue, notification system, worker output) but those channels aren't part of the spec. Symptoms: a global event bus with no topic scoping; untyped payloads (`any`, raw JSON) that consumers route by guess; a catch-all UI notification surface receiving messages meant for scoped views; shared worker / stream output regions where multiple writers interleave. The leak manifests as *"a message appeared in the wrong part of the app"* — usually long after the emitting code was forgotten. | If grep finds a global event bus / `EventEmitter` at app scope / `pubsub` library wired at root with no topic discipline, AND the codebase has an `any`-typed or stringly-typed message payload, AND a single global notification / toast root receives traffic from >2 unrelated modules — at least one of those three is true in any leaky-async project. Confirmation: ask the team when they last had a "wrong-place message" incident; if the answer is "last month" or fresher, the verdict is real. | Apply §2b *Async Channel Contracts*: typed channel + origin tag + allowed-consumer list + audit-on-add at §3d code review. Promote to a §3 fitness function (cross-module subscriber not on allowed-consumer list = test fail) when audit-on-add proves insufficient at team pace. The four-part pattern parallels §4's untrusted-content boundary; cite the parallel, don't merge them. |
| **Accepting AI's 80% as 100%** | AI assistants nail the first ~80% of a feature fast — the happy path, the obvious cases, code that "looks right" because the model fluently mimicked the surface shape of working code. The remaining 20% is where the real difficulty lives: edge cases, error handling, integration points, subtle correctness requirements, the assumptions the code quietly makes about its inputs. PRs that ship the 80% as if it were complete leave the 20% as latent production debt — and worse, the code passes basic tests and reads as plausible, so the gap isn't visible to a normal review pass. (Osmani/Saboo/Kartakis 2026 — *The 80% problem*.) | Pick three recent AI-assisted PRs. For each, ask the author: *"What failure modes does this code accommodate? What edge cases are tested? What's the integration assumption with X?"* If the answer is vague, post-hoc rationalized, or "I figured the AI handled it," the 20% wasn't done. Quantitative confirmation: count regressions per AI-assisted feature in the first month post-ship — a spike there (vs. comparable human-written features) confirms the verdict. | Treat AI output as 80% complete by default. The human's job is the last 20%: edge-case coverage (use property-based testing, §3), explicit error-handling paths (cite the specific failure modes the code accommodates), integration verification (walk the boundaries by hand, don't trust that "it should work"), correctness review (read the code; don't rubber-stamp because it looks right). For Tier 2+ projects working in agentic-engineering posture (§0.6b), wire the 20%-check into the §3d code-review gate as an explicit reviewer checklist item rather than a manual "remember to ask" — the gap is too easy to miss otherwise. |
| **Closed-loop self-review (the system evaluating itself)** | The same model family (or worse, the same model instance) that wrote the code is also the only reviewer of the code. No external eye, no different training corpus, no adversarial lens. The loop closes: the system marks its own homework, gains confidence from its own confidence, and ships changes nobody else looked at. The failure mode isn't "AI bad" — it's *correlated blind spots*. A logical leap the author made invisibly is one the same-family reviewer is statistically more likely to make invisibly too. The system can be confidently and catastrophically wrong at the same time (Osmani 2026 *Agentic Code Review* — *"borrowed confidence: the system's certainty becomes yours"*). | Count auto-merges per week where the reviewer was the same provider as the author (e.g., Claude-author + Claude-reviewer; GPT-author + GPT-reviewer). If >0 in any high-blast-radius tier (§3d Medium+), the loop is closed for those changes. Also: take the last 10 auto-merged PRs and re-review them with a different-family model; if it raises ≥1 issue the original review missed, the closed-loop verdict is confirmed. The empirical floor (Osmani 2026): 4 review tools across 146 PRs found 93.4% of issues at exactly one tool each, zero by all four — heterogeneity finds things homogeneity provably doesn't. | Apply §3d *Cross-provider review*: require a different-family reviewer (different vendor / different training corpus / different tool architecture) for Medium+ changes. The discipline isn't "pick the best reviewer" — it's "pair reviewers with different characters" (e.g., one tuned for correctness, one for production-failure severity, one as the adversarial-eye second pass). For projects that can't afford cross-provider review on every change, at minimum sample 5–15% of Medium+ auto-merges with a different-family second pass (per §3d spot-check sampling) so the closed loop is broken statistically even when it's not broken per-PR. |
| **Rewriting CI to make AI pass** | Under pressure to ship, the gate gets weakened to fit the agent's output rather than the agent's output getting strengthened to clear the gate. Symptoms: tests removed without justification, lint rules disabled per-file, coverage thresholds lowered, type-check `// @ts-ignore` / `# type: ignore` proliferating, "flaky test" labels appearing on tests that catch real regressions, build steps `\|\| true`'d. The gate exists precisely because it cannot be talked out of its verdict; weakening it to accommodate AI output converts a verification mechanism into theater (Osmani 2026 — *"deterministic gates are the one part of the pipeline that cannot be talked out of their verdict"*). Agents under "make it green" pressure are gradient-descent optimizers; they will find the cheapest path to green, and if that path is weakening the gate, that's the path they'll take. | Audit the last 20 CI configuration changes (`.github/workflows/*`, `tsconfig.json`, lint configs, coverage configs, test exclusion patterns). For each: was the change *strengthening* or *weakening* the gate? If >2 of the last 20 are weakenings with no documented justification, the anti-pattern is real. Also: count `// @ts-ignore` / `# type: ignore` / `eslint-disable` / `noqa` additions in AI-assisted PRs vs. baseline; a spike confirms agents are silencing rather than fixing. | Treat CI configuration as a Medium+ tier change in the §3d risk taxonomy — never auto-merge a CI-weakening change without explicit human approval and a documented reason. Apply §6b *Pipeline Audit*: every gate has a documented purpose; gates can only be removed by explicit re-justification, never by attrition. Per §3d *Reviewer agent pattern*, the auto-review skill should treat any change touching CI / lint / coverage / type-check configuration as a HIGH flag automatically. If the gate genuinely needs to move, move it for a documented reason (logged in §7 ADR) — never to "unblock the agent." |
| **Accepting agent-rewritten tests uncritically** | An AI-assisted PR comes back with passing tests. The reviewer reads the diff, sees the green check, and approves — without noticing the agent has rewritten assertion strings, expected values, or test setups to match the (broken) code rather than fixing the code to match the (correct) tests. The test suite passes by construction. Specifically: agents under "make tests pass" pressure modify `expect(x).toBe(y)` to whatever `x` actually is, change setup fixtures to whatever the function actually consumes, or weaken assertions from `toEqual` to `toBeTruthy`. The PR ships, the green check provides false assurance, and the broken behavior reaches production with a passing test that documents (and thus pins) the broken behavior. | In the last 10 AI-assisted PRs that touched both code AND tests, count how many of the test changes are pure rename/move vs. assertion-content changes. If assertion-content changes are >0 in any PR not labeled "fix existing wrong test," the verdict is at minimum that the discipline isn't being applied; if the reviewer didn't explicitly ask "why did this assertion need to change?" for each one, the verdict is confirmed. For projects with mutation testing budget, run mutation testing against the modified tests; mutations that survive prove the test wouldn't catch the real regression. | Per §3d *Reviewer agent pattern*, the auto-review skill (and the human reviewer) must treat test modifications in non-rename/non-move form as HIGH-priority flags — every assertion change must answer *"why did this assertion need to change, and is the new assertion correct?"* Per §3e *Refactoring Discipline*, a "refactor" commit that modifies test content isn't a refactor, it's a rewrite, and should be a separate PR with explicit behavior-change framing. For Medium+ tier changes, require explicit author justification for each assertion modification ("the previous assertion was wrong because X; the new assertion is correct because Y") in the PR description. Mutation testing is the strong falsifier where the budget allows. |
| **No agent-approval gate table** | Project has agents taking consequential actions (write files, run commands, network access, sub-agent dispatch) but no single document codifying which actions are gated, at what severity, with what audit trail. New contributors discover gates by tripping them. | If the project has consequential agent actions but no `docs/agent-approval-gates.md` (or equivalent), the gates are implicit. Even one HARD action without a tabulated gate is a sign. | Maintain a gate table per §14 "Agent Approval Gates": HARD/SOFT/NONE severity, action class, user-visible surface, audit trail location, implementation pointer. Group by category. |
| **Runbooks-as-aspiration** | Per-stateful-surface runbooks exist on disk, but RTO/RPO targets are vague ("soon", "minimal") or restore steps haven't been exercised in >6 months. The runbook reads as policy, not procedure. | Pick the longest-untested runbook and run a recovery drill cold (without coaching). If it fails, the runbook is aspiration. RTO/RPO sections without numbers (just adjectives) are also a confirmed signal. | Apply §5 "Recovery Runbooks per Stateful Surface": numbered restore steps with prerequisites, concrete RTO/RPO numbers, quarterly drills rotating across surfaces. |
| **"From now on when X" without a hook** | Project documents an automated behavior ("we always log Y", "we never let the agent touch Z") in `CLAUDE.md` / `AGENTS.md` / `.cursorrules` (whichever instruction file the harness reads) or process docs but no hook implements it. The agent doesn't perform the behavior; humans assume it's being done. | Search the project's harness configuration (`.claude/settings.json`, `.aider.conf.yml`, `.cursorrules`, or whichever config file the harness uses for hooks) for the corresponding event and predicate. If the doc says "always do X" but no hook in any of §14's four event categories (*before-tool* / *after-tool* / *session-start* / *turn-end*) fires X, the verdict is confirmed. | Apply §14 "Lifecycle Hooks": wire automated behaviors through the harness's hook layer. Doc-only "always do X" rules are aspiration unless they're hook-implemented. |
| **Single-provider testing for multi-provider product** | LLM-feature product serves multiple providers (Anthropic / OpenAI / Gemini / etc.) but the behavioral bench / E2E suite runs against only one. Production paths through other providers ship without behavioral verification. | Count the providers the product serves vs. the providers covered in the bench matrix. If serves > covered, the gap is silent regression risk. Often surfaces post-incident: "we shipped a tool-schema change; it works on Anthropic but Gemini rejects it because we never tested." | Apply §3 "Multi-Provider Behavioral Testing": matrix of providers × substrate tiers; gate critical cells per commit; full matrix nightly or per-release. Real-provider RTT, not just mocks. |
| **Agent logs without review** | Project ships agent activity logs to a sink (disk, observability platform, S3) but nobody actually reads them. The retention policy looks compliance-shaped; nothing ever gets queried. | Ask when the agent log was last queried for anything other than incident response. If "never" or "I don't know," the log is write-only. If retention is set in months but no review cadence is documented, the log exists for paperwork, not for audit. | Apply §4 "Agent Log Discipline" review-cadence guidance: weekly tool-call scan, per-release error-layer review, per-incident forensic reconstruction, quarterly field-utility review. If review doesn't happen, drop the logging cost. |
| **ADR alternatives without research depth** | ADR has an "alternatives considered" section that names 1–3 alternatives in 1–2 sentences each. Reader can't tell what kind of audit went into the rejection — was it a deep read, a README skim, or just the assistant's training-data summary? | If an ADR doesn't cite a research doc, ask the author when the alternatives were last deep-read and what concrete dimensions were compared. If the answer is "we just knew" or "it's industry consensus," the audit didn't happen. | Apply §7 "Cross-Implementation Research": pair foundational ADRs with a dated research doc, comparison matrix, and tiered steal-list. The research doc gives the ADR's rejection reasoning auditable depth. |
| **Cost caps in policy doc but not in code** | Project documentation states "max $X per day for agent operations" but no enforcement exists in the harness configuration. Cost overruns happen and post-hoc retros say "well we have a policy" — but the policy never blocked anything. | Search the harness configuration (`settings.json`, hook configurations, etc.) for cap enforcement. If the doc says max $X but no hook / setting / runtime check enforces it, the verdict is confirmed. Cap-without-enforcement is aspiration. | Apply §9.7 "Cost Caps and Budget Gates": enforce caps in the harness layer (hooks, settings constraints, runtime checks). Document the policy AND the enforcement, with the audit-trail entry recorded when a cap fires. |
| **Fitness functions as documentation** | Architectural fitness functions exist in the test suite, but they assert constraints that are always trivially true. They never fail. They're aspirational descriptions of architecture, not active gates. | Run the fitness function suite in a deliberately broken state (introduce a known violation). If the suite still passes, the constraint is too loose or the test isn't actually checking what it claims. Functions that have never failed in their lifetime are also a sign — either the codebase has perfect compliance (unlikely) or the test is documentation. | Apply §3 "Architectural Fitness Functions": each function should be specific enough to fail when its invariant is violated. If you can't construct a violation case, the test is documentation, not a fitness function. |
| **Refactoring without tests** | Code restructured "for clarity" without tests covering the affected behavior. Either no tests exist, or the tests were added/changed as part of the refactor commit. Behavior may have changed silently. | If a "refactor" commit also modifies tests in ways that aren't pure rename / move, it's not a refactor — it's a rewrite. If the codebase has refactor-style commits but the test suite doesn't run reliably, the safety net is missing. | Apply §3e "Refactoring Discipline": tests as the safety net are non-negotiable. If behavior isn't covered, write the test first; then refactor. If you can't write the test, you're not refactoring — you're rewriting. |
| **Security as reactive — no threat model** | Project ships features with security controls in place (boundary validation, secrets management, auth) but no systematic threat model. Defenses cover threats the team happened to think of; threats they didn't think of slip through. Security incidents repeatedly surface "we should have caught this." | Ask the team to draw the system's trust-boundary data flow diagram on a whiteboard from memory. If they can't, the threat model doesn't exist. Look for a document mapping system boundaries → threats → mitigation decisions. If absent, security is reactive, not deliberate. | Apply §4 "Threat Modeling": the 5-step protocol (DFD → STRIDE → rate → decide mitigations → living document). One pass at project bootstrap; re-visit when boundaries change; per-release for compliance-bound projects. |
| **Security investment outpaces threat model** | Team adopts Full-depth security practices (zero-trust posture, typed untrusted-content wrappers, multi-provider behavioral matrix, architectural fitness functions) before the threat model or incident history justifies the cost. Often driven by aspirational compliance, vendor headline anxiety, or rigor-signaling — security work feels rigorous and is hard to argue against. Carrying cost is invisible until the project ships late. | Count §4 / §3 Full-depth practices in flight vs. specific threats they address (named in the threat model or incident postmortems). If Full-depth practices > documented threats, the investment is outpacing the model. Also: if weeks of security infra are landing before the features that earn user trust ship, the verdict is confirmed. | Default to Starter / Working depth across §4 practices. Deepen when a threat-model finding, incident, compliance trigger, or vendor/customer requirement justifies the cost — not when the practice sounds rigorous. The §0.6 "Adopting everything at once" anti-pattern applies to security specifically; flag aspirational Full-depth work in §8 acknowledged gaps with an explicit "why now" check. |
| **Pipeline cargo cult — slow CI as accepted reality** | Project's CI pipeline takes 20+ minutes for what should be a 5-minute pass. Gates were added per incident over time; none have been removed. Contributors stopped complaining months ago because the slowness is treated as immutable. New contributors inherit the slow pipeline and add their own gates without re-justifying existing ones. Pipeline configuration is often copy-pasted from another project. | Measure cycle time P50 / P99 over 30 days. If trending up over consecutive months without remediation, the verdict is confirmed. List every gate; if 3+ have "I don't know" or "never that I remember" answers to "when did this last catch a regression?", the cargo cult is real. Identical pipeline configs across multiple projects with different threat models is the strongest confirmation signal. | Apply §6b "Pipeline Audit": quarterly gut check on cycle time + per-gate purpose + last-caught-something date. Each gate gets a disposition (keep / move local / demote nightly / remove). Inner-loop feedback budgets documented in CLAUDE.md. Cargo-culted pipeline configs re-justified per gate against current threat model and feature surface. |
| **Aesthetic restructure** | Someone proposes (or an agent quietly executes) a directory / file-layout reorganization framed as "cleaner" or "more consistent." The change breaks paths referenced from downstream `CLAUDE.md` files, skill files, tests, change-propagation maps, or external documentation. Coordination cost was not enumerated. | When a restructure is proposed, ask the proposer to enumerate the external contracts that will break (tests, docs, downstream `CLAUDE.md` references, skill paths, propagation maps). If they can't or won't, the change is aesthetic and the coordination cost is invisible to them. Often the current layout is fine and the structural rule just needs codification. | Apply §1 "Preserving Project Structure": codify the rule (CLAUDE.md), encode invariants as §3 fitness functions, flag structural changes in §3d code review. Restructure only at appropriate phases (discovery, pre-shipping, major-version boundary, or trigger-fired per §8). |
| **Deferred decisions that never get decided** | Project has decisions-log entries / ADRs / design docs marked "decide later", "TBD", "deferred", or "Proposed" status that persist across multiple phases without resolution. The gap registry tracks these implicitly but they're not in it; they're in the middle ground of "we'll get to it" that never gets gotten to. | Count decisions-log entries / ADRs in "deferred" or "Proposed" state with no follow-up resolution. If the count grows over time (or stays flat across multiple phases without items resolving), the discipline is missing. Old `docs/designs/` files without recent updates and no archive move are the same pattern in design-doc form. | Apply §8 "Periodic Dropped-Item Audit" (typically quarterly). For each dropped item, force a disposition: Revive (still relevant, schedule it) / Archive (was relevant, preserve in `_archive/`) / Delete (truly dead) / Re-decide (the deferred decision gets a real decision now). Default to archive unless revival is justified. |

**For AI assistants:** During initial onboarding (§0 discovery), scan for these anti-patterns in the project's existing state. If the project already shows signs of documentation theater or cargo-culted practices from a previous process adoption, call it out. Recommend removing unused process artifacts before adding new ones — reducing noise is as valuable as adding signal.

**When you flag a borderline case, name the watch signal explicitly.** "Borderline documentation theater: 14 specs and 8 ADRs before any application code. Watch signal: if Phase 0 stretches past 9 sessions without code progress, the anti-pattern is real." A verdict without a falsifier becomes opinion; a verdict with one becomes a checkpoint.

### 0.6b AI-Discipline Spectrum — Vibe Coding ↔ Structured ↔ Agentic

§0.6 sized process to project maturity. This sub-section frames a **complementary, orthogonal axis: per-task AI-collaboration discipline**. A Tier 3 project still vibe-codes the occasional throwaway prototype; a Tier 1 project can apply full agentic engineering to its threat-model boundary. The skill is knowing which posture each piece of work warrants — and being explicit about that call.

Three points on the spectrum, after Osmani, Saboo & Kartakis (2026), *The New SDLC with Vibe Coding: From ad-hoc prompting to Agentic Engineering*:

| Dimension | Vibe coding | Structured AI-assisted | Agentic engineering |
|---|---|---|---|
| **Intent specification** | Casual natural-language prompts | Detailed prompts with examples and constraints | Formal specs (§2), architecture docs (§7), per-project rule files |
| **Verification** | "Does it seem to work?" | Manual testing + spot-checking (§3d sampling band) | Automated tests + evals (§3 *Tests and Evals*) + CI gates (§6b) + LLM judges (§3d cross-provider review) |
| **Codebase understanding** | Minimal; developer may not read the generated code | Selective review of critical paths | Comprehensive review of architecture; AI handles implementation detail under structural constraints (§1) |
| **Error handling** | Copy-paste error messages back to the AI | Developer diagnoses root cause; AI implements the fix | Agents self-diagnose within bounded surface; humans handle architectural issues |
| **Appropriate scope** | Prototypes, scripts, personal projects, hackathons, exploration | Features inside an established codebase | Production systems, team-scale development, compliance-bound work |
| **Risk profile** | High — acceptable only when the code is genuinely disposable | Moderate — human judgement at the key checkpoints | Low — systematic verification at every stage |

**The single biggest differentiator is verification.** Vibe coding makes verification optional; agentic engineering makes it mandatory via two complementary mechanisms — **tests** verify the deterministic parts (a function given this input produces that output), **evals** verify the non-deterministic parts (the agent took the right trajectory, used the right tools, produced output meeting the quality bar). Without both, the practice sits closer to vibe coding regardless of how sophisticated the prompts are. See §3 *Tests and Evals — verification's two halves* and §3 *Multi-Provider Behavioral Testing*.

**How to pick the spectrum position:** match it to the stakes of the task, explicitly, at the start of the work.

- **Throwaway / exploration / prototype / hackathon** → vibe coding is the right speed. Don't pay agentic-engineering cost to learn what something could look like.
- **Feature inside an established codebase** → structured AI-assisted. Detailed prompts, manual review of critical paths, lean on the project's existing test/CI discipline.
- **Production system, payment processing, security boundary, compliance-bound work, AI-feature product reaching real users** → agentic engineering, no shortcuts. The cost of "it seems to work" in these surfaces is exponentially higher than the cost of the discipline.

**Failure mode: keeping the boundary fuzzy.** Teams that don't make the per-task spectrum call explicit produce **prototypes that ship by accident** — a vibe-coded experiment becomes the production thing because nobody re-established the discipline when the stakes changed. Per §1 *Preserving Project Structure* applied to AI-discipline: once a piece of code lives in a higher-stakes context, the discipline needs to graduate with it; quietly keeping it at the original posture is how vibe-coded prototypes become production fragility.

**Watch signal:** ask the team to point at three recently-merged PRs and name the spectrum position each was developed at. If the answers cluster around "I dunno, the usual," the boundary is fuzzy in practice and the prototypes-that-ship-by-accident failure mode is imminent. Falsifier: at least 2 of 3 PRs get a confident, specific spectrum-position answer that matches the change's stakes.

**Cross-references:**
- §3 *Tests and Evals — verification's two halves* — the verification mechanisms that define the spectrum position
- §3d code review — risk taxonomy auto-merge thresholds tighten as the spectrum position moves right
- §4 untrusted-content / threat modeling — agentic engineering is the floor, not a stretch goal, for products handling external content
- §9.7 cost caps — vibe coding has *low CapEx + high OpEx* (token burn, prompting loops, maintenance tax accumulating in unreviewed code); agentic engineering inverts (higher CapEx investment in harness/tests/specs; lower OpEx via first-pass success rate and lower defect cost downstream)
- Osmani/Saboo/Kartakis 2026 — original framing of the three-point spectrum and the six-dimension table; see *The New SDLC with Vibe Coding*, Table 1

### 0.7 Audit Protocol — How to Review Efficiently

Auditing the full document against a project is expensive — both in tokens and in time. A comprehensive audit of every umami file (landing + 4 core companions + relevant extensions) can consume 40,000+ tokens. The umami v3 architecture is designed so most audits don't need that much: a Tier 1 audit needs only the landing document (~13K tokens); a Tier 2 audit pulls in the one or two companion files that match the audit scope (~25K tokens). Use a tiered audit approach.

**For AI assistants performing an audit:**

**Audits are read-only by default.** An umami audit assesses process maturity and identifies gaps — it does not modify code, configuration, or project files. Do not restructure directories, add tests, insert logging, refactor code, or apply recommendations during the audit phase. The audit produces a findings report. The user decides what to act on, when, and how. See "After the audit" below.

1. **Determine the project's current tier.** Read the project's `CLAUDE.md`, test infrastructure, and documentation. Match the project's current state to the adoption tiers above. Most projects are between Tier 1 and Tier 2.

2. **Audit one tier above current.** If the project is solidly at Tier 1, audit against Tier 2 practices. If it's at Tier 2, audit against Tier 3. Don't audit practices two tiers above — they'll create recommendations the project isn't ready to act on.

3. **Focus on gaps, not compliance.** The output should be: "Here are 3-5 specific practices from the next tier that would address problems you're currently experiencing." Not: "Here are 47 recommendations across all sections."

4. **Read selectively. Use the Section Navigation Map.** You do NOT need to fetch every umami file for every audit. Always fetch the landing document (`umami.md`) first — it carries §0 (discovery + framework), the Navigation Map, and Tier 1 practices. Consult the Navigation Map to identify which core companion files apply to the tier you're auditing. Tier 1 audits use landing alone; Tier 2 audits typically fetch one or two companions; Tier 3 audits may fetch more.

5. **Extensions only when relevant.** Only fetch domain extension files if the project has that domain layer AND is at Tier 2+. A Tier 1 web project doesn't need an audit against `umami-web.md` — it needs to get its basic testing and structure right first. The same principle applies to core companions: don't fetch `umami-agents.md` if the project isn't running agents at scale.

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

### Latent practices observed
- [Practice X] — evidence: [hook / script / file / pattern showing the team exercises this]. Currently uncodified in [target doc / spec section]. Recommendation: codify in [the project's CLAUDE.md / a process doc / surface for umami contribution if universally applicable].

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
- **Always fetch the landing document fresh from the canonical URL** (`https://raw.githubusercontent.com/.../umami.md`). Never cache locally. The framework evolves; cached copies go stale silently.
- **Consult the Section Navigation Map.** Identify which core companion files (`umami-quality.md`, `umami-runtime.md`, `umami-process.md`, `umami-agents.md`) and which domain extensions apply before fetching anything beyond the landing document. Fetch only what the audit scope requires.
- **If the fetch fails, tell the user and stop.** Do not fall back to a stale local copy. An audit against three-month-old guidance is worse than no audit — it produces confident, wrong recommendations.
- **Never recommend more than 5 things.** A wall of recommendations is not actionable. Prioritize ruthlessly.
- **Cite a file path or doc reference for every observation.** "The project lacks ADRs" is an opinion; "no files exist under `docs/decisions/`" is a finding.
- **Don't fetch companion or extension files unless they apply.** A Tier 1 audit doesn't need any companion file. A web project doesn't need `umami-data.md`. Confirm scope relevance before pulling.
- **Audit one tier above current — never two.** Recommendations the project isn't ready for create noise, not value.
- **Every recommendation cites Impact and Effort.** Impact names a specific improvement (anti-pattern closed, gap-registry entry resolved, measurable pain reduced — ideally with a falsifiable signal). Effort uses the §4 *Reading the cost profiles* scheme (Who · Magnitude · Shape). Both are required; vague impact ("improves quality") and vague effort ("not too bad") defeat prioritization. **Flag Quick win** only when Impact is concrete AND Effort is Hours; the flag dilutes if applied to medium-effort items. Unflagged recommendations are still actionable — readers prioritize from the Impact/Effort dimensions themselves.
- **Surface latent practices.** Beyond tier-gap recommendations, look for practices the team is *already exercising* that aren't yet codified — either in the project's own `CLAUDE.md` / process docs, or in umami's spec. Evidence: hooks doing something the docs don't describe, scripts doing operations not captured in process, conventions visible across commits but not in `CLAUDE.md`, gap-registry entries pre-staging work that isn't reflected in any tier-table practice. When found, recommend codification.

When the audit flags an anti-pattern, name the watch signal that would confirm or refute the verdict (see §0.6). Verdicts without falsifiers become opinion.

**Latent-practice findings are often the highest-leverage recommendations** because the team is *already paying the cost* of the discipline without getting the *benefit* of having it named — cross-referenceable in code review, teachable to new contributors, encodable as §3 fitness functions, citeable in commit messages, durable when contributors rotate. Codifying makes tacit knowledge into a contract.

### 0.7b Initialization Protocol — Bootstrapping Umami in a New Project

§0.7 covers recurring audits. This section covers the first-time setup — bringing umami into a project that doesn't yet reference it, or upgrading a partial setup.

**Bootstrap entrypoint (self-installing).** A project with no umami presence pastes one instruction into their agent:

> *"Set up umami in this project. Fetch https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md and follow §0.7b."*

The agent fetches the spec, follows this section, and during the apply phase installs `umami-init` and `umami-audit` skills locally. Subsequent runs use slash commands.

**This is a lightweight setup, not a framework install.** Init writes only URL references and small invocation-aid skill files. There is no framework copy, no runtime dependency, no library to keep updated. The umami spec stays at its canonical URL and is fetched fresh on every run; the local artifacts are just a way to make access to umami consistent and harness-recognized as commands.

**What gets stored locally vs. fetched fresh:**

- **Stored locally:** URL *references* to the canonical umami spec (in instruction files like `CLAUDE.md`) and *skill files* (`.claude/skills/umami-init.md`, `.claude/skills/umami-audit.md`) that describe *how to invoke* the protocol.
- **Never stored locally:** the umami spec itself. Always fetched fresh from the canonical URL on every audit/init run.

Skill files are invocation aids — they encode procedure shape, hard rules, and bootstrap text so the harness recognizes `/umami-init` and `/umami-audit` as commands. They do **not** contain a copy of umami.md. Drift between an installed skill and the canonical spec is detected per §0.7 (structural + calendar drift checks).

**Procedure for AI assistants performing initialization:**

1. **Detect current state.** Grep instruction file(s) (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, etc.) for umami URLs. Determine starting state:
   - **None** — first-time setup.
   - **Partial** — some umami URLs present; missing relevant companion files, missing relevant domain extensions, or referencing extensions for layers the project doesn't have.
   - **Complete** — references match the project shape; recommend `/umami-audit` instead.

2. **Run §0.1–§0.4 discovery** interactively, one decision at a time per §3c when answers compound.

3. **Derive recommended URL set** via §0.5 mapping. The URL block always includes the **landing document** (`umami.md`). Core companion files (`umami-quality.md`, `umami-runtime.md`, `umami-process.md`, `umami-agents.md`) and domain extensions are added based on the tier the project is targeting and which concerns apply. For Tier 1 / first-pass adoption, the URL block may legitimately list only the landing document plus relevant domain extensions — companion files can be added when the project escalates to Tier 2.

4. **Compute the diff:** adds (companion files + domain extensions to add to URL list), removes (rare; usually flag-only), and skill installations (`.claude/skills/umami-init.md` and `.claude/skills/umami-audit.md`, each with `**Last synced:** YYYY-MM-DD` set to today).

5. **Show the user the proposed changes, then present the four-option dialog.** Enumerate every file that would be modified or created — paths, line counts, the exact URL block that would land in each instruction file, which skill files would be created or updated and at what `Last synced:` date. The user must be able to read the diff before deciding. Then surface the dialog (apply all / selective walkthrough / do something else / skip) per §0.7. Self-contained prompt per §3b.

6. **Apply on approval.** Update all detected instruction files in lockstep (a project with both `CLAUDE.md` and `AGENTS.md` gets identical URL lists in both). Write the skill files. Don't overwrite existing skill files without diffing first.

7. **On apply, auto-chain into the first audit.** When step 6 actually wrote files, immediately invoke `/umami-audit` to produce a baseline process audit against the freshly-installed configuration. Announce the transition (*"Init complete — wrote {file list}. Running first process audit now…"*) and proceed without further confirmation; the user already consented to the workflow at the four-option dialog. The audit runs its full §0.7 procedure — read-only fetch, findings report, and its own four-option findings-disposition dialog at the end — so the user still chooses interactively what to act on. Init's job isn't done when the skills are on disk; it's done when the user has seen where they stand. If init was skipped at the dialog (no files written), do not auto-chain; hand off with *"Init skipped — re-invoke `/umami-init` when you're ready."*

**Hard rules** mirror §0.7:

- Read-only by default. The four-option dialog gates every write; no destructive changes without explicit approval.
- Always fetch the landing document (`umami.md`) fresh from the canonical URL. Never cache locally.
- For Tier 2+ scope, fetch the companion files identified by the Section Navigation Map. Don't fetch companions speculatively.
- If the fetch fails, tell the user and stop. Don't fall back to a stale local copy.
- Cite a file path or doc reference for every observation.
- Drift detection applies to installed skills (see §0.7).
- **Auto-chain into `/umami-audit` on successful apply** (step 7). Printing a hand-off message and stopping leaves the user with installed skills but no view of their baseline; the bootstrap one-liner ends in a finding-bearing audit, not a confirmation message. Auto-chain only when files were written — skip the audit if the user chose **Skip** at the four-option dialog.

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

### Preserving Project Structure

§1's other sub-sections cover what to *set up* — directory layout, workspace partitioning, the phase/session hierarchy, multi-surface routing. This sub-section covers how to *preserve* what you've set up. Once a project commits to a structure, that structure becomes an **external contract** — for tests that reference paths, for documentation that mentions modules, for change-propagation maps (§10), for skills and automation that reference file locations, for downstream consumers if the project is a library or shared spec. Restructuring late has costs that compound with project age.

**The core principle: structural commitments are contracts.** The same reasoning §11 applies to spec-section identifiers (external contracts; don't renumber) applies to file paths, module names, and directory layouts. Changing them means breaking every reference. The cost is real and recurring.

**When structural changes are appropriate:**

| Phase | Why it's OK to restructure |
|---|---|
| **Discovery (§0)** | No commitments have formed yet; this is when to get the structure right |
| **Pre-shipping** | No external consumers exist; internal refactoring is local |
| **Major-version boundaries** | Breaking changes are scheduled and communicated; downstream consumers expect adjustment |
| **Trigger-driven (per §8 watch signals)** | A pre-identified seam fires its trigger; restructure has been pre-staged |

**When structural changes are expensive and should be avoided:**

- After publication, when downstream `CLAUDE.md` files / skills / automation reference paths
- When the change is *aesthetic* ("cleaner layout") rather than driven by a real constraint
- Mid-version, when external contracts haven't been renegotiated
- Bundled with feature work (per §3e: structure changes are refactorings; same atomic-commit rules apply)

**Protecting structure from drift:**

| Tool | What it catches |
|---|---|
| **Codified rules in CLAUDE.md / instruction files** | New contributors and agents follow the explicit rule instead of inventing or inferring one |
| **§3 architectural fitness functions** | Module import-direction violations, file-location-rule violations, naming-pattern violations |
| **§3d code review classifications** | New files outside the canonical layout flagged HIGH for human review |
| **§10 change propagation maps** | Capture "files that move together"; restructures that split them get flagged |
| **§8 acknowledged gaps — seam pre-identification** | When a trigger fires (file size, growth pattern), the restructure is pre-staged with execution plan |

**Watch signals:**

| Signal | What it catches |
|---|---|
| New files added in inconsistent directories | The structural rule isn't being followed; either codify it more visibly or train contributors |
| Code review repeatedly flags "where does this file go?" | The structural rule isn't internalized; documentation gap |
| Structural changes batched with feature work | §3e refactoring discipline violated; structure changes should be their own commit |
| Restructure proposed without external-contract analysis | The proposer doesn't see the coordination cost; ask them to enumerate what breaks |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Aesthetic restructure | "Cleaner layout" reorg that breaks external contracts | The cleanest layout is the one with the lowest aesthetic-improvement-to-coordination-cost ratio. Often the current layout is fine; codify the rule instead |
| Structural drift via small changes | No single change is a restructure but the cumulative effect is one | §3e refactoring discipline + §3d code review flagging at the structural level |
| No codified rules | New contributors guess at conventions; inconsistency accumulates | Codify rules in CLAUDE.md (file layout, directory conventions, naming, import patterns) |
| Treating structure as forever-frozen | Project grows; structure no longer fits; team says "we can't change it" | Major-version boundaries are the right time. Pre-identify seams in §8 *before* urgency; when the trigger fires, execute the staged plan |
| Restructuring driven by an agent that doesn't see external contracts | Agent "tidies" the layout in a refactor; downstream consumers break silently | §3d Layer 2 (AI pre-screen) flags structural changes for human review |

**Cross-references:**
- §1 above — the setup sub-sections this protects
- §3 architectural fitness functions — encode structural rules as automated tests
- §3d code review — structural changes get HIGH-flagged
- §3e refactoring discipline — structural changes are refactorings; same atomic-commit rules apply
- §8 acknowledged gaps — pre-identify seams before urgency
- §10 change propagation maps — capture structural patterns
- §11 file size budgets — the spec-ID-as-external-contract exemption is the same logic applied to one specific structural element

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

## Security Essentials (Tier 1 floor)

The day-one security floor lives here so a Tier 1 fetch (`umami.md` alone) carries the must-knows. The **full security discipline** — threat modeling, trust posture, agent runtime security, untrusted-content boundaries, agent log discipline — lives in **§4 in [`umami-runtime.md`](umami-runtime.md)**, which the agent should fetch when crossing into Tier 2+ security work.

**Day-one rules (universal):**

- **No secrets in code. Ever.** Not in source files, config files committed to git, comments, or variable names that hint at the value. Use environment variables, secret stores, or encrypted config excluded from version control.
- **Scan for leaked secrets.** Pre-commit hook or CI check that detects API keys, tokens, and passwords in committed code. Specific tool matters less than having the check in place.
- **Run automated vulnerability scanning in CI.** `npm audit`, `pip-audit`, `cargo audit`, Dependabot, Snyk — pick what fits the ecosystem. Don't ignore alerts; triage them.
- **Validate untrusted input at system boundaries.** HTTP requests, file uploads, webhook payloads, user input, external API responses, CSV imports. Trust internal code within a defined trust zone — don't scatter defensive validation through every function.
- **Treat deserialized data as untrusted.** JSON from an API, data from a queue, objects from a cache — anything that crossed a serialization boundary could have been tampered with.
- **For AI-assisted development:** Include security constraints in the project instruction file (`CLAUDE.md` or equivalent): *"Never use eval. Always parameterize queries. Never log PII."* These are low-cost instructions that prevent the most common agent-generated vulnerabilities. Review agent-generated code for security the same way you review for correctness.
- **Don't build custom auth unless you have a specific reason.** Established libraries and services exist for every platform. Custom auth implementations are a leading source of security vulnerabilities.
- **Build output hygiene** is part of §6 above: `.gitignore` covers `dist/`, `build/`, `out/`, `*.map`, `.env*` at minimum; scan build output before deploy.

**When to fetch §4 in [`umami-runtime.md`](umami-runtime.md):**

- You're identifying threats deliberately (threat modeling — STRIDE / OWASP / LINDDUN / PASTA framework picker)
- You're choosing between perimeter-trust and zero-trust postures (NIST 800-207 / CISA ZTMM alignment)
- The project ships LLM features that ingest external content (untrusted-content boundary discipline)
- The project gives agents tools that touch privileged operations (agent runtime security: kill switches, sandboxing, identity isolation)
- The project needs agent log discipline for compliance, incident response, or operational debugging

See the *Section Navigation Map* near the top of this document for full per-section fetch triggers.

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
