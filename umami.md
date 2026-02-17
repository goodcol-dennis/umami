# Rapid Development Guardrails — Project Template

This document is a template for establishing processes, testing strategies, and AI token efficiency practices that enable fast, reliable software development. It is intended to be adapted per-project and consumed by both humans and LLMs.

**This is a general-purpose template.** It must not contain references to any specific project, codebase, brand, or product. All examples should use generic descriptions. If you adapt this template for a specific project, do so in that project's own docs — not here.

**This file lives in the [goodcol-dennis/umami](https://github.com/goodcol-dennis/umami) repo** so it can be shared across projects. Do NOT copy it into a project's `docs/` folder. Instead, keep the URL in each project's `CLAUDE.md` as a reference for on-demand process audits:

```markdown
## Process Audit Reference
- Development guardrails (core): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
- Extension — Web frontend: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-web.md
- Extension — Data pipelines: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-data.md
- Extension — IaC / DevOps: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-iac.md
- Extension — Mobile: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-mobile.md
- Extension — WordPress: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-wordpress.md
- Extension — Drupal: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-drupal.md
- Extension — Compliance: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-compliance.md
- Extension — Scripting: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-scripting.md
- Extension — Systems integration: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-integration.md
  Do NOT fetch these every session. These are reference URLs for periodic process reviews.
  When the user asks you to audit the development process, fetch the core document and
  follow the tiered audit protocol in §0.7 — determine the project's current adoption tier,
  then audit one tier above. Do NOT read every section or fetch every extension. Focus on
  3-5 actionable recommendations, not comprehensive compliance.
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
| **CMS / WordPress** | yes / no | Is the project built on WordPress? (themes, plugins, site builds) |
| **CMS / Drupal** | yes / no | Is the project built on Drupal? (modules, themes, config management) |

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
| CMS / WordPress | §3 (testing), §3b (TDD), §6 (consistency — coding standards), §7 (ADRs — plugin/architecture decisions), §8 (acknowledged gaps — plugin risks) | [umami-wordpress.md](umami-wordpress.md) | — |
| CMS / Drupal | §3 (testing), §3b (TDD), §5 (state tracking — config management), §6 (coding standards), §7 (ADRs — module/architecture decisions), §8 (acknowledged gaps — module risks) | [umami-drupal.md](umami-drupal.md) | — |
| CLI / scripts only | §3 (unit tests), §3b (TDD + debugging), §6 (type checking), §11 (file size budgets) | [umami-scripting.md](umami-scripting.md) | §3 visual/E2E, §4 runtime validation UI, §7 UX audit |
| Multi-layer system | All sections, but **organize §10 (change propagation) per-layer** and **organize §3 (testing) per-layer**. Consider §1 workspace partitioning if discovery/analysis phase exists alongside application code. | All that apply | — |
| Compliance requirements | §2 (specs — contracts as evidence), §3 (test evidence), §5 (state tracking — audit trail), §7 (ADRs — decision traceability), §8 (acknowledged gaps — risk register), §12 (change tracking — change management records), §15 (checklists — process evidence). These shift from "recommended" to **required**. | [umami-compliance.md](umami-compliance.md) | Nothing skipped — compliance adds rigor, it doesn't remove sections. |
| AI-assisted development (any project using agents) | §9 (token efficiency), §14 (agent orchestration — delegation, skills, parallel review, tool integration) | — | — |

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
| Runtime validation | §4 | The system handles external input or runs in production |
| Documentation / ADRs | §7 | You make a decision you'll need to explain later (including to future you) |
| Token efficiency | §9 | Agent sessions are re-deriving the same codebase understanding |
| File size budgets | §11 | Files are long enough that agents truncate or miss context |

**Tier 3 — Scale** (adopt when complexity demands it)

These are heavier practices that solve real problems in larger, longer-lived, or compliance-bound projects. Applying them to a prototype adds drag without payoff.

| Practice | Section | Adopt when... |
|----------|---------|---------------|
| State tracking & recoverability | §5 | Stateful operations need rollback or audit trails |
| Acknowledged gaps | §8 | Tech debt is accumulating faster than it's being addressed |
| Change propagation maps | §10 | Changes routinely touch 5+ files and contributors miss downstream impacts |
| Change tracking | §12 | Work spans multiple sessions and context is lost between handoffs |
| Agent orchestration | §14 | You're using multi-agent workflows or delegating to specialized agents |

**Extensions** follow the same logic: apply when the domain is present *and* the project has reached the maturity level where that guidance adds value. A WordPress site in its first week needs §20.2 security basics, not §20.8 production monitoring.

**How to move between tiers:** Don't promote the whole project at once. When you hit a specific pain point (regressions, lost context, agents repeating mistakes), check whether a Tier 2 or 3 practice addresses it. Adopt that practice. Periodic audits (§0.7) are designed to surface these moments.

### Onboarding Anti-Patterns

When onboarding a project to umami — especially an existing codebase — watch for these patterns. If you identify any during discovery or an initial audit, flag them and recommend the mitigation.

| Anti-pattern | How to spot it | Mitigation |
|---|---|---|
| **Adopting everything at once** | The agent (or team) tries to implement all 15 sections simultaneously. New projects get CLAUDE.md, change propagation maps, ADRs, multi-layer tests, and token efficiency practices before any application code exists. | Start with Tier 1 only (§0.6). Add higher-tier practices when specific pain points justify them, not preemptively. A project that doesn't ship code because it's busy setting up process has inverted its priorities. |
| **Process without product** | Days spent building guardrail infrastructure (instruction files, documentation scaffolding, test harnesses) before writing any application code. Process exists to support delivery, not the reverse. | Build something first. Add structure as the project grows. A working prototype with no CLAUDE.md is better than a pristine process scaffold with no code. |
| **Documentation theater** | ADRs, specs, and acknowledged gaps exist as files but no workflow references them. Decisions get re-litigated because nobody checks the ADRs. Acknowledged gaps grow but are never reviewed. | Every document should be referenced by at least one workflow. An ADR that isn't checked before making the same type of decision is overhead, not governance. If a document isn't being read, either integrate it into the workflow or delete it. |
| **Cargo-culting practices** | Change propagation maps on a 3-file project. Formal specs for a 10-line script. Multi-layer testing on a single function. Agent orchestration for a solo developer with one assistant. | Every practice in the tier tables has an "adopt when..." trigger. If the trigger hasn't fired, the practice is premature. More process is not inherently better — only process that addresses a real problem earns its cost. |
| **Treating the template as law** | Rigidly following every recommendation instead of adapting to the project's context. Refusing to skip sections that don't apply. Forcing project structure to match §1 exactly even when it doesn't fit. | Umami is a toolkit, not a compliance checklist. Skip what doesn't apply. Adapt what partially applies. The goal is better software, not template conformance. If a recommendation creates friction without solving a problem, it's the wrong recommendation for this project. |

**For AI assistants:** During initial onboarding (§0 discovery), scan for these anti-patterns in the project's existing state. If the project already shows signs of documentation theater or cargo-culted practices from a previous process adoption, call it out. Recommend removing unused process artifacts before adding new ones — reducing noise is as valuable as adding signal.

### 0.7 Audit Protocol — How to Review Efficiently

Auditing the full document against a project is expensive — both in tokens and in time. A comprehensive audit of the core template plus extensions can consume 50,000+ tokens, most of which is wasted if the project is early-stage and only needs Tier 1 guidance. Use a tiered audit approach instead.

**For AI assistants performing an audit:**

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
2. [Practice] (§X) — [why this addresses a current pain point]
3. [Practice] (§X) — [why this addresses a current pain point]

### Not yet relevant
- [Practices that were checked but don't apply yet, with the trigger that would make them relevant]
```

This format keeps the audit focused and actionable. A project should come away with 3-5 concrete next steps, not a wall of recommendations.

**Standardize the invocation.** Create an `umami-audit` skill in your project's skill library (§14) so the audit is always triggered the same way — `/umami-audit` or equivalent — regardless of who runs it or which agent tool they use. The skill should embed the raw URLs and reference this protocol so the agent doesn't improvise the process.

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
├── CLAUDE.md              # AI assistant instructions (injected every session)
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

---

## 2. Specification-First Development

Every feature starts with a written spec, not code. Architecture documents and diagrams define system behavior, component contracts, and design constraints before implementation begins. These serve as the source of truth for all contributors.

**This section establishes spec discipline, not a spec framework.** There are many spec frameworks and methodologies (RFC-style documents, Gherkin/BDD, design docs, shape-up pitches, PRDs, etc.). This template is compatible with any of them — and deliberately doesn't recommend one. The high-value practice is *having* a spec process that forces thinking before coding. Which format you use matters far less than whether you use one at all. Pick a format that fits your team and project, then apply the discipline below to it.

### What to Specify

- **System architecture** — how components connect and communicate.
- **Component contracts** — typed inputs, outputs, and configuration schemas.
- **Design system** — enforced visual language (colors, typography, spacing) so the UI stays consistent regardless of who writes the code.
- **Data contracts** — data shapes validated at design time, catching mismatches before runtime.

### How Specs Prevent Waste

A spec that takes 30 minutes to write prevents hours of rework. For AI contributors specifically, a spec means the AI implements to a target rather than inferring intent from context clues — fewer clarification questions, fewer wrong-direction implementations.

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

This checklist is not bureaucracy. It catches the two most common sources of wasted follow-up work: regressions from untested side effects, and scope creep that the requester didn't ask for.

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

Each domain extension includes specific security guidance for its context — WordPress escaping and nonces (§20.1), Drupal access control and Form API (§21.1), etc. For projects handling regulated data (PHI, PII, payment cards), the compliance extension covers data classification, handling procedures, and audit readiness (§22.2–22.3).

---

## 5. State Tracking & Recoverability

Every state mutation is tracked through content-addressable hashing or equivalent versioning.

- **Change detection** — diffs computed at field level, not "the whole file changed."
- **Undo/redo** — navigable version history, not a naive stack.
- **Deduplication** — identical states produce identical hashes, no redundant storage.
- **Debounced persistence** — frequent edits batched to avoid write storms, with forced caps to prevent data loss.

The result: every edit is recoverable, and you can always answer "what changed and when."

For production systems, recoverability extends beyond code versioning to disaster recovery and incident response — RTO/RPO targets, backup verification, and restore procedures. The IaC extension covers infrastructure recovery (§16.12). The compliance extension covers the procedural layer — incident response plans, DR testing, and communication plans (§22.4).

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

---

## 8. Acknowledged Gaps

Transparency about what isn't automated yet is itself a guardrail. Document these explicitly:

- CI/CD pipeline status (local-only vs. automated).
- Linting/formatting automation (manual vs. tooled).
- Pre-commit hooks (present, planned, or intentionally absent).
- Coverage thresholds (enforced or aspirational).
- Known technical debt with severity and ownership.

Documenting gaps prevents false confidence and makes the cost of each gap visible to decision-makers.

---

## 9. Token Efficiency Practices

AI-assisted development bills by the token. Every search the AI runs, every file it reads to orient itself, every clarification question — that's spend. These practices minimize waste without reducing output quality.

### 9.1 Front-Load Context via Project Instructions

Provide a project instruction file (e.g., `CLAUDE.md`) at the repo root. This is injected into every AI session automatically. It should contain:

| Section | Why It Saves Tokens |
|---------|-------------------|
| **Exact versions** (runtime, package manager, language) | Eliminates "let me check what version" exploration |
| **Common commands** (copy-paste-ready) | No tokens spent figuring out how to run tests or start a dev server |
| **Project structure** (directory tree with one-line descriptions) | AI navigates directly instead of globbing |
| **Critical rules** (non-negotiable constraints) | Stated once, followed everywhere — no re-discovery |
| **Doc index with file paths** (topic → exact path) | AI reads the right doc on the first try instead of searching |

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

### 9.6 The Math

A typical "let me find that file" cycle costs ~2,000–5,000 tokens (glob, read results, maybe grep, read file). A single line in a project instruction file pointing to the exact path costs ~20 tokens. Over a session with dozens of file lookups, front-loaded context can reduce token consumption by 30–50%.

---

## 10. Change Propagation Maps

For every recurring change type, document which files must be updated and in what order. This is the single highest-value token optimization: without it, the AI rediscovers the dependency chain every session through grep and file reads (~15,000 tokens). With it, zero search cost.

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

The next session reads this and resumes in ~200 tokens instead of spending 5,000+ tokens re-orienting through git log, git diff, and file reads.

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

### Skill Libraries

A **skill** is a reusable set of instructions for a recurring agent task. Different tools call these different things — custom prompts, system instructions, agent templates, slash commands — but the concept is universal: pre-written instructions that replace per-session re-derivation.

```
project-root/
├── .ai/                          # Or .claude/, .cursor/, etc.
│   └── skills/
│       ├── umami-audit/
│       │   └── instructions.md   # Tiered process audit (§0.7)
│       ├── security-review/
│       │   └── instructions.md   # What to check, how to report
│       ├── pr-summary/
│       │   └── instructions.md   # How to summarize a PR
│       └── data-migration/
│           └── instructions.md   # Pre-flight checks, rollback steps
```

**Standard skill — `umami-audit`:** Every project using umami should have an `umami-audit` skill that fetches the core document (and relevant extensions), follows the tiered audit protocol (§0.7), and outputs the standard audit format. This ensures the audit is invoked the same way in every project — `/umami-audit` or equivalent — rather than being phrased differently each time. The skill should include the raw URLs from the project's `CLAUDE.md` so the agent doesn't need to search for them.

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

**Configuration scope matters:**

- **Personal** — your credentials, your preferences. Not committed to the repo.
- **Project** — shared team integrations. Committed to the repo (without secrets) so every team member's agents have the same access.

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
- [ ] New endpoints/inputs have boundary validation — untrusted data sanitized at entry points (§4).
- [ ] New dependencies justified — not duplicating existing packages, actively maintained, vulnerability-free (§6).

---

## Principle

Speed without guardrails is just velocity toward defects. These mechanisms ensure that code — whether written by a human or an AI — is typed, tested, validated at runtime, visually regression-checked, version-tracked, and architecturally constrained before it reaches a user.
