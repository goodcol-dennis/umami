# Umami Recipes

**Recipes are drop-in implementation artifacts for cross-cutting features** — opinionated, copyable, often spanning multiple files. They live alongside the umami framework but aren't part of the §0–§31 numbered guidance.

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

## Licensing

Code blocks inside recipes (bash, YAML, config snippets) are MIT-licensed (see `LICENSE-CODE` at the repo root) so they can be embedded in proprietary codebases; the surrounding prose remains CC BY-SA 4.0.

## Roadmap

| Recipe | Status | What it does |
|---|---|---|
| [`activity-stream.md`](activity-stream.md) | Drafted | Consolidated activity stream (multi-source capture: Claude `Stop` hook + git `post-commit` + manual `/log`) — primary use case is billable-timesheet reconstruction; replaces the v3.0 `consulting-timesheet.md` placeholder |
| [`claude-md-starter.md`](claude-md-starter.md) | Drafted | Distilled Tier-1 CLAUDE.md starter block — the zero-ceremony entry point; paste one block, get the guardrail floor on the next agent turn. Graduation triggers point into the full framework. |
| [`closed-loop-pr-review.md`](closed-loop-pr-review.md) | Planned | Auto-merge ~90% of PRs via mechanical pre-flight + AI review + risk-tiered disposition, with optional cross-provider review for adversarial verification on Medium+ tiers |
| `agent-cost-monthly-report.md` | Future | Aggregate agent token costs across workflows for invoicing or budget tracking |
| `adr-template.md` | Future | Drop-in ADR template with the §7 fields pre-stubbed |
| `recovery-runbook-template.md` | Future | Pre-filled §5 runbook for common stateful surfaces (database, secrets store, working tree) |
| ~~`status-block-starter.md`~~ | Folded into [`claude-md-starter.md`](claude-md-starter.md) | §9.1 status block template — the starter block ships the Status skeleton, so no separate recipe is needed |
| `gitignore-stack-{node,python,rust}.md` | Future | Opinionated `.gitignore` for common stacks |

This roadmap is illustrative, not committed. Recipes get added when a contributor has a working pattern to share.

## Prior art and adjacent projects

Recipes aren't a novel idea — they're the umami-shaped version of "opinionated skill libraries" that other AI-tooling projects have already shipped at scale. The clearest example:

**[garrytan/gstack](https://github.com/garrytan/gstack)** — Garry Tan's open-source Claude Code skill library. 23 specialized skills + 8 power tools, organized as a virtual team (CEO, eng manager, designer, staff engineer, QA lead, release engineer, CSO, debugger, devex lead) running a sprint flow: *Think → Plan → Build → Review → Test → Ship → Reflect*. MIT-licensed. Works on ~10 AI coding agents (Claude Code, Codex CLI, OpenCode, Cursor, Factory, etc.).

How this relates to umami:

- **gstack skills are recipe-shaped.** Drop-in implementation aids, opinionated, copyable, ready to invoke. Many of gstack's skills (e.g., `/office-hours`, `/cso`, `/qa`, `/ship`) are what mature umami recipes could look like once they graduate from `Planned` → `Shipped`.
- **gstack implements practices umami documents.** `/office-hours` is shaped like §3c (Interactive Decision Planning). `/cso` operationalizes §4 Threat Modeling. `/review` implements §3d Code Review Discipline. `/retro` and `/learn` mirror §8 (gap registry + retros). The principles in umami's `core/` describe the *why*; gstack's skills are one concrete *how*.
- **They compose.** A team can adopt umami as the principles framework and gstack as the skill toolkit. `recipes/` doesn't aim to compete with gstack — it aims to be where umami-flavored skill implementations land, with the option of pointing at gstack (or other libraries) for the prior art on a given pattern.

If you're starting a new project today and want a complete, opinionated AI-team-in-a-box, gstack is the most thorough public example. If you want a principles framework that any toolset (gstack included) can respect, umami is the answer. The two are complementary, not competitive.

**Other AI-tooling libraries worth knowing about** (less directly recipe-shaped but adjacent):
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — comparison reference in the main [README](../README.md)
- [Anthropic's official Claude Code best practices](https://docs.anthropic.com/en/docs/claude-code) — the upstream documentation umami's discipline wraps around

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

Recipes were introduced as a directory in v3.0 as the architectural slot for drop-in artifacts. They're independent of the §0–§31 numbering — a recipe isn't a section, it's an implementation aid.
