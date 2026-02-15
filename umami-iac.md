# Infrastructure-as-Code Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §16**

This extension covers infrastructure-as-code (Terraform, Pulumi, CloudFormation, CDK), cloud provisioning, and DevOps automation. The core template is oriented toward application development — testing assumes unit/E2E/visual, specs assume component contracts, and the structure assumes `src/`. Infrastructure projects have fundamentally different risks, blast radii, and disciplines.

**Apply this extension when** the §0.2 system shape questionnaire identifies an Infrastructure / IaC layer.

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

---

## 16.4 Cost as a First-Class Concern

Unlike application code, every infrastructure resource has a direct, ongoing cost. Cost awareness should be part of the review process, not an afterthought.

**Practices:**
- Tag every resource with `environment`, `owner`, and `project` at minimum. Untagged resources are invisible debt.
- Set billing alerts before provisioning infrastructure (e.g., alert at 150% of estimated monthly cost).
- Include cost estimates in PR descriptions for infrastructure changes — "this adds an RDS instance at ~$X/month."
- Audit running resources periodically. Orphaned resources (unused EBS volumes, idle load balancers, forgotten dev clusters) compound silently.
- Use `infracost` or similar tools to estimate cost impact of Terraform changes in CI.

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
| **Lint** | `tflint` | Provider-specific issues, deprecated features, naming conventions | CI on every PR |
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

§16.2 covers blast radius — what happens when a change goes wrong. This section covers the broader question: **what happens when a component fails in production?** Every infrastructure decision should be evaluated for fault tolerance, not just cost and functionality.

**The core question:** For every resource you provision, ask: "What happens when this fails?" If the answer is "the system goes down," you have a single point of failure.

**Reliability patterns:**

| Pattern | What it protects against | How to implement |
|---|---|---|
| **Redundancy** | Single instance failure | Multi-AZ deployments, read replicas, auto-scaling groups with min > 1 |
| **Health checks** | Silent failures | Load balancer health checks, container liveness/readiness probes, application-level heartbeats |
| **Automatic failover** | Primary failure | RDS Multi-AZ, active-passive clustering, DNS failover |
| **Circuit breakers** | Cascading failures | Service mesh circuit breaking, retry budgets, bulkhead isolation |
| **Graceful degradation** | Partial outage | Feature flags to disable non-critical features, fallback to cached data, read-only mode |

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

Infrastructure should be provisioned with an understanding of the system's load characteristics — not oversized "just in case" and not undersized until it falls over.

**Before provisioning, answer these questions:**
- **What is the expected load?** Requests per second, concurrent users, data volume per day, storage growth rate. Use estimates, not guesses — even rough numbers (§12 magnitude estimates) are better than nothing.
- **What is the scaling dimension?** CPU-bound, memory-bound, I/O-bound, network-bound? The answer determines instance type, not just instance size.
- **Where are the bottlenecks?** The system's throughput is limited by its slowest component. Scaling everything except the bottleneck wastes money.
- **Is scaling horizontal or vertical?** Horizontal (add more instances) requires stateless design or shared-nothing architecture. Vertical (bigger instance) is simpler but has a ceiling.

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

Infrastructure exists to serve a system, and that system has reliability targets. SLOs (Service Level Objectives) make those targets explicit and measurable.

**Definitions:**
- **SLI (Service Level Indicator)** — a measurable signal of system health. Examples: request latency (p99), error rate, availability (% of successful responses), data freshness.
- **SLO (Service Level Objective)** — the target value for an SLI. Examples: "p99 latency < 200ms," "99.9% availability per month," "data freshness < 5 minutes."
- **Error budget** — the amount of unreliability your SLO allows. A 99.9% availability SLO means you have ~43 minutes of downtime budget per month.

**Why SLOs matter for infrastructure:**
- They make reliability decisions concrete. "Should we deploy multi-AZ?" becomes "Do we need 99.9% or 99.99%?" — and the cost difference is quantifiable.
- They prevent over-engineering. If your SLO is 99.9% and you're running at 99.99%, you may be spending money on reliability you don't need.
- They prevent under-engineering. If your SLO is 99.9% and you're running at 99.5%, you have a measurable gap to close.

**How to implement:**
- **Define SLOs before provisioning.** The SLO should be in the project docs (or ADR) before infrastructure is designed. It drives architecture decisions: redundancy, failover, backup frequency, monitoring granularity.
- **Instrument SLIs in monitoring.** Every SLO needs a corresponding SLI that's automatically measured. If you can't measure it, you can't manage it.
- **Alert on error budget burn rate, not individual failures.** A single error is noise. Consuming 50% of your monthly error budget in one hour is a signal. Set alerts on burn rate, not on individual 500s.
- **Review SLOs quarterly.** Business requirements change. An SLO that was appropriate at launch may be too tight (wasting money) or too loose (users are unhappy) six months later.

**SLO tiers for common infrastructure:**

| Component | Typical SLO | Key SLI | Implication |
|---|---|---|---|
| **Web frontend** | 99.9% availability | Successful responses / total responses | Multi-AZ, health checks, CDN |
| **API service** | 99.9% availability, p99 < 500ms | Latency percentiles, error rate | Auto-scaling, connection pooling, caching |
| **Database** | 99.95% availability, RPO < 1 hour | Query latency, replication lag | Multi-AZ, automated backups, read replicas |
| **Batch pipeline** | 99% on-time completion | Completion within SLA window | Retry logic, alerting on overrun, capacity headroom |
| **Message queue** | 99.9% availability, < 1s delivery | End-to-end message latency | Clustered brokers, dead letter queues |

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

### Periodic
- [ ] Drift detection run against prod (weekly/nightly).
- [ ] Orphaned resource sweep (monthly).
- [ ] Cost review against budget (monthly).
- [ ] Credential rotation audit (quarterly).
- [ ] SLO review — targets still appropriate, error budgets on track (quarterly) (§16.14).
- [ ] Capacity review — utilization vs. provisioned, right-sizing opportunities (quarterly) (§16.13).
- [ ] Failover/restore drill — verify recovery procedures actually work (quarterly) (§16.12).
