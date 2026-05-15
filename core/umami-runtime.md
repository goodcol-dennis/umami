# Umami — Runtime / Operations / Security Extension

This file is part of umami v3's concern-based file architecture. The landing document ([umami.md](umami.md)) contains the framework, Section Navigation Map, and Tier 1 practices. This file collects the *runtime / operations / security* concern cluster — runtime validation, threat modeling, trust posture, security disciplines, state recovery, developer experience and pipeline health.

**When to fetch this file:** When an audit, init, or implementation task hits a Tier 2+ practice in any of §4 / §5 / §6b. Specifically: threat modeling, trust posture, security depth beyond the day-one floor, agent runtime security, untrusted-content boundaries, agent log discipline, state recovery runbooks, or pipeline health audit. The landing document's *Security Essentials* sidebar holds the Tier 1 floor and points here for depth.

**Contents:**

- §4 Runtime Validation (full — categories, severity, observability, threat modeling, trust posture, security discipline, agent runtime security, untrusted-content boundaries, agent log discipline)
- §5 State Tracking & Recoverability
- §6b Developer Experience and Pipeline Health

**Cross-references** in this file use plain `§N` notation. File location is metadata; section numbers are stable identifiers across all umami files.

---

## 4. Runtime Validation

The system validates structural correctness on every edit, not just before execution.

### Reading the cost profiles

The practices in §2, §3, and §4 vary widely in implementation cost — some are afternoon tasks an LLM can run end-to-end; others are months-long architectural projects requiring specialist humans. The cost variance within each section is wide enough that a reader picking blindly from the list of options can land on something far more expensive than expected.

**Default to the cheapest version that fits the actual risk; deepen only when threats, incidents, or compliance pressure justify the cost.** The annotations exist to protect velocity, not to push toward maximum rigor. Over-investment in security or testing depth is the failure mode flagged in §0.6 "Security investment outpaces threat model" — every week on Full-depth infra is a week not spent on the features and fixes that earn user trust.

Each annotated practice carries a **Cost profile** line (or column entry) capturing three dimensions:

| Dimension | Values |
|---|---|
| **Who does the work** | Agent-autonomous · Agent-with-review · Operator-required · Specialist-required (legal, security, infra) |
| **Magnitude** | Hours (<1 day) · Days (1–5 days) · Weeks (1–4 weeks) · Months (>1 month) |
| **Shape** | One-time setup · Recurring discipline · Architectural (touches code structure) · Spend (infra/licensing) |

Several practices also support *progressive depth* — adopt the starter version when the §0.6 trigger fires, deepen as risk warrants. Where this applies, the practice carries a **Depth tiers within the practice** mini-table. Distinct from §0.6 project tiers (Foundation / Structure / Scale): depth tiers describe how deeply you implement *one* practice; project tiers describe which practices to *adopt at all*.

This subsection lives in §4 because that's where the cost variance is widest, but §2 and §3 use the same scheme. When you encounter a **Cost profile** annotation earlier in the document, the dimensions above are the reference.

### Categories of Checks

- **Missing or excess connections** between components.
- **Unconfigured components** with required fields left empty.
- **Cycle detection** in directed graphs or pipelines.
- **Orphaned components** with no connections.
- **Type mismatches** at connection boundaries.
- **Schema compatibility** — warn on mismatch, block on incompatibility.

### Severity Model

| Level | Behavior |
|-------|----------|
| **Error** | Blocks execution. Must be resolved. |
| **Warning** | Informs the user. Does not block. |
| **Info** | Logged for observability. No user action required. |

Enforcement belongs in the engine, not the UI. The UI reflects validation state; it doesn't own it.

### Production Observability

Testing (§3) and validation (above) catch problems before and during deployment. Observability catches everything that slips through — the slow queries, the cascading failures, the silent data corruption. It's the production-time counterpart to development-time validation.

**Cost profile:** Agent-with-review · Days setup + ongoing tuning · Architectural + Spend (observability backend)

**Three signals, correlated:**
- **Metrics** tell you *something is wrong* (error rate spiked).
- **Logs** tell you *what went wrong* (specific error with context).
- **Traces** tell you *where it went wrong* (which service in the chain failed).

These only work together if they share correlation identifiers — a trace ID in every log line, service name on every metric. Without correlation, you have three separate piles of data instead of one coherent picture.

**Structured logging rules:**
- Use structured format (JSON) in production. Human-readable format is fine for local development.
- Include trace IDs in every log line — this is the bridge between logs and traces.
- Use consistent log levels across services: DEBUG (never in production by default), INFO (normal operations), WARN (handled unexpected conditions), ERROR (failures needing attention).
- **Never log sensitive data.** Passwords, tokens, PII, credit card numbers. Sanitize before logging. This is not optional.
- Log at boundaries, not everywhere. Log when data enters or leaves your service, when operations complete or fail. Don't log inside tight loops.

**Instrumentation discipline:**
- Instrument inbound requests, outbound calls, and business-critical operations. Capture method, status, and duration.
- Instrumentation is part of the "definition of done" — not a follow-up task. When removing a feature, remove its instrumentation too (§13).
- Don't instrument every function call. Instrumentation has overhead. Excessive instrumentation creates noise and inflates costs.

Each domain extension includes specific observability guidance for its context — what to monitor, what to alert on, and what tools to consider.

### Threat Modeling

Security discipline (below) tells you what to defend against once you know the threats. **Threat modeling tells you what the threats are** — for your specific system, with its specific data flows, boundaries, and trust relationships. Without it, security work is reactive (defending against threats you happened to think of) rather than deliberate (defending against threats you systematically identified).

§4's other security sub-sections assume you've identified the threats relevant to your project; this sub-section is the practice of identifying them.

**Cost profile:** Operator-required (workshop format) · Hours–Days per pass · Recurring (per architecture change)

**Depth tiers within the practice:**

| Depth | What it looks like | Cost profile |
|---|---|---|
| Starter | Free-form list — "what could go wrong here?" at the obvious boundaries; mitigations tracked informally | Operator-required · Hours · One-time + revisit |
| Working | STRIDE applied to a hand-drawn DFD of the critical paths; mitigations decided per High/Medium threat | Operator-required · Days per pass · Recurring (per architecture change) |
| Full | Maintained DFDs per system, per-release re-modeling, evidence-pack alignment with §22 | Operator-required (security lead) · Days/release ongoing · Recurring |

**When to do threat modeling:**

- At project bootstrap, before locking architectural choices (auth model, trust boundaries, data classification)
- When adding any new boundary — a new external integration, a new user-input surface, a new agent tool that touches privileged operations
- After an incident, as part of postmortem follow-up
- Per release for projects in regulated industries (§22 treats threat modeling as required evidence)

**The basic protocol:**

1. **Identify the system's boundaries.** Draw a data flow diagram (DFD) at the appropriate level. Mark trust boundaries — every place where data crosses from one trust zone to another (untrusted internet → your service, your service → your database, your service → an LLM API, etc.).
2. **Enumerate threats at each boundary** using a framework like **STRIDE** (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege) — or per-domain frameworks (OWASP for web, MITRE ATT&CK for adversarial, LINDDUN for privacy).
3. **Rate each threat** by likelihood and impact. Use a simple scale (Low / Medium / High); don't over-engineer the rating. The goal is prioritization, not precision.
4. **Decide mitigations** per threat — for each High and Medium item: Mitigate (apply a §4 security discipline) / Accept (document residual risk in §8) / Transfer (insurance, third-party) / Avoid (change the design).
5. **Document the model** as a living artifact — diagram + threat table + mitigation decisions. Re-visit when boundaries change. The artifact informs §3 fitness functions (testing the mitigations), §3d code review (flagging changes that affect boundaries), and §22 evidence packs.

**Threat-modeling frameworks worth considering:**

| Framework | Shape | When to consider |
|---|---|---|
| **STRIDE** (Microsoft) | Per-element threat categorization | General-purpose; default starting point |
| **OWASP Top 10** | Web-specific common threats | Web applications |
| **MITRE ATT&CK** | Adversary-tactics catalog | Mature security programs; adversarial modeling |
| **LINDDUN** | Privacy-specific threats | Projects handling personal data (often paired with §22 compliance) |
| **PASTA** | Process for Attack Simulation and Threat Analysis | Risk-centric, business-aligned modeling |
| **Free-form / informal** | A diagram + a list of threats, no formal framework | Small teams, early-stage projects — trades rigor for speed |

**Watch signals:**

| Signal | What it catches |
|---|---|
| Threat model exists but boundaries don't match current architecture | Boundary diagram has drifted from the running system |
| New boundaries added without threat-model update | Project grew; threat model didn't. Real coverage gap |
| All threats rated Low | Team isn't surfacing real risks; either system is genuinely low-risk or rating discipline is broken |
| Threat model never revisited after an incident | Postmortem follow-through is missing; incidents teach the model |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Threat modeling as one-time exercise | Document from project bootstrap; never updated; bears no resemblance to current system | Threat models are living artifacts. Re-visit when boundaries change; default to per-release review for compliance-bound projects |
| Threat modeling as theater | Comprehensive document; no mitigations shipped | Each threat → mitigation decision is the deliverable. A model without decisions is documentation, not security |
| STRIDE applied without DFD | Threats enumerated abstractly; no map of where they apply | STRIDE is per-element; needs the data flow diagram to be meaningful |
| Mitigation backlog without prioritization | All threats matter; nothing gets done | Prioritize by likelihood × impact; ship mitigations for High items first |
| Threat modeling exclusively pre-implementation | Initial model is rigorous; post-launch evolution isn't modeled | Recurring practice. Re-do when architecture changes; new integration = new modeling |

**Cross-references:**
- §4 below — security discipline applies the mitigations threat modeling identifies
- §4 untrusted-content boundaries — addresses the threats LLM-feature products face at content boundaries
- §3 architectural fitness functions — threat-model mitigations can be encoded as fitness functions ("no untrusted content reaches the model without wrap")
- §8 acknowledged gaps — threats decided to accept get tracked here
- §22 compliance — threat models are evidence-pack components for regulated industries

### Trust Posture

Threat Modeling identifies the threats; this sub-section is the prior question: *how aggressively do you defend, regardless of which specific threats you enumerated?* Two postures dominate, with a spectrum between them.

| Posture | Premise | What it costs | What it gets you |
|---|---|---|---|
| **Perimeter-trust** | A security boundary (network, environment, service edge) is meaningful; inside it, services trust each other; defenses concentrate at the boundary | Cheap and simple | Works until the perimeter breaks (insider threat, lateral movement, supply chain compromise) |
| **Zero-trust** | No implicit trust based on location. Every request, every service, every identity is verified continuously. Codified in NIST 800-207, CISA Zero Trust Maturity Model | Architectural + spend (identity infra, secrets rotation, monitoring) | Contained blast radius when (not if) a zone is compromised |

**Cost profile:** Operator-required (posture decision) + Specialist-required (zero-trust implementation) · Months · Architectural + Spend (identity, monitoring, rotation)

**The "trust internal code" line is zone-local.** §4 Security Discipline says "validate at boundaries, trust internal code" — that rule applies *within a defined trust zone*, not as license to skip auth between services. Zero-trust means defining more, smaller zones (per-service, per-tenant); perimeter-trust means defining one big zone. Either way: validate at the zone boundary, don't scatter defensive code within. The distinction between postures is *how many zones you draw*, not whether internal code re-validates.

**Depth tiers within the practice:**

| Depth | What it looks like | Cost profile |
|---|---|---|
| Starter | Single internal trust zone; identity isolation for the agent (§4 Agent Runtime Security); validate at external boundaries only | Agent-with-review · Days · One-time |
| Working | Multiple zones (public-facing, internal, secrets); service-to-service auth (mTLS, JWT, signed requests); secrets-tier separation; least privilege enforced via IAM (§16) | Operator-required · Weeks · Architectural |
| Full | Per-service identities with short-lived credentials and rotation; continuous verification; micro-segmentation; assume-breach blast-radius design; mapped to NIST 800-207 components or CISA ZTMM pillars | Specialist-required (security/infra) · Months · Architectural + Spend |

**Velocity check.** Starter is the default; Working is the structural deepening; Full is for projects whose actual threat model or compliance pressure demands it. Skipping Starter and aiming at Full because zero-trust sounds rigorous is the over-investment pattern flagged in §0.6 "Security investment outpaces threat model" — it slows the project without buying threat coverage proportional to the cost. Every week spent on Full-depth posture infrastructure is a week not spent on the features that earn user trust.

**Frameworks worth considering:**

| Framework | Shape | When to consider |
|---|---|---|
| **NIST SP 800-207** | Reference architecture: PE (policy engine), PA (policy administrator), PEP (policy enforcement point) components | Compliance-bound projects; federal-adjacent work |
| **CISA Zero Trust Maturity Model** | Five-pillar maturity model (Identity, Devices, Networks, Applications, Data) | Self-assessment of current vs. target posture |
| **Google BeyondCorp** | Identity- and device-based access; no VPN | Modern SaaS adoption pattern |
| **Forrester ZTX** | Extended zero-trust with workloads, data, automation | Enterprise-scale programs |

**Watch signals:**

| Signal | What it catches |
|---|---|
| Posture stated but services on a flat internal network | Aspirational posture; implementation hasn't caught up |
| "Internal" service accepts unauthenticated requests | Implicit trust based on network location — perimeter-trust dressed as zero-trust |
| Long-lived static credentials for service-to-service auth | Continuous verification missing; rotation cadence absent |
| Audit logs distinguish "internal" from "external" calls | The framing implies a dichotomy that doesn't exist under zero-trust |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Zero-trust as marketing | Doc says zero-trust; implementation is perimeter with extra steps | Map current state honestly to NIST 800-207 components or CISA pillars. Honest gap assessment beats aspirational language |
| Defensive code scattered "for zero-trust" | Every internal function re-validates everything; velocity tanks | Zero-trust means more zones, not more defensive code inside one zone. Validate at zone boundaries; trust within |
| Posture mandated without budget | Team told to adopt zero-trust; no spend on identity provider, secret manager, observability | Surface as §8 acknowledged gap. Zero-trust without infra investment is policy theater |
| Postures inconsistent across services | Half zero-trust, half perimeter, no documented handoff between them | Commit to one posture per boundary, or explicitly document the handoff (which zone is which, where verification re-anchors) |
| Aiming for Full out of the gate | Team commits to NIST 800-207 mapping or micro-segmentation before validating that perimeter-trust would fail the actual threat model; weeks of infra work land before the features that earn user trust ship | Default to Starter. Deepen when an incident, compliance trigger, or threat-model finding justifies it — not when zero-trust sounds rigorous. See §0.6 "Security investment outpaces threat model" |

**Cross-references:**
- §0.3 — trust posture is a foundational decision captured up front
- §4 Threat Modeling above — informs which zone boundaries deserve verification
- §4 Security Discipline below — the controls applied at zone boundaries
- §4 Agent Runtime Security below — already zero-trust-posture for agents; this section generalizes the principle
- §16 IaC — service-to-service auth, secret rotation, network segmentation
- §22 Compliance — many frameworks expect zero-trust-aligned evidence (identity-based access controls, segmentation)

### Security Discipline

Security is a cross-cutting concern, like observability. Every project that accepts input, communicates over a network, or manages user data has a threat surface — whether the team thinks about it or not. The goal isn't to become a security expert; it's to build the habit of considering security as part of the development process rather than as an afterthought or a separate phase.

**This section establishes security discipline, not a security framework.** Like spec-first development (§2), the high-value practice is *having* a security thought process. Which tools or frameworks you use matters less than whether you think about security at all.

**Cost profile:** Varies by depth — see *Depth tiers* below.

**Depth tiers within the practice:**

| Depth | What it looks like | Cost profile |
|---|---|---|
| Starter | `.gitignore` covering secrets and build output, dependency scanning in CI (Dependabot or equivalent), security constraints in the project instruction file ("never use eval", "always parameterize queries", "never log PII") | Agent-autonomous · Hours · One-time + recurring scan |
| Working | Boundary validation at all entry points, off-the-shelf authn/authz, leaked-secret pre-commit scanning, regular dependency triage, build output hygiene checks in CI | Agent-with-review · Days · Architectural |
| Full | Typed untrusted-content wrapper with provenance and spotlighting (see *Untrusted Content Boundaries* below); short-lived credentials with rotation; per-release security review | Operator-required · Weeks–Months · Architectural |

**Validate at system boundaries, trust internal code.**
- Untrusted data enters at the edges — HTTP requests, file uploads, webhook payloads, user input, external API responses, CSV imports. Validate and sanitize at these entry points.
- Once data has passed boundary validation, internal code can trust it. Don't scatter defensive validation through every function — it adds noise without adding safety.
- Treat deserialized data as untrusted. JSON from an API, data from a queue, objects from a cache — anything that crossed a serialization boundary could have been tampered with or malformed.

**Secrets management:**
- **No secrets in code. Ever.** Not in source files, not in config files committed to git, not in comments, not in variable names that hint at the value. Use environment variables, secret stores, or encrypted config files that are excluded from version control.
- **Scan for leaked secrets.** Use pre-commit hooks or CI checks that detect patterns like API keys, tokens, and passwords in committed code. Tools exist for every ecosystem — the specific tool matters less than having the check in place.
- **Rotate, don't just revoke.** When a secret is exposed, rotating it (issuing a new one) is safer than just revoking the old one, because you can't be sure the old one wasn't already captured.

**Authentication and authorization:**
- If the system has users, authentication (who are you?) and authorization (what can you do?) are not optional features — they're structural requirements. Decide on the approach early and document it in an ADR (§7).
- Apply the principle of least privilege. Users, services, and agents should have the minimum access needed for their function.
- Don't build custom auth unless you have a specific reason. Established libraries and services exist for every platform. Custom auth implementations are a leading source of security vulnerabilities.

**Dependency security:**
- Every dependency is code you don't control. Each one expands your threat surface. Audit new dependencies before adding them — check maintenance status, known vulnerabilities, and how many transitive dependencies they introduce.
- Run automated vulnerability scanning in CI. `npm audit`, `pip-audit`, `cargo audit`, Dependabot, Snyk — the tool matters less than the habit.
- Don't ignore vulnerability alerts. Triage them: patch immediately (critical/high), schedule a fix (medium), or document the acceptance and rationale in acknowledged gaps (§8) if the risk is genuinely low.

**For AI-assisted development:**
- Agents generate code without a security threat model in mind. They'll use `eval()`, concatenate SQL strings, log sensitive data, and disable CORS — not maliciously, but because they optimize for "make it work" unless instructed otherwise.
- Include security constraints in your project instruction file (CLAUDE.md or equivalent): "Never use eval. Always use parameterized queries. Never log PII." These are low-cost instructions that prevent the most common agent-generated vulnerabilities.
- Review agent-generated code for security the same way you review it for correctness. A passing test suite doesn't mean the code is secure.

**Build output hygiene:**

Build processes can silently leak source code, internal architecture, and secrets into production or version control. Source maps are the highest-profile example — they expose the entire original source tree to anyone with browser devtools — but the problem is broader.

| Leak vector | What it exposes | Prevention |
|---|---|---|
| **Source maps in production** | Full original source code, file paths, internal comments | Disable source maps in production builds, or upload them only to your error-tracking service (Sentry, Datadog) and block public access |
| **Debug builds deployed** | Verbose error messages, stack traces, component names, internal state | Enforce `NODE_ENV=production` (or equivalent) in build pipelines; fail the build if debug flags are detected in production config |
| **Secrets baked into client bundles** | API keys, tokens, internal URLs | Never reference secrets in client-side code; use server-side proxies or backend-for-frontend patterns; scan build output for known secret patterns |
| **Internal comments in production** | Architecture hints, TODO notes, developer names, internal URLs | Strip comments during minification (default for most bundlers — verify it's not disabled) |
| **Build output committed to git** | Compiled code, bundles, generated files in repo history | `.gitignore` covers `dist/`, `build/`, `out/`, `*.map`; pre-commit hook rejects commits that add files matching build output patterns |
| **Environment files in build context** | Database credentials, API keys, service URLs | `.dockerignore` and `.gitignore` cover `.env*`; build pipelines inject secrets at runtime, not via committed files |

**Rules:**
- **`.gitignore` is your first line of defense.** At minimum: `dist/`, `build/`, `out/`, `*.map`, `.env*`, `node_modules/`, `__pycache__/`. Audit it when adding new build tools — each tool may produce output in a different directory.
- **Scan build output before deploy.** A CI step that greps the build directory for source maps, `.env` patterns, known secret formats, or unexpectedly large files catches leaks before they reach production.
- **Treat build output like a public artifact.** Anything in the deploy directory should be safe for anyone to read. If it wouldn't be safe on a public CDN, it shouldn't be in the build output.
- **Pre-commit hooks for build artifacts.** Block commits that add files matching `*.map`, `dist/**`, `build/**`, or other build output patterns. Accidental commits are the most common path for build artifacts entering git history — and once in history, they persist even after deletion.

Each domain extension includes specific security guidance for its context — WordPress escaping and nonces (§20.1), Drupal access control and Form API (§21.1), source map discipline for web frontends (§17.9), etc. For projects handling regulated data (PHI, PII, payment cards), the compliance extension covers data classification, handling procedures, and audit readiness (§22.2–22.3).

### Agent Runtime Security

The "For AI-assisted development" guidance above covers code the agent *generates*. This subsection covers risks from the agent *itself* — the runtime environment where the agent operates, the tools it can invoke, and the trust boundaries around its actions.

**Why this matters:** An AI agent with shell access, network access, and filesystem access is a privileged process. If it reads hostile input (a poisoned repo, a malicious PDF, a manipulated MCP tool response), the compromise isn't theoretical — it's shell execution, secret exfiltration, or silent data modification. Treat agent security as infrastructure, not as an afterthought.

**Cost profile:** Varies by depth — see *Depth tiers* below.

**Depth tiers within the practice:**

| Depth | What it looks like | Cost profile |
|---|---|---|
| Starter | Harness permission rules denying credential paths (`~/.ssh/`, `~/.aws/`, `**/.env*`); never give the agent personal credentials; default-on approval gates for consequential actions | Agent-autonomous · Hours · One-time |
| Working | Dedicated bot/service accounts with scoped tokens; sandboxed environment (container/VM) for untrusted work; per-tool restriction lists matched to task type | Operator-required (org admin coordination) · Days · One-time + Spend (sandbox infra) |
| Full | Kill switches with heartbeat-driven termination; memory hygiene with rotation after untrusted-content sessions; supply-chain review for skills/MCP/hooks before installation; short-lived credentials with rotation | Specialist-required (infra/security) · Weeks · Architectural + Recurring |

**Identity isolation:**
- Do not give agents your personal credentials. Use dedicated bot accounts, scoped tokens, and purpose-specific API keys. If the agent is compromised, the blast radius should be the agent's identity — not yours.
- Short-lived credentials are better than long-lived ones. Prefer tokens that expire (OAuth with short TTLs, temporary STS credentials) over static API keys.
- If the agent connects to external services (Slack, GitHub, email, databases), each connection should use a service account with minimum necessary permissions — not a developer's personal account.

**Sandbox untrusted work:**
- When reviewing untrusted repositories, processing external documents, or working with foreign content, run the agent in an isolated environment — a container, devcontainer, VM, or remote sandbox with no egress by default.
- The principle: if the agent gets compromised, the blast radius must be small. No access to the host filesystem, no access to credentials outside the workspace, no network access unless explicitly allowed.

**Tool and path restrictions:**
- If your agent harness supports permission policies, start with deny rules for sensitive paths: `~/.ssh/`, `~/.aws/`, `**/.env*`, credential stores. Deny outbound network commands (`curl | bash`, `ssh`, `scp`, `nc`) unless the workflow explicitly requires them.
- Restrict the agent's toolset to what the task requires. An agent performing code review doesn't need write access. An agent running tests doesn't need network egress.

**Approval boundaries:**
- The model should not be the final authority on shell execution, network egress, writes outside the workspace, secret access, or deployment. These actions need a human approval boundary — either interactive confirmation or a policy layer between the model and the action.
- This applies especially to autonomous and unattended workflows (see §23.10 for scripting-specific guidance). The more autonomous the agent, the stricter the approval boundaries should be.

**Kill switches:**
- For long-running or autonomous agent sessions, implement a heartbeat mechanism. If the agent stops checking in, terminate the process group — not just the parent process, but all child processes.
- Know the difference between graceful shutdown (the agent finishes its current step) and hard kill (immediate termination). Have both available. Don't rely on a potentially compromised process to stop itself.

**Memory and persistence hygiene:**
- Persistent agent memory is useful but also a vector. A payload that gets written into memory during one session can influence behavior in all future sessions.
- Keep memory narrow — don't store secrets, don't store raw content from untrusted sources. Rotate or reset memory after sessions that involve untrusted content.
- For compliance-bound projects, see §22.11 for additional agent-as-attack-surface guidance.

**Supply chain awareness for agent tooling:**
- Skills, hooks, MCP server configurations, and agent descriptors are supply chain artifacts. A malicious skill can contain prompt injection. A compromised MCP server can exfiltrate data while appearing to provide context.
- Review agent tooling with the same rigor you apply to code dependencies (§6). Don't install skills, hooks, or MCP configurations from untrusted sources without inspection.
- Agents installing software dependencies are vulnerable to typosquatting and dependency confusion — they'll install whatever a tutorial or error message suggests without verifying the package name. See §6 Supply Chain Attack Defenses for the full set of controls.

### Untrusted Content Boundaries and Prompt-Injection Hardening

For products with LLM features that ingest external content (web fetches, user messages, tool outputs, file contents, sub-agent outputs), prompt injection is a real attack surface. The model can't tell instructions from content unless you signal the boundary. Treat anything that crossed a trust boundary as untrusted — wrap it explicitly, tag its origin, and mark the boundary visibly to the model.

**Cost profile:** Operator-required (potentially specialist for multi-provider) · Weeks–Months · Architectural

This is the highest-cost practice in §4. It is the "Full" depth of *Security Discipline* above — typed wrappers, provenance tagging, and per-provider spotlighting require touching every site where untrusted content reaches the model. Retrofitting after a feature ships is markedly more expensive than wrapping before shipping. Only justified for LLM-feature products at meaningful scale.

**Velocity check.** Pre-emptive adoption — wrapping content for a product that doesn't yet ingest external content, or whose volume is low and whose threat surface is internal — is the over-investment pattern flagged in §0.6 "Security investment outpaces threat model". The Starter / Working depth of *Security Discipline* above is the right floor until the threat surface materializes. The wrapper discipline is months of architectural work; spending those months before the product needs it is months not spent shipping.

The discipline has four parts:

**1. Untrusted-content wrapper.** A typed wrapper (e.g., `UntrustedContent<T>`) around anything from outside the trust boundary. The wrapper makes it *impossible* for untrusted content to reach the model without going through the wrap path — the type system enforces what discipline alone won't. If untrusted content can be plain `String` in your codebase, the type system can't help you.

**2. Provenance tagging.** Every wrapped piece carries a structured tag identifying where it came from — `WebFetch`, `UserMessage`, `ToolOutput`, `SubAgentResult`, `FileRead`, `MCPResponse`, etc. Provenance is an enum or tagged union, not free-text. The tag travels with the content; downstream consumers can apply per-source policy without re-deriving origin.

**3. Per-provider spotlighting.** Different LLM providers respond best to different markers for untrusted content — XML-style tags, fenced blocks, explicit prefix conventions, role-tagged messages. Pick a strategy per provider and apply it consistently. The model needs a *visible* signal that a section is untrusted content rather than instructions; "the system prompt mentions it" isn't enough.

**4. Wrap sites at every boundary.** There should be exactly one entrypoint that produces wrapped content per source (one for tool outputs, one for user input, one for sub-agent results, etc.). New tool surfaces require *audit-on-add* — if a new tool returns externally-sourced content, it must wrap before the result enters the model's context. Project §3d code-review classifications should add an "audit-on-add for untrusted-content surfaces" project-specific dimension.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Plain-string content from outside the trust boundary reaching the model | Wrap-site missing |
| Spotlighting markers appearing verbatim in model output | Model treating untrusted content as instructions; spotlighting strategy needs strengthening |
| Successful prompt injection in a planted-injection regression test | The specific wrap site or spotlighting strategy that the injection bypassed |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| "Just sanitize the strings" | Codebase has scattered sanitize-on-read calls; new code path forgets one | Sanitization is whack-a-mole. Replace with `UntrustedContent<T>` typed boundary; sanitization (if any) lives at unwrap, not at every read site |
| "We'll wrap later" | Untrusted content flows as plain strings while shipping the feature; wrapping retroactively touches every callsite | Wrap before shipping. Once untrusted content is loose in the codebase, retrofitting is expensive and incomplete |
| "Every developer remembers to wrap" | New tool surface ships, doesn't wrap, model gets prompt-injected | The type system should make plain-string-from-untrusted-source uncompileable. Discipline alone is insufficient at agentic velocity |
| "Spotlighting will catch it all" | Strategy works for known injection patterns; novel injection bypasses | Defense-in-depth — spotlighting is the third layer, not the first. Wrapper + provenance + spotlighting + audit-on-add together |

**Cross-references:**
- §4 "Validate at system boundaries" (above) — this is the LLM-content equivalent for products processing external content via agents
- §3d code review — new tool surfaces should be flagged for "audit-on-add" classification under a project-specific dimension
- §0.6 anti-pattern table — "Treats untrusted content as plain strings"

### Agent Log Discipline

For projects where agents take consequential actions, the agent's activity log is the only durable record of what happened. The discipline isn't *log everything* — it's logging the right things at the right granularity, with retention and review baked in. A log that nobody reads is a write-only buffer, not an audit trail.

§4 above covers observability from the production-systems perspective; this sub-section covers the agent-specific log shape that enables incident response, compliance, and operational debugging when the agent does something surprising.

**Cost profile:** Agent-with-review · Days setup + recurring review cadence · Recurring discipline

**The five log layers:**

| Layer | What gets logged | Why |
|---|---|---|
| **Tool calls** | Every tool invocation: tool name, args (redacted), result summary, duration, model, cost | Reconstruct what the agent tried; correlate with outcomes |
| **Decisions** | Every gate decision (per §14 HARD-gate response): action, severity, user choice, timestamp, scope | Audit trail for compliance; pattern analysis ("how often is the user approving X?") |
| **Compaction events** | When context compacted; what was preserved vs. dropped (per §9.6 strategic compaction) | Debug "the agent forgot something" reports |
| **Errors** | Tool failures, model errors, retry chains, fallback paths | Find brittle patterns; track provider reliability |
| **Sub-agent dispatches** | Dispatch ID, scope, behavior outcome, cost, parent linkage | Trace cross-agent work; debug recursive loops |

The 5-layer model above assumes a fairly sophisticated harness (one with context compaction and sub-agent dispatch). **Merge layers when your shape doesn't have all of them** — e.g., a single-agent product with no compaction has 3 layers (tool calls / decisions / errors); a chatbot with no agent tool surface has 2 (decisions / errors). The principle is *one layer per natural unit of audit*, not "always 5 layers." Simpler shapes have simpler logs.

Each retained layer has its own retention and review cadence. Don't conflate them — a single "agent log" file is hard to review at any one of the relevant granularities.

**Retention discipline:**

| Layer | Typical retention |
|---|---|
| Tool calls | Until session deleted |
| Decisions / grants | Persistent until user clears |
| Compaction events | Until session deleted (debug-grade) |
| Errors | At least until next release; longer for compliance-bound projects |
| Sub-agent dispatches | Per dispatch-archive policy (often age-encrypted long-term) |

Pin retention with explicit numbers in the project's recovery runbooks (§5). "Permanent" and "indefinite" aren't retention policies — they're handwaves. Concrete numbers force the conversation about acceptable storage cost vs. audit utility.

**Redact at write, not at read.** Secrets, PII, and tokens must never reach the log file in the first place. Redaction lives at log-emit, not log-read. Once unredacted content hits disk, you've created a different problem (encrypted-at-rest concerns, secret-rotation triggers, log-shipping caveats). The cheapest sensitive-data leak is the one not written.

**Review cadence — load-bearing.** A log nobody reads is a write-only buffer. Schedule periodic review:

- **Weekly:** scan tool-call patterns for anomalies (loop-stuck retries, tool-call-count spikes)
- **Per-release:** review error layer for drift (new failure modes, increased provider errors)
- **Per-incident:** pull the relevant time window across all five layers for forensic reconstruction
- **Quarterly:** review whether logged-but-never-queried fields earn their cost

If review never happens, either remove the logging cost or make review part of process.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Log silence (agent active but no log entries) | Emitter broken or downstream sink failing; nobody notices because the log is consulted reactively |
| Log volume spike (sustained N× normal rate) | Loop detected, retry storm, runaway sub-agent dispatch — symptom of a substrate issue |
| Logged-but-never-queried fields | Costs storage and write latency without producing audit value. Either start querying or stop logging |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Log-everything | Every step at full token-grain; haystack obscures needles | Log per-decision and per-tool-call, not per-message-token. Granularity is the work |
| Wrong grain for the layer | Tool calls logged at message-token grain; sub-agent dispatches logged as flat blob | Each layer has its own natural unit. Per-tool-call for tools, per-dispatch for sub-agents, per-error for errors. Don't flatten |
| Debug logs in production retention | DEBUG-level logs accumulate to permanent retention; storage cost balloons; sensitive intermediate state persists | Debug retention ≤ 7 days; promote to longer retention only with explicit justification |
| Retention without review | Logs roll off after N days but no one ever read them; sized for compliance, not used for it | Schedule the review cadence above; if review doesn't happen, drop the retention cost |

**Cross-references:**
- §14 Agent Approval Gates — gate decisions feed the decisions layer; gate table audit-trail column points at this log
- §5 Recovery runbooks — runbook detection signatures should map to log-line patterns; if you can't write the detection from the log, the log is missing the field
- §9.6 strategic compaction — compaction events are a layer worth logging
- §22 compliance — agent logs are evidence-pack components; retention policy must align with regulatory requirements
- §0.6 anti-pattern table — "Agent logs without review"

---

## 5. State Tracking & Recoverability

Every state mutation is tracked through content-addressable hashing or equivalent versioning.

- **Change detection** — diffs computed at field level, not "the whole file changed."
- **Undo/redo** — navigable version history, not a naive stack.
- **Deduplication** — identical states produce identical hashes, no redundant storage.
- **Debounced persistence** — frequent edits batched to avoid write storms, with forced caps to prevent data loss.

The result: every edit is recoverable, and you can always answer "what changed and when."

For production systems, recoverability extends beyond code versioning to disaster recovery and incident response — RTO/RPO targets, backup verification, and restore procedures. The IaC extension covers infrastructure recovery (§16.12). The compliance extension covers the procedural layer — incident response plans, DR testing, and communication plans (§22.4).

### Recovery Runbooks per Stateful Surface

For projects with persistent state — configuration files, credential stores, session databases, agent logs, working trees, on-disk caches, indexed memory — formalize *per-surface restore procedures* before they're needed in an incident. A runbook turns "we have backups somewhere" into "here's exactly what to do in the next 15 minutes."

§5 above describes how state tracking *prevents* loss; runbooks describe how to *recover* when prevention fails.

**Surface inventory.** Each project has a set of stateful surfaces. Catalog them up front:

| Common surface | Typical concerns |
|---|---|
| Configuration files | Corruption, accidental deletion, schema-incompatible upgrades |
| Credential stores (keyring, secret store, env files) | Lockout, key rotation gone wrong, host migration |
| Session / chat databases | Corruption, accidental wipe, schema migration failure |
| Agent logs / activity logs | Disk-full truncation, log rotation gone wrong |
| Working-tree / branch state | Force-push accident, branch deletion, stash loss |
| Persistent caches | Stale invalidation, partial corruption |
| Indexed memory / embeddings | Index corruption, drift from source-of-truth |

Illustrative; project-specific surfaces (license keys, customer-data exports, schema-state files, etc.) extend the list.

**Per-surface runbook — template fields:**

| Field | What it captures |
|---|---|
| **Failure modes** | Concrete ways this surface can fail (corruption, deletion, lock, schema mismatch, etc.) |
| **Detection** | How you find out the surface is broken — error signature, missing data, user report |
| **Restore steps** | Exact commands or procedures to recover. Numbered, copy-paste-ready, with prerequisites named |
| **RTO / RPO targets** | Recovery Time Objective (how fast must we restore?) and Recovery Point Objective (how much data loss is acceptable?). Both as numbers, not "soon" / "minimal" |
| **Prevention** | What reduces the likelihood or blast radius (snapshots, replication, validation, monitoring) |

**Worked example shape (one surface, end-to-end).** Below is one project's runbook for a credential store. Replace the platform-specific pieces (system keyring on Linux, Keychain on macOS, Credential Manager on Windows, Vault / 1Password / a secrets-manager service for cloud environments) with whatever the project actually uses; the template fields stay the same.

```markdown
## Surface: Credential store

### Failure modes
- User logged out of the credential session; agent loses access to API keys
- Credential store corruption (rare; usually after hard shutdown or migration)
- Host migration without credential export (new machine starts with empty store)

### Detection
- Agent operations fail with credential-lookup errors specific to the platform
  (e.g., D-Bus exceptions on Linux, Keychain access denied on macOS, Vault auth
  failure in cloud environments)
- API calls return 401 across all providers simultaneously
- Platform-specific lookup tool returns nothing for known service names

### Restore steps
1. Verify the credential store is reachable / unlocked
2. If reachable but empty: re-import from backup
   (e.g., encrypted JSON at a known backup location)
3. If no backup: re-issue API keys with each provider, store via the platform's
   credential CLI / API
4. Restart agent to pick up restored credentials

### RTO / RPO
- RTO: 15 minutes (from detection to working agent)
- RPO: depends on backup recency; e.g., weekly backups → worst case ~7 days
  of stale keys

### Prevention
- Scheduled backup script writes encrypted credentials to a known location
- Auto-unlock on login configured at the OS or service-account level
- Probe at session start that exercises one credential lookup; alert if it fails
```

The shape carries information density: detection signatures help detect; numbered restore steps work under stress; RTO/RPO numbers are real commitments; prevention closes the loop. The same shape applies to other surfaces — the template doesn't change, the platform specifics do.

**Watch signals:**

| Signal | What it catches |
|---|---|
| Surface drift (project ships a new stateful surface but no runbook) | New surface deployed without lifecycle planning; first incident discovers the gap |
| Untested runbooks (>6 months without exercise) | Restore steps may have rotted (commands changed, paths moved, deps different); first real incident finds out |
| RTO/RPO without numbers ("soon" or "minimal" instead of concrete values) | The runbook is aspiration, not policy; can't be evaluated against incident outcomes |

**Failure modes:**

| Failure mode | Symptom | Fix |
|---|---|---|
| Runbook-as-aspiration | Runbook exists; no one has tested the restore steps | Run a quarterly recovery drill on at least one surface; rotate which surface |
| Runbooks without RTO/RPO | "Recover when convenient" | Numbers, even rough ones (RTO: 15m / 1h / 1d; RPO: minutes / hours / days). Forces the conversation about acceptable loss |
| Runbooks for surfaces that no longer exist | Stale runbook for an architecture two refactors ago | Audit-on-architecture-change: when removing a stateful surface, remove the runbook in the same change |
| Detection signatures missing | Restore steps documented but readers don't know when to invoke them | Detection is the most-skipped section but the most-needed under incident stress; never write a runbook without it |

**Cross-references:**
- §5 state tracking (above) — runbooks describe recovery from the failures §5's tracking is meant to prevent
- §8 acknowledged gaps — surfaces without runbooks are tracked gaps
- §14 agent approval gates — gates produce audit trails; runbooks restore the state behind them. HARD-gated actions warrant runbooks for the resulting state transitions
- §22 compliance — runbooks are operational-maturity evidence for compliance audits

---

## 6b. Developer Experience and Pipeline Health

Developer experience is a velocity input. Slow CI, slow local feedback loops, and unaudited pipeline gates tax every contribution. The math is brutal: a 25-minute CI run × 8 commits per day per contributor × 5 contributors = 1,000 contributor-minutes per day spent waiting, or ~14 working hours per week of pure latency across the team. Inner-loop slowness (a test runner that takes 90 seconds instead of 9) compounds across every iteration and is often worse than outer-loop slowness.

Velocity-protective practices elsewhere in umami (§4 depth tiers, §0.6 tier-sizing, the cost profile annotations in §2/§3/§4) are undermined if the pipeline silently consumes the velocity they preserve. This section frames pipeline and inner-loop health as a recurring audit practice, not a one-time setup.

### Why DevEx earns its own section

§6 Enforced Consistency tells you *what* to enforce. This section tells you *whether the enforcement system itself is healthy*. The two questions look similar but they differ: a project can have excellent linting and typing rules and still have a pipeline that exists in name only — slow, flaky, ignored locally, with gates nobody can name the purpose of.

### Pipeline Audit

The core practice of this section: a periodic gut check on CI/CD. Quarterly is the default cadence; per-incident as a secondary trigger.

**Cost profile:** Operator-required · Days per audit · Recurring discipline

**Depth tiers within the practice:**

| Depth | What it looks like | Cost profile |
|---|---|---|
| Starter | Pipeline cycle time measured (P50 / P99 over 30 days); gate inventory listed (one row per gate, what it checks) | Agent-with-review · Hours · Recurring (quarterly) |
| Working | + Each gate has a stated purpose, an owner, and a "last caught something" date; gates without recent catches flagged for disposition | Operator-required · Days · Recurring (quarterly) |
| Full | + Per-contribution cost accounting (cycle time × commit frequency × contributor count); cycle-time budget enforced as a meta-gate (CI fails if pipeline exceeds budget); pipeline gates mapped to §4 threat-model mitigations and §3 fitness functions | Operator-required (pipeline engineer) · Days–Weeks setup, Days per audit · Recurring + Architectural |

**The audit protocol:**

1. **Measure cycle time** — P50 / P99 of pipeline duration over the last 30 days. Include queue time, not just execution time.
2. **Inventory gates** — list every gate (build, lint, format, type-check, unit tests, integration tests, E2E, visual regression, security scan, deploy gate, manual approvals). For each: what does it check, when did it last catch something, who owns it.
3. **Audit purposes** — for each gate, can someone name the specific failure mode it catches and a recent example? If the answer is "we've always had it" or "for compliance" without naming the specific control, the gate is unmoored from its purpose.
4. **Calculate the tax** — cycle time × commits per day × contributors = contributor-hours per week spent waiting. This is the tax the pipeline imposes; compare it to the value the gates produce.
5. **Decide dispositions** per gate — Keep (still catches things) / Move local (catches issues that should be caught pre-push) / Demote to nightly (catches drift, not per-commit issues) / Remove (no longer earns its cost).
6. **Re-baseline** — record cycle time and gate inventory; schedule the next audit (default 90 days).

### Inner-Loop Feedback

The CI pipeline is the outer loop. The inner loop is what runs on the contributor's machine before they push: test runner in watch mode, type checker (incremental), linter on save, IDE feedback. Slow inner loops are often worse than slow CI because they hit every iteration, not every push.

**Inner-loop budgets:**

| Inner-loop signal | Budget heuristic | Why this number |
|---|---|---|
| Test runner (per-file watch mode) | < 5 seconds | Slower and contributors stop running tests during development |
| Type checker (incremental) | < 3 seconds | Slower and contributors disable real-time type checking |
| Linter (on-save) | < 1 second | Slower and contributors disable IDE integration |
| Full local build | < 30 seconds | Slower and contributors push without local verification |

These are heuristics, not hard rules. Your project may justify slower budgets (large monorepos, generated code, native compilation), but the inner-loop budget needs an explicit number in the project's CLAUDE.md or process docs. Without a number, drift is invisible — the test runner gets 5% slower every quarter and nobody notices.

**Cost profile (inner-loop maintenance):** Operator-required (occasional optimization) · Days · Recurring discipline

### Watch signals

| Signal | What it catches |
|---|---|
| CI cycle time creeping up over consecutive months | Gate added per incident, never removed; flaky tests retried; build artifacts growing |
| Contributors skipping local CI before pushing | Inner loop too slow; CI catches issues that should have been caught locally — but at 25× the cost |
| "It works on my machine" reports increasing | Dev environment diverging from CI environment; either CI is wrong or local is — needs resolution |
| Pipeline failures dismissed without investigation | Flaky tests becoming normalized; gates losing trust; eventually a real regression gets dismissed too |
| Identical gate configuration across multiple projects regardless of context | Pipeline cargo-culted from one project to another without local justification |
| No gate has caught a real regression in N months | Gates documenting aspiration, not catching incidents |
| Audit ran; no gates removed | Audit-without-disposition pattern (see §0.6 "Documentation theater" applied to pipeline) |

### Failure modes

| Failure mode | Symptom | Fix |
|---|---|---|
| Slow CI as accepted reality | Pipeline takes 25+ minutes; contributors stopped complaining months ago because it never gets faster | Cycle time is a managed metric, not an act of god. Measure first; then audit per the protocol above; remove gates that don't earn their cost |
| Gate-on-incident, never-remove | Every incident historically added a CI gate; nothing ever gets removed | Per gate, ask "is the threat this addresses still live?" If addressed elsewhere or no longer relevant, the gate is debt |
| Pipeline cargo cult | Pipeline config copied from another project; gates that made sense there don't apply here, but they ship | When adopting a pipeline pattern, re-justify each gate against the current project's threat model and feature surface |
| "We need this for compliance" without naming the control | Gate exists; rationale is "compliance"; nobody can name which specific control (SOC 2 CC8.1, PCI-DSS 6.4, etc.) it satisfies | Per §22, every compliance-driven gate maps to a specific control. If the mapping isn't documented, the rationale is folklore |
| Inner loop ignored | CI is audited; local test runner takes 90 seconds and nobody talks about it | The inner loop is often the bigger velocity tax. Include inner-loop signals in the audit |
| Audit without disposition | Audit runs; finds 6 gates with no recent catches; nothing gets removed | Each finding needs Keep / Move local / Demote nightly / Remove. An audit without disposition is theater |

### Cross-references
- §0.6 "Cargo-culting practices" — applies to pipeline gates specifically; this section operationalizes it for CI/CD
- §0.6 "Pipeline cargo cult — slow CI as accepted reality" — the anti-pattern this section addresses
- §3 multi-layer testing — what runs in each gate's test step; pipeline audit asks whether the right layer runs at the right gate
- §4 security gates — boundary-trust verification at pipeline gates; pipeline audit checks whether these earn their cost
- §6 Enforced Consistency — *what* to enforce; this section asks *whether enforcement is healthy*
- §13 dead code hygiene — dead gates are dead code; the same disposition discipline applies
- §15 Pre-commit checklist — what runs *before* CI; inner-loop budgets feed into this
- §16 IaC — pipeline definition often lives in IaC; gate changes are infrastructure changes
- §22 compliance — gates driven by compliance need explicit control mapping

---

