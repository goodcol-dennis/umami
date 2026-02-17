# Umami — Project Instructions

This repository contains `umami.md` (a development guardrails template) and its domain-specific extensions. The content is consumed by both humans and LLM coding agents. Every file is a Markdown document — there is no application code.

## What this repo is

A **process template**, not a software project. There are no tests, no builds, no dependencies. Quality is measured by clarity, internal consistency, and correct cross-references — not by CI passing.

## Files

| File | Role |
|------|------|
| `umami.md` | Core template — sections §0–§15 |
| `umami-web.md` | Web frontend extension — §17 |
| `umami-data.md` | Data pipelines extension — §18 |
| `umami-iac.md` | IaC / DevOps extension — §16 |
| `umami-mobile.md` | Mobile extension — §19 |
| `umami-wordpress.md` | WordPress extension — §20 |
| `umami-drupal.md` | Drupal extension — §21 |
| `umami-compliance.md` | Compliance / regulated industries extension — §22 |
| `README.md` | Public-facing documentation, adoption guide, comparison tables |
| `LICENSE` | CC BY-SA 4.0 |

## Section numbering

Core sections are §0–§15. Extensions use §16+ (assigned per extension, see table above). New extensions get the next available number. Section numbers are **stable identifiers** — they are cross-referenced across files and must never be renumbered.

## Change Propagation Map

When you make changes to this repo, multiple files often need coordinating updates. Consult this map before marking any change as complete.

| Change type | Files touched (in order) |
|---|---|
| **Add a new extension file** | 1. Create `umami-{name}.md` with next available §number → 2. `README.md`: extension table, URL list, CLAUDE.md example block, "What the document covers" extensions table → 3. `umami.md`: CLAUDE.md example block (§0.8), §0.5 mapping table if the extension maps to specific core sections → 4. This file (`CLAUDE.md`): Files table above |
| **Add a new core section to `umami.md`** | 1. `umami.md`: add section, update §0.5 mapping table if applicable → 2. `README.md`: "What the document covers" core table → 3. `umami.md`: adoption tier tables in §0.6 (assign to Foundation/Structure/Scale) → 4. `README.md`: corresponding tier table → 5. `umami.md`: §15 checklist if the section produces a pre-commit artifact |
| **Add a subsection to an existing core section** | 1. `umami.md`: add subsection → 2. `README.md`: update section description if the subsection changes what the section covers → 3. If the subsection is a new practice, add to appropriate tier in §0.6 + README tier tables |
| **Update the CLAUDE.md example block** | 1. `umami.md` (§0.8) → 2. `README.md` (step 5 in "How to use it") — these must stay in sync |
| **Rename or re-describe a section** | 1. `umami.md` → 2. `README.md` section description tables → 3. Any extension files that cross-reference the renamed section |
| **Add cross-references between core and extensions** | 1. Source file (the one adding the reference) → 2. Target file (add reciprocal "see also" if appropriate) |
| **Update adoption tiers** | 1. `umami.md` §0.6 → 2. `README.md` tier tables — these must mirror each other exactly |

## Writing conventions

- **Voice:** Direct, imperative, second-person ("Document the boundary," not "One should document the boundary").
- **Audience:** The primary reader is an LLM coding agent. The secondary reader is a human developer. Write for both — clear enough that an agent follows it without ambiguity, readable enough that a human skims it efficiently.
- **No fluff:** Every sentence should either define a practice, explain why it matters, or provide a concrete example. If a sentence does none of these, delete it.
- **Cross-references:** Use `§N` notation (e.g., "see §4 for runtime validation"). Never use page numbers or vague references like "see above."
- **Tables over prose:** When listing practices, requirements, or mappings, prefer tables. They're faster to scan for both humans and agents.

## Branching

- `main` — released, tagged versions (currently v1.0)
- `develop` — active work, merged to main for releases

## What NOT to do

- Do not add application code, tests, or CI pipelines — this is a documentation repo.
- Do not renumber existing sections — cross-references across all files and downstream projects depend on stable numbers.
- Do not duplicate guidance between core and extensions — put it in one place and cross-reference.
- Do not add speculative sections ("we might need this someday") — only add practices that address a demonstrated need.
