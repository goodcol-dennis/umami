# Recipe: CLAUDE.md Starter (Distilled Tier 1)

**Status:** Drafted (distilled from umami Tier 1; not yet validated by external adopters)

This is the zero-ceremony entry point to umami: paste one block into your project's `CLAUDE.md` and the Tier-1 guardrail floor acts on the very next agent turn — no skills to install, no fetch protocol, no adoption ledger. It is **not** the full framework: no audits, no §0.9 adoption gate, none of the companion-file depth (§2 specs, §3d review, §4 threat modeling, §14 orchestration). It buys you the floor — structure conventions, test-first discipline, systematic debugging, scope control, dead-code hygiene, and the day-one security rules — in a single paste.

> **Harness scope:** `CLAUDE.md` is the convention name used throughout — Claude Code, Cursor, Windsurf, and other tools read it. If your toolchain uses a different instruction file (`AGENTS.md`, `.cursorrules`, `CONVENTIONS.md`), paste the same block there. Nothing in the block is harness-specific.

## The block

Copy everything between the fences into your project's `CLAUDE.md`, then fill the `{placeholders}`.

```markdown
<!-- umami Tier-1 starter — distilled from https://github.com/goodcol-dennis/umami (this block: MIT, per that repo's LICENSE-CODE). -->
<!-- Fill every {placeholder}. Delete rules that don't apply. Keep the whole block under ~150 lines. -->

## Project

- **Name:** {project-name}
- **Stack:** {language, framework, runtime version}
- **Test command:** {command that runs the full suite}
- **Lint / typecheck:** {lint command} / {typecheck command}
- **Read first:** {entry-point modules a new session should read before editing}

## Structure

- Source lives in {src/}; tests live in {tests/} and mirror the source tree one-to-one — a test file's path tells you which module it covers.
- Shared type and interface definitions live together in one place ({types/} or equivalent); types used by a single module stay next to their owner.
- Config files live at the repo root, not scattered through subdirectories.
- No deep nesting: a path needing more than {4} directory levels means restructure, not another level.
- Before creating a new file, check whether an existing module is the right home. Prefer editing to creating.

## Consistency

- Strict type checking where the language supports it — no implicit any, no unchecked nulls. Typecheck passes clean before commit.
- Lint clean before commit. Never disable a rule inline to silence a finding — fix it or report it.
- Pin dependencies with a lockfile ({package-lock.json / poetry.lock / Cargo.lock}) and commit the lockfile.
- Reuse existing patterns, helpers, and config values before inventing new ones. No hardcoded values where the project already has variables for them.

## Tests — red, green, refactor

- Write the failing test first. Watch it fail. Write the minimum code to pass. Refactor. A test that never failed proves nothing.
- Run the full suite before every commit — the entire suite, not just the new test.
- Skip test-first only for: throwaway exploration or POC code (label it as such), pure config changes, and documentation. If skipped code survives into the product, backfill tests before building on it.
- Never weaken, rewrite, or delete an existing test to make your change pass. If a test blocks you, stop and say so — the human decides whether the test or the code is wrong.

## Debugging

- Debug systematically: reproduce → isolate → root-cause → fix. In that order, every time.
- No shotgun fixes. Never stack speculative changes to see what sticks — one hypothesis, tested and confirmed or discarded, at a time.
- State the root cause in one sentence before committing the fix. If you can't, you haven't found it — keep isolating.
- Where feasible, ship the fix with a regression test that fails without it.

## Scope

- Every changed line traces to the current request. If you can't connect an edit to what was asked, revert it.
- Report incidental findings (unrelated bugs, dead code, style issues) — do not fix them in the same change. Name them in your summary; leave the code alone.
- Ask before expanding scope. No silent "while I'm here" work.

## Dead code

- Delete, don't comment out. Git history preserves anything you might need back.
- Grep for all references before deleting or renaming anything — imports, type casts, string lookups, dynamic access.
- If your change made code dead (you removed its last caller), delete it in the same commit. If it was already dead before your change, that's an incidental finding — report it, don't touch it.
- Remove unused imports and exports immediately, never "later."

## Security floor

- No secrets in code. Not in source, comments, committed config, or variable names that hint at values. Use environment variables or a secret store; keep .env* gitignored.
- Before installing any new dependency, verify the exact package name, publisher, and download count against the official registry. A name that resembles a popular package but does not match exactly is a likely typosquat — stop and flag it.
- Parameterize every query. Never build SQL, shell, or eval strings from external input; never eval external data at all.
- Validate untrusted input at system boundaries: HTTP requests, file uploads, webhooks, external API responses, anything deserialized. Inside the boundary, trust internal code — do not scatter defensive checks through every function.
- Run dependency vulnerability scanning ({npm audit / pip-audit / cargo audit}) and triage alerts — do not ignore them.
- Never log secrets, tokens, or PII.
- Do not build custom auth without a specific, stated reason. Use an established library or service.

## Commits

- Full test suite passes before every commit.
- Review git status before committing: no unintended files, no build artifacts ({dist/, build/, *.map}), no .env files.
- Stage files explicitly; never blanket-add the whole tree.
- Commit messages state what changed and why, in one or two lines.

## Status

<!-- Keep this block current — update it in the same commit as the change it describes. -->

- **Current version:** {v0.x or tag}
- **Just shipped:** {one line per recent change, newest first}
- **Active gaps:** {known debt and untested areas — keep this honest}
- **Next target:** {what the next session should pick up}

## Automation honesty

Automated "from now on when X" behaviors require a harness hook — an instruction here cannot fire on events; if you're asked for one, say so and point at the hook config ({your harness's hook configuration, e.g. .claude/settings.json}).
```

## Adapting

- Fill every `{placeholder}` before the first agent session. An unfilled placeholder reads as literal instruction text and produces literal behavior.
- Delete rules that don't apply — no database means no parameterized-query line; drop whole sections rather than leaving half-relevant ones.
- Keep the block under ~150 lines total, including your additions. Past that, agents skim and the floor stops holding.
- Add project-specific rules under the existing headers instead of spawning new instruction files — one file, one floor.

## When to graduate

The starter is a floor, not a ceiling. When any trigger below fires, the pain has outgrown the paste — move to the full framework.

| Trigger | Where the full framework picks up |
|---|---|
| Features span more than one session; context is lost between handoffs | §2 Specification-First Development, plus §12 change tracking |
| Regressions traced to agent edits slip through; code generation outpaces human review | §3d Code Review Discipline (risk-tiered review, cross-provider verification) |
| The system now has multiple layers (API + UI + jobs + data) | Full §0.7b initialization — tiered adoption with an auto-chained baseline audit |
| Team grows past one person | Full framework — shared conventions need §0 discovery and §7 documented decisions, not one person's pasted block |
| The Status block's "Active gaps" list only ever grows | §8 Acknowledged Gaps (rolling registry + retros) |

Every row graduates the same way — the §0.7b bootstrap one-liner. Tell your agent:

> Fetch https://raw.githubusercontent.com/goodcol-dennis/umami/refs/heads/main/umami.md, read §0.7b Initialization, and run it against this project.

Init treats a starter-block project as a first-time (or partial) setup — its detection greps for umami raw-fetch URLs, which this block deliberately doesn't carry. It proposes the full URL block and skills, and you reconcile at the four-option dialog: keep the starter rules that still apply, let the framework take over the rest.

## Cross-references

- Distills: §1 (structure), §3b (TDD, debugging, scope), §6 (consistency, dependency hygiene, supply-chain defenses), §13 (dead code), the landing's *Security Essentials* sidebar (Tier 1 floor), §9.1 (status block), §14 (the hook-honesty line), §15 (commit checklist).
- Field reports: file a **Validation report** issue (https://github.com/goodcol-dennis/umami/issues/new?template=validation-report.md) — adopter reports are what move this recipe from Drafted to Shipped.
