# Umami — Process / Documentation / Tracking Extension

This file is part of umami v3's concern-based file architecture. The landing document ([umami.md](umami.md)) contains the framework, Section Navigation Map, and Tier 1 practices. This file collects the *process / documentation / tracking* concern cluster — how the project explains itself, surfaces gaps, coordinates changes, and tracks state across sessions.

**When to fetch this file:** When an audit, init, or implementation task hits a Tier 2+ practice in any of §7 / §8 / §10 / §12. Specifically: ADR discipline, cross-implementation research, gap registry / per-release retros, periodic dropped-item audit, change-propagation maps, session-handoff tracking.

**Contents:**

- §7 Documentation as Constraint
- §8 Acknowledged Gaps (rolling registry + per-release retros + periodic dropped-item audit)
- §10 Change Propagation Maps
- §12 Lightweight Change Tracking

**Cross-references** in this file use plain `§N` notation. File location is metadata; section numbers are stable identifiers across all umami files.

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

### Audience targeting

Different docs serve different audiences — senior engineers (deep technical context, library names, version pins), executives or stakeholders (decisions and tradeoffs without jargon), operations / SRE (runbooks, recovery steps, signals), end users (task-oriented guides), AI agents (prescriptive ground truth without ambiguity). Specify the audience in the doc's frontmatter or opening line. Audience determines technical depth, jargon density, and what context the reader is assumed to already have.

When asking the AI to *generate* documentation, name the audience in the prompt — *"target a senior engineering audience"* changes the output significantly from *"write for an executive stakeholder"*. Mode-specific (§14): doc generation is implementation mode; audience is one of the inputs.

**Diátaxis as a complementary lens.** [Diátaxis](https://diataxis.fr/) (Daniele Procida) classifies documentation into four types — tutorials, how-to guides, reference, and explanation — each serving a different reader need and mode of engagement. This decomposition is orthogonal to audience targeting (a single audience often needs all four types) and is rigorous enough to detect when documentation is mixing concerns: a "tutorial" that's actually reference, an "explanation" hiding how-to steps. Audience targeting is the first cut (*who is this for?*); Diátaxis is the second cut (*what kind of content is this?*). Both apply to any doc.

### Cross-Implementation Research

When committing to a foundational architectural approach where alternatives have meaningful trade-offs (an agent loop architecture, an edit-format strategy, a sub-agent model, an authentication framework, a state-management pattern), audit alternatives systematically *before* locking the choice. The audit produces a research doc; the research doc feeds the ADR.

**Research doc structure:**

| Element | What it captures |
|---|---|
| **Alternatives audited** | Named, dated, deep-read (not README-skim). Why each was selected as a comparison anchor — lineage proximity, scale relevance, ideological diversity. 3–5 alternatives is plenty; more is shallowness disguised as thoroughness |
| **Comparison matrix** | Dimensions that matter for *your* specific decision (project-specific axes, not generic checklist). Each cell concrete — "exact + whitespace-normalized + ellipsis-wildcard + fuzzy + cross-file" beats "five-level fallback" |
| **Tiered steal-list** | Tier 1: direct fixes for current pain. Tier 2: patterns to adopt as the project grows. Tier 3: patterns deliberately rejected (and why) |
| **Date and revisit window** | Audit is a snapshot of the world at date X. Note when it should be re-validated (typically 6–12 months) |

**Tie to the ADR.** The research doc and the ADR are paired artifacts. The ADR cites the research doc; the research doc enumerates alternatives in the depth ADRs typically don't. ADR explains *what was chosen and why*; research doc shows the *alternatives considered* with concrete enough depth that "why not X" is answerable. Without the research doc, an ADR's "alternatives considered" section becomes a gesture; with it, the rejection reasoning is auditable.

**Watch signals:**

| Signal | What it catches |
|---|---|
| ADR has "alternatives considered" section but doesn't cite a research doc | Either the research wasn't done, or it lives in someone's head and is lost when they leave |
| Research doc with no date | Can't tell if it's still relevant; alternatives evolve, and the doc may be auditing yesterday's versions |
| Research doc without a comparison matrix (just prose summary) | Reader can't compare across alternatives; the work didn't go deep enough to surface trade-offs at the dimension level |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Research without follow-through | Five competitors audited; no steal-list; ADR makes the choice anyway with no synthesis | The steal-list is the deliverable. Without it, the audit was effort that didn't compound |
| Comparison matrix without depth | "Yes/No" cells across 12 dimensions | "Yes" hides what kind of yes. Each cell concrete enough that a reader sees the trade-off, not just presence/absence |
| Audit N years stale | Research doc cited a version of competitor X from 2 years ago; competitor has shipped major rewrites since | Date the doc. Set a revisit window. When the world has moved, the audit's authority decays |
| Research used to justify the predetermined choice | Comparison matrix conveniently shapes itself toward what was already going to be picked | Audit an alternative the team is *suspicious* of, not just one they want to dismiss. The research is for surfacing surprises, not validating prior decisions |

**Cross-references:**
- §7 ADRs — research doc feeds the ADR's "alternatives considered" section with concrete depth
- §2 specs — research informs which alternatives are worth specifying against
- §0.6 anti-pattern table — "Cargo-culting practices" (one source of cross-impl research is *catching* patterns that look universal but actually aren't)

---

## 8. Acknowledged Gaps

Transparency about what isn't automated yet is itself a guardrail. Document these explicitly:

- CI/CD pipeline status (local-only vs. automated).
- Linting/formatting automation (manual vs. tooled).
- Pre-commit hooks (present, planned, or intentionally absent).
- Coverage thresholds (enforced or aspirational).
- Known technical debt with severity and ownership.

### Living Retros vs. Gap Registry

Two different documents serve two different jobs. Don't conflate them — they decay differently and answer different questions.

| Document | Type | Lifecycle | Answers |
|---------|------|-----------|---------|
| **Gap registry** (`docs/audits/gaps.md` or similar) | Rolling state — current view of open issues. | Mutable. Entries get added, statuses change, items close (mark ~~strikethrough~~ rather than delete — closing matters as much as opening). Always current. | "What's open right now? What's the severity? Who owns it? What triggers addressing it?" |
| **Per-release retro** (`docs/audits/v0.X.Y-retro.md` or `phase-N-retro.md`) | Point-in-time snapshot — frozen at release. | Immutable after the release ships. Never edited; new retros append, old ones stay as-shipped. | "What was true at release T? What shipped, what slipped, what was the budget actually spent on?" |

The retro is what was true *at point T*; the registry is current. A retro that gets edited later loses its value as a frozen reference. A registry that's frozen loses its value as a current-state document.

**Retro template** (one per release / phase / milestone, depending on cadence):

```markdown
# Retrospective — v0.X.Y (Phase N: <Capability>)

**Released:** YYYY-MM-DD
**Sessions:** S<N>–S<M>
**Active gaps remaining:** [list with names, severity, trigger]

## What shipped
- [Concrete deliverables, ideally with file/spec references]

## What slipped
- [Things planned for this release that deferred — with new target if known]

## Where the budget went
- [Surprises, time sinks, things that took longer than expected — useful for sizing future work]

## Decisions made
- [Pointers to decisions.md entries from this release]

## Followups
- [New gaps opened, new ADRs needed, refactors to schedule]
```

The retro stays useful for years as a reference for "what was the state of the world at v0.10.0?" The registry only ever shows the current snapshot. Both are needed; neither replaces the other.

### Periodic Dropped-Item Audit

§8 above covers known gaps (rolling registry, point-in-time retros). This sub-section covers a third concern: **items that aren't formally tracked because they represent dropped intent or dropped relevance** — designs proposed but never decided, explorations that surfaced findings but the findings never reached a decision, POCs that ran their course but were never archived, "decide later" deferrals that nobody returns to, and shipped features that lost active use or active ownership without anyone noticing. In a healthy project, decisions are made (ADRs / decisions log) or explicitly deferred, and shipped features stay tied to active use. The dropped category — pre-ship intent that fizzled, post-ship features that quietly lost their purpose — is the silent middle ground.

The gap registry tracks items everyone *knows* are open. This audit catches items that *quietly fell off attention*. Both are needed.

**What to scan periodically** (quarterly is a reasonable default):

| Location | Look for |
|---|---|
| `docs/designs/` (or equivalent forward-design directory) | Files without recent updates; no implementation activity; no archive move |
| `docs/research/` (or equivalent exploration directory) | Research that surfaced findings; the findings never reached a decision |
| `poc/` (per §3b) | POCs nobody can explain — what question, what's the answer, why are they still here |
| Decisions log entries | "decide later" / "TBD" / "deferred" items with no resolution after multiple phases |
| ADRs in "Proposed" state | ADRs that never reached "Accepted" or "Rejected" |
| Phase backlogs | Items that have been "deferred" across N phases |
| Code TODOs referencing unbuilt designs | "TODO: implement when we ship X" where X never happened |
| Shipped features that have lost active use or ownership | Features documented in README, marketing, or feature lists but with no recent production exercise, no recent test runs, no clear owner. See §0.6 "Winchester Mansion sprawl" for the architectural-sprawl framing |

**For each dropped item, decide one of:**

- **Revive** — still relevant; schedule into the next phase; add to gap registry if blocking
- **Archive** — was relevant; not blocking; move to `docs/designs/_archive/` (or equivalent) with a note
- **Delete** — no longer relevant; remove the file (git history preserves it)
- **Re-decide** — "decide later" decisions get a real decision now (Yes / No / Pivot)

**Default disposition: archive unless revival is justified**, not keep unless deletion is justified. Items at rest stay at rest; the audit's job is to force motion.

**Post-ship items (shipped features) use different dispositions.** A shipped feature that surfaces in the audit gets: **Keep** (active use confirmed) / **Deprecate** (announce removal with timeline so users can migrate) / **Remove** (no users, no future, no transition needed). The pre-ship default (archive unless revival is justified) doesn't apply — shipped features carry operational cost while they exist, so the default tilts toward Deprecate-or-Remove when active use can't be confirmed. See §13 dead code hygiene for the per-line equivalent.

**Watch signals:**

| Signal | What it catches |
|---|---|
| `docs/designs/` has many files >6 months old without implementation or archive | Forward designs accumulating without resolution; backlog rot |
| Decisions log has many "deferred" entries without resolution | "Decide later" became "never decide"; decision-avoidance pattern |
| Phase retros show same items "deferred" across multiple phases | Items silently dying; force the disposition |
| Feature documented in marketing or README has no production exercise in the last 90 days | Winchester sprawl candidate — feature kept beyond its useful life |
| Audit produces a very large list | Either cadence is too long, or process maturity needs work to catch items earlier |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Audit treats everything as "still relevant" | Findings list grows; nothing gets archived | Default to archive unless revival is justified |
| Audit runs without dispositions | Findings produced; no decisions made; next audit finds the same items | Each item gets a disposition. Audit-without-decisions is theater |
| Aggressive deletion erases history | Items deleted in one audit, re-proposed in a later session without knowledge of prior thinking | Archive (don't delete) preserves discoverability; deletion is for truly dead items |
| Audit cadence too long | First run finds 50+ items; team is overwhelmed | Quarterly is reasonable; first run may need batched triage; subsequent runs should be smaller |

**Cross-references:**
- §8 above — gap registry tracks known items; this audit catches forgotten items
- §3b POC lifecycle — same disposition vocabulary (Keep / Archive / Delete) applied to a broader scope
- §7 ADRs — "Proposed" ADRs that fell off the radar; audit reviews and decides
- §0.7 process maturity audit — different audit type; runs on different cadence
- §3d code review — TODOs referencing unbuilt designs can be flagged in code review
- §0.6 "Winchester Mansion sprawl" — the anti-pattern this audit (in its feature-scoped mode) is the primary mitigation for
- §13 dead code hygiene — per-line equivalent; pairs with the feature-level audit (line-level dead code + feature-level dead capabilities)
- §1 Preserving Project Structure — upstream protection; resists the drift that produces dropped items

---

## 10. Change Propagation Maps

For every recurring change type, document which files must be updated and in what order. This is the single highest-value token optimization: without it, the AI rediscovers the dependency chain every session through grep and file reads. With it, zero search cost.

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

Remove the handoff block once the next session has picked up the work.

---

