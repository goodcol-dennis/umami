# Umami — Rapid Development Guardrails

A shared template of processes, testing strategies, and AI token efficiency practices for fast, reliable software development.

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

## Contributing

If you try this on your project and find gaps, patterns that don't apply, or things that should be added — open an issue or PR. This document gets better when people use it on real projects and report back what worked and what didn't.

## Important

**Do not copy `umami.md` into your project.** Always reference it by URL so every project stays in sync with the latest version. Adapt it for your specific project in that project's own docs.
