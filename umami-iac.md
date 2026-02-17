# Infrastructure-as-Code Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §16**

This extension covers infrastructure-as-code (Terraform, Pulumi, CloudFormation, CDK), cloud provisioning, and DevOps automation. The core template is oriented toward application development — testing assumes unit/E2E/visual, specs assume component contracts, and the structure assumes `src/`. Infrastructure projects have fundamentally different risks, blast radii, and disciplines.

**Apply this extension when** the §0.2 system shape questionnaire identifies an Infrastructure / IaC layer.

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

## 16.15 Observability as Infrastructure

Observability — metrics, logs, traces, and alerts — is infrastructure. The monitoring stack needs the same discipline as any other provisioned system: version-controlled configuration, environment promotion, cost management, and documented architecture decisions.

### Instrument with OTEL

Use OpenTelemetry (OTEL) as the vendor-neutral standard for instrumentation. The key architectural benefit: your application code emits telemetry through the OTEL SDK, the OTEL Collector receives and routes it, and the backend (Grafana, Datadog, Prometheus, etc.) is a configuration change — not a re-instrumentation.

**What to provision:**
- **OTEL Collector** — deploy as a sidecar or standalone service. It decouples applications from backends, handles batching and retry, and lets you change backends without touching application code.
- **Metrics backend** — Prometheus, Mimir, CloudWatch, Datadog. Choose one, document the decision in an ADR.
- **Log aggregation** — centralized logging (Loki, Elasticsearch, CloudWatch Logs). Structured JSON logs (§4) from every service, searchable by trace ID.
- **Tracing backend** — Jaeger, Tempo, X-Ray. Needed for distributed systems; optional for single-service deployments.

**Rules:**
- Use OTEL SDKs for all new instrumentation — not vendor-specific SDKs. Even if you're committed to one vendor today, the switching cost later is significant.
- Use auto-instrumentation first, manual instrumentation second. Most frameworks have OTEL auto-instrumentation libraries that capture HTTP requests, database calls, and external service calls with zero code changes.
- Pin OTEL SDK versions like any other dependency (§16.7).

### Alerting Discipline

The purpose of an alert is to notify a human that something requires action. An alert that doesn't require action is noise. Noise leads to alert fatigue. Alert fatigue leads to missed real incidents.

**Alert on symptoms, not causes:**
- Good: "Error rate > 5% for 5 minutes" — users are affected.
- Bad: "CPU > 80%" — may or may not affect users. CPU at 80% might be perfectly normal during a batch job.

**Alert tiers:**

| Tier | Urgency | Response | Examples |
|------|---------|----------|---------|
| **Page** (P1) | Immediate | Drop everything | Service down, data loss, security breach |
| **Urgent** (P2) | Business hours | Address today | Error rate elevated, SLO budget burning fast, disk > 90% |
| **Warning** (P3) | This week | Investigate if it persists | Latency trending up, cert expiring in 14 days |
| **Info** | Awareness only | Review in ops review | Deployment completed, scaling event |

**Rules:**
- Every alert must have a runbook — or at least a link to documentation. If the on-call engineer doesn't know what to do, the alert is incomplete.
- Every alert must have an owner. Unowned alerts are ignored alerts.
- Alert on error budget burn rate (§16.14), not individual errors. A single 500 is not an incident. Burning 10% of your monthly error budget in one hour is.
- Use percentile-based thresholds over averages. p99 > 500ms catches tail latency; average > 500ms only fires when everything is on fire.
- Use sustained thresholds: "Error rate > 5% for 5 minutes" prevents flapping on momentary spikes.
- Review alerts monthly. If an alert fires regularly and nobody acts on it, fix the underlying issue or adjust the threshold.

### Golden Signals Dashboards

Every service should have a dashboard showing four signals (from Google's SRE book):

| Signal | What it measures | Key metric |
|--------|-----------------|------------|
| **Latency** | How long requests take | p50, p95, p99 response time |
| **Traffic** | How much demand the system handles | Requests per second |
| **Errors** | How often requests fail | Error rate (%), error count by type |
| **Saturation** | How full the system is | CPU %, memory %, disk %, queue depth, connection pool usage |

**Dashboard hierarchy:**
1. **Service overview** — golden signals per service. Start here during an incident.
2. **Dependency view** — latency and errors for downstream dependencies. Answers "is the problem mine or downstream?"
3. **Business metrics** — orders per minute, signups per day. Answers "is the system doing what it should?"
4. **Infrastructure** — resource utilization, scaling events, deployment markers.

**Rules:**
- Start with the golden signals dashboard before building anything elaborate.
- Add deployment markers — overlaying deploy events on metric graphs instantly answers "did the last deploy cause this?"
- Keep dashboards focused. A dashboard with 50 panels is a wall of noise.

### Observability Cost Management

Observability data is high-volume. Unmanaged, it becomes one of the largest infrastructure line items. Treat it like any other cost (§16.4).

| Data type | Cost driver |
|-----------|------------|
| **Metrics** | Cardinality — each unique label combination creates a time series. A metric with a `user_id` label creates a series per user. |
| **Logs** | Volume (GB/day). Verbose logging in high-traffic services adds up fast. |
| **Traces** | Span count. 100% trace sampling at scale generates enormous volumes. |

**Cost controls:**
- Control metric cardinality. If a label can take more than ~100 unique values, it should not be a metric label — put high-cardinality identifiers in logs and traces instead.
- Sample traces in production. 100% sampling is rarely necessary. Capture 100% of error traces and a statistical sample of successful ones.
- Set log levels appropriately. DEBUG in production generates 10-100x more volume than INFO.
- Set retention policies: metrics 13 months, logs 30-90 days, traces 7-14 days.
- Review observability spend monthly alongside infrastructure costs (§16.4).

---

## 16.16 CI/CD Pipeline Discipline

Every CI/CD stage either catches a real problem or slows delivery. The discipline is knowing the difference.

**Design principles:**
- **Fast feedback first.** Cheap checks (format, lint, validate) run before expensive checks (plan, security scan, integration test). A syntax error caught in 5 seconds shouldn't wait behind a 10-minute security scan.
- **Parallelize independent stages.** Lint, security scan, and cost estimate don't depend on each other — run them simultaneously. A pipeline with 6 sequential stages that could be 3 parallel groups is wasting half its time.
- **Keep pipelines under 15 minutes for the critical path.** Longer pipelines cause developers to batch changes, which increases blast radius per deploy. If a stage is slow, evaluate whether it's earning its time.
- **One pipeline definition, parameterized per environment.** Don't maintain separate pipelines for dev/staging/prod. Same stages, different variables. Divergent pipelines mean divergent behavior.

**Gate discipline:**
- **Reserve manual approval for high-blast-radius changes** (§16.2). Production database modifications, networking changes, IAM changes. Not every config tweak.
- **Auto-approve low-risk changes** — tag updates, scaling adjustments, non-destructive additions. If the plan shows only additions and in-place updates to non-critical resources, human review is overhead without safety benefit.
- **Distinguish blocking vs. advisory checks.** High-severity security findings block merge. Medium findings warn and create a tracked issue (§8). Low findings report only. If everything blocks, developers stop reading the output.

**Anti-patterns:**
- **Gate sprawl** — 12 stages taking 45 minutes when 5 stages taking 8 minutes catch the same issues. Before adding a gate, ask: would this have been caught by an existing check if configured correctly?
- **"Add a check for that"** — when something breaks in production, the instinct is to add a new CI gate. Often the correct fix is improving an existing check or fixing the underlying code, not adding pipeline complexity.
- **Flaky checks blocking deploy** — a security scan that intermittently fails or a plan that times out teaches the team to re-run and ignore. Fix or replace flaky checks; don't let them erode trust in the pipeline.
- **Pipeline as documentation** — encoding business logic and policy decisions in pipeline YAML instead of in policy-as-code or Terraform modules. Pipelines should execute checks, not define them.

---

## 16.17 Security Governance Without Friction

Security gates that block everything eventually get bypassed. The goal is security that developers work *with*, not *around*.

**Shift-left security:**
- **Embed security checks in CI** (§16.8), not in a separate review queue. A `checkov` scan that runs automatically on every PR is more effective than a quarterly security review, and faster.
- **Provide fix guidance, not just findings.** A scan that says "S3 bucket allows public access" is less actionable than one that says "add `block_public_access` — see the approved S3 module." When writing custom policies, include remediation guidance in the output.
- **Pre-approved modules** — provide Terraform modules that are already security-reviewed. Teams using the approved VPC module don't need a per-project VPC security review. This is the highest-leverage security investment: shift the work from review to reuse.

**Governance patterns:**
- **Policy-as-code** (OPA, Sentinel, Kyverno) — encode security requirements as automated checks. Policies written in code are testable, version-controlled, and consistently enforced. Policies in a wiki are aspirational.
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

**When platform engineering matters:**
- Multiple teams write similar Terraform for similar infrastructure.
- Onboarding a new service requires copying and modifying another team's config.
- Security and compliance requirements must be consistent across all services.
- Teams spend more time on infrastructure plumbing than on their actual product.

If none of these apply, skip this section. A platform for one team is over-engineering.

**Shared module library:**
- Internal Terraform modules that encode your organization's standards (networking, security, tagging, monitoring). Teams compose from these modules instead of writing from scratch.
- Version modules semantically. Breaking changes require a major version bump and a migration guide.
- Test modules independently (§16.8) — a broken shared module breaks every consumer.
- Every module has a documented owner. Unowned modules decay.
- Document inputs, outputs, and assumptions. If a team can't use your module without reading its source, the interface isn't good enough.

**Golden paths:**
- A "start here" template for common workload types (web service, batch job, data pipeline) that includes infrastructure, CI/CD, monitoring, and alerting scaffolding.
- Golden paths are opinionated defaults, not mandates. Teams can deviate when they have a reason — but the default should be good enough that most teams don't need to.
- Build golden paths *with* the teams that use them, not *for* them. A path that doesn't match real needs doesn't get adopted.

**Self-service with guardrails:**
- Teams provision their own infrastructure using approved modules and templates. The modules enforce policy (encryption, tagging, access controls, cost limits) so teams get compliance by default, not by effort.
- Provide a service catalog or scaffolding tool that generates the initial Terraform for a new service using approved modules. Reduce the "blank page" problem.

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
| §15 Checklists | §16.16 CI/CD pipeline discipline — gate design, fast feedback, pipeline anti-patterns |
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
