# Umami Extension — Homelab Infrastructure Patterns

> **Section 26 — Homelab Infrastructure Management**
> Extension of [umami.md](../umami.md). Patterns for managing a homelab environment with VMs, containers, VPN, DNS, monitoring, and remote access.

**Adopt when (§0.9 default-deny):** the homelab hosts services others depend on, data you would mind losing, or a remotely reachable entry point. A single experimental box you can rebuild in an afternoon does not warrant this extension — snapshots (§26.4) alone cover it.
**Cost profile:** Operator-required · Days initial + Recurring discipline (backups, updates, hardening list).
**Kill criterion:** retire any practice below that has produced no finding, no prevented loss, and no consulted artifact across 2 consecutive review cycles (§0.9 retirement pass).

The recurring practices in this file (backup verification §26.12, update cadence §26.13, history audits §26.2) are a menu, not a calendar — schedule only those whose trigger has fired; an unrun scheduled check reads as coverage that doesn't exist (the §22 compliance-theater anti-pattern).

---

## 26.0 Context

This extension captures patterns that emerge from building and operating a small-scale homelab — typically a single hypervisor node running a mix of VMs and lightweight containers. It is not a universal homelab template — it reflects discipline patterns that apply regardless of the specific technology stack.

**Typical stack components:** A hypervisor (Proxmox, ESXi, or similar), Linux containers or VMs, a VPN overlay for remote access, a reverse proxy for service routing, local DNS, monitoring and alerting, and home automation.

---

## 26.1 Living Documentation as AI Context

**Pattern:** A single `CLAUDE.md` at the repo root serves as both human documentation and AI agent context. It is the authoritative source of truth for the entire infrastructure.

**What works:**
- **Structured tables** for VMs, containers, VPN peers, service URLs, and network reservations — agents can look up any IP, port, or credential reference without SSH-ing into machines.
- **Common commands section** — eliminates agent guesswork for container management, snapshot, and rollback patterns.
- **"Adding a New Service" checklist** — a step-by-step runbook that both humans and agents follow, preventing forgotten steps (network reservation, DNS entry, proxy host, docs update).
- **Hardening status with completed/pending split** — creates a living security punch list. Completed items serve as an audit trail; pending items are actionable.
- **Acknowledged gaps section** — explicitly states what is *not* automated, *not* tested, *not* backed up. Prevents agents from assuming capabilities that don't exist.

**Key insight:** The document is updated *as part of every infrastructure change*, not after. If a container is added but `CLAUDE.md` isn't updated, the change is incomplete. This is enforced by convention, not tooling.

**Anti-pattern avoided:** Separate wiki, Notion, or README files that drift from reality. One file, one truth.

---

## 26.2 Secrets Discipline

**Pattern:** Secrets never enter version control. Injection at runtime, auditing for leaks, and remediation if found.

**Prevention layers:**
- **`.gitignore` covers `.env`, `*.key`, `*.pem`, `*.crt`** — first line of defense against accidental commits.
- **Placeholder convention** — `<PRIVATE_KEY>`, `<VPN_PRIVATE_KEY>` in committed scripts, with env var substitution at build/deploy time.
- **No credentials in documentation** — `CLAUDE.md` references *that credentials exist* and where to find them, never the values themselves.

**Injection strategies (choose based on scale):**
- **Environment file** — a gitignored `secrets/credentials.env` sourced at runtime. Simplest option for a solo project or small team.
- **Secret manager** — HashiCorp Vault, AWS Secrets Manager, Bitwarden Secrets, or `pass`. Better for multi-machine setups where secrets need to be distributed securely.
- **CI/CD secrets** — GitHub Actions secrets, GitLab CI variables. Keeps secrets out of the repo entirely and injects them during pipeline runs.

**Auditing and remediation:**
- **Pre-commit hooks** — tools like `gitleaks`, `detect-secrets`, or `trufflehog` scan staged changes for high-entropy strings, API keys, and known credential patterns before they enter history.
- **Periodic git history audit** — run `gitleaks detect` or `trufflehog git` against the full repo history, not just the working tree.
- **If secrets are found in history** — rotate the credential immediately (assume compromised), then scrub history with `git-filter-repo --replace-text` or `BFG Repo-Cleaner`, force push, and notify collaborators to re-clone. Track the incident in the hardening checklist.

**Key insight:** AI agents read every file in context. If credentials appear in documentation or scripts, they end up in API calls, logs, and conversation history. The separation between "what exists" (committed) and "what it is" (injected) is critical when working with AI-assisted development.

**Anti-pattern:** Hardcoding passwords "because it's just a homelab." The moment you use an AI agent or push to any remote, every committed secret is effectively exposed.

---

## 26.3 Script-Based Provisioning

**Pattern:** Self-contained shell scripts that can be pushed to a container or VM and executed, rather than full configuration management for a small-scale setup.

**What works:**
- **Consistent script structure** — shebang, `set -euo pipefail`, header comment, preflight checks, body, status messages to stderr. Every script follows the same template (see also §23 — Scripting).
- **`shellcheck` before every commit** — pre-commit hook enforces this. Catches quoting issues, unused variables, and bashisms before they reach production.
- **Push-and-execute workflow** — scripts live in the repo, get pushed to containers via the hypervisor's CLI tools, and run. No SSH key distribution to containers, no agent software.
- **Pinned versions** — no `:latest` tags, no `curl | bash` fetching latest releases. Every package version is explicit and reproducible.

**Trade-off acknowledged:** Scripts are *not* idempotent. They're designed for initial setup on clean containers. This is explicitly documented in the acknowledged gaps. The mitigation is snapshots before changes.

**Key insight:** For a homelab with a handful of services, the overhead of Ansible/Terraform/Pulumi exceeds the benefit. Simple scripts + good documentation + snapshots provide sufficient reproducibility. Document the threshold at which you'd upgrade to a configuration management tool.

---

## 26.4 Snapshot-Before-Change Culture

**Pattern:** Every infrastructure change is preceded by a snapshot, creating a fast rollback path.

**What works:**
- **Named snapshots before any script execution or manual change** — e.g., `pre-<change-description>`.
- **Documented in common commands** — agents and humans both see the pattern and follow it.
- **Automated backups supplement snapshots** — weekly full backups for critical containers (with rotation), weekly VM snapshots (with rotation). Cron jobs in a standard location, logs in a standard location.

**Key insight:** Snapshots are cheap and fast. The 30 seconds to create one saves hours of rebuilding. When working with AI agents, this is especially important — agents can make confident changes knowing rollback is one command away.

---

## 26.5 DNS Architecture with Private TLD

**Pattern:** All services accessible via hostnames on a private TLD, resolved by a dedicated DNS server, with wildcard routing through a reverse proxy.

**What works:**
- **Private TLD** — use an IANA-reserved TLD (e.g., `.internal`, `.home.arpa`) to avoid collision with public DNS.
- **Wildcard DNS** — `*.<your-tld>` resolves to the reverse proxy, which routes by Host header. Adding a new service only requires a proxy host entry, not a DNS change.
- **Explicit overrides** — specific address records for services that don't go through the proxy (e.g., the hypervisor management UI).
- **Encrypted upstream resolution** — DNS-over-HTTPS or DNS-over-TLS on the local DNS server for upstream queries.
- **DHCP-distributed DNS** — all LAN clients automatically use the homelab DNS server, no manual `/etc/hosts` needed.

**Key insight:** The wildcard pattern means most new services require zero DNS configuration. The reverse proxy becomes the single routing layer, and TLS termination happens in one place.

---

## 26.6 VPN Overlay for Remote Access

**Pattern:** A hub-spoke VPN topology through a cloud relay, providing remote access to all homelab services from any location.

**What works:**
- **Cloud relay as public endpoint** — a minimal cloud instance with a static IP; no home IP exposure, no port forwarding on the home router.
- **Split tunneling** — remote clients route only homelab traffic through VPN; internet goes direct. Simpler relay config, better performance.
- **Per-device peers** — each device (laptop, phone, travel router) has its own keys and IP. Easy to revoke or audit.
- **Firewall at the gateway** — the VPN gateway has forwarding rules restricting VPN clients to specific services. VPN access doesn't mean flat LAN access.
- **Travel router pattern** — a small single-board computer with a WiFi AP, a web portal for upstream WiFi config, and a VPN tunnel back to homelab. Extends the VPN to all devices at a remote location without per-device VPN apps.

**Key insight:** The travel router pattern is powerful — one VPN peer serves an entire location. Devices connect to its AP and get homelab access transparently. A web portal eliminates SSH for WiFi configuration.

---

## 26.7 Firewall-Per-Interface on Edge Devices

**Pattern:** Devices exposed to untrusted networks (travel routers, VPN gateways) have per-interface firewall rules, not just perimeter firewalls.

**What works:**
- **Untrusted interface locked down** — the upstream/WAN interface only allows established connections and DHCP inbound. All other inbound is dropped. Nobody on the shared WiFi can reach management interfaces.
- **Trusted interface permissive** — the AP interface, ethernet, and VPN interfaces are trusted and allowed full access.
- **Fallback routing** — if VPN is down, AP clients can still route through upstream WiFi. Firewall rules allow forwarding through multiple paths, preventing total connectivity loss.

**Key insight:** The threat model for a travel device is different from a home server. The untrusted network is *directly connected*, not behind a NAT/router. Per-interface firewall rules are the minimum viable security.

---

## 26.8 Monitoring and Alerting Pipeline

**Pattern:** Layered monitoring — availability checks, metrics collection, and notification channels — with clear separation of concerns.

**What works:**
- **Availability monitoring** — lightweight HTTP/TCP/ping checks for all services with alerts on failure.
- **Metrics pipeline** — agent-based collection to a time-series database with dashboards. Covers system metrics (CPU, memory, disk), UPS status, and network gear.
- **Boot notification** — a systemd oneshot service (or equivalent) that sends a notification on every server reboot. Catches unexpected reboots (power outages, kernel panics).

**Notification channels (choose based on needs):**
- **Transactional email** — simplest path. Cloud services like SES, Mailgun, or Postmark. Requires email authentication on the sending domain (DKIM, SPF, DMARC) or messages land in spam.
- **Push notifications** — Pushover, ntfy, Gotify. Better for mobile alerting, no email deliverability concerns.
- **Chat/webhook** — Slack, Discord, or Telegram bots. Good for team visibility or if you already live in chat.
- **Incident management** — PagerDuty, Opsgenie, Grafana OnCall. Adds escalation policies, on-call schedules, and acknowledgment tracking. Overkill for solo, valuable for teams.

**Key insight:** The boot notification is the simplest and most valuable alert. If the server reboots while you're away, you know immediately. Combined with "restore on AC power loss" in BIOS settings, the server self-recovers from power outages and tells you about it.

---

## 26.9 Incremental Hardening

**Pattern:** Security is applied incrementally and tracked as a checklist, not as a big-bang hardening pass.

**What works:**
- **Completed/pending split in docs** — every hardening step is listed with its current status. New items are added to "pending" as they're identified, moved to "completed" when done.
- **Prioritized by exposure** — internet-facing services hardened first, then the hypervisor host, then internal containers. Outside-in from most exposed to least.
- **Specific and actionable items** — not "harden SSH" but "SSH key-only, root login disabled, fail2ban sshd jail." Each item is verifiable.

**Key insight:** Perfect security on day one is the enemy of getting anything running. Document what's done, what's pending, and what's explicitly accepted as a gap. The documentation itself is the forcing function for progress.

---

## 26.10 DHCP Reservation Discipline

**Pattern:** Every infrastructure device has a DHCP reservation. No static IPs configured on the devices themselves.

**What works:**
- **Central management** — all IP assignments live in the network controller's DHCP reservation table. One place to see the entire network map.
- **Containers use DHCP** — containers are configured for DHCP, not static IPs. The reservation pins them to known addresses without hardcoding in container config.
- **Documented in `CLAUDE.md`** — the infrastructure tables show every container/VM ID with its IP, making it trivial for agents to reference.

**Key insight:** DHCP reservations are more maintainable than static IPs across many devices. Changing an IP means updating one place (the DHCP server), not connecting to the device to reconfigure it.

---

## 26.11 Network Segmentation

**Pattern:** Separate traffic classes into isolated network segments (VLANs or subnets) so a compromised IoT device can't reach your NAS, and guest WiFi can't see management interfaces.

**What works:**
- **At minimum three segments** — management (hypervisor, switches, APs), trusted (workstations, servers), and IoT/untrusted (smart home devices, guest WiFi). More granularity is better but adds complexity.
- **Firewall rules between segments** — IoT can reach the internet but not the management or trusted segments. Trusted can reach IoT for control (e.g., Home Assistant) but IoT can't initiate connections back.
- **Hypervisor-aware VLANs** — tag container/VM interfaces into the correct VLAN at the hypervisor level. A container running Home Assistant gets an IoT-facing interface *and* a trusted-facing interface if it needs to bridge segments.
- **Documented topology** — a table or diagram showing which VLAN each device, container, and service belongs to. This is critical context for AI agents making network changes.

**Key insight:** VLANs are cheap on managed switches and most consumer prosumer gear. The cost of setup is an afternoon; the cost of a flat network with IoT devices is an open attack surface. Start with coarse segments and refine as needed.

---

## 26.12 Backup Strategy (3-2-1 Rule)

**Pattern:** Follow the 3-2-1 backup rule — three copies of data, on two different media types, with one copy offsite.

**What works:**
- **Automated local backups** — scheduled full backups of critical containers/VMs with rotation (e.g., keep last 3 weekly). Use the hypervisor's built-in backup tools.
- **Separate backup storage** — backups stored on a different disk or NAS than the primary storage. A single disk failure shouldn't take both production and backups.
- **Offsite copy** — cloud storage (Backblaze B2, Wasabi, cloud provider object storage), a remote NAS at another location, or encrypted backups at a friend's house. This is the most commonly skipped step and the most important.
- **Backup verification** — periodically restore a backup to a test container/VM to confirm it actually works. Untested backups are Schrödinger's backups.
- **Application-aware backups** — databases need dump-then-backup, not just filesystem snapshots. A snapshot of a running database can produce a corrupt backup.

**Key insight:** Most homelabs have the first "3" (snapshots + local backup) but skip the offsite copy. The offsite copy is the one that matters when your server dies.

---

## 26.13 Update and Patch Management

**Pattern:** Regular, deliberate updates with a rollback plan — not "update everything and pray" and not "never update because it might break."

**What works:**
- **Snapshot before updating** — always. This is the rollback plan.
- **Staggered updates** — update one non-critical container first, verify it works, then proceed to others. Don't `apt upgrade` everything in parallel.
- **Separate host from guests** — hypervisor/host OS updates are higher risk than container updates. Schedule them separately and with more caution.
- **Automated security updates for containers** — unattended-upgrades (or equivalent) for security patches on containers. Manual review for major version bumps.
- **Track what's running** — a table in `CLAUDE.md` listing each service and its current version. When a CVE drops, you can immediately check if you're affected.

**Key insight:** The biggest risk in a homelab isn't a zero-day — it's running six-month-old packages because updates feel risky. Snapshots make updates safe; discipline makes them regular.

---

## 26.14 TLS Certificate Management

**Pattern:** All internal services accessed over HTTPS with automated certificate management, not self-signed certs with browser warnings.

**What works:**
- **Reverse proxy as TLS termination point** — one place manages all certificates. Internal services run plain HTTP; the proxy adds TLS.
- **Automated certificate provisioning** — Let's Encrypt with DNS-01 challenge for internal domains (works even when services aren't internet-accessible). Wildcard certs reduce management overhead.
- **Certificate renewal automation** — cron or built-in proxy renewal. Monitor for renewal failures — an expired cert is worse than no cert because it trains users to click through warnings.
- **Internal CA as alternative** — for fully air-gapped labs, run a private CA and distribute the root cert to trusted devices. More setup, but no external dependency.

**Key insight:** Self-signed certs with browser exceptions are a security anti-pattern — they train you to ignore certificate warnings, which is exactly the behavior an attacker exploits. Automated Let's Encrypt or a proper internal CA costs an hour to set up and eliminates the problem.

---

## 26.15 Storage Architecture

**Pattern:** Deliberate storage layout — know what's expendable, what's precious, and where each lives.

**What works:**
- **Tiered storage** — fast storage (SSD/NVMe) for VMs and active containers, bulk storage (HDD) for media, backups, and archives. Don't put everything on the same pool.
- **Redundancy for precious data** — ZFS mirror, BTRFS RAID1, or hardware RAID for data you can't recreate. Single disks for data you can (container OS disks, easily re-provisioned services).
- **Bind mounts for persistent data** — container application data lives on the host filesystem and is bind-mounted in. If the container is destroyed, the data survives.
- **Documented storage map** — a table showing which pool/disk holds what, how much space is used, and what the growth trend is. Disk-full surprises are avoidable.

**Key insight:** The question isn't "should I use ZFS?" — it's "which data would hurt to lose?" Put redundancy and backups around the answer. Everything else can be on a single disk and re-provisioned from scripts.

---

## 26.16 Power Management

**Pattern:** Graceful handling of power events — UPS for ride-through, automated shutdown on extended outage, and automatic recovery when power returns.

**What works:**
- **UPS on the server and network gear** — protects against brief outages and provides time for graceful shutdown on extended outages.
- **NUT or apcupsd for UPS monitoring** — the hypervisor monitors the UPS and triggers a clean shutdown when battery reaches a threshold.
- **BIOS set to "restore on AC power loss"** — the server powers back on automatically when power returns. Combined with a boot notification (§26.8), you know it happened.
- **UPS metrics in monitoring** — battery level, load percentage, and estimated runtime visible in dashboards. Know when to replace the battery before it fails.

**Key insight:** A UPS without monitoring software is just a battery. The value is in the automated shutdown — protecting against filesystem corruption and database inconsistency during unclean power loss.

---

## 26.17 What Homelabs Typically Don't Do Well (Yet)

Honest accounting of common gaps, per §8 principles:

- **No CI/CD** — scripts are linted locally, pushed manually. A pre-commit hook runs shellcheck, but there's no pipeline.
- **No automated testing** — install scripts are verified manually on fresh containers. No test harness.
- **No offsite backup** — local backups exist, but a site-level event (fire, flood, disk failure) loses everything. Consider cloud backup, a remote NAS, or a friend's server.
- **No infrastructure-as-code tool** — hypervisor resources (containers, VMs, firewall rules) are created manually or via scripts, not Terraform/Pulumi. State lives in the hypervisor, not in the repo.
- **Scripts are not idempotent** — running an install script twice may fail or produce unexpected results.
- **Single point of failure** — one physical server, one switch, one AP. No redundancy at any layer.

These are common and accepted trade-offs for a personal homelab. Document your specific gaps and the threshold at which you'd address each one.
