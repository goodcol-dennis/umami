# ADR 0006 — Extract the audit and init protocols (§0.7, §0.7b) to `core/umami-protocols.md`

**Status:** Accepted 2026-10-11
**Authors:** Dennis Portello, Claude
**Related:** [§0.7 / §0.7b](../../core/umami-protocols.md), landing stubs in [`umami.md`](../../umami.md), [ADR-0001](0001-v3-file-split.md) (the file-split principle), the landing-budget entry in [`audits/gaps.md`](../../audits/gaps.md), [`tools/check-refs.sh`](../../tools/check-refs.sh) (third invariant)

## Context

The landing (`umami.md`) is the one file every session loads, so its size is a managed budget: 125,000 bytes ≈ 25K tokens, enforced as `check-refs.sh`'s third invariant since v3.1 after the file had silently regrown from ~13K to ~30K tokens. The standing rule from the gap registry is *extract along an orthogonal seam; never absorb growth or raise the budget*. The first application was the §0.6 anti-pattern catalog → `core/umami-anti-patterns.md` (2026-07-03), which left the landing at ~118KB.

On 2026-10-11 the skill family gained a new audit step (§0.7 step 8, framework freshness) and a scoped upgrade mode in §0.7b. That took the landing to 122,474 bytes — 2.5KB of headroom. Measured by section, §0.7 and §0.7b together are ~22KB (18% of the landing) and are where every skill-family change lands; the protocol surface will keep growing as skills are added (`umami-wave` was added the same day).

## Decision

Move §0.7 and §0.7b **verbatim** into a new core companion, `core/umami-protocols.md`, and leave a one-paragraph stub under each heading in the landing. Section numbers are unchanged. The stubs state where the full text lives, give the protocol in one line, and keep the bootstrap entrypoint literally true: *"fetch `umami.md` and follow §0.7b"* still works because the §0.7b stub tells the agent to fetch the protocols file. Both skills' hard rules now fetch `core/umami-protocols.md` after the landing. The §0 Navigation Map row, the companion-file list, both URL blocks, README tables and `CLAUDE.md` name the new file; the propagation-map row for protocol edits points at it.

The seam is the same one that justified the catalog extraction: the landing is loaded by *every* session, while the protocols are needed only when an audit or init *runs*. The alternatives in the landing's top-ten sections by size — §0.6 adoption tiers, §0.5 mapping, §0.9 ledger — are the audit's *inputs* and belong where every session can read them.

## Consequences

- **Easier:** ~20KB (~4K tokens) off every Tier-1 fetch; the protocols can grow with the skill family without threatening the budget; protocol edits touch one file plus the skill mirror, as the propagation map already assumed.
- **Harder:** an audit or init is now a two-fetch operation (landing, then protocols). A paste-URL user who ignores the stub and follows the one-line summary gets a degraded protocol — acceptable, since the stub says plainly where the full text is and the installed skills fetch it automatically.
- **New external contract:** `core/umami-protocols.md` is a path adopters may reference; it follows the core-file stability rules (restructure only at major versions).
- The landing's §0 row in the Navigation Map now names two files; the Nav Map's "Always" column still applies to the landing alone.

## Alternatives considered

- **Raise the budget.** Rejected: the budget exists to force extraction; raising it is absorbing growth with extra steps.
- **Thin the protocols in place** (move output formats and hard rules out of the landing into the skills only). Rejected: the hard rules are what keep *paste-URL* agents honest — users without installed skills would lose them.
- **Extract a different section** (§0.6b spectrum, §1 *Preserving Project Structure*, §0.8 example). Rejected: each is either Tier-1 practice every session should see, or too small to buy meaningful headroom (§0.8 is ~2KB).
- **Fold the protocols into `core/umami-agents.md`** (where §14 skill libraries live). Rejected: that file is already the largest companion, and the protocols are not agent-infrastructure practice; a dedicated file keeps the fetch targeted.
