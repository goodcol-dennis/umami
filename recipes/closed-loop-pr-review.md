# Recipe: Closed-Loop PR Review

**Status:** Planned (placeholder — pattern named, full implementation deferred until field-validated)

## What it does

Automates ~90% of PR reviews on a mature codebase by combining mechanical pre-flight gates, AI pre-screen, risk classification, and tier-based auto-merge. Real concerns are flagged for human review; low-risk changes merge automatically without humans in the loop. Optional cross-provider review uses a different LLM family than the code author for adversarial verification on Medium+ tier changes.

This recipe is the concrete implementation of §3d Code Review Discipline + §30.5 Closed-Loop PR Review. The discipline says *what* to do; this recipe gives the actual GitHub Actions workflow, prompts, and config.

## When it earns its cost

- Project ships changes at agentic velocity (multiple PRs per day per contributor)
- 60%+ of changes are Trivial / Low per the §3d risk taxonomy
- Token budget can absorb per-PR review cost (with or without cross-provider review)
- Tests are trustworthy enough that mechanical pre-flight is meaningful
- Team has agreed on a risk taxonomy and committed it to the project's `CLAUDE.md`

## When it doesn't earn its cost

- Small team, low PR volume, humans keep up easily
- Early-stage project with frequent breaking changes — most PRs are Medium+
- Weak test coverage; mechanical pre-flight isn't trustworthy
- Compliance-bound project where audit trail requires human sign-off on every change (see §22)
- Project budget can't absorb per-PR review costs; this is Tier 3 / Scale practice

## Prerequisites

This recipe is **Planned** — the full implementation is not yet drafted. The shape will likely include:

- A `.github/workflows/pr-review.yml` (or equivalent CI config) implementing the loop protocol
- A `.umami/risk-taxonomy.yml` mapping path globs and diff-content patterns to tier (Trivial / Low / Medium / High / Critical) per the §3d taxonomy
- A reviewer prompt template (per provider) embedding the project's risk dimensions
- A classifier prompt template
- A cost-cap configuration per §9.7
- A logging adapter that writes auto-merge decisions to the project's §4 agent log
- A branch protection configuration that respects the auto-merge tier table

It will pair with:
- §3d (Code Review Discipline) — the underlying discipline
- §30.5 (Closed-Loop PR Review) — the workflow pattern documentation
- §9.7 (Cost Caps and Budget Gates) — non-negotiable per-PR cost cap
- §4 (Agent Log Discipline) — auto-merge events feed the decisions layer
- §14 (Agent Approval Gates) — auto-merge is a HARD action; gate must be explicit
- §10 (Change Propagation Maps) — path additions must update both the propagation map and the risk-taxonomy signal map

## The recipe

*To be drafted. The following is the placeholder shape:*

```yaml
# .umami/risk-taxonomy.yml — example skeleton

dimensions:
  security:
    paths: ["auth/**", "src/api/auth/**", "**/middleware/auth*"]
    diff_patterns: ["password", "token", "secret", "BEARER", "api_key"]
  data_integrity:
    paths: ["db/migrations/**", "**/*.sql"]
    diff_patterns: ["ALTER TABLE", "DROP", "NOT NULL"]
  contract_integrity:
    paths: ["src/api/**", "openapi.yaml"]
    diff_patterns: ["@deprecated", "BREAKING:"]

tiers:
  trivial:
    examples: [typo, dep_version_bump, formatting_only, generated_file_regen]
    requires: [mechanical_pass]
    disposition: auto_merge

  low:
    examples: [internal_refactor, test_addition, doc_update]
    requires: [mechanical_pass, ai_pre_screen_no_flags]
    disposition: auto_merge_with_notification

  medium:
    examples: [new_feature_behind_flag, ui_change]
    requires: [mechanical_pass, ai_pre_screen_with_flags, human_ack]
    disposition: merge_on_human_ack
    cross_provider_review: true

  high:
    # new_dependency is High, not Medium — the supply-chain risk lives in the
    # package, not the diff, so an AI pre-screen cannot clear it alone (§3d, §6)
    examples: [auth_change, payment_flow, schema_migration, new_dependency, public_api_change]
    requires: [mechanical_pass, ai_pre_screen, full_human_review, threat_model_link]
    disposition: merge_on_full_human_approval
    cross_provider_review: true

  critical:
    examples: [secrets_handling, untrusted_content_boundary, major_architecture]
    requires: [mechanical_pass, ai_pre_screen, full_team_review, adr]
    disposition: merge_on_team_approval
    cross_provider_review: true
    auto_merge: never
```

```yaml
# .github/workflows/pr-review.yml — example skeleton

name: Closed-Loop PR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  mechanical:
    # lint, types, tests, coverage delta
    # outputs: pass/fail + diff summary

  classify:
    needs: mechanical
    # Apply .umami/risk-taxonomy.yml to determine tier
    # outputs: tier name

  ai_review:
    needs: classify
    # Invoke primary reviewer
    # If tier is Medium+, also invoke cross-provider reviewer
    # outputs: flags document

  disposition:
    needs: [classify, ai_review]
    # Look up disposition for tier in taxonomy
    # Apply: auto_merge | request_ack | request_review | block
    # Log decision to project agent log
```

The actual implementation drafts when a contributor has run it on a real codebase for at least one release cycle and refined what works.

## Cross-references

- §3d Code Review Discipline — risk taxonomy, three-layer model, cross-provider review
- §30.5 Closed-Loop PR Review — workflow pattern, prerequisites, failure modes
- §9.7 Cost Caps and Budget Gates — per-PR cost cap; cross-provider review multiplies cost
- §4 Agent Log Discipline — every auto-merge is a logged decision event
- §14 Agent Approval Gates — auto-merge is a HARD action; gate semantics
- §10 Change Propagation Maps — path additions update both the propagation map and the risk-taxonomy signal map
- §6b Developer Experience and Pipeline Health — pipeline audit covers whether this workflow earns its cost over time
- garrytan/gstack `/review` and `/ship` skills — adjacent prior art; gstack ships review as an invocable skill, this recipe ships review as a CI-side workflow

## Status updates

- 2026-05-16: Placeholder created. Pattern documented in §3d (discipline) and §30.5 (workflow). Full recipe deferred until a contributor has run the workflow on a real codebase for ≥1 release cycle and can share what worked / what surfaced.
