# Umami Recipes

**Recipes are drop-in implementation artifacts for cross-cutting features** — opinionated, copyable, often spanning multiple files. They live alongside the umami framework but aren't part of the §0–§30 numbered guidance.

## What recipes are (and aren't)

| Category | Tells you... | Format | Lives in |
|---|---|---|---|
| **Core practices** (landing + `core/`) | universal guardrails | long-form guidance | repo root + `core/` |
| **Domain extensions** (`ext/*`) | domain-specific guardrails | long-form guidance | `ext/` |
| **Agent skills** (`.claude/skills/*`) | how to invoke a workflow | procedure files + hard rules | `.claude/skills/` |
| **Recipes** (this folder) | exactly how to wire up a cross-cutting feature | code snippets + config templates + setup instructions | `recipes/` |

A domain extension tells you *why* you'd want time-tracking discipline for consulting work. A recipe tells you *exactly* what hooks to install, what commit-message format to use, and what script to run so an LLM can generate a billable timesheet from a month of work.

## Status conventions

Each recipe declares its maturity:

- **Status: Planned** — placeholder; the pattern is named but not yet drafted. Useful for reserving slots.
- **Status: Drafted** — initial implementation. Works for the contributor's own projects; may not be polished or portable.
- **Status: Shipped** — mature, used in projects, refined based on real adoption. Safe to drop into a fresh project.

## How to use a recipe

1. Read the recipe — understand what it does, what it costs, when it earns its cost.
2. Copy the artifacts (snippets, scripts, config) into your project.
3. Adapt to your stack — recipes are opinionated but not universal. Adjust paths, tool names, conventions.
4. Cite the recipe in your project's `CLAUDE.md` or ADR so future contributors know where the pattern came from.

## Roadmap

| Recipe | Status | What it does |
|---|---|---|
| [`consulting-timesheet.md`](consulting-timesheet.md) | Planned | Inject enough tracking that an LLM can generate a billable timesheet at month-end |
| `agent-cost-monthly-report.md` | Future | Aggregate agent token costs across workflows for invoicing or budget tracking |
| `adr-template.md` | Future | Drop-in ADR template with the §7 fields pre-stubbed |
| `recovery-runbook-template.md` | Future | Pre-filled §5 runbook for common stateful surfaces (database, secrets store, working tree) |
| `status-block-starter.md` | Future | §9.1 status block template ready to paste into a project's `CLAUDE.md` |
| `gitignore-stack-{node,python,rust}.md` | Future | Opinionated `.gitignore` for common stacks |

This roadmap is illustrative, not committed. Recipes get added when a contributor has a working pattern to share.

## Contributing a recipe

Open a PR with a new `recipes/{name}.md`. Include:

- **Status** (Planned / Drafted / Shipped)
- **What it does** — one-paragraph summary
- **When it earns its cost** — conditions under which the recipe pays back
- **When it doesn't** — anti-conditions; cases where the recipe is wasted effort
- **Prerequisites** — what your project needs to already have in place
- **The recipe** — actual snippets, scripts, config. Working code preferred.
- **Cross-references** to relevant umami sections (e.g., "pairs with §12 change tracking")

If a recipe matures into a full discipline that applies broadly, consider promoting it to a `core/` companion or `ext/` extension instead.

## Relationship to the v3 architecture

Recipes were introduced as a directory in v3.0 as the architectural slot for drop-in artifacts. They're independent of the §0–§30 numbering — a recipe isn't a section, it's an implementation aid.
