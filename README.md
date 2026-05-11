# Umami — Rapid Development Guardrails

A shared template of processes, testing strategies, and AI token efficiency practices for fast, reliable software development.

## Why "Umami"?

Umami is the fifth taste — the one you can't quite name but immediately notice when it's missing. It's what makes a simple dish feel complete. These guardrails serve the same role for software projects: not a framework, not a tool, but the foundational practices that quietly make everything else work better. You might not point to any single rule and say "that's the one," but take them away and the whole process feels off.

## What is this?

[`umami.md`](umami.md) is a comprehensive development guardrails document designed to be consumed by both humans and LLM coding agents (like Claude Code, Cursor, Copilot, etc.). It covers project discovery, specification-first development, multi-layer testing, runtime validation, state tracking, documentation discipline, token efficiency, agent orchestration, and more.

> **A note on `CLAUDE.md`:** This template references `CLAUDE.md` as the project instruction file because it is the most widely recognized convention — Claude Code, Cursor, Windsurf, and other tools all read it. If your toolchain uses a different file (`.cursorrules`, `AGENTS.md`, `CODEBASE.md`, `copilot-instructions.md`), substitute accordingly. The practices are tool-agnostic; only the filename is convention.

**Domain-specific extensions** supplement the core with guardrails tailored to specific project types:

| Extension | Covers |
|-----------|--------|
| [`umami-web.md`](umami-web.md) | Visual regression, design systems, E2E browser testing, accessibility, performance budgets, frontend observability (RUM, error tracking), source map and build output discipline |
| [`umami-data.md`](umami-data.md) | Data quality testing, pipeline idempotency, schema evolution, boundary contracts, data observability (pipeline tracing, structured logging), backward/forward compatibility, delivery guarantees, derived data, batch vs stream |
| [`umami-iac.md`](umami-iac.md) | Dry-run culture, blast radius, state hygiene, cost awareness, secrets, drift detection, reliability engineering, scalability, SLOs/SLIs, observability as infrastructure (OTEL, alerting, dashboards, cost management), CI/CD pipeline discipline, security governance, platform engineering, common anti-patterns |
| [`umami-mobile.md`](umami-mobile.md) | Device matrix, release discipline, offline-first, platform testing, app store compliance, mobile observability (crash reporting, release health) |
| [`umami-cms.md`](umami-cms.md) | Extension inventory and audits, update management, CMS security fundamentals, content/config/code separation, core integrity, theme architecture, deployment discipline, production monitoring |
| [`cms/umami-wordpress.md`](cms/umami-wordpress.md) | *(Planned rollup into §25 — see banner in file.)* WordPress-specific: escaping functions, nonces, capabilities, plugin conflicts, hook discipline, wp_options performance, WP-CLI |
| [`cms/umami-drupal.md`](cms/umami-drupal.md) | *(Planned rollup into §25 — see banner in file.)* Drupal-specific: Twig escaping, Form API, config management, caching architecture, Composer discipline, Drush, service architecture |
| [`umami-compliance.md`](umami-compliance.md) | Data classification, regulated data handling (PHI/PII), incident response, disaster recovery, formal change management, audit evidence mapping, vendor risk, data lifecycle/retention, agent-as-attack-surface (prompt injection, supply chain, memory poisoning), cyber liability insurance readiness |
| [`umami-scripting.md`](umami-scripting.md) | Error handling and exit codes, input validation, output discipline (stdout/stderr/structured), idempotency, dependency and environment management, secrets handling, script testing (BATS, shellcheck), cross-platform portability, script organization |
| [`umami-integration.md`](umami-integration.md) | API versioning, circuit breakers, retry/backoff discipline, timeout discipline, rate limiting, graceful degradation, webhook reliability, correlation IDs and distributed tracing, contract testing, integration testing strategies |
| [`umami-homelab.md`](umami-homelab.md) | Living documentation, secrets discipline, script-based provisioning, snapshot culture, private DNS, VPN overlay, edge device firewalls, monitoring/alerting, incremental hardening, DHCP reservations, network segmentation, backup strategy, update management, TLS certificates, storage architecture, power management |
| [`umami-desktop.md`](umami-desktop.md) | GUI thread models, event loop discipline, headless E2E testing (F11/F12 protocol), single-file app discipline, app identity and packaging, data directory conventions, permission models, build/run discipline |
| [`desktop/umami-linux.md`](desktop/umami-linux.md) | GTK4/libadwaita, immediate-mode toolkits, Wayland vs X11, XDG base directories, DBus integration (dock badges, notifications), cage + wtype E2E toolchain, FFI patterns, Cargo workspace shapes. Currently the only OS-specific sub-extension under §27 — see scope note. |
| [`desktop/umami-spa-wrapper.md`](desktop/umami-spa-wrapper.md) | WebKitGTK session persistence (ITP, cookies, IndexedDB), clipboard bridge (GTK ↔ JS), notification forwarding, navigation policy (domain allow-lists), SSO/OAuth in-app handling, dock badge wiring, audio/media permissions, context menu suppression. Narrowest extension in the corpus — a worked example of §27 + §28 for one specific build pattern, not a domain peer. |

**Observability is a cross-cutting concern.** Rather than a separate extension, each domain extension includes its own observability guidance — what to monitor, how to alert, what to log — tailored to that domain's specific failure modes. The core template (§4) covers the foundational concepts (three signals, structured logging, instrumentation discipline).

The core template is **not** tied to any specific project. You reference it (and the relevant extensions) from your project and let your AI agent adapt the guidance to your codebase.

## Get started — one-liner bootstrap

Paste this into your AI assistant (Claude Code, Cursor, Copilot, etc.):

> **Set up umami in this project. Fetch https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/develop/umami.md and follow §0.7b.**

The agent fetches the spec, runs §0 discovery interactively (asking which kind of project this is, whether you have a data layer, frontend, mobile app, etc.), and proposes the right core + extension set per §0.5.

**Before any file is written, you'll see exactly what's changing** — every file touched, the URL block that would land in your instruction files, and any skill files that would be created. With your approval — via a four-option dialog (apply all / selective walkthrough / do something else / skip) — the changes are applied. Nothing happens to your project until you say so.

**This is a lightweight setup, not a framework install.** Init writes only URL references (so your agent knows where to fetch the spec) and small skill files (so the harness recognizes `/umami-init` and `/umami-audit` as commands). The umami spec itself is never stored locally — it's fetched fresh on every audit/init run from the canonical URL, which is a hard rule (§0.7) so the framework's evolution always reaches every project. There's no dependency to maintain, no library to upgrade.

After init, ongoing use:

- **`/umami-init`** — re-run when project shape changes (added a frontend, became multi-layer, added compliance requirements).
- **`/umami-audit`** — periodic process review.

### Manual setup (fallback)

If your harness can't write files, or you prefer manual control, paste this URL list into your project's `CLAUDE.md` (or equivalent) — keeping only the extensions that match your project shape (see §0.5 for the mapping):

```
# Core guardrails (always)
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md

# Extensions (pick the ones that match your project)
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-web.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-data.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-iac.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-mobile.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-cms.md
# WordPress and Drupal sub-extensions below — planned rollup into umami-cms.md in a future release
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/cms/umami-wordpress.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/cms/umami-drupal.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-compliance.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-scripting.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-integration.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-homelab.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-desktop.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/desktop/umami-linux.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/desktop/umami-spa-wrapper.md
```

Then ask the agent:

> Here are my development guardrails: [paste URL]
>
> Please read this document, then:
> 1. Run the project discovery questionnaire (§0) — propose answers based on exploring our codebase.
> 2. Determine our current adoption tier (§0.6) based on what practices we already follow.
> 3. Recommend 3-5 specific next practices from the next tier up that address problems we're currently experiencing.

The agent will explore your project and give you a focused set of recommendations — not a wall of 50 things to fix. Subsequent audits should follow the same tiered approach (§0.7), getting progressively more targeted as your process matures.

## Start with the tier that fits, not the whole document

Umami is a toolkit, not a mandate. Adopting everything at once on a new project adds process drag that outweighs the benefit. Instead, adopt in tiers — start with the foundations, then add practices when specific problems or project growth make them valuable.

**Tier 1 — Foundation** (every project, from day one)

These practices cost almost nothing to adopt and prevent the most common sources of waste.

| Practice | Section | Why it's foundational |
|----------|---------|----------------------|
| Project discovery | §0 | Know what you're building before applying guardrails |
| Predictable project structure | §1 | Agents and humans find things without searching |
| Phase / Session hierarchy for multi-sitting work | §1 | Gives commits, decisions, and roadmap a unit of work bigger than the commit and smaller than the milestone |
| Development discipline (TDD, systematic debugging) | §3b | Prevents "fix one thing, break another" cycles that burn tokens |
| Security discipline (boundaries, secrets, dependencies) | §4, §6 | Security bugs are the most expensive bugs — catch them by habit, not by audit |
| Enforced consistency (types, linting, formatting) | §6 | Catches errors at build time, not in production or code review |
| Dead code hygiene | §13 | Reduces codebase noise that confuses agents and humans |
| Pre-commit checklist | §15 (partial) | Catches common mistakes before they compound |

**Tier 2 — Structure** (adopt when the project outlives its first sprint)

These practices pay off when you start maintaining what you built, onboarding contributors, or coming back to your own code after a week away.

| Practice | Section | Adopt when... |
|----------|---------|---------------|
| Spec-first development | §2 | You're building features that take more than a session |
| Multi-layer testing | §3 | You have more than one layer (API + UI, pipeline + warehouse) |
| Interactive decision planning | §3c | A design has 3+ load-bearing decisions that compound on each other |
| Refactoring discipline | §3e | Agents refactor at velocity, or refactoring bundled with feature work hurts reviewability |
| Threat modeling | §4 | Project has security-relevant boundaries past prototype; you want security to be deliberate, not reactive |
| Runtime validation | §4 | Your system handles external input or runs in production |
| Documentation / ADRs | §7 | You make a decision you'll need to explain to someone later (including future you) |
| Token efficiency | §9 | Agent sessions are re-deriving the same codebase understanding |
| Status block in CLAUDE.md | §9.1 | Project ships in versions and a fresh session needs to know "where are we right now" |
| Progressive disclosure of context | §9.5b | MCP/tool count exceeds ~10, tool metadata > 30% of context, or deterministic multi-step workflows |
| Agent approval gate table | §14 | Project has agents taking consequential actions (write files, run commands, network, sub-agent dispatch) |
| Recovery runbooks per stateful surface | §5 | Project has persistent state that would be hard to reconstruct from scratch |
| Lifecycle hooks for automated behaviors | §14 | Project has "from now on when X, do Y" rules that need to fire automatically |
| File size budgets | §11 | Files are getting long enough that agents truncate or miss context |

**Tier 3 — Scale** (adopt when complexity demands it)

These are heavier practices that solve real problems in larger, longer-lived, or compliance-bound projects. Applying them to a prototype adds drag without payoff.

| Practice | Section | Adopt when... |
|----------|---------|---------------|
| State tracking & recoverability | §5 | Your system manages stateful operations that need rollback |
| Acknowledged gaps + per-release retros | §8 | Tech debt is accumulating, or releases need a frozen "what was true at vX.Y" record alongside the rolling gap registry |
| Measuring efficiency over time (ET, run-frequency) | §9.7 | Optimizing across recurring agent workflows or model tiers; need apples-to-apples cost comparison |
| Three-layer code review with AI pre-screen | §3d | Code generation outpaces human review; team is rubber-stamping or bottlenecking on review |
| Untrusted-content boundary discipline (typed wrapper / provenance / spotlighting) | §4 | LLM-feature product ingests external content and reaches users in production |
| Multi-provider behavioral testing (provider × substrate-tier matrix) | §3 | LLM-feature product serves multiple providers and correctness depends on model behavior |
| Architectural fitness functions | §3 | Project has clear architectural boundaries linter rules can't express; team has been bitten by boundary violations |
| Agent log discipline (layers / retention / review cadence) | §4 | Agents take consequential actions in production; audit trail matters for incident response, compliance, or debugging |
| Cross-implementation research before foundational ADRs | §7 | Committing to a foundational architectural approach with meaningful trade-offs |
| Cost caps and budget gates (3-layer + force-over-cap typed-confirm) | §9.7 | Project runs agents at scale; cost predictability matters; spend has surprised the team |
| Change propagation maps | §10 | Changes routinely touch 5+ files and contributors miss downstream impacts |
| Change tracking | §12 | Work spans multiple sessions and context is lost between handoffs |
| Agent orchestration | §14 | You're using multi-agent workflows or delegating to specialized agents |

**Extensions** follow the same principle: apply when the domain is present *and* the project is at least Tier 2. A WordPress site in its first week doesn't need §20.8 production monitoring — but it does need §20.2 security basics.

**How to move between tiers:** Use periodic audits. When you hit a pain point (regressions, lost context between sessions, agents making the same mistakes), check whether a Tier 2 or 3 practice addresses it. Adopt that specific practice, not the whole tier.

**Watch for onboarding anti-patterns.** The core template (§0.6) documents the five most common mistakes when adopting umami — adopting everything at once, process without product, documentation theater, cargo-culting practices, and treating the template as law. The agent is instructed to flag these during discovery and recommend mitigations.

### 4. Come back to it later — don't load it every session

This is **not** a document your agent should load every session. It's a process reference — use it to set up your project's guardrails, then let your project's own `CLAUDE.md` and docs carry the day-to-day instructions.

Come back to it occasionally (e.g., at the start of a new phase, after a rough sprint, or when onboarding a new contributor) and ask your agent to audit against a specific tier or a specific problem area — not the whole document at once.

### 5. Keep the URL in your project's `CLAUDE.md` for easy audits

Add this to your project's `CLAUDE.md` (or equivalent instruction file) so the URL is always at hand when you want to run a process review:

```markdown
## Process Audit Reference
- Development guardrails (core): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
- Extension — Web frontend: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-web.md
- Extension — Data pipelines: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-data.md
- Extension — IaC / DevOps: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-iac.md
- Extension — Mobile: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-mobile.md
- Extension — CMS (shared): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-cms.md
- Extension — WordPress (*planned rollup into §25*): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/cms/umami-wordpress.md
- Extension — Drupal (*planned rollup into §25*): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/cms/umami-drupal.md
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

Then whenever you want a gap analysis, tell your agent: *"Audit our process against the guardrails doc."* If your tool supports reusable prompts (Claude Code skills, Cursor notepads, custom GPT instructions), create an `umami-audit` prompt that fetches the core document and follows the tiered protocol (§0.7) — same invocation, same output format, every time. See §14 in the core template for how to set up this as a reusable prompt.

## What the document covers

### Core (`umami.md`)

| Section | Topic |
|---------|-------|
| §0 | Project discovery — onboarding questionnaire, adoption tiers, onboarding anti-patterns, tiered audit protocol |
| §1 | Project structure — predictable layouts, workspace partitioning, phase/session hierarchy for long-running work, multi-surface/one-primitive pattern |
| §2 | Specification-first development — specs before code; relationship to Spec-Driven Development (SDD) as the closest movement |
| §3 | Multi-layer test infrastructure — unit, E2E, visual regression, API tests, architectural fitness functions (architecture-invariant tests), multi-provider behavioral testing (provider × substrate-tier matrix) for LLM-feature products |
| §3b | Development process discipline — TDD, systematic debugging, verification, brownfield mapping before changes |
| §3c | Interactive decision planning — six-step protocol for designs with multiple compounding decisions, output-format discipline |
| §3d | Code review discipline — three-layer model (mechanical / AI pre-screen / risk-classified human focus); flags-document format; spot-check sampling; watch signals |
| §3e | Refactoring discipline — tests as safety net (non-negotiable); named transformations; small atomic commits; refactoring vs. cleanup distinction; agentic-velocity refactoring patterns |
| §4 | Runtime validation — structural correctness, observability, threat modeling (DFD + STRIDE / OWASP / MITRE ATT&CK / LINDDUN / PASTA), security discipline, agent runtime security, untrusted-content boundaries (prompt-injection hardening for LLM-feature products), agent log discipline (5-layer logs + retention + review cadence) |
| §5 | State tracking & recoverability — versioned, undoable state, per-stateful-surface recovery runbooks (failure modes / detection / restore steps / RTO-RPO / prevention) |
| §6 | Enforced consistency — strict types, style rules, environment isolation, dependency hygiene |
| §7 | Documentation as constraint — living audits, ADRs, audience targeting (with Diátaxis as a complementary content-type lens), cross-implementation research (research doc ↔ ADR pairing) |
| §8 | Acknowledged gaps — rolling gap registry plus point-in-time per-release retros |
| §9 | Token efficiency — front-loaded context (incl. CLAUDE.md status block), persistent memory, pre-derived understanding, progressive disclosure (lazy schema load, top-K tool retrieval, summaries-then-detail, workflow-as-code), context window optimization, effective-tokens metric, cost caps and budget gates |
| §10 | Change propagation maps — which files to touch for recurring changes |
| §11 | File size budgets — keep files small to reduce token cost and complexity |
| §12 | Lightweight change tracking — active change blocks, session handoffs |
| §13 | Dead code hygiene — delete, don't comment out |
| §14 | Agent orchestration — modes of AI use (implementation / thinking / reviewing), delegation (incl. cost-as-lever framing), model routing, skills, parallel review, MCP/tool integration with server-selection criteria, agent approval gate tables (HARD/SOFT/NONE), lifecycle hooks (PreToolUse / PostToolUse / SessionStart / Stop) |
| §15 | Checklist — before starting, during dev, before commit, before merge |

### Extensions

| File | Sections | When to apply |
|------|----------|---------------|
| [`umami-web.md`](umami-web.md) | §17.1–17.9 | Project has a web frontend |
| [`umami-data.md`](umami-data.md) | §18.1–18.11 | Project has data ingestion, pipelines, or a data warehouse |
| [`umami-iac.md`](umami-iac.md) | §16.1–16.19 | Project has infrastructure-as-code or cloud provisioning |
| [`umami-mobile.md`](umami-mobile.md) | §19.1–19.7 | Project has a native or cross-platform mobile app |
| [`umami-cms.md`](umami-cms.md) | §25.1–25.9 | Project is built on any CMS |
| [`cms/umami-wordpress.md`](cms/umami-wordpress.md) | §20.1–20.8 | Project is built on WordPress (loads with §25). **Planned rollup into §25 in a future release** — references will continue to resolve. |
| [`cms/umami-drupal.md`](cms/umami-drupal.md) | §21.1–21.9 | Project is built on Drupal (loads with §25). **Planned rollup into §25 in a future release** — references will continue to resolve. |
| [`umami-compliance.md`](umami-compliance.md) | §22.1–22.11 | Project has compliance/regulatory requirements or needs cyber liability insurance readiness |
| [`umami-scripting.md`](umami-scripting.md) | §23.1–23.10 | Project has CLI scripts, operational automation, or scripting-language CLI tools |
| [`umami-integration.md`](umami-integration.md) | §24.1–24.10 | Project integrates with external services, APIs, or message-based systems |
| [`umami-homelab.md`](umami-homelab.md) | §26.1–26.17 | Project is a homelab or small-scale self-hosted infrastructure |
| [`umami-desktop.md`](umami-desktop.md) | §27.1–27.9 | Project has a desktop GUI application |
| [`desktop/umami-linux.md`](desktop/umami-linux.md) | §28.1–28.10 | Desktop app targets Linux (loads with §27) |
| [`desktop/umami-spa-wrapper.md`](desktop/umami-spa-wrapper.md) | §29.1–29.12 | Desktop app wraps a web app in WebKitGTK (loads with §27 + §28) |

## Compliance and regulated environments

Umami isn't a compliance framework, but many of its practices produce exactly the artifacts that auditors and compliance frameworks ask for. If your project is subject to SOC 2, ISO 27001, HIPAA, PCI DSS, or similar requirements, you'll find that adopting umami's guardrails gets you a long way toward the "documented, repeatable process" that those frameworks demand.

| Umami practice | What it produces for compliance |
|---|---|
| **Architecture Decision Records** (§7) | Decision traceability — why choices were made, what was rejected |
| **Spec-first development** (§2) | Requirements documentation before implementation |
| **Multi-layer testing** (§3) | Evidence of verification at every layer |
| **Version-controlled baselines** (§3) | Proof that changes were intentional and reviewed |
| **Runtime validation** (§4) | Input validation and structural correctness checks |
| **State tracking with hashing** (§5) | Audit trail with integrity verification |
| **Acknowledged gaps** (§8) | A living risk register — known gaps with severity and ownership |
| **Change propagation maps** (§10) | Change impact analysis — what a change touches and in what order |
| **Change tracking** (§12) | Change management records — scope, acceptance criteria, decisions |
| **Agent orchestration** (§14) | Delegation discipline — consistent, auditable use of AI agents |
| **Pre-commit/pre-merge checklists** (§15) | Process evidence — proof that steps were followed, not just defined |

The project discovery questionnaire (§0.1) now asks about compliance requirements upfront. When compliance applies, several sections shift from "recommended" to "required" — the template adapts its own rigor based on the answer.

## How is this different from Superpowers?

[Superpowers](https://github.com/obra/superpowers) is an excellent project that tackles a related problem. Both aim to make AI-assisted development more disciplined and reliable. They're complementary, not competing — but they solve different problems with different trade-offs.

**Superpowers** is a **behavioral constraint system for the agent during active development.** It's a plugin with 14+ modular skills (brainstorming, planning, TDD, debugging, code review, etc.) that get loaded into the agent's context on demand. A bootstrap skill injects on every session start, and individual skills load when triggered. Its core insight is that agents rationalize skipping discipline — so it includes anti-rationalization tables, "iron laws," and red-flag lists to keep the agent honest in the moment.

**Umami** is a **process template for the project, not a runtime constraint on the agent.** It's a single document you review periodically and use to set up your project's guardrails — the `CLAUDE.md`, the test infrastructure, the documentation discipline, the change propagation maps, the session handoff patterns. Once applied, your project's own docs carry the day-to-day instructions. Umami itself stays out of the agent's context.

The key differences:

| | Umami | Superpowers |
|---|---|---|
| **What it is** | A process reference document | An agent plugin/skills framework |
| **When it loads** | On demand, for periodic audits | Bootstrap every session; skills on demand |
| **Token cost** | Zero per session (not in context) | Ongoing (bootstrap + loaded skills) |
| **What it optimizes for** | Reducing waste from regressions, tech debt, and reprocessing information across sessions | Preventing the agent from skipping steps during a single session |
| **How it works** | Sets up project infrastructure (docs, tests, memory, maps) that persist and compound | Constrains agent behavior in real-time with rules and checklists |
| **Platform** | Any LLM that can fetch a URL | Claude Code plugin (+ Codex, OpenCode) |
| **Adoption cost** | Paste a URL, ask for a gap analysis | Install a plugin, learn the skill system |

**The core philosophical difference:** Superpowers assumes the agent will misbehave unless actively constrained in every session. Umami assumes the agent will behave well if the project is set up with the right structure, documentation, and context — so it invests in making the project self-explanatory rather than policing the agent at runtime.

**Can you use both?** Yes. Superpowers keeps the agent disciplined during execution. Umami keeps the project structured so that disciplined execution doesn't get wasted on a disorganized codebase. They address different layers of the same problem.

## How is this different from Everything Claude Code?

[Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code) is a comprehensive agent harness optimization system — a collection of agents, skills, hooks, commands, rules, and MCP configurations designed to make AI coding agents more productive and secure. It supports multiple harnesses (Claude Code, Codex, Cursor, Kiro, OpenCode, Gemini, Trae, CodeBuddy) and ships as an installable npm package with 170+ skills, 46 specialized subagents, 76 slash commands, and language-specific rules for 13+ ecosystems.

Umami and ECC solve different problems at different layers. They're complementary, not competing.

| | Umami | Everything Claude Code |
|---|---|---|
| **What it is** | A process reference template | An agent harness plugin / configuration system |
| **What it provides** | Guardrails, practices, and checklists that shape *how* the project is structured | Agents, skills, hooks, and rules that shape *how* the agent behaves at runtime |
| **When it loads** | On demand, for periodic audits | Bootstrap at session start; skills/agents on demand |
| **Token cost** | Zero per session (not in context) | Ongoing (loaded skills, agent definitions, MCP tool schemas) |
| **What it optimizes for** | Reducing waste from regressions, tech debt, and reprocessing across sessions | Maximizing agent productivity, quality, and security within a session |
| **How it works** | Sets up project infrastructure (docs, tests, memory, maps) that persist and compound | Provides pre-built operational tooling the agent invokes during work |
| **Platform** | Any LLM that can fetch a URL | Multi-harness (Claude Code, Codex, Cursor, Kiro, Gemini, Trae, CodeBuddy) |
| **Scope** | Domain-agnostic process + domain-specific extensions (web, data, IaC, mobile, CMS, compliance, scripting, integration) | Language-specific rules (TypeScript, Python, Go, Rust, etc.) + workflow skills (TDD, code review, security, deployment) |
| **License** | CC BY-SA 4.0 | MIT |

**The core philosophical difference:** Umami invests in making the *project* self-explanatory so any agent (or human) works effectively from the project's own context — instruction files, codebase understanding docs, change propagation maps, session handoffs. ECC invests in making the *agent* more capable through pre-built skills, specialized subagents, and runtime automations.

**Where they influenced each other:** ECC's security guide and token optimization research surfaced practices that Umami now incorporates as process-level guidance — agent runtime security (§4), context window optimization (§9.6), and agent-as-attack-surface for compliance-bound projects (§22.11). These are the *what to practice* counterparts to ECC's *how to implement* tooling.

**Can you use both?** Yes. Umami structures the project so the agent starts each session with clear context and minimal re-derivation. ECC gives the agent better tools for the work it does within that session. A project with umami's guardrails and ECC's operational tooling gets both layers — the project is well-structured *and* the agent is well-equipped.

## How is this different from Anthropic's official Claude Code best practices?

[Anthropic's Claude Code documentation](https://docs.claude.com/en/docs/claude-code) is the official guidance for using Claude Code effectively — covering hooks, slash commands, MCP servers, settings, agent skills, model routing, and more. It's the comprehensive reference for what the tool can do.

Umami is the **opinionated process layer above the tool**. The official docs answer *"what does Claude Code do?"* Umami answers *"given a tool like Claude Code, how should the project be structured to make every session efficient and every output high-quality?"*

| | Umami | Anthropic Claude Code docs |
|---|---|---|
| **What it is** | A process discipline framework | Official tool documentation |
| **Scope** | Project-level practices that work across harnesses | Tool-level capabilities and configuration |
| **Stance** | Opinionated (tiers, anti-patterns with watch signals, audit protocol) | Reference-shaped (here's what the tool does; here's how to configure it) |
| **Audience** | Teams adopting AI-coding discipline at the project level | Anyone using Claude Code |
| **AI-tool agnostic?** | Yes — works with Claude Code, Cursor, Codex, Goose, etc. | Claude-Code-specific (some practices generalize) |
| **Lifecycle** | Periodic audits + version-tracked process maturity | Always-current reference |

**They compose.** Anthropic's docs tell you what Claude Code can do; umami tells you what your *project* should do to make any harness most effective. A team using both gets the tool-level capabilities (from Anthropic) plus the process-level discipline (from umami).

**Where they overlap:** practices around hooks, skills, MCP servers, and instruction files appear in both. Umami's §0.7 audit protocol and §0.7b init protocol depend on harness-supported skills — the underlying mechanism is what Anthropic documents. Where they diverge: tier-based adoption, anti-pattern watch signals, extension ecosystem, and cross-harness portability aren't Anthropic's job to provide — Anthropic ships the tool; umami ships the process discipline above it.

**Should you read both?** Yes. Anthropic's docs first if you're new to Claude Code; umami when you're past the "how do I make this work" phase and into "how do I structure the project for sustained good output across many sessions."

## Relationship to The Pragmatic Programmer

| Pragmatic Programmer Principle | Where Umami Operationalizes It |
|---|---|
| **DRY** (Don't Repeat Yourself) | Change propagation maps (§10), single-source-of-truth structure (§1) |
| **Orthogonality** | Modular project structure (§1), extension architecture, decoupled components |
| **ETC** (Easy to Change) | File size budgets (§11), dead code hygiene (§13), living documentation (§7) |
| **Tracer Bullets** | Spec-first development (§2) — build a thin end-to-end slice first, then fill in |
| **Design by Contract** | Runtime validation (§4), schema contracts, boundary testing |
| **Property-Based Testing** | Multi-layer test infrastructure (§3) — test invariants, not just examples |
| **Don't Program by Coincidence** | Development process discipline (§3b) — understand why code works, not just that it works |
| **The Specification Trap** | "When Not to Specify" (§2) — know when a spec adds drag instead of clarity |
| **Broken Windows** | Acknowledged gaps (§8) — make tech debt visible rather than letting it accumulate silently |
| **Estimating** | Magnitude estimates in change tracking (§12) — S/M/L/XL scope before starting work |
| **Pragmatic Teams** | Agent orchestration (§14) — coordination patterns for human + AI teams |
| **Your Knowledge Portfolio** | Token efficiency (§9) — pre-derived understanding, persistent memory, front-loaded context |

## Relationship to Designing Data-Intensive Applications

| DDIA Concept | Where Umami Operationalizes It |
|---|---|
| **Reliability, Scalability, Maintainability** | Project discovery (§0.1) — identify which pillar is the primary driver before choosing architecture |
| **Schema Evolution & Encoding** | Backward/forward compatibility (§18.8) — evaluate every schema change for both directions |
| **Exactly-Once / At-Least-Once Delivery** | Delivery guarantees (§18.9) — document the guarantee each pipeline stage provides |
| **Derived Data & Sources of Truth** | Derived data discipline (§18.10) — know what's rebuildable vs. what's authoritative |
| **Batch vs Stream Processing** | Processing model trade-offs (§18.11) — choose deliberately, reconcile when using both |
| **Fault Tolerance & Replication** | Reliability engineering (§16.12) — redundancy, failover, RTO/RPO, restore drills |
| **Partitioning & Load** | Scalability awareness (§16.13) — load parameters, bottleneck identification, capacity planning |
| **SLOs & Consistency** | SLOs/SLIs/error budgets (§16.14) — measurable reliability targets driving infrastructure decisions |
| **Idempotency** | Pipeline idempotency (§18.2) — safe-to-rerun pipelines, upsert patterns, checkpoint tracking |
| **Data Quality & Validation** | Data quality testing (§18.1) — completeness, uniqueness, freshness, referential integrity |

Kleppmann's book focuses on *understanding* distributed systems. Umami translates that understanding into checklists, rules, and review practices that prevent the failure modes the book describes.

## Relationship to Software Architecture: The Hard Parts

| The Hard Parts Concept | Where Umami Operationalizes It |
|---|---|
| **Trade-off analysis as discipline** | Interactive decision planning (§3c) — six-step protocol with explicit alternatives, recommendations, and rationale |
| **Architectural fitness functions** | Fitness functions as a test layer (§3) — automated tests that verify architecture invariants, distinct from unit / integration / linter / behavioral tests |
| **Architecture quanta and bounded contexts** | Workspace partitioning (§1) — partition by lifecycle, not by language; quanta are the lifecycle units |
| **Service granularity decisions** | Multiple surfaces, one primitive (§1) — single typed primitive forces consistency across granularity choices |
| **Decomposition decisions (monolith vs. services)** | Interactive decision planning (§3c) + cross-implementation research (§7) — pair decomposition decisions with research docs and the §3c protocol |
| **Distributed-system contracts** | Systems integration extension (§24) — circuit breakers, retries, contract testing, rate limiting, idempotency keys |
| **Data ownership and sovereignty** | Data extension (§18) — derived data discipline, source-of-truth contracts, schema evolution per §18.3 / §18.8 |
| **The First Law of Software Architecture** ("everything is a trade-off") | §3c failure mode "skipping the recommendation" + the entire interactive-decision protocol — explicit trade-off framing is the work, not a side concern |

The Hard Parts focuses on *the analytic discipline* of architectural trade-offs in distributed systems. Umami operationalizes that discipline at the project-process layer: when to apply it (§3c triggers), how to capture the analysis (§7 research docs paired with ADRs), and how to verify the architectural invariants survive in code (§3 fitness functions).

## Contributing

If you try this on your project and find gaps, patterns that don't apply, or things that should be added — open an issue or PR. This document gets better when people use it on real projects and report back what worked and what didn't.

## Important

**Do not copy `umami.md` or the extension files into your project.** Always reference them by URL so every project stays in sync with the latest version. Adapt the guidance for your specific project in that project's own docs.

## License

This work is licensed under [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/). You are free to share and adapt this material for any purpose, including commercial use, as long as you give appropriate credit and distribute any derivative works under the same license.
