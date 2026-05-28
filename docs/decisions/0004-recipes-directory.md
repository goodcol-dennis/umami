# ADR 0004 — Recipes directory as a fourth content category

**Status:** Accepted 2026-05-13
**Authors:** Dennis Portello, Claude
**Related:** [ADR 0001](0001-v3-file-split.md), [ADR 0002](0002-v3-folder-reorg.md), [`recipes/README.md`](../../recipes/README.md), [`audits/v3.0-retro.md`](../../audits/v3.0-retro.md)

## Context

After [ADR 0001](0001-v3-file-split.md) and [ADR 0002](0002-v3-folder-reorg.md) reorganized the umami corpus into landing + `core/` + `ext/`, a fourth content category became visible that didn't fit any existing slot: **drop-in implementation artifacts**.

Examples that motivated the category:
- A consulting timesheet pattern (inject log markers, define commit-message conventions, run a reconciliation script)
- A closed-loop PR review CI workflow (YAML + prompts + risk-taxonomy config)
- An ADR template ready to copy into a project
- A pre-filled §5 recovery runbook for common surfaces (database, secrets store, working tree)
- A status block starter ready to paste into a project's `CLAUDE.md`

These artifacts share a shape:
- **Opinionated** — there's a specific way to do this, not abstract guidance
- **Drop-in** — designed to be copied into a project and adapted, not read for principles
- **Implementation-shaped** — code, config, YAML, scripts, not principles
- **Cross-cutting** — relate to one or more sections of umami but aren't part of any one's discipline

The category isn't covered by:
- **Core practices** (landing + `core/`) — these are universal guardrails, principles, not implementations
- **Domain extensions** (`ext/`) — these are guidance for a domain, not a specific implementation
- **Agent skills** (`.claude/skills/`) — these are agent workflow invocation aids, not project artifacts

There's prior art for this shape: [garrytan/gstack](https://github.com/garrytan/gstack) is essentially a comprehensive recipe library for Claude Code — opinionated slash-command skills that implement specific practices. Recipes in umami are similar in shape but project-side rather than agent-skill-side.

## Decision

Add a `recipes/` directory at the repo root with:

1. **`recipes/README.md`** — explains what recipes are vs. extensions vs. skills, the status conventions (Planned / Drafted / Shipped), how to use a recipe, the roadmap, the contribution model, and a "Prior art and adjacent projects" section pointing at gstack and Everything Claude Code.

2. **Seeded with two placeholders**:
   - `recipes/consulting-timesheet.md` — inject enough tracking that an LLM can generate a billable timesheet at month-end
   - `recipes/closed-loop-pr-review.md` — auto-merge ~90% of PRs via mechanical pre-flight + AI review + risk-tiered disposition; cross-provider review on Medium+ tiers

3. **Status conventions** — each recipe declares Planned (slot reserved, content not yet drafted), Drafted (initial implementation, works for one project, may not be portable), or Shipped (mature, refined based on real adoption).

4. **Promotion path** — if a recipe matures into a discipline that applies broadly, it gets promoted to a `core/` companion or `ext/` extension. Recipes are the proving ground for opinionated implementations; not everything graduates.

## Consequences

**Positive:**
- The framework now has a home for opinionated implementations distinct from principled guidance
- Recipes can be added at low cost — single file, no propagation to core sections
- The seed content (consulting-timesheet, closed-loop-pr-review) demonstrates the pattern without committing to fully-drafted recipes today
- Mature umami practices (§3d, §6b, §30.5, etc.) gain a slot for their concrete implementations to land — bridging discipline (in core/extension) to implementation (in recipes/)
- The relationship to prior art (gstack) is made explicit; umami doesn't claim novelty where novelty doesn't exist

**Negative / accepted trade-offs:**
- Yet another content category to maintain and reason about — readers now have four shapes to understand (core / extension / recipe / skill)
- Recipes risk drift from the practices they implement; without versioning discipline, a recipe could fall out of sync with the underlying §-numbered guidance
- Placeholder recipes (Status: Planned) accumulate if not promoted to Drafted or Shipped — risks documentation theater (see §0.6 anti-pattern) if not periodically audited
- The boundary between "extension" and "recipe" is soft for some cases — could lead to confusion about where new content lands

## Alternatives considered

**Option A — Don't add recipes; let everything live in extensions:**
- Treat implementation artifacts as extensions of the existing extension category.
- Rejected because extensions are guidance documents (long-form, principled). Inserting opinionated code/YAML/scripts into them blurs the category. Recipes need their own slot.

**Option B — Add recipes to skill files (`.claude/skills/`):**
- Recipes already overlap with what gstack does as skills.
- Rejected because skills are *agent invocation aids* (run by an agent on a workflow), not *project artifacts* (copied into a project's filesystem). The categories are related but distinct: a skill might `/install-timesheet-tracking` which copies the recipe into the project.

**Option C — Defer to v3.1+:**
- Don't add recipes in v3.0; wait until a real recipe is ready to ship.
- Rejected because the directory is essentially free (`README.md` + placeholders) and reserving the architectural slot in v3.0 means future recipes don't have to re-decide where they go. The placeholders demonstrate the pattern even if they aren't full implementations.

**Option D — Different name (`cookbook/`, `templates/`, `snippets/`, `patterns/`):**
- Considered alternatives. `templates/` was rejected because umami itself is a template. `snippets/` was rejected as too narrow (recipes can be multi-file). `cookbook/` was a near-miss; `recipes/` was preferred as the more evocative term that maps directly to "cooking recipe" — fits umami's culinary branding (umami = fifth taste).

## Boundary criteria

When deciding whether new content goes in a `core/` companion, an `ext/` extension, or `recipes/`:

| Content shape | Goes in... |
|---|---|
| Universal principle that applies regardless of domain | `core/` |
| Domain-specific guardrails (web, data, mobile, CMS, etc.) | `ext/` |
| Opinionated implementation of a practice that exists in `core/` or `ext/` | `recipes/` |
| Agent workflow that gets invoked as a slash command | `.claude/skills/` |

For ambiguous cases, the test is: "Is this a *what to think about* (extension/core) or a *what to type / copy* (recipe)?"

## Validation

The recipes/ directory will be validated when external adopters actually use a shipped recipe in their own project and report whether the pattern works. The current seeds (consulting-timesheet, closed-loop-pr-review) are Planned-status; they get promoted to Drafted when the maintainer has run them on a real project, and to Shipped when refined based on adoption feedback.

If the recipes/ category proves redundant with skills/extensions in practice, it can be deprecated in a future major version. The directory's lifetime cost is low; the architectural slot is worth keeping until a clearer answer emerges.
