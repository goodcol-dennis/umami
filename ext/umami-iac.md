# Infrastructure-as-Code Guardrails

**Extension of [Rapid Development Guardrails](../umami.md) — §16**

This extension covers infrastructure-as-code (Terraform, Pulumi, CloudFormation, CDK), cloud provisioning, and DevOps automation. The core template is oriented toward application development — testing assumes unit/E2E/visual, specs assume component contracts, and the structure assumes `src/`. Infrastructure projects have fundamentally different risks, blast radii, and disciplines.

**Apply this extension when** the §0.2 system shape questionnaire identifies an Infrastructure / IaC layer.

**Adopt when (§0.9 default-deny):** the project provisions infrastructure through code AND a change has already caused (or nearly caused) an unintended resource change, outage, or surprise bill. A lone Terraform file for a dev VM does not warrant this extension — §16.1's plan-before-apply habit alone covers it.
**Cost profile:** Operator-required · Days initial + Recurring discipline (plan review on every change; periodic drift, cost, and credential sweeps).
**Kill criterion:** retire any practice below that has produced no finding, no prevented incident, and no consulted artifact across 2 consecutive review cycles (§0.9 retirement pass).

**This extension establishes infrastructure discipline, not a deployment methodology.** GitOps (ArgoCD, Flux), CI/CD-driven applies, manual plan-and-apply — these are all valid approaches and this extension is compatible with any of them. The principles below (plan before apply, blast radius awareness, state hygiene, drift detection) apply regardless of whether your deployment is pull-based, push-based, or manual. The high-value practice is treating infrastructure as code with the same discipline as application code. How you deliver that code to production is a tooling decision.

---

## 16.1 Dry-Run Culture — Never Apply Blind

The equivalent of "run tests before committing" for IaC is **always plan before apply**. This is non-negotiable.

```
terraform plan → review → terraform apply
```

**Rules:**
- Never run `apply` without reviewing the plan output first.
- In CI/CD: plan on PR, apply on merge. Never auto-apply without human review.
- Treat "will destroy" and "must replace" lines in a plan as red flags requiring explicit justification.
- Save plan files (`terraform plan -out=tfplan`) so what you reviewed is exactly what gets applied.

**Why this matters more than in app code:** A bad deploy of application code usually means a broken page. A bad `terraform apply` can delete databases, tear down networks, or expose secrets. The blast radius is categorically larger.

**Validate locally before pushing.** The same discipline applies to the checks that protect your code *before* it reaches CI. Run the local validation chain before every push:

```
terraform fmt -check -recursive   # formatting
terraform validate                 # syntax + provider schema
tflint                             # linting (unused vars, naming, provider rules)
terraform plan                     # actual changes (catches runtime issues)
```

All four must pass. If any fails, fix before pushing. Each push-fail-fix round-trip through CI costs 5–10 minutes of pipeline time plus a context switch — five rounds of that turns a 10-minute fix into a 2-hour slog. CI exists to catch what you missed, not to be your first feedback loop.

---

## 16.2 Blast Radius Awareness

Every infrastructure change should be evaluated on two axes: **reversibility** and **blast radius**.

| Change Type | Reversibility | Blast Radius | Discipline Required |
|---|---|---|---|
| Add new resource | Easy (destroy it) | Low | Normal review |
| Modify in-place (tags, config) | Easy (revert values) | Low-Medium | Normal review |
| Replace (destroy + recreate) | Risky (data loss possible) | High | Explicit approval |
| Destroy resource | Irreversible | Critical | Manual confirmation, backup verified |
| Modify networking/IAM | Cascading effects | Critical | Test in non-prod first |

**Lifecycle rules:**
- Use `prevent_destroy` on stateful resources (databases, S3 buckets with data, encryption keys).
- Use `create_before_destroy` on resources that can't have downtime.
- Never `terraform destroy` on a production workspace without a second pair of eyes.

---

## 16.3 State Hygiene

Terraform state is the source of truth for what exists. Corrupted or mismanaged state is the #1 cause of infrastructure disasters.

**Rules:**
- Remote state backend with locking (S3 + DynamoDB for AWS, GCS + locking for GCP).
- State file encryption at rest — always.
- Never manually edit state files. Use `terraform state mv`, `terraform import`, `terraform state rm`.
- Never commit state files to git (`.tfstate` in `.gitignore`).
- Enable state versioning (S3 bucket versioning) for recovery.
- One state file per environment. Never share state between dev/staging/prod.

**Anti-patterns:**
- **"Let me just edit the state file"** — manual JSON edits corrupt state. Use `terraform state mv` and `terraform import` even when they feel slower.
- **"Delete state and re-import everything"** — this is a recovery procedure, not a workflow. If you're doing this regularly, your state management has a structural problem.
- **Running apply from a local machine against production** — CI/CD should be the only path to prod. Local applies bypass review, audit logging, and credential scoping.

---

## 16.4 Cost as a First-Class Concern

Unlike application code, every infrastructure resource has a direct, ongoing cost. Cost awareness should be part of the review process, not an afterthought.

**Practices:**
- Tag every resource with `environment`, `owner`, and `project` at minimum. Untagged resources are invisible debt.
- Set billing alerts before provisioning infrastructure (e.g., alert at 150% of estimated monthly cost).
- Include cost estimates in PR descriptions for infrastructure changes — "this adds an RDS instance at ~$X/month."
- Audit running resources periodically. Orphaned resources (unused EBS volumes, idle load balancers, forgotten dev clusters) compound silently.
- Use `infracost` or similar tools to estimate cost impact of Terraform changes in CI.

**Anti-patterns:**
- **"We'll optimize costs later"** — costs compound daily. A forgotten dev cluster running for 3 months costs the same as the production one you carefully right-sized.
- **Running dev/staging at production scale** — dev environments should be architecturally identical but appropriately sized. A 3-node production database doesn't need a 3-node dev replica.
- **No tagging → no accountability** — untagged resources can't be attributed to a project, team, or environment. When no one owns a cost, no one manages it.

---

## 16.5 Secrets Discipline

IaC projects handle credentials constantly. One leaked secret can compromise an entire cloud account.

**Rules:**
- Never hardcode secrets in Terraform files, variable defaults, or `tfvars` — use a secrets manager or environment variables.
- Never commit secrets to git. Run `gitleaks` or similar in CI. Consider a pre-commit hook.
- Use short-lived credentials where possible (IAM roles > access keys, OIDC federation > service account keys).
- Rotate long-lived credentials on a schedule (90 days max).
- Mark sensitive outputs: `sensitive = true` in Terraform.
- Audit IAM permissions periodically — principle of least privilege, especially for CI/CD service accounts.

---

## 16.6 Environment Promotion

Infrastructure changes should flow through environments just like application code.

```
dev → staging → prod
```

**Practices:**
- Same Terraform modules, different variable files per environment (`environments/dev/`, `environments/prod/`).
- Dev can be smaller (fewer nodes, smaller instances) but must be architecturally identical to prod.
- Test destructive changes in dev/staging before applying to prod. Always.
- Environment parity: if it works in staging but breaks in prod, your environments have drifted. Fix that.

**Anti-patterns:**
- **One-off environments** — staging has 3 undocumented differences from prod because someone configured it manually. When something works in staging but fails in prod, the first 2 hours are spent finding the differences. Use the same modules with different variable files — environments should be reproducible from code, not unique artifacts of manual configuration.
- **"It's a small change, deploy straight to prod"** — small changes have caused the largest outages. The promotion path exists for every change, not just the ones that feel risky.
- **"Temporary" config overrides** — a manual change to staging "just for this test" that persists for 6 months. If it's in the environment, it should be in the code.

---

## 16.7 Module and Provider Versioning

Infrastructure providers release breaking changes. Pin everything.

**Rules:**
- Pin provider versions with pessimistic constraints (`~> 5.30`, not `>= 5.0`).
- Pin module versions when using third-party modules (e.g., `source = "terraform-aws-modules/vpc/aws"` with `version = "5.5.0"`).
- Lock file (`.terraform.lock.hcl`) should be committed to git — it ensures reproducible provider installations.
- Update providers deliberately, not accidentally. Review changelogs before bumping versions.
- Pin Terraform CLI version itself (document in README, enforce in CI with `required_version`).

---

## 16.8 IaC Testing Layers

The testing pyramid for infrastructure looks different from application code:

| Layer | Tool | What it catches | When to run |
|---|---|---|---|
| **Format** | `terraform fmt` | Style inconsistencies | Pre-commit |
| **Validate** | `terraform validate` | Syntax errors, invalid references | Pre-commit / CI |
| **Lint** | `tflint` | Provider-specific issues, deprecated features, naming conventions | Pre-commit / CI |
| **Security scan** | `checkov`, `tfsec` | Misconfigurations (public S3, open security groups, missing encryption) | CI on every PR |
| **Cost estimate** | `infracost` | Unexpected cost impact | CI on every PR |
| **Plan** | `terraform plan` | Actual changes that would be applied, dependency issues | CI on every PR |
| **Integration** | Apply to ephemeral env | Real provisioning works end-to-end | Before major changes |

**Minimum viable IaC CI:** format check + validate + lint + security scan + plan on every PR. This catches 90% of issues before they reach apply.

---

## 16.9 Drift Detection

Infrastructure can change outside of Terraform — manual console clicks, another team's script, cloud provider auto-remediation. These changes create drift between declared state and reality.

**Practices:**
- Run `terraform plan` on a schedule (e.g., nightly) against prod to detect drift. Alert if changes are detected.
- Establish a policy: if someone changes infrastructure manually, they must import or reconcile the change in Terraform within 24 hours. Undocumented manual changes are bugs.
- Consider policy-as-code tools (OPA, Sentinel) that block non-Terraform changes to managed resources.

**Anti-patterns:**
- **"Quick console fix"** — a manual change that never gets reconciled in code. Within a week, the next `terraform plan` shows unexpected drift and nobody remembers why. Enforce the 24-hour reconciliation policy above.
- **Ignoring drift alerts** — treating drift detection as noise trains the team to ignore it. If drift alerts fire regularly for expected reasons, fix the detection rules, don't mute the alerts.
- **Manual workarounds for Terraform limitations** — if Terraform can't manage a resource, document it as an acknowledged gap (§8) and track it. Don't silently manage it in the console.

---

## 16.10 Documentation for Infrastructure

Infrastructure documentation has different priorities than application documentation:

| Document | Purpose | Why it matters |
|---|---|---|
| **Network diagram** | Visual map of VPCs, subnets, peering, routing | You cannot debug networking from code alone |
| **Resource inventory** | What exists, what it costs, who owns it | Prevents orphaned resources and surprise bills |
| **Runbooks** | Step-by-step procedures for common operations (rotate cert, scale cluster, restore DB) | Reduces MTTR; enables on-call engineers who didn't build the infrastructure |
| **ADRs** | Why this cloud, this region, this instance type, this architecture | Prevents re-litigation, captures trade-offs |
| **Disaster recovery plan** | RPO/RTO targets, backup verification, restore procedures | Untested backups are not backups |

---

## 16.11 Cloud Account Hygiene

Before building, audit. Before deploying, clean up.

**Pre-project checklist:**
- [ ] Inventory existing resources and spending
- [ ] Enable MFA on all human IAM users, especially admin accounts
- [ ] Enable CloudTrail (or equivalent audit logging)
- [ ] Set billing alerts
- [ ] Delete expired certificates, orphaned resources, unused credentials
- [ ] Choose region deliberately (cost, latency, compliance, existing resources)
- [ ] Decide: workload account vs. management account

**Ongoing:**
- Monthly cost review
- Quarterly credential rotation audit
- Quarterly unused resource sweep

---

## 16.12 Reliability Engineering

**Adopt when:** the system has production users who notice downtime, or a stated availability target. Skip for dev/staging-only infrastructure — redundancy for an environment nobody depends on is cost without benefit.

§16.2 covers blast radius — what happens when a change goes wrong. This section covers the broader question: **what happens when a component fails in production?**

**The core question:** For every resource you provision, ask: "What happens when this fails?" If the answer is "the system goes down," you have a single point of failure. The mitigations — redundancy, health checks, automatic failover, circuit breakers, graceful degradation — are standard; choose per component. The IaC-specific discipline:

**Fault tolerance in IaC:**
- **Codify redundancy, don't bolt it on.** If a resource should be multi-AZ, define it that way from the start. Retrofitting redundancy is harder and riskier than building it in.
- **Test failures deliberately.** Game days and chaos engineering aren't luxuries — they're how you verify that failover actually works. An untested failover is a guess, not a guarantee.
- **Define RTO and RPO for stateful resources.** Recovery Time Objective (how fast you recover) and Recovery Point Objective (how much data you can afford to lose) should be explicit for every database, queue, and storage system. These numbers drive backup frequency, replication strategy, and architecture decisions.

**Anti-patterns:**
- **"We have backups"** without verified restores. Untested backups are not backups. Schedule restore drills.
- **Single-AZ deployments in production** for critical services. The cost difference between single-AZ and multi-AZ is small compared to the cost of downtime.
- **No health checks on load-balanced targets.** Traffic routes to dead instances until someone notices manually.

---

## 16.13 Scalability Awareness

**Adopt when:** load is growing, costs are drifting, or an instance-sizing decision is actually on the table. Skip while a single right-sized instance handles the workload with headroom.

Infrastructure should be provisioned with an understanding of the system's load characteristics — not oversized "just in case" and not undersized until it falls over.

**Before provisioning, answer:** the expected load (requests per second, data volume, growth rate — rough §12 magnitude estimates beat guesses); the scaling dimension (CPU-, memory-, I/O-, or network-bound — it determines instance type, not just size); where the bottleneck is (scaling everything except the bottleneck wastes money); and whether scaling is horizontal (requires stateless or shared-nothing design) or vertical (simpler, but has a ceiling).

**Scalability in IaC:**
- **Use auto-scaling with defined bounds.** Set min, max, and scaling triggers based on actual metrics (CPU, queue depth, request latency), not guesses. Review and adjust after observing real traffic.
- **Right-size before scaling.** An oversized instance running at 5% CPU doesn't need auto-scaling — it needs right-sizing. Use cloud provider recommendations and actual utilization data.
- **Separate stateless and stateful components.** Stateless services (web servers, API servers, workers) scale horizontally. Stateful services (databases, caches, queues) scale differently and need their own strategy. Don't conflate them.
- **Load test before launch.** Verify that the infrastructure handles expected load *before* production traffic hits it. A load test that reveals bottlenecks in staging is cheap; discovering them in production is expensive.

**Capacity planning:**
- Document expected load parameters alongside the infrastructure code. When the next engineer looks at the Terraform, they should understand *why* the instance type was chosen.
- Set alerts at 70-80% of capacity thresholds so you scale proactively, not reactively.
- Review utilization quarterly. Workloads change; infrastructure should follow.

---

## 16.14 SLOs, SLIs, and Error Budgets

**Adopt when:** someone will hold the system to a reliability target — users, an SLA, an on-call rotation. Skip while "best effort" is the honest answer; an SLO nobody enforces is documentation theater.

Infrastructure exists to serve a system, and that system has reliability targets. SLOs (Service Level Objectives) make those targets explicit and measurable — and they cut both ways: a target you're missing is a measurable gap to close; a target you're exceeding is money spent on reliability you don't need.

**How to implement:**
- **Define SLOs before provisioning.** The SLO should be in the project docs (or ADR) before infrastructure is designed. It drives architecture decisions: redundancy, failover, backup frequency, monitoring granularity. "Should we deploy multi-AZ?" becomes "Do we need 99.9% or 99.99%?" — and the cost difference is quantifiable.
- **Instrument SLIs in monitoring.** Every SLO needs a corresponding SLI that's automatically measured. If you can't measure it, you can't manage it.
- **Alert on error budget burn rate, not individual failures.** A single error is noise. Consuming 50% of your monthly error budget in one hour is a signal. Set alerts on burn rate, not on individual 500s.
- **Review SLOs quarterly.** Business requirements change. An SLO that was appropriate at launch may be too tight (wasting money) or too loose (users are unhappy) six months later.

---

## 16.15 Observability as Infrastructure

**Adopt when:** an incident has already required log archaeology across more than one component, or an SLO (§16.14) needs measuring. A single service with good structured logs (§4) doesn't need a monitoring stack yet.

Observability — metrics, logs, traces, and alerts — is infrastructure. The monitoring stack needs the same discipline as any other provisioned system: version-controlled configuration, environment promotion, cost management, and documented architecture decisions.

### Instrument with OTEL

Use OpenTelemetry (OTEL) as the vendor-neutral instrumentation standard: applications emit through the OTEL SDK, a collector receives and routes, and the backend (Prometheus, Grafana, Datadog, CloudWatch, …) becomes a configuration change rather than a re-instrumentation.

**Rules:**
- Use OTEL SDKs for all new instrumentation — not vendor-specific SDKs. Even if you're committed to one vendor today, the switching cost later is significant.
- Use auto-instrumentation first, manual instrumentation second. Most frameworks capture HTTP requests, database calls, and external service calls with zero code changes.
- Document the backend choice for metrics, logs, and traces in an ADR. Structured JSON logs (§4) from every service, searchable by trace ID; a tracing backend is needed for distributed systems, optional for single-service deployments.
- Pin OTEL SDK versions like any other dependency (§16.7).

### Alerting Discipline

The purpose of an alert is to notify a human that something requires action. An alert that doesn't require action is noise; noise leads to alert fatigue; alert fatigue leads to missed real incidents.

**Rules:**
- Alert on symptoms, not causes. "Error rate > 5% for 5 minutes" means users are affected; "CPU > 80%" may be a batch job doing its work.
- Every alert must have a runbook — or at least a link to documentation — and an owner. Unowned alerts are ignored alerts.
- Alert on error budget burn rate (§16.14), not individual errors. A single 500 is not an incident. Burning 10% of your monthly error budget in one hour is.
- Use percentile-based thresholds (p99, not averages) with sustained windows ("for 5 minutes") to catch tail latency without flapping.
- Assign each alert an urgency tier (page / urgent / warning / info) and route accordingly — if everything pages, nothing does.
- Review alerts monthly. If an alert fires regularly and nobody acts on it, fix the underlying issue or adjust the threshold.

### Dashboards

- Start with a golden-signals dashboard per service — latency, traffic, errors, saturation — before building anything elaborate.
- Add deployment markers. Overlaying deploy events on metric graphs instantly answers "did the last deploy cause this?"
- Keep dashboards focused. A dashboard with 50 panels is a wall of noise.

### Observability Cost Management

Observability data is high-volume. Unmanaged, it becomes one of the largest infrastructure line items. Treat it like any other cost (§16.4).

**Cost controls:**
- Control metric cardinality. If a label can take more than ~100 unique values, it should not be a metric label — put high-cardinality identifiers in logs and traces instead.
- Sample traces in production. Capture 100% of error traces and a statistical sample of successful ones.
- Set log levels appropriately — DEBUG in production generates 10-100x more volume than INFO.
- Set retention policies: metrics 13 months, logs 30-90 days, traces 7-14 days.
- Review observability spend monthly alongside infrastructure costs (§16.4).

---

## 16.16 CI/CD Pipeline Discipline

Pipeline definitions are infrastructure: they are code, they gate every change, and modifying a gate is an infra change that deserves the same review as the resources it protects. Three IaC-specific deltas: include the plan output in CI so reviewers approve exactly what will apply (§16.1); reserve manual approval for high-blast-radius changes (§16.2) — production data stores, networking, IAM — and let plans showing only low-risk additions and in-place updates auto-approve; encode policy in policy-as-code or Terraform modules (§16.17), not in pipeline YAML — pipelines execute checks, they don't define them.

The full pipeline-health discipline — gate inventory, cycle-time budgets, per-gate dispositions, flaky-gate and gate-sprawl anti-patterns — is §6b in `core/umami-runtime.md`; run it there, don't maintain a parallel copy here.

---

## 16.17 Security Governance Without Friction

**Adopt when:** more than one person (or agent) ships infrastructure changes, or a security review queue already exists. A solo operator needs §16.8's scanners and §16.5's secrets discipline, not a governance layer.

Security gates that block everything eventually get bypassed. The goal is security that developers work *with*, not *around*.

**Shift-left security:**
- **Embed security checks in CI** (§16.8), not in a separate review queue. A `checkov` scan that runs automatically on every PR is more effective than a quarterly security review, and faster.
- **Provide fix guidance, not just findings.** "Add `block_public_access` — see the approved S3 module" is actionable; "S3 bucket allows public access" is not. When writing custom policies, include remediation guidance in the output.
- **Pre-approved modules** — provide Terraform modules that are already security-reviewed. Teams using the approved VPC module don't need a per-project VPC security review. This is the highest-leverage security investment: shift the work from review to reuse.

**Governance patterns:**
- **Policy-as-code** (OPA, Sentinel, Kyverno) — policies written in code are testable, version-controlled, and consistently enforced. Policies in a wiki are aspirational.
- **Tiered review requirements** — not every change needs the same scrutiny:

| Change scope | Review required |
|---|---|
| Uses approved modules, no IAM/networking changes | Automated checks only |
| New resource types or modified security groups | Team peer review |
| IAM policy changes, cross-account access, new networking | Security team review |
| New cloud account, new region, architecture change | Architecture review + security review |

- **Exception process** — when a team needs to deviate from policy, document the exception and its justification as an ADR (§7). Blanket denials push teams to work around the process entirely.

**Anti-patterns:**
- **Security as a queue** — a security team that manually reviews every infrastructure PR creates a bottleneck. Automate what you can, reserve human review for architecture changes and new patterns.
- **Checkbox compliance** — running a scan, ignoring the output, and marking the ticket as done. If nobody acts on findings, the scan is waste that creates false confidence.
- **Over-scoping IAM to avoid friction** — granting `AdministratorAccess` because the least-privilege policy is too annoying to maintain. Document the minimum permissions needed for each role and enforce them.

---

## 16.18 Platform Engineering

When multiple teams share infrastructure patterns, the question shifts from "how do I provision resources?" to "how do I provide self-service infrastructure that's secure and consistent by default?"

**Adopt when:** multiple teams write similar Terraform for similar infrastructure; onboarding a new service means copying another team's config; security and compliance must be consistent across services; or teams spend more time on infrastructure plumbing than on their product. If none of these apply, skip this section. A platform for one team is over-engineering.

**Shared module library:**
- Internal Terraform modules encode your organization's standards (networking, security, tagging, monitoring); teams compose from them instead of writing from scratch.
- Version modules semantically. Breaking changes require a major version bump and a migration guide.
- Test modules independently (§16.8) — a broken shared module breaks every consumer.
- Every module has a documented owner and documented inputs, outputs, and assumptions. If a team can't use your module without reading its source, the interface isn't good enough.

**Golden paths and self-service:**
- Provide a "start here" template per common workload type (web service, batch job, data pipeline) that includes infrastructure, CI/CD, monitoring, and alerting scaffolding.
- Golden paths are opinionated defaults, not mandates — and build them *with* the teams that use them, not *for* them. A path that doesn't match real needs doesn't get adopted.
- Approved modules and templates enforce policy (encryption, tagging, access controls, cost limits) so teams get compliance by default, not by effort. A scaffolding tool that generates the initial Terraform for a new service reduces the "blank page" problem.

**Anti-patterns:**
- **Premature platform** — building a shared platform before you have repeated patterns across multiple teams. Start with shared modules. Evolve to a platform when the repetition justifies it.
- **Platform without adoption** — golden paths that nobody uses because they're too rigid, too complex, or don't match real team needs. Measure adoption rate and iterate.
- **"Just use Kubernetes"** — Kubernetes solves orchestration, not infrastructure discipline. A poorly managed K8s cluster has all the same problems as poorly managed VMs, plus the complexity of Kubernetes itself. Evaluate whether managed services (RDS, Lambda, SQS, Cloud Run) are simpler and cheaper before defaulting to K8s.
- **Central team as bottleneck** — if every module change requires the platform team, you've replaced one bottleneck (manual infrastructure) with another (the platform team's backlog). Enable teams to contribute to modules with review, not gatekeeping.

---

## 16.19 Common IaC Anti-Patterns

Tooling misconceptions and process traps that cost time and money. When reviewing IaC or advising on infrastructure decisions, flag these if you see them.

**Tooling misconceptions:**

| Misconception | Reality | What to do instead |
|---|---|---|
| "Terraform manages everything" | Terraform manages infrastructure state. It doesn't manage application deployment, database migrations, secret rotation, or application configuration. | Use the right tool for each job. Terraform for infrastructure, application tooling for application concerns. A Terraform `null_resource` with a provisioner is usually a sign you're using the wrong tool. |
| "We need one IaC tool for everything" | Different tools suit different layers. Terraform for cloud resources, Helm for K8s manifests, Ansible for configuration management. | Choose tools by layer, not by mandate. Forced standardization on one tool leads to workarounds that are worse than using two tools well. |
| "Cloud-native means Kubernetes" | Managed services (RDS, Lambda, SQS, Cloud Run) are often simpler, cheaper, and more reliable than self-managed equivalents on K8s. | K8s adds value when you need orchestration, portability, or workload density. For everything else, evaluate managed services first. |
| "Infrastructure is just like application code" | IaC shares principles with application code (version control, review, testing) but has slower feedback loops, higher blast radius per change, and state management concerns that application code doesn't have. | Apply software engineering principles *adapted* for infrastructure characteristics. Don't blindly import application development patterns. |
| "Serverless means no infrastructure" | Serverless shifts infrastructure management, it doesn't eliminate it. You still manage IAM, networking, monitoring, cost, and deployment. | Apply the same IaC discipline to serverless resources. They're still infrastructure — they're just someone else's servers. |

**Process anti-patterns:**

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **"Automate everything from day one"** | Automating a process you don't understand codifies mistakes. | Start with manual processes you understand. Automate the ones that repeat and are well-defined. |
| **Copy-paste infrastructure** | Snippets from the internet or AI assume a different context. A security group rule that's fine for a dev blog is a vulnerability for a healthcare app. | Understand every resource you provision — what it does, what it exposes, what it costs. Review AI-generated IaC with the same scrutiny as AI-generated application code. |
| **"We'll clean it up later"** | Orphaned resources, outdated modules, unused security groups, and stale IAM roles compound. They increase cost, attack surface, and cognitive load. | Schedule cleanup as recurring work (§16.11 periodic checklist). Treat orphaned resources as bugs, not as backlog. |
| **Monolithic Terraform** | One state file with 500 resources means every plan takes minutes, every change risks everything, and state locking blocks the whole team. | Decompose by service, layer, or team. Smaller state files = faster plans, smaller blast radius, independent team velocity. |
| **"The console is faster"** | It is — for the first change. Then you have untracked state, no audit trail, and drift that surprises the next `terraform plan`. | Use the console for investigation and debugging. Use Terraform for changes. If the console is genuinely faster for a recurring operation, that's a sign your IaC workflow needs improvement. |
| **CI as your linter** | Pushing without running local checks and waiting for CI to report failures turns a 10-minute fix into a 2-hour push-fail-fix loop. Each round-trip costs 5–10 minutes of pipeline time plus a context switch, and pollutes the commit history with fix-up commits. | Run the local validation chain before every push (§16.1): fmt, validate, lint, plan. CI catches what you missed — it should not be your first feedback loop. |

---

## Mapping to Core Guardrail Sections

This extension does not replace core guardrails — it extends them for the IaC context:

| Core Section | IaC Equivalent |
|---|---|
| §3 Testing | §16.8 IaC Testing Layers (fmt, validate, lint, scan, plan) |
| §3b TDD / Process Discipline | §16.1 Dry-run culture (plan before apply) |
| §4 Runtime Validation | §16.9 Drift detection |
| §5 State Tracking | §16.3 Terraform state hygiene |
| §6 Enforced Consistency | §16.7 Provider/module pinning, format checks, tagging policy |
| §7 ADRs | Same, but for cloud/region/architecture decisions |
| §8 Acknowledged Gaps | §16.11 Cloud account hygiene (what isn't automated yet) |
| §11 File Size Budgets | Module decomposition (large monolithic Terraform files → extracted modules) |
| §4 / §8 Reliability | §16.12 Reliability engineering — fault tolerance, RTO/RPO, failure testing |
| §0 Discovery | §16.13 Scalability awareness — load parameters, capacity planning |
| §7 ADRs | §16.14 SLOs/SLIs — measurable reliability targets driving architecture decisions |
| §4 Observability | §16.15 Observability as infrastructure — OTEL, alerting, dashboards, cost management |
| §15 Checklists | §16.16 CI/CD pipeline discipline — IaC-specific pipeline deltas; full discipline in §6b |
| §4 Security | §16.17 Security governance — shift-left security, policy-as-code, tiered review |
| §1 Project Structure | §16.18 Platform engineering — shared modules, golden paths, self-service |
| §13 Dead Code Hygiene | §16.19 Common anti-patterns — tooling misconceptions, process traps, cleanup discipline |

---

## IaC Checklist (extends §15)

### Before Every Infrastructure Change
- [ ] `terraform plan` reviewed — no unexpected destroys or replacements.
- [ ] Blast radius assessed — reversibility and scope understood.
- [ ] Cost impact estimated (if adding or resizing resources).
- [ ] Secrets confirmed not hardcoded or committed.
- [ ] Failure mode considered — "what happens when this component fails?" (§16.12).

### Before Every Infrastructure PR
- [ ] Format, validate, lint, security scan all pass.
- [ ] Plan output included in or linked from PR description.
- [ ] State file not included in commit.
- [ ] Provider/module versions pinned.
- [ ] Tested in non-prod environment first (for destructive or networking changes).
- [ ] SLO impact assessed — does this change affect reliability targets? (§16.14).
- [ ] Review gate appropriate — does this change need manual approval or can it auto-merge? (§16.16).
- [ ] Security scan findings addressed — high-severity blocked, medium tracked in acknowledged gaps (§16.17).

### Before Every Service/Feature Launch
- [ ] Golden signals dashboard created (latency, traffic, errors, saturation) (§16.15).
- [ ] Alerts configured for SLO-based thresholds with runbooks (§16.15).
- [ ] Structured logging with trace ID correlation verified (§16.15).
- [ ] Trace context propagation verified end-to-end for distributed services (§16.15).

### Periodic

**This checklist is a menu, not a calendar** — schedule only the items whose §0.9 trigger has fired for this project; an unrun scheduled check is worse than an unscheduled one (it reads as coverage that doesn't exist, per the §22 compliance-theater anti-pattern).

- [ ] Drift detection run against prod (weekly/nightly).
- [ ] Orphaned resource sweep (monthly).
- [ ] Cost review against budget, including observability spend (monthly) (§16.4, §16.15).
- [ ] Credential rotation audit (quarterly).
- [ ] SLO review — targets still appropriate, error budgets on track (quarterly) (§16.14).
- [ ] Capacity review — utilization vs. provisioned, right-sizing opportunities (quarterly) (§16.13).
- [ ] Failover/restore drill — verify recovery procedures actually work (quarterly) (§16.12).
- [ ] Alert review — silence or fix alerts that fire without action (monthly) (§16.15).
- [ ] Metric cardinality audit — identify and reduce high-cardinality metrics (quarterly) (§16.15).
- [ ] Pipeline review — stages still earning their time, no gate sprawl (quarterly) (§16.16).
- [ ] Shared module health — all modules versioned, tested, owned, documented (quarterly) (§16.18).
- [ ] Security policy-as-code review — policies current, exceptions documented (quarterly) (§16.17).
