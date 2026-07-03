# Umami — Agent Infrastructure Extension

This file is part of umami v3's concern-based file architecture. The landing document ([umami.md](../umami.md)) contains the framework, Section Navigation Map, and Tier 1 practices. This file collects the *agent infrastructure* concern cluster — practices specific to running AI agents efficiently within the project context.

**When to fetch this file:** When an audit, init, or implementation task hits a Tier 2+ practice in any of §9 / §11 / §14. Specifically: token efficiency, persistent memory, context-window optimization, file-size budgets (sized for agent context), agent orchestration, approval gates, lifecycle hooks, model routing, MCP/tool integration.

**Contents:**

- §9 Token Efficiency Practices
- §11 File Size Budgets
- §14 Agent Orchestration

**Cross-references** in this file use plain `§N` notation. File location is metadata; section numbers are stable identifiers across all umami files.

**Related extension:** [umami-agent-workflows.md](../ext/umami-agent-workflows.md) (§30) covers agent-*workflow* patterns (closed-loop auto-remediation, production agentic CI). This file covers agent-*infrastructure* building blocks.

---

## 9. Token Efficiency Practices

AI-assisted development bills by the token. Every search the AI runs, every file it reads to orient itself, every clarification question — that's spend. These practices minimize waste without reducing output quality.

**The cheapest LLM call is the one you don't make.** Every practice in this section is an instance of that principle — pre-load what's known, persist what's been derived, defer what isn't yet needed, summarize what's been used, and delegate deterministic work outside the context window. When deciding whether a practice is worth its overhead, that's the test: does it eliminate a call, shrink the call, or shorten the conversation?

### 9.1 Front-Load Context via Project Instructions

Provide a project instruction file (e.g., `CLAUDE.md`) at the repo root. This is injected into every AI session automatically. It should contain:

| Section | Why It Saves Tokens |
|---------|-------------------|
| **Exact versions** (runtime, package manager, language) | Eliminates "let me check what version" exploration |
| **Common commands** (copy-paste-ready) | No tokens spent figuring out how to run tests or start a dev server |
| **Project structure** (directory tree with one-line descriptions) | AI navigates directly instead of globbing |
| **Critical rules** (non-negotiable constraints) | Stated once, followed everywhere — no re-discovery |
| **Doc index with file paths** (topic → exact path) | AI reads the right doc on the first try instead of searching |
| **Status block** (current version, what just shipped, active gaps with names, files over budget, next phase target) | Fresh sessions know where the work *is* — not just what the project is. Eliminates "let me read the recent commits to figure out what's going on" rounds. |

**Status block specifics.** The Status block is updated *every release*, not when the project is initially set up and then forgotten. Treat it as resumable context: a fresh agent session reads CLAUDE.md and can immediately answer "what's the current version, what just shipped, what's open, where's the work going next?" Without this, every new session re-derives state from git log. Example shape:

```markdown
## Status

`v0.11.0` released — Phase 10 (save / export / reduce). Active gaps: <named-gap-1>,
<named-gap-2>. Files over the §11 budget: `<file-a>` (1002 lines), `<file-b>` (1062).
Next phase tag: **v0.12.0 — <Capability>** (scope summary).
See [ROADMAP.md], [v0.11.0-retro.md], [decisions.md].
```

The Status block is also where the §1 Phase / Session structure surfaces visibly — naming the current phase and the next phase tag. Update it as part of the release workflow; if you forget, the next session will tell you (it'll re-derive everything from scratch and the cost will be obvious).

**Per-send re-walk.** When instruction files (CLAUDE.md / AGENTS.md / skills) can change *during* a session — the team edits CLAUDE.md mid-session, a skill gets updated, AGENTS.md gets refined as you work — re-walk per *send* rather than per *session start*. Loading once at session start means the agent runs against stale instructions for the rest of the conversation, which becomes a real problem when those files are actively maintained. *Session-start* hooks (§14) fire only at session start; per-send re-walk is the live-edit alternative. The cost is small (a few hundred tokens per re-walk for short files); the benefit is that edits land instantly without restart. Harness-dependent: support varies. When the harness supports per-send re-walk, prefer it for projects under active CLAUDE.md / skills development.

### 9.2 Persistent Memory Across Sessions

Maintain a memory file that carries learnings between conversations:

- **Known pitfalls** — framework quirks, API limitations, broken assumptions. Without this, the AI rediscovers the same dead ends every session.
- **Selector/API workarounds** — hard-won knowledge about what doesn't work and what to do instead.
- **Architecture patterns** — e.g., "adding a new component type requires updates in these 6 files." Prevents a codebase search every time.
- **Pre-existing failures** — known test failures that aren't your bugs. Prevents the AI from spending tokens diagnosing out-of-scope issues.

### 9.3 Pre-Derived Codebase Understanding

The most expensive repeated cost is not file reads — it's the agent re-deriving the same conclusions about your codebase every session. "This is an Express app, routes go here, services call the db layer, config lives in env vars" — that understanding gets rebuilt from scratch each time unless you write it down as statements of fact.

Maintain a **codebase understanding document** (e.g., `CODEBASE.md` at the repo root). This is not architecture docs, not a directory map — it's the conclusions the agent would reach after exploring, written in advance so it never has to.

**What to capture:**

| Category | Example |
|----------|---------|
| **How to do common tasks** | "To add a new API endpoint: create a route file in `src/api/`, a service in `src/services/`, and a migration in `db/migrations/`. Register the route in `src/api/index.ts`." |
| **Where things live and why** | "All database queries go through `src/db/` — never call the DB directly from a route handler. This is enforced by convention, not tooling." |
| **How components connect** | "Routes call services. Services call db. Services never import from routes. DB functions return plain objects, not ORM models." |
| **Runtime behavior** | "The app reads config from environment variables at startup. No hot-reload for config — restart required." |
| **Non-obvious constraints** | "The `users` table has a unique constraint on email, but the app validates uniqueness in the service layer before hitting the DB to return a friendlier error." |
| **Testing patterns** | "Integration tests use a separate test database, created fresh per suite via `scripts/reset-test-db.sh`. Unit tests mock the db layer." |

**What NOT to capture:**

- Things that change every sprint (use Active Change blocks for that)
- Opinions or aspirations ("we should refactor X") — only capture what IS, not what should be
- Anything already in MEMORY.md — no duplication

**When to update it:**

- After completing a feature that changes how the codebase works (new layer, new pattern, new convention)
- After an agent session where the agent had to re-derive something that should have been pre-written
- The moment observed reality contradicts the document — reality wins; fix the doc in the same change
- As part of the "Before Every PR/Merge" checklist

**The key instruction in CLAUDE.md:**

```
Read CODEBASE.md before starting any task. Treat it as ground truth for how this project works.
Do not re-derive what is already stated there. Only explore files you plan to modify.
If observed reality contradicts CODEBASE.md, reality wins — trust what the code actually does,
and update CODEBASE.md in the same change so the next session inherits the correction.
```

The reality-wins clause is load-bearing, not a hedge: without it, "treat it as ground truth" instructs the agent to act confidently on a document that drifted last sprint. The document is a cache of derived understanding; a cache can be stale, and a stale entry gets invalidated by the read that discovers it, not trusted over the source.

The goal is zero "let me understand the codebase" processing. The agent reads the document and already understands. When the codebase evolves, the document evolves with it.

### 9.4 Documentation That Replaces Exploration

Every doc the AI doesn't have to search for is tokens saved:

- **Audit files with resolution status** — the AI checks whether an issue is already fixed instead of re-investigating.
- **Convention docs** — the AI follows a documented pattern instead of inferring one from scattered examples.
- **Decision records** — "we chose X over Y because Z." Prevents re-evaluation of settled decisions.

### 9.5 Structural Habits

- **Link docs to specific file paths** — `see [tools/definitions.ts](src/tools/definitions.ts)` not "see the definitions file." Eliminates glob/grep round-trips.
- **Pin environment details** — fixed ports, fixed paths, fixed versions. Each ambiguity resolved costs a tool call.
- **Delegate broad searches to subagents** — use cheaper/smaller models for exploration; keep the primary context focused on implementation.
- **Keep instruction files concise** — a 200-line memory file costs less per session than a 2000-line one. Link to detail files rather than inlining everything.

### 9.5b Progressive Disclosure

The most expensive context is context the agent doesn't currently need. Several practices above (front-loading, pre-derived understanding, structural habits) give the agent what it *will* need; **progressive disclosure** is the inverse — *don't load what it doesn't yet need, and let go of what it's done with.*

This shows up in four domains, all instances of the same pattern:

| Domain | Static (default) | Progressive disclosure |
|---|---|---|
| **Tool schemas** | All MCP/tool schemas live in context every turn — measured at 40–80% of context cost on tool-heavy setups | `search` → `describe` → `execute` pattern: cheap meta-tool to discover what's available, on-demand schema load for the chosen tool, then call it |
| **Tool inventory** | Every available tool's full description is exposed up front | Top-K retrieval over the toolset; load the 3–5 most relevant tools for this turn's task |
| **Data** | Fetch full records, full diffs, full logs into context | Fetch summaries / IDs / row counts first; pull the full record only when the agent needs the detail; summarize what's been used rather than carrying it forward |
| **Workflow** | LLM orchestrates each step in natural language; intermediate state lives in context | Pre-agent CLI work for known-deterministic data gathering; LLM emits code that runs the workflow elsewhere; only the final result returns to context |

**The trade-off.** Progressive disclosure usually costs more *round-trips* (extra search/describe calls, multi-step retrieval) in exchange for fewer *tokens per turn*, and constant — rather than linear — context cost as the toolset grows. On interactive sessions the round-trip cost shows up as latency, often ~50% slower than a static loadout. For high-frequency or large-toolset work, the token reduction is dramatic enough to justify the wait — observed input-token reductions of 90%+ are real once toolsets pass a few dozen tools.

**When to apply:**
- **Tool schemas:** when MCP/tool count exceeds ~10, any single tool's schema exceeds ~1 KB, or measured tool metadata exceeds ~30% of context.
- **Data:** always — preferring summaries-then-detail is rarely wrong, even at small scale.
- **Workflow:** when the workflow is deterministic (no per-step LLM judgment needed) and the intermediate state is large.

**When *not* to apply:**
- One- or two-tool setups where lazy loading adds round-trips without saving meaningful tokens.
- Latency-critical interactive work where the extra round-trips hurt UX more than the tokens cost.
- Workflows where the LLM legitimately needs to see intermediate state to make the next decision.

**Conversation cache as ally.** When a tool's schema has already been loaded earlier in the conversation, the harness's prompt cache typically holds it cheaply for the rest of the session. Lazy loading isn't lazy *forever* — it's lazy on first use, then cached. Design the discovery flow so frequently-used tools end up loaded once and reused.

### 9.6 Context Window Optimization

Beyond reducing per-lookup cost, there are structural strategies for getting more value from the context window itself — the finite budget of tokens the model can hold at once.

**Model routing for subagents:**

Not every task needs your most capable (and most expensive) model. When your tooling supports model selection for delegated tasks, match the model to the task complexity:

| Task type | Model tier | Rationale |
|-----------|-----------|-----------|
| File search, codebase exploration | Lightweight (fast/cheap) | Pattern matching doesn't need deep reasoning |
| Single-file edits, formatting, simple refactors | Lightweight | Clear instructions, bounded scope |
| Multi-file implementation, feature work | Standard | Balances capability with cost for typical coding |
| Complex architecture, cross-cutting refactors | Most capable | Needs to hold multiple subsystems in context simultaneously |
| Security analysis, compliance review | Most capable | Can't afford to miss vulnerabilities or misinterpret requirements |

Default to the standard tier for most coding. Upgrade when the first attempt fails, the task spans 5+ files, or the task involves security or architectural decisions.

**Strategic compaction:**

Most agent harnesses automatically compact conversation history when the context window fills. This is usually better than hitting the limit and losing context abruptly, but automatic compaction can discard context you still need. When your tooling supports it:

- Compact manually at logical boundaries — after completing a feature, after exploration, before switching to a different area of the codebase. This preserves context coherence better than automatic mid-task compaction.
- Before compacting, save important intermediate state to files (session summaries, investigation findings, partial plans). The agent can re-read these cheaply; re-deriving them is expensive.
- If your workflow involves heavy exploration followed by focused implementation, compact between the two phases — the exploration context is no longer needed once you've captured the conclusions.

**MCP and tool context costs:**

External tool integrations (MCP servers, database connections, API integrations) consume context window space for their tool definitions, schemas, and response payloads. This cost is ongoing — every tool's schema is present in context even when not in use, and **measured at scale, tool metadata routinely accounts for 40–80% of total context cost** depending on toolset size. It's the largest single dimension to leave unmanaged.

Three layers of mitigation:

1. **Prune what you don't need.** Enable only the tools required for the current task. An agent doing code review doesn't need database and deployment integrations loaded. Audit the tool list periodically — a single unused tool can account for the majority of tool-call traffic in a workflow.
2. **Lazy-load what you do need.** Prefer MCP servers that follow a `search` → `describe` → `execute` pattern (or equivalent dynamic-toolset architecture) — schemas load on demand rather than at session start. With a dynamic toolset, context cost stays roughly constant in the number of tools available; with a static one, it grows linearly. See §9.5b for the broader principle.
3. **Wrap when you can't redesign.** When the underlying server is static and you can't change it, wrap it: route through a thin proxy, expose only the subset of tools you actually use, or substitute a CLI wrapper bundled into a skill. The skill loads on demand; the MCP server's tool definitions occupy context permanently.

**On tool *design* (when you're building, not consuming):** tools designed for agentic workflows look different from API wrappers. They're single-purpose at the workflow level (one tool per task the agent actually needs to do, not one tool per HTTP endpoint), have clear and constrained inputs, return only what's needed, and bundle related operations (a `manage_X` tool that handles common workflows usually beats separate `create` / `update` / `delete` tools). API wrappers that mirror every endpoint produce the bloat this section is trying to mitigate.

**Tool responses are also progressive.** When a tool's natural response is a large object (a full PR diff, a long log, a complete record), prefer returning a summary or set of IDs by default with a follow-up call for detail. Carrying the full object forward in context every turn is the equivalent of a static schema for response data.

### 9.7 Measuring Efficiency Over Time

Raw token counts mislead when models or workloads shift. Two metrics give you a stable view of efficiency across model tiers and run frequencies.

**Effective Tokens (ET).** Apply model-cost multipliers and token-type weights so a "10% savings" means the same thing regardless of which model ran it:

```
ET = m × (1.0 × input + 0.1 × cache_read + 4.0 × output)
```

Approximate model multipliers (set yours from current pricing): Haiku-class ≈ 0.25×, Sonnet-class ≈ 1.0×, Opus-class ≈ 5.0×. Cache-read tokens are weighted at ~0.1× because they cost roughly an order of magnitude less than fresh inputs. Output tokens are weighted at ~4× because they cost several times more per token than inputs.

A 10% ET reduction means a genuine 10% cost reduction, regardless of the model mix that produced it. A 10% raw-token reduction can be illusion (you switched a workload from Opus to Haiku) or worse-than-it-looks (you switched the other way).

**Weight by run frequency.** When prioritizing efficiency work across multiple recurring agent workflows (CI runs, scheduled audits, daily summaries), multiply the per-run ET savings by run frequency. A 60% reduction on a workflow that runs 7 times per day compounds to far more aggregate savings than the same reduction on a once-weekly task. Optimize the high-frequency runs first.

### Cost Caps and Budget Gates

Measurement (ET formula above) tells you what costs were spent. Cost caps tell the harness when to *stop* spending. For projects running agents at scale — many invocations per day, many sub-agent dispatches, many provider calls — caps are the difference between predictable cost and surprise bills.

**Applies to — two audiences, two implementations.** Teams *building* agent products implement the cap layers below in their own harness code. Teams *using* a coding agent can only enforce what their harness and provider expose — typically provider-side spend limits, plan budgets, and (where supported) hook-based checks. If your harness exposes no budget hook, the practicable form of this practice is a provider-side spend limit plus the per-day review habit; document *that* as the cap rather than aspiring to enforcement surfaces you don't have (§0.6 "Cost caps in policy doc but not in code" still applies — the enforcement just lives at the provider).

**Three layers of cap:**

| Layer | What it caps | When it triggers |
|---|---|---|
| **Per-task** | Cost of one user request from prompt to result | Reaches limit during execution; agent halts and asks |
| **Per-session** | Cost across one chat session / interactive run | Cumulative across a session; cap applies to total session spend |
| **Per-day (or per-period)** | Total spend across a time window — usually per-user-per-day | Caps total window spend; affects new sessions starting |

When a cap is reached, the gate is HARD per §14 — block until user approves continuation. Don't soften to SOFT (auto-continue) on cost caps; the user needs the explicit choice.

**Force-over-cap typed-confirm.** A SOFT "click to continue" gate normalizes blowing through the cap. Use a *typed confirmation* — the user types the cost figure or a phrase like `"continue over $20"` — to override. Typing forces a beat of attention that clicking doesn't. The harness should record the override (action / cost / who-approved / timestamp) in the audit trail (§4 agent log decisions layer).

**Escalation paths:**

| Scenario | Path |
|---|---|
| Per-task cap hit on a typical workload | Likely the cap is set too low; revisit. Don't normalize blowing through |
| Per-session cap hit late in a complex task | Either the task was bigger than estimated, or the agent is looping. Halt and inspect |
| Per-day cap hit early | A workflow is running away. Block subsequent sessions; investigate the per-task pattern |

**Watch signals:**

| Signal | What it catches |
|---|---|
| Caps consistently hit at typical workload | Caps too low; user is fighting the system rather than getting useful gates |
| Force-over-cap fires routinely (>10% of cap-hits) | Either the cap is mis-calibrated or the typed-confirm is being clicked through |
| No cap-hit telemetry over weeks at known agent activity | Caps are set so high they're aspirational; effectively no gate |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Hard caps without escalation | User gets blocked mid-task with no path forward except restart | Force-over-cap typed-confirm gives a real path; don't gate to a dead end |
| Caps without measurement | "We have caps" but no ET tracking; can't tell if caps are calibrated | §9.7 ET measurement is the prerequisite for sane cap calibration |
| Per-day cap without per-task / per-session | One runaway task burns the daily budget; subsequent legitimate work is blocked | Cap at multiple layers; the most-binding fires first |
| Caps in policy doc but not in code | Documentation says "max $X per day" but no enforcement | Caps must be enforced in the harness (a hook, a settings constraint, etc.). Doc-only caps are aspiration |

**Cross-references:**
- §9.7 ET formula (above) — measurement is the prerequisite for cap calibration
- §14 Agent Approval Gates — cost caps are HARD gates; the gate table should include cost-cap rows
- §4 agent log discipline — cap decisions go in the decisions log layer

---

## 11. File Size Budgets

Large files are the primary driver of both token cost and technical debt:

- A 500-line file costs ~1,500 tokens per read. If the AI reads it 3 times per session, that's 4,500 tokens on one file.
- A 2,000-line file costs ~6,000 tokens per read. Three reads = 18,000 tokens.
- A 4,000-line file costs ~12,000 tokens per read. Three reads = 36,000 tokens — on a single file.

**Budget: files over 400 lines are candidates for extraction.** Not a hard rule, but a signal to evaluate whether the file has accrued multiple responsibilities.

Signs a file needs splitting:
- It appears in every change propagation map (it does too many things).
- Multiple unrelated functions live in the same file.
- The AI regularly reads the whole file but only modifies 10-20 lines.
- Merge conflicts happen frequently in the file.

Splitting large files also reduces blast radius: a change to one extracted module doesn't require the AI to re-read 3,000 unrelated lines for context.

### Documents whose section IDs are external contracts

The 400-line budget targets *source code* — files that ship as part of an application. It also applies to most design docs, with a typical ceiling of ~800 lines (split when there are clear sub-topics). It does **not** apply to documents whose section identifiers are external contracts.

A canonical example is the umami corpus itself. Sections are referenced as `§0.6`, `§3c`, `§9.1`, etc., across the landing document (`umami.md`), the companion files (including this one), extension files, downstream consumers, agent skills, and bookmarks. Renumbering or splitting would break those references silently. The cost of preserving stable IDs outweighs the benefit of staying under a line budget.

For documents in this category:
- The budget is **suspended**, not removed. Track the size as a gap (§8) and revisit if the file grows large enough that agents truncate it on read or that humans can no longer scan it.
- When growth becomes untenable, the right answer is usually **extraction along an orthogonal seam** — split out a coherent subsection that has minimal cross-references *into* the rest of the document. Update every cross-reference in lockstep, version-bump the corpus, and post a renumber note.
- If a file in this category is approaching the size where action is unavoidable, document the candidate seam in the gap registry well before the split — the seam is easier to identify in advance than under pressure.

---

## 14. Agent Orchestration

When your AI tooling supports multi-agent workflows — a lead agent delegating to specialist workers — the same guardrail principles apply, but the coordination model introduces new opportunities for token efficiency and new risks for waste.

This section is tool-agnostic. The patterns apply whether you're using Claude Code, Cursor, Windsurf, Copilot Workspace, or any agentic framework that supports delegation.

### The Orchestration Model

Most multi-agent systems follow the same pattern:

```
Human
  └─→ Lead Agent (full context, all tools)
        ├─→ Worker A (restricted context, read-only tools)
        ├─→ Worker B (restricted context, specific tools)
        └─→ Worker C (own context, own tools)
```

Each worker gets its own context window, a restricted toolset, and focused instructions. Results are summarized back to the lead. The lead's context stays clean — it never sees the 50 files Worker A read during exploration, only the 3-sentence conclusion.

### Modes of AI Use — Implementation, Thinking, Reviewing

When working with AI agents, distinguish three modes. They have different prompt patterns, different output formats, and different success criteria. Most projects implicitly default to implementation mode; the other two are equally important and often under-used.

| Mode | What you're asking for | Output shape | Examples |
|---|---|---|---|
| **Implementation** | Working code, executed action | Diff, file edits, completed task | "Write the auth middleware", "Fix this bug", "Refactor X" |
| **Thinking** | Clear reasoning, alternatives, tradeoffs | Document, decision matrix, recommendation with rationale | "Help me reason through this design", "Compare these approaches", "What are the tradeoffs of X vs Y?" |
| **Reviewing** | Critique, structured findings, attention routing | Findings report, prioritized callouts, file:line citations | "Audit this for security issues", "Review this PR", "Where does this break the contract?" |

**Implementation mode** is what most of umami covers — working-code outputs. The agent acts.

**Thinking mode** is the agent as thinking partner. The output is *reasoning made visible* — alternatives laid out, tradeoffs named, recommendations with reasoning. The §3c interactive decision planning protocol operationalizes this mode.

**Reviewing mode** is the agent as critic. Output is structured findings, not approval/rejection. The agent surfaces issues; humans decide what to act on. The §0.7 audit protocol and §3d code review operationalize this mode.

**Why this matters:** the three modes have different prompt patterns. An implementation prompt that works ("write a login form using these libraries") often fails in thinking mode — a different shape is needed ("walk me through the tradeoffs of OAuth vs. password-based auth for this app, with at least two recommendations and reasoning"). Specifying mode up-front in the prompt or skill is part of getting good output. Combined with the output-format discipline from §3c, this gives the agent a clear target instead of letting it guess.

**Mode in skills.** The skill library below contains skills in all three modes. Implementation-mode skills (codebase-search, refactor-helper) act. Thinking-mode skills (`/architectural-tradeoff`, `/migration-path-analysis`) elicit structured reasoning visible in the output. Reviewing-mode skills (`/umami-audit`, `/umami-auto-review`) produce structured findings.

### Delegation Principles

**Delegate when:**

- The task is **exploratory** — searching, reading, profiling. Worker context is disposable; don't pollute the lead's context with search results.
- Tasks are **independent and parallelizable** — security review, performance review, and test coverage review can run simultaneously.
- The task produces **verbose output** that only needs a summary — test suite runs, linting reports, dependency audits.
- A **cheaper/faster model** can handle it — codebase search and file reading don't need your most capable model.

**Don't delegate when:**

- The task requires **back-and-forth with the user** — delegation adds latency to every exchange.
- The task is **trivially small** — spawning a worker for a single grep adds overhead without savings.
- The task **depends on the lead's accumulated context** — if the worker would need the full conversation history to do its job, delegation doesn't save tokens; it duplicates them.

**Delegation as a token-cost lever.** Beyond context cleanliness, scoping toolsets per specialized subagent is a measurable cost reduction in its own right. A monolithic agent with every tool loaded pays for every tool's schema on every turn; specialized subagents with tool subsets pay only for the tools relevant to their task. Observed token-overhead reductions of ~50–60% are common when a single fat agent is split into purpose-scoped workers. This compounds with the orchestration benefits — it's not a separate technique.

### Model Routing — Delegate to Cheaper Models

Not every sub-task requires your most capable (and most expensive) model. Model routing is the practice of matching task complexity to model cost — sending expensive reasoning to a flagship model and routine work to a cheaper, faster one.

**Why this matters for token budgets:** A flagship model (Opus-class) may cost 10–15x more per token than a fast model (Haiku-class). If 60% of your agent's work is exploration, search, and boilerplate — tasks any competent model handles — you're overspending by 6–9x on that portion. Model routing isn't optimization theater; it's the single highest-leverage token cost reduction available.

#### Routing Decision Table

| Task type | Route to | Why |
|-----------|----------|-----|
| **Codebase exploration** — find files, search symbols, read and summarize code | Fast/cheap model | Read-heavy, low reasoning. The model is a search cursor, not an architect. |
| **Boilerplate generation** — test scaffolds, repetitive CRUD, config files | Fast/cheap model | Pattern-matching, not design. A cheaper model follows a template as well as a flagship. |
| **Lint, format, style fixes** | Fast/cheap model | Mechanical transforms with clear rules. |
| **Code review — surface-level** — style, naming, dead code, obvious bugs | Mid-tier model | Needs some judgment but not deep architectural reasoning. |
| **Architecture decisions** — design trade-offs, API contracts, system boundaries | Flagship model | Requires nuanced reasoning, multi-factor trade-offs, and deep context. |
| **Complex debugging** — multi-file, multi-layer, subtle state bugs | Flagship model | Needs the full reasoning stack — hypothesis generation, evidence gathering, synthesis. |
| **Security review** — vulnerability analysis, threat modeling | Flagship model | False negatives are expensive. Don't economize on security reasoning. |
| **Spec writing and planning** — translating requirements into implementation plans | Flagship model | This is where reasoning quality directly affects downstream token spend. A better plan means fewer false starts. |

#### Implementation Patterns

**Pattern 1: Explicit sub-agent routing.** When your orchestration tool supports model selection per worker, specify the model in the delegation instruction:

```
"Explore the src/auth/ directory and summarize the authentication flow.
 Use the fast model — this is a read-only exploration task."
```

**Pattern 2: Tiered skill definitions.** In your skill library (see below), annotate each skill with the minimum model tier required:

```markdown
## Skill: codebase-search
Model: haiku (fast/cheap)
Purpose: Find files, symbols, and patterns in the codebase.

## Skill: security-review
Model: opus (flagship)
Purpose: Analyze code for security vulnerabilities and threat vectors.
```

**Pattern 3: Escalation.** Start with a cheaper model. If it returns low-confidence results or flags ambiguity, escalate to a more capable model. This is the agent equivalent of "try the easy thing first."

#### What NOT to Route Cheap

Some tasks look routine but have hidden complexity:

- **Refactoring across module boundaries** — cheap models miss cross-file dependencies and break contracts.
- **Error handling design** — choosing what to catch, what to propagate, and what to log requires system-level reasoning.
- **Anything the user will directly read** — commit messages, PR descriptions, documentation. Quality of writing correlates with model capability; cheap models produce generic output.
- **Tasks involving the user's specific project conventions** — if the model needs to internalize CLAUDE.md rules and apply them to novel situations, it needs reasoning capacity.

#### Measuring Model Routing Effectiveness

Track two metrics across sessions:

1. **Cost per completed task** — total token cost (input + output, weighted by model price) divided by tasks completed. This should trend down as you route more work to cheaper models.
2. **Rework rate by model tier** — how often does output from the cheap model get rejected or require the flagship to redo it? If rework exceeds ~15%, you're routing too aggressively — the savings are illusory because you're paying twice.

### Skill Libraries

A **skill** is a reusable set of instructions for a recurring agent task. Different tools call these different things — custom prompts, system instructions, agent templates, slash commands — but the concept is universal: pre-written instructions that replace per-session re-derivation.

```
project-root/
├── .ai/                              # Or .claude/, .cursor/, etc.
│   └── skills/
│       ├── umami-audit/              # Reviewing mode (§0.7) — process audit
│       ├── umami-init/               # Reviewing mode (§0.7b) — first-time setup
│       ├── umami-auto-review/   # Reviewing mode (§3d) — code review pre-screen
│       ├── architectural-tradeoff/   # Thinking mode — compare design options
│       ├── migration-path-analysis/  # Thinking mode — map legacy before changes
│       ├── codebase-search/          # Implementation mode — find files/symbols
│       ├── security-review/          # Reviewing mode — vulnerability analysis
│       ├── pr-summary/               # Implementation mode — summarize a PR
│       └── data-migration/           # Implementation mode — pre-flight + rollback
```

Skills come in all three modes from "Modes of AI Use" above. Implementation-mode skills act (write code, make changes, summarize). Thinking-mode skills produce *reasoning visible in output* (alternatives, tradeoffs, recommendations with rationale). Reviewing-mode skills produce *structured findings* (audits, code review flags documents). Tag each skill with its mode so the harness invokes it with the right expectations.

**Standard skills — `umami-audit`, `umami-init`, `umami-auto-review`:** Every project using umami should have these three reviewing-mode skills (§0.7, §0.7b, §3d). They share the same architecture: fetch the canonical spec fresh, follow the protocol, output structured findings. Each skill includes the raw URL of the umami spec so the agent doesn't search for it. See `.claude/skills/` in the umami repo for the canonical templates.

**What makes a good skill:**

- Encodes domain knowledge that would otherwise be re-derived every session.
- Defines a clear output format so results are consistent and comparable across runs.
- Specifies which tools the agent needs (and which it doesn't — restricting tools reduces risk and token spend).
- Can inject dynamic context (current git diff, recent errors, open issues) so the agent starts with fresh state, not stale instructions.

**When to create a skill:** You've given the same instructions to an agent 3+ times, or a task requires domain-specific checklists (security review, accessibility audit, compliance check).

**Token impact:** A skill that pre-loads a 200-token instruction set replaces the 2,000–5,000 tokens the agent would spend figuring out the same approach through exploration. Skills stored in the project repo also ensure every team member's agents behave consistently — same review standards, same output format, same checklists.

### Parallel Work Patterns

The highest-value use of multi-agent orchestration is **parallel review and analysis**:

| Pattern | Workers | Output |
|---------|---------|--------|
| **Multi-angle code review** | Security + Performance + Test coverage | Three independent reports, synthesized by lead |
| **Exploratory research** | One per subsystem (auth, database, API) | Each worker maps its subsystem; lead assembles the full picture |
| **Test execution** | One per test layer (unit, integration, E2E) | Parallel test runs; lead aggregates pass/fail |
| **Competing hypotheses** | One per theory for a bug | Each investigates one theory; strongest result wins |

**Coordination rules:**

- Each worker should operate on **non-overlapping scope**. Two agents editing the same file is a merge conflict waiting to happen.
- Workers should report in a **structured format** so the lead can synthesize without re-reading raw output.
- Use a **shared task list** if your tooling supports it — workers claim tasks, preventing duplicate effort.

### External Tool Integration

Most AI development tools support connecting agents to external services — issue trackers, monitoring, databases, CI/CD. The agent equivalent of giving a developer tool access.

**High-value integrations:**

| Integration | Token savings |
|-------------|--------------|
| **Issue tracker** | Agent reads issue directly (~200 tokens) instead of you copy-pasting descriptions + comments (~2,000+ tokens) |
| **Error monitoring** | Agent queries recent errors to prioritize bugs instead of you describing symptoms |
| **Database schema** | Agent queries schema directly instead of you describing table structures |
| **CI/CD pipeline** | Agent reads build logs and test results instead of you pasting terminal output |

**Selecting MCP servers and tool integrations.** Not all integrations carry the same context cost (see §9.6 — tool metadata is 40–80% of context cost on tool-heavy setups). When choosing between equivalent options, prefer ones that:

- Use a **dynamic toolset architecture** (`search` → `describe` → `execute` or equivalent) so schemas load on demand. See §9.5b for the broader principle.
- Expose **purpose-scoped tools** rather than mirroring every API endpoint. One tool per workflow task beats one tool per HTTP endpoint.
- Return **summaries or IDs** by default with detail-on-request, rather than always returning full payloads.
- **Externalize cross-cutting concerns** (auth, rate limiting, error handling, governance) into the runtime/gateway layer rather than embedding them in every tool's response.

When you're *building* an MCP server (rather than consuming one), apply §9.6's tool-design principles: single workflow purpose, lazy schema loading, clear and constrained inputs, bundle related operations into higher-level tools rather than mirroring CRUD.

**Configuration scope matters:**

- **Personal** — your credentials, your preferences. Not committed to the repo.
- **Project** — shared team integrations. Committed to the repo (without secrets) so every team member's agents have the same access.

### Agent Approval Gates

For projects where agents take consequential actions (write files, run commands, reach the network, dispatch sub-agents, modify shared state), formalize *which actions need human approval, what gets logged, and which actions are explicitly autonomy-boundary*. Without this, the harness's defaults silently determine your security posture.

§14 above describes how agents work; this sub-section describes how to gate what they do.

**Applies to — two audiences, differently.** Agent *users*: the gates already exist — they are your harness's permission system; your gate table documents which harness setting, permission rule, or hook implements each row, so the *Implementation pointer* column points at configuration, not code you write. Agent-*product* builders: you implement the gates yourselves, and the pointer names the module. The severity model and the table shape are the same for both.

**Severity model:**

| Severity | Meaning |
|---|---|
| **HARD** | Blocks until approved. Agent cannot proceed without explicit user confirmation. |
| **SOFT** | Informs and proceeds unless the user countermands. Default-allow with visibility. |
| **NONE** | No live gate; the action is *structurally restricted* (sandbox path-jail, network namespace, type-system constraint). Free to execute within the structural boundary. |

Three severities are enough. NONE matters: it's the explicit acknowledgment that not every gate needs a live prompt — sometimes structural restriction is stronger than a prompt users will fatigue-approve.

**Gate table — template shape (one row per action class):**

| Column | What it captures |
|---|---|
| **Action** | The action class (e.g., "Read file outside project root", "git push to main") |
| **Gate severity** | HARD / SOFT / NONE |
| **User-visible surface** | Where the user sees the gate (grant prompt, Apply button, decision card, none) |
| **Audit trail location** | Where the disposition is recorded (tool-call log, grants registry, commit log, hooks log) |
| **Implementation pointer** | File path or module implementing the gate |

Group rows by category — filesystem ops, network ops, code-modifying ops, sub-agent dispatch, tool-output handling, hooks layer. Project-specific categories extend (e.g., "telemetry emissions" for products with metrics that include user data, "migration ops" for schema-bearing changes).

**Autonomy boundaries — always HARD regardless of session mode:**

Some actions are HARD-blocked regardless of whether the agent is interactive, scheduled, or autonomous. Policy commitments that don't soften under "trust the agent more in autonomous mode":

- Deploys to production
- `git push --force` to `main` / `master`
- Dependency changes (new package additions)
- Public-API breaking changes
- Access-scope expansion (broader sandbox grants than current)

Document these explicitly in the gate table with a note that the severity is HARD-mode-independent.

**Logging summary — companion table.** The Retention column names each layer's *default*, which per §4 agent-log discipline is a starting position to replace with an explicit policy, not a policy itself ("permanent" and "until deleted" are handwaves):

| Log | Location | Retention |
|---|---|---|
| Tool-call log (per-message) | Project-specific (chat sessions storage, etc.) | Harness default: until session deleted. Set an explicit horizon (e.g., 90 days) when compliance or incident-response needs one |
| Grant decisions | Grants registry | Harness default: until user clears. Add a review cadence — stale grants widen access silently |
| Commit log (agent-driven commits) | Standard `git log` | Permanent by design — the one layer where permanence is a chosen policy (git history), not a default |
| Hook execution log | User-controlled | Set explicitly per hook; "user-controlled" with no stated horizon is the handwave §4 warns about |

Without an explicit retention decision per layer, "we have an audit trail" means nothing under compliance review (§22).

**Watch signals:**

| Signal | What it catches |
|---|---|
| Gate-table drift (action exists in code but not in table) | New action class shipped without gate-table update; the gate may be implicit or missing |
| Audit-trail gap (action happens but no log location) | Consequential action runs without leaving evidence — the gate may be there but the audit isn't |
| HARD-soften creep (action moves HARD → SOFT silently) | Approval friction is being eroded; a gate is being weakened without explicit decision |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| "We have a gate" without a table | Gates are scattered across code; no single source of truth; new contributors don't know what's gated | Maintain the gate table as source of truth; cite implementation files from the table |
| All-HARD or all-SOFT | Every action is HARD (approval fatigue) or every action is SOFT (no real gate). Neither shape works at scale | The discipline of choosing per-action is the work; uniform severity is a refusal to think |
| Audit trails for "compliance" but no review | Every action is logged to a file nobody reads | If no one reviews the log, the log isn't an audit trail; it's a write-only buffer. Either make review part of process or remove the logging cost |
| Autonomy boundaries that aren't enforced | Doc says "no force-push to main" but the agent has the credentials to do it | Enforce in code where possible (pre-push hook, branch protection); doc-only autonomy boundaries are aspiration, not policy |

**Cross-references:**
- §22 compliance — audit trails feed compliance reviews; gate tables are evidence-pack components
- §3d code review — new tool surfaces should be flagged for "gate-table update" review
- §0.6 anti-pattern catalog (`core/umami-anti-patterns.md`) — "No agent-approval gate table"

### Lifecycle Hooks

Most agentic harnesses expose **lifecycle hooks** — user-controlled extension points where a project can insert custom behavior at well-defined moments in the agent's execution. Hooks are how you implement automated behaviors that aren't in the harness's defaults, without modifying harness code, without losing the change on the next harness update.

**The four canonical event categories most harnesses converge on** (harness-neutral names; each harness exposes these under different identifiers):

| Event category | Triggered when | Common uses |
|---|---|---|
| **before-tool** | A tool call is about to execute | Block tool calls based on user-defined predicates (deny lists, allow lists, content checks); add custom approval gates beyond the harness's defaults; redact arguments before the call |
| **after-tool** | A tool call has completed | Log / audit, redact sensitive results before they reach the model, trigger downstream behavior (notifications, metrics, dispatch chains) |
| **session-start** | Chat session begins (or resumes) | Re-walk instruction files (the project's primary AI instruction file — `CLAUDE.md` / `AGENTS.md` / `.cursorrules` / equivalent — plus skills/rules), refresh project memory, run pre-flight checks. For projects under active instruction-file development, see also §9.1 per-send re-walk |
| **turn-end** | The agent loop terminates for a turn | Cleanup, summary generation, archival, write-back of session state, activity-stream logging (see `recipes/activity-stream.md`) |

**How each harness names these categories** (sample, not exhaustive — consult your harness's hook documentation for the current names and input/output schemas):

| Harness | before-tool | after-tool | session-start | turn-end |
|---|---|---|---|---|
| **Claude Code** | `PreToolUse` | `PostToolUse` | `SessionStart` | `Stop` |
| **Cursor** | (rules / hooks; check current docs) | (check current docs) | rule-load on session begin | (check current docs) |
| **Aider** | command-execution shell hook (via `.aider.conf.yml`) | post-command shell hook | startup hook | post-turn hook |
| **Codex CLI** | (check OpenAI Codex CLI docs) | (varies) | (varies) | (varies) |
| **Goose** | extension `PreInvoke` (MCP-layer) | extension `PostInvoke` | extension load on session | extension `on_complete` |

The category names matter; the specific identifiers don't. When this document or a recipe refers to "the turn-end hook" or "the session-start hook," substitute your harness's name. The naming table above is a starting position — fill in the row for your harness with confidence once you've validated against its current documentation. The `core/umami-agents.md` §14 hook examples and `recipes/activity-stream.md` Stop-hook snippets use the Claude Code identifiers because that's the harness this corpus is field-tested on.

**The "from now on when X" insight.** Any automated behavior of the form *"from now on, every time Y happens, do Z"* requires a hook. Memory and process documentation cannot fulfill these — the agent is not the runtime, the harness is. If a user says "remember to log every git push" or "block tool calls that touch /etc," that's a hook configuration, not a memory entry. Process docs that say "we always do X" are aspiration unless wired through hooks.

**Configuration shape.** Hooks are user-controlled — configured via the harness's settings (e.g., `.claude/settings.json` for Claude Code, `.aider.conf.yml` for Aider, `.cursorrules` / `.cursor/rules/` for Cursor, harness-specific YAML elsewhere). The harness ships sensible defaults; project-specific or developer-specific hooks layer on top. Project hooks live in the repo (committed, shared); personal hooks live in user-scope settings (uncommitted).

**Watch signals:**

| Signal | What it catches |
|---|---|
| Hooks-as-aspiration (configured but never fire) | The hook is mis-targeted — its predicate doesn't match what actually runs, or it's registered for an event the agent doesn't reach |
| Hook drift (rule references deprecated tool, path, or behavior) | Codebase moved on; hook didn't. First incident discovers the gap |
| Hook overhead (slow hook delays every tool call) | Hook is doing too much — fast-path the common case, or move work to the *after-tool* event where latency is cheaper |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Process doc says "always do X"; no hook implements it | Documentation describes a behavior the agent doesn't perform; humans assume the agent is doing it | Wire X through a hook. If it can't be wired (the behavior depends on human judgment), update the doc to match reality |
| Hook silently swallows errors | A failing hook doesn't fire its intended action; nobody notices because the failure logs at debug level | Hook errors should be loud (write to a known location, surface in agent's session log). Silent failure is worse than no hook |
| Per-developer hooks committed to the repo | Personal preferences end up in the project's shared settings, affecting everyone | Personal hooks in user-scope settings (uncommitted); project hooks in repo-scope settings (committed). The split matters for team coordination |
| Hook proliferation (15+ hooks doing similar things) | Hard to reason about what fires when; rules conflict; debugging "why did this happen?" is expensive | Periodic hook review: consolidate similar predicates, remove dead hooks, document each remaining hook's purpose |

**Cross-references:**
- §14 Agent Approval Gates (above) — hooks are the user-controlled extension point for adding gates beyond what the harness ships. *before-tool* hooks implement custom HARD/SOFT gates
- §0.7 / §0.7b audit and init protocols — skill/rule files load at session-start time; hooks fire on session start to refresh them
- §9.1 front-load context — *session-start* hooks can re-walk instruction files per session start
- `recipes/activity-stream.md` — a worked example of the *turn-end* hook category, with a Claude Code reference implementation and adaptation pointers for other harnesses

### Agent Orchestration Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| **Over-delegation** | Spawning workers for single-grep tasks | Only delegate when overhead (spawn + summarize) < doing it inline |
| **Duplicate exploration** | Lead and worker both searching the same files | Delegate exploration OR do it yourself — never both |
| **Context duplication** | Passing the full conversation to every worker | Workers get focused instructions, not the whole history |
| **Unsupervised destruction** | Worker deletes files or pushes code without review | Restrict worker toolsets; require human approval for destructive actions |
| **Skill rot** | Skills reference outdated file paths or deprecated APIs | Review skills when you update the change propagation map (§10) or codebase understanding doc (§9.3) |

### Team Coordination (Human + Agent)

When multiple developers work with AI agents on the same codebase, coordinate the humans — the agents will follow.

- **Shared conventions file, not per-developer memory.** Project instruction files (CLAUDE.md, CODEBASE.md) are the team's shared understanding. Individual agent memory files hold personal preferences. Don't let critical project knowledge live only in one developer's agent memory — if that developer leaves, the knowledge leaves with them.
- **Review agent-generated code like any other code.** Code review discipline doesn't change because an agent wrote it. The reviewer is responsible for understanding what they approve — "the agent wrote it" is not a justification for merging code no human understands (§3b — Don't Program by Coincidence).
- **Avoid parallel agent edits to the same files.** Two agents editing the same file in separate branches produces merge conflicts that are hard to resolve because neither developer fully understands the other agent's changes. Coordinate scope before starting, not after conflicting.
- **Converge on shared skills.** If two developers create different agent skills for the same task (e.g., two different security review prompts), consolidate them into the project skill library. Inconsistent agent behavior across the team produces inconsistent output.

---

## 14b. Prompt & Instruction-File Engineering

Instruction files (`CLAUDE.md` / `AGENTS.md` / `.cursorrules` / equivalent) and the prompts inside skills are the most load-bearing agent inputs in the project — and they're usually edited by feel, untracked, untested. §14b treats them as engineered artifacts: **a change to an instruction file is a change to agent behavior**, and behavior changes get versioned, reviewed, and verified.

**Adopt when** (§0.9 default-deny — cite a trigger): an instruction-file or prompt change measurably moved agent behavior and you couldn't tell which edit did it; **or** the instruction file is edited often by multiple people; **or** a prompt regression shipped. Solo dev on a stable instruction file: **defer**.

**Cost profile:** Agent-with-review · Hours per change · Recurring discipline.

**The practice:**
- **Treat instruction/prompt edits as behavior changes.** Diff them in §3d review like code. A one-line `CLAUDE.md` edit can shift every session's behavior; it deserves the same scrutiny as a code change with that blast radius.
- **Structure the prompt.** Delineate instructions from content (XML tags / fenced blocks), use consistent role framing, add few-shot examples for nuanced tasks, and keep *stable* instructions separate from *volatile* context (per §9 front-loading) so the cacheable part stays cacheable.
- **Verify against evals.** A prompt or instruction-file change shipped with no §3f eval delta is unverified. For a load-bearing prompt, compare behavior on the golden set before/after the change.
- **Separate shared from personal.** Committed project instructions (shared behavior) vs. uncommitted user-scope preferences — same split as §14 hook configuration.

**Watch signals:** instruction file grows monotonically and nobody measures the effect · prompt changes land without an eval delta · the same instruction is restated in 3+ places (drift risk).

**Kill criterion (ledger, §0.9):** demote to "review like code, no formal before/after" once the instruction surface stabilizes and behavior stops moving across edits.

**Cross-references:** §9 token efficiency / front-loading (stable-vs-volatile context) · §3f eval suite (what verifies a prompt change) · §3d review (instruction edits are behavior changes) · §0.6b AI-discipline spectrum · §14 lifecycle hooks (session-start re-walk of instruction files).

## 14c. Model-Version Pinning & Drift Detection

Providers ship model updates that silently change behavior, and floating aliases (`*-latest`, an unversioned `gpt-x`) move under you between runs. A prompt that worked yesterday can regress today with no diff in your repo. §14c makes the model an explicit, pinned, monitored dependency.

**Adopt when** (§0.9 default-deny — cite a trigger): correctness depends on a model's behavior in production **and** either a provider model update has already changed that behavior, or your config currently routes through a floating alias. If you don't ship agent behavior, or already pin and eval on bumps: **defer**.

**Cost profile:** Operator-required · Hours setup + per-bump eval cost · Recurring.

**The practice:**
- **Pin exact model IDs** (dated / version-locked), never floating aliases, in agent config — and record the pinned version where the §0.9 ledger or config can show it.
- **Gate every model bump on evals.** Before adopting a new version, run the §3f suite against the held-out golden set on the new model; compare scores; canary on a slice of traffic before full cutover.
- **Keep a rollback.** The prior pinned version stays available; revert on regression rather than firefighting forward.
- **Track deprecation.** Note provider EOL dates; schedule migrations through the eval gate, not under deadline pressure.
- **Watch divergence in multi-model setups.** Lead and worker models can drift apart (§14 orchestration / model routing); a bump to one is a behavior change to the system.

**Watch signals:** config uses `*-latest` / unversioned aliases · a model was bumped with no eval run · a behavior regression was traced to a silent model update *after* it shipped.

**Kill criterion (ledger, §0.9):** low standing cost once set up, so removal is rare; demote the per-bump eval gate if the product stops depending on specific model behavior.

**Cross-references:** §3f eval suite (the bump gate) · §3 *Multi-Provider Behavioral Testing* · §14 model routing · §9.7 cost caps (new model versions change cost) · §0.9 (the pin decision is a recorded adoption).

## 14d. Agent-Failure Debugging (trajectory forensics)

§3b debugs *code*. §14d debugs *the agent* — diagnosing why an autonomous run went wrong when the code is fine: a tool-call loop, context loss after compaction, the wrong tool chosen, a silent fallback to a weaker model, or confidently-wrong output that read as plausible. These failures are nondeterministic and don't reproduce from a stack trace.

**Adopt when** (§0.9 default-deny — cite a trigger): agents run autonomously enough that failures are nondeterministic and hard to reproduce, **and** you've had at least one agent failure you couldn't diagnose from code logs alone. Interactive-only / low-autonomy use: **defer**.

**Cost profile:** Operator-required · Hours per incident · Recurring (incident-driven).

**The practice:**
- **Capture the trajectory.** Per-turn trace — tool calls, arguments, results, decisions — must be logged (§4 agent log discipline). You cannot debug what you didn't record; this is the prerequisite, set up before the first incident.
- **Reproduce from the trace.** Replay the run, note seed/temperature, and isolate the divergent turn.
- **Match the failure shape to a first check:** tool-call loop → budget / stuck-loop guard; context loss → inspect what compaction dropped; silent model fallback → verify which model *actually* ran (ties to §14c); confidently-wrong output → the §3d intent-reconstruction problem, not a code bug.
- **Run the incident runbook:** grab logs → reconstruct the call sequence → diff skills / hooks / instruction-files since the last good run (§14b) → identify the changed input.
- **Feed findings back.** A reproducible agent failure becomes a §3f eval case so it can't silently return.

**Watch signals:** agent failures closed as "flaky, re-ran it" with no root cause · no per-turn trace exists when an incident hits · the same failure recurs across runs.

**Kill criterion (ledger, §0.9):** incident-driven, low standing cost; demote the formal runbook if autonomy drops and failures become trivially reproducible from ordinary logs.

**Cross-references:** §3b systematic debugging (code) · §4 agent log discipline (the trace source) · §3d review (confidently-wrong output = intent reconstruction) · §3f eval suite (failures become regression cases) · §14c drift (silent model fallback).

---

