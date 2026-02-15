# Umami — Rapid Development Guardrails

A shared template of processes, testing strategies, and AI token efficiency practices for fast, reliable software development.

## Why "Umami"?

Umami is the fifth taste — the one you can't quite name but immediately notice when it's missing. It's what makes a simple dish feel complete. These guardrails serve the same role for software projects: not a framework, not a tool, but the foundational practices that quietly make everything else work better. You might not point to any single rule and say "that's the one," but take them away and the whole process feels off.

## What is this?

[`umami.md`](umami.md) is a comprehensive development guardrails document designed to be consumed by both humans and LLM coding agents (like Claude Code, Cursor, Copilot, etc.). It covers project discovery, specification-first development, multi-layer testing, runtime validation, state tracking, documentation discipline, token efficiency, agent orchestration, and more.

**Domain-specific extensions** supplement the core with guardrails tailored to specific project types:

| Extension | Covers |
|-----------|--------|
| [`umami-web.md`](umami-web.md) | Visual regression, design systems, E2E browser testing, accessibility, performance budgets |
| [`umami-data.md`](umami-data.md) | Data quality testing, pipeline idempotency, schema evolution, boundary contracts, observability |
| [`umami-iac.md`](umami-iac.md) | Dry-run culture, blast radius, state hygiene, cost awareness, secrets, drift detection |
| [`umami-mobile.md`](umami-mobile.md) | Device matrix, release discipline, offline-first, platform testing, app store compliance |
| [`umami-wordpress.md`](umami-wordpress.md) | Security (escaping, nonces, capabilities), plugin audits, theme architecture, hook discipline, wp_options performance |
| [`umami-drupal.md`](umami-drupal.md) | Security (Twig escaping, access control, Form API), module audits, config management, caching architecture, Composer discipline |

The core template is **not** tied to any specific project. You reference it (and the relevant extensions) from your project and let your AI agent adapt the guidance to your codebase.

## How to use it

### 1. Copy the raw URLs

```
# Core guardrails (always)
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md

# Extensions (pick the ones that match your project)
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-web.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-data.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-iac.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-mobile.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-wordpress.md
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-drupal.md
```

### 2. Give it to your LLM agent

Paste the core URL (and any relevant extension URLs) into a conversation with your AI coding assistant and ask something like:

> Here are my development guardrails: [paste URL]
>
> Please read this document, then:
> 1. Tell me your understanding of what it covers.
> 2. Look at our project and do a gap analysis — where does our current process fall short of what this document recommends?
> 3. Suggest concrete next steps to close the most impactful gaps.

The agent will fetch the document, compare its guidance against your project's current state (structure, tests, docs, CI, etc.), and identify where you can improve.

### 3. Apply what makes sense, then come back later

This is **not** a document your agent should load every session. It's a process reference — use it to set up your project's guardrails, then let your project's own `CLAUDE.md` and docs carry the day-to-day instructions.

Come back to it occasionally (e.g., at the start of a new phase, after a rough sprint, or when onboarding a new contributor) and ask your agent to re-read it and do a fresh gap analysis against your current state.

### 4. Keep the URL in your project's `CLAUDE.md` for easy audits

Add this to your project's `CLAUDE.md` (or equivalent instruction file) so the URL is always at hand when you want to run a process review:

```markdown
## Process Audit Reference
- Development guardrails (core): https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
- Extension — Web frontend: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-web.md
- Extension — Data pipelines: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-data.md
- Extension — IaC / DevOps: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-iac.md
- Extension — Mobile: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-mobile.md
- Extension — WordPress: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-wordpress.md
- Extension — Drupal: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami-drupal.md
  Do NOT fetch these every session. These are reference URLs for periodic process reviews.
  When the user asks you to audit the development process, fetch the core document and
  any relevant extensions, then compare their recommendations against the project's current state.
```

Then whenever you want a gap analysis, just tell your agent: *"Audit our process against the guardrails doc in CLAUDE.md."* It knows where to find it without you having to dig up the URL.

## What the document covers

### Core (`umami.md`)

| Section | Topic |
|---------|-------|
| §0 | Project discovery — onboarding questionnaire to understand your system shape before applying guardrails |
| §1 | Project structure — predictable layouts, workspace partitioning |
| §2 | Specification-first development — specs before code |
| §3 | Multi-layer test infrastructure — unit, E2E, visual regression, API tests |
| §3b | Development process discipline — TDD, systematic debugging, verification |
| §4 | Runtime validation — structural correctness on every edit |
| §5 | State tracking & recoverability — versioned, undoable state |
| §6 | Enforced consistency — strict types, style rules, environment isolation |
| §7 | Documentation as constraint — living audits, ADRs |
| §8 | Acknowledged gaps — transparency about what isn't automated |
| §9 | Token efficiency — front-loaded context, persistent memory, pre-derived understanding |
| §10 | Change propagation maps — which files to touch for recurring changes |
| §11 | File size budgets — keep files small to reduce token cost and complexity |
| §12 | Lightweight change tracking — active change blocks, session handoffs |
| §13 | Dead code hygiene — delete, don't comment out |
| §14 | Agent orchestration — delegation, skills, parallel review, tool integration |
| §15 | Checklist — before starting, during dev, before commit, before merge |

### Extensions

| File | Sections | When to apply |
|------|----------|---------------|
| [`umami-web.md`](umami-web.md) | §17.1–17.7 | Project has a web frontend |
| [`umami-data.md`](umami-data.md) | §18.1–18.7 | Project has data ingestion, pipelines, or a data warehouse |
| [`umami-iac.md`](umami-iac.md) | §16.1–16.11 | Project has infrastructure-as-code or cloud provisioning |
| [`umami-mobile.md`](umami-mobile.md) | §19.1–19.6 | Project has a native or cross-platform mobile app |
| [`umami-wordpress.md`](umami-wordpress.md) | §20.1–20.7 | Project is built on WordPress |
| [`umami-drupal.md`](umami-drupal.md) | §21.1–21.8 | Project is built on Drupal |

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

A major motivation for umami was **token efficiency across sessions.** Regressions, tech debt, and the agent re-deriving the same understanding of your codebase every session are expensive. Umami addresses this with change propagation maps (§10), pre-derived codebase understanding (§9.3), session handoffs (§12), file size budgets (§11), and front-loaded context (§9.1) — all of which reduce the per-session cost of working with AI agents. These aren't topics Superpowers covers, because its focus is on what happens *during* a session, not what happens *between* them.

**Can you use both?** Yes. Superpowers keeps the agent disciplined during execution. Umami keeps the project structured so that disciplined execution doesn't get wasted on a disorganized codebase. They address different layers of the same problem.

## Relationship to The Pragmatic Programmer

Umami operationalizes many of the principles from *The Pragmatic Programmer* by Andy Hunt and Dave Thomas. Rather than leaving those ideas as abstract advice, umami encodes them into concrete guardrails, checklists, and project structures.

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

The mapping isn't one-to-one — umami extends these ideas into the AI-assisted development era, where token cost, session handoffs, and agent coordination are first-class concerns that the book (written before LLMs) couldn't anticipate.

## Contributing

If you try this on your project and find gaps, patterns that don't apply, or things that should be added — open an issue or PR. This document gets better when people use it on real projects and report back what worked and what didn't.

## Important

**Do not copy `umami.md` or the extension files into your project.** Always reference them by URL so every project stays in sync with the latest version. Adapt the guidance for your specific project in that project's own docs.
