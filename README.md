# Umami — Rapid Development Guardrails

A shared template of processes, testing strategies, and AI token efficiency practices for fast, reliable software development.

## Why "Umami"?

Umami is the fifth taste — the one you can't quite name but immediately notice when it's missing. It's what makes a simple dish feel complete. These guardrails serve the same role for software projects: not a framework, not a tool, but the foundational practices that quietly make everything else work better. You might not point to any single rule and say "that's the one," but take them away and the whole process feels off.

## What is this?

[`umami.md`](umami.md) is a comprehensive development guardrails document designed to be consumed by both humans and LLM coding agents (like Claude Code, Cursor, Copilot, etc.). It covers project discovery, specification-first development, multi-layer testing, runtime validation, state tracking, documentation discipline, token efficiency, and more.

It is **not** tied to any specific project. You reference it from your project and let your AI agent adapt its guidance to your codebase.

## How to use it

### 1. Copy the raw URL

```
https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
```

### 2. Give it to your LLM agent

Paste the URL into a conversation with your AI coding assistant and ask something like:

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
- Development guardrails: https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md
  Do NOT fetch this every session. This is a reference URL for periodic process reviews.
  When the user asks you to audit the development process, fetch this document and
  compare its recommendations against the project's current state.
```

Then whenever you want a gap analysis, just tell your agent: *"Audit our process against the guardrails doc in CLAUDE.md."* It knows where to find it without you having to dig up the URL.

## What the document covers

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
| §14 | Checklist — before starting, during dev, before commit, before merge |

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

## Contributing

If you try this on your project and find gaps, patterns that don't apply, or things that should be added — open an issue or PR. This document gets better when people use it on real projects and report back what worked and what didn't.

## Important

**Do not copy `umami.md` into your project.** Always reference it by URL so every project stays in sync with the latest version. Adapt it for your specific project in that project's own docs.
