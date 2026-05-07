# CMS Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §25**

This extension covers practices common to all content management systems — WordPress, Drupal, and others. CMS platforms share a distinct risk profile: a large ecosystem of third-party extensions (plugins, modules, themes), a culture of composing sites from pre-built components, content/configuration/code boundaries that blur easily, and production environments where non-developers make changes through admin UIs.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CMS layer. Then apply the platform-specific sub-extension ([WordPress](cms/umami-wordpress.md) §20, [Drupal](cms/umami-drupal.md) §21) for implementation details.

> **Planned consolidation:** The standalone WordPress (§20) and Drupal (§21) extensions are being rolled into this file in a future release. The shared CMS practices already cover most of the surface area; platform-specific implementation detail will move here as thinner subsections rather than separate documents. Section numbers §20 and §21 will be retained for traceability.

**Loading order:** A CMS project loads three layers:
1. [umami.md](umami.md) — core guardrails
2. This file (`umami-cms.md`) — CMS-generic practices
3. The platform-specific file (e.g., `cms/umami-wordpress.md`) — platform-specific implementation

---

## 25.1 Extension Inventory and Audit Discipline

Every third-party extension (plugin, module, theme) is a dependency you didn't write, can't fully control, and must keep updated. A CMS site with 30 extensions has 30 potential attack vectors, 30 potential performance bottlenecks, and 30 potential sources of conflict.

### Extension Inventory

Maintain a living inventory of every active extension:

| Field | Why it matters |
|-------|---------------|
| **Name (machine name)** | Identification — use the canonical/machine name |
| **Version** | Track deployed vs. available |
| **Type** | Core / third-party / custom |
| **Purpose** | One-line justification for why it exists |
| **Author / source** | Official marketplace, premium vendor, custom-built |
| **Last updated (by author)** | Extensions not updated in 12+ months are risk indicators |
| **Security coverage** | Does the extension have official security team oversight? (Drupal green shield, WordPress.org review, etc.) |
| **Alternatives considered** | Prevents re-evaluation; documents why this one over others |
| **Can it be removed?** | Periodic reassessment — is it still needed? |
| **Known conflicts** | Documented interactions with other active extensions |

### Selection Criteria

Before installing any third-party extension, evaluate:

- [ ] **Active maintenance** — updated within the last 6 months? Responsive to bug reports?
- [ ] **Community adoption** — sufficient install base relative to the extension's age?
- [ ] **Security history** — any past vulnerabilities? How were they handled?
- [ ] **Performance impact** — does it load assets on every page, or only where needed?
- [ ] **Dependency chain** — what other extensions does it require? Each dependency is another thing to maintain.
- [ ] **Code quality** — if it's critical to the site, review the source. Look for raw SQL, missing access checks, unescaped output.
- [ ] **Can you build it instead?** — a small amount of custom code is often better than a large third-party extension that does 50 things you don't need.
- [ ] **Does the CMS already do this?** — check core capabilities before adding third-party extensions. CMS cores are feature-rich; duplicating core functionality with an extension adds overhead without value.

### Abandoned Extension Protocol

When a third-party extension shows no activity for 12+ months:

1. Check for known vulnerabilities in security databases.
2. Check for maintained forks or successor projects.
3. Evaluate whether the functionality can be built custom.
4. If you must keep it, document the risk in acknowledged gaps (§8) with a review date.
5. Consider contributing to maintenance if the extension is critical to your project.

---

## 25.2 Update Management

CMS platforms and their extensions require regular updates — more frequently than typical application dependencies, because the public-facing nature of CMS sites makes them active attack targets.

### Update Categories

| Category | Risk level | Timeline | Testing |
|----------|-----------|----------|---------|
| **Security patches** (core + extensions) | Critical | Within 48 hours of release | Staging first if possible; production immediately if staging isn't available |
| **Core minor updates** | Medium | Within 2 weeks | Test in staging; verify extension compatibility |
| **Core major updates** | High | Plan as a project | Full compatibility audit; test all extensions; check deprecations |
| **Extension updates** | Medium | Weekly batch | Review changelogs; test in staging |
| **Platform runtime updates** (PHP, Node, etc.) | Medium–High | Test everything | Runtime changes can break extensions in subtle ways |

### Update Checklist

- [ ] Staging environment mirrors production (same extensions, same data).
- [ ] Full backup taken before applying updates to production.
- [ ] Updates applied to staging first and tested.
- [ ] Critical user flows verified after update.
- [ ] Rollback plan documented (restore backup, revert extension version).

---

## 25.3 Security Fundamentals

CMS platforms are the most targeted category of web applications. Most CMS compromises exploit known vulnerabilities in unpatched extensions, not zero-day exploits in core.

### Output Escaping

Every CMS has a mechanism for output escaping, but they differ significantly:

| Approach | Platforms | Developer responsibility |
|----------|-----------|------------------------|
| **Auto-escaping** (template engine escapes by default) | Drupal (Twig), modern CMS with template engines | Audit exceptions to auto-escaping (`|raw`, `{!! !!}`, etc.) |
| **Manual escaping** (developer must call escape functions) | WordPress (PHP templates) | Every `echo` of dynamic data must use the appropriate escape function |

**Regardless of approach:** Audit every point where dynamic data enters HTML output. Auto-escaping doesn't cover all contexts (JavaScript, CSS, URLs). Manual escaping requires discipline at every output point.

### Input Sanitization

Sanitize at the boundary — when data enters the system:
- Use the CMS's built-in sanitization functions for the data type (text, email, URL, filename, integer).
- Never trust client-side validation alone.
- Validate file uploads server-side (MIME type, not just extension).

### Access Control

- **Check permissions, not roles.** Permission-based checks are granular and composable; role-based checks are brittle.
- **Every route/endpoint must have an access check.** Never rely on "hiding the URL" as security.
- **Every form submission must be protected against CSRF.** Use the CMS's built-in token/nonce system.

### Database Security

- **Use the CMS's database API** — it handles parameterization and escaping.
- **Never concatenate user input into SQL.** Use parameterized queries or the ORM.
- **Prefer high-level query APIs** (e.g., entity queries, post queries) over raw SQL. They handle caching, access control, and escaping.

### Security Audit Checklist

- [ ] Every output of dynamic data is properly escaped for its context.
- [ ] Every form has CSRF protection; every handler verifies it.
- [ ] Every privileged action checks permissions (not roles).
- [ ] Every database query with user input uses parameterized queries or the CMS API.
- [ ] No dangerous functions (`eval()`, `assert()`, `extract()` on user input).
- [ ] File uploads validated server-side for type, not just extension.
- [ ] No secrets hardcoded — all in environment config or secret management.
- [ ] Code editing from admin panel disabled in production.
- [ ] Debug/error display disabled in production (errors logged, not displayed).

---

## 25.4 Content, Configuration, and Code Separation

CMS platforms blur the lines between content, configuration, and code. Getting this wrong causes deployment failures, data loss, and configuration drift.

### The Three Layers

| Layer | Definition | Where it lives | Version controlled? |
|-------|-----------|---------------|-------------------|
| **Code** | Themes, custom extensions, build configs | Filesystem (git) | Yes — always |
| **Configuration** | Site settings, content types, permissions, URL patterns | Depends on CMS (files or database) | Yes — exported to files |
| **Content** | What users see — articles, pages, media, user accounts | Database | No — backed up, not version-controlled |

**The rule:** If it defines *structure or behavior*, it's configuration — version-control it. If it defines *what users see*, it's content — back it up.

### Common Mistakes

- Making configuration changes directly in production (overwritten on next deploy).
- Storing configuration only in the database with no export mechanism.
- Version-controlling user content (bloats the repo, creates merge conflicts).
- Mixing business logic into themes/templates (doesn't survive a theme switch).

---

## 25.5 Theme and Presentation Architecture

### Presentation vs. Business Logic

| Belongs in the theme/template | Belongs in a plugin/module |
|-------------------------------|---------------------------|
| HTML structure, CSS, layouts | Content types, taxonomies, custom fields |
| Theme-specific JavaScript (UI interactions) | Data processing, API integrations |
| Display formatting and template overrides | Functionality that should survive a theme switch |

**The test:** If switching themes would break core site functionality, that functionality is in the wrong place.

### Template Override Discipline

- **Never edit core or third-party theme files directly.** Use the CMS's override mechanism (child themes, template overrides). Updates to the original will overwrite direct edits.
- **Keep templates focused on presentation.** If a template needs data, prepare it in a preprocess/controller layer — don't put business logic in templates.
- **Use the CMS's asset system** for CSS and JavaScript. Never inline `<script>` or `<link>` tags in templates.
- **Load assets conditionally** — only on pages that need them. Global loading of page-specific assets hurts performance.

---

## 25.6 Deployment and Environment Discipline

CMS deployments are more complex than typical application deployments because the database contains both content and (often) configuration. Code deploys must coordinate with database state.

### Environment Tiers

Every CMS project needs at minimum:

| Environment | Purpose | Rules |
|-------------|---------|-------|
| **Local/Development** | Active development | Debug mode on, development extensions enabled |
| **Staging** | Testing before production | Mirrors production data and extensions; all changes tested here first |
| **Production** | Live site | Debug off, file editing disabled, monitoring active |

### What to Version Control

| Include | Exclude |
|---------|---------|
| Custom themes | User-uploaded media/files |
| Custom plugins/modules | Database dumps (back up separately) |
| Configuration exports | Environment-specific secrets |
| Dependency lock files | Generated/compiled assets |
| Build tool configs | Vendor/node_modules directories |

### Database and Environment Migration

Most CMS platforms store site URLs and paths in the database. Moving between environments requires URL/path rewriting. **Rules:**
- Always use the CMS's official migration tools — never manually edit serialized data.
- Always run a dry-run first.
- Always back up before running replacements on production.

---

## 25.7 Production Monitoring

CMS sites fail in ways that are invisible without monitoring: silent errors, extensions that degrade performance after an update, scheduled tasks that stop running, and slow queries that accumulate as content grows.

### Error Logging

- **Log errors to files or external services, never display to visitors.** Displaying errors leaks server paths and internals.
- **Set up log rotation** — CMS error logs on high-traffic sites grow indefinitely.
- **For production-grade logging**, send logs to an external aggregation service rather than relying on local files. External aggregation enables search, alerting, and retention.
- **Never log sensitive data** — passwords, payment details, session tokens, PII.

### Health Monitoring

- **External uptime monitoring** — check the site from outside your infrastructure. If your server is down, it can't tell you it's down.
- **Cron/scheduled task health** — many CMS platforms have pseudo-cron that depends on site visits. Low-traffic sites may have scheduled tasks that don't run. If scheduled tasks matter, configure a real system cron and monitor that it runs.
- **Extension update monitoring** — track available security updates. Unpatched extensions are the #1 CMS attack vector.

### Performance Monitoring

- **Query count and response time per page** — track these metrics; they reveal performance degradation from extension updates or content growth.
- **Cache hit rates** — if using an object cache or page cache, monitor hit rates. Low rates mean the cache isn't helping.
- **Slow query logging** — enable database slow query logs. Content growth turns fast queries into slow ones.

---

## 25.8 CMS Testing Layers

| Layer | What it catches | When to run |
|-------|----------------|-------------|
| **Lint / coding standards** | Syntax errors, platform-specific anti-patterns | Pre-commit / CI |
| **Static analysis** | Type errors, deprecated API usage | CI on every PR |
| **Security scan** | Known extension vulnerabilities, misconfigurations | Weekly + after updates |
| **Extension conflict test** | Incompatibilities between active extensions | After extension updates (staging) |
| **Unit tests** | Custom extension logic | CI on every PR |
| **E2E tests** | User flows (login, forms, content creation, admin workflows) | CI on every PR |
| **Performance audit** | Page load time, query count, asset size | Before release |
| **Accessibility scan** | WCAG compliance | Before release |

---

## 25.9 Core Integrity — Never Modify the CMS Core

Modifying CMS core files (or files belonging to contributed/third-party extensions) is one of the most damaging practices in CMS development. Core modifications create invisible technical debt that compounds with every update cycle.

### Why Core Modifications Are Dangerous

- **Updates overwrite them.** The next security patch or version update silently reverts the change, reintroducing the original behavior and potentially breaking dependent code. Or worse — the team avoids updates entirely because "we modified core."
- **They're invisible.** There's no manifest of changes. New developers, agencies, or AI agents have no way to know what was modified or why. The modification looks like original code.
- **They break upgrade paths.** Major version upgrades assume unmodified core. Core modifications make upgrades unpredictable and often require manual, line-by-line review of every modified file.
- **They can't be shared.** A core modification can't be contributed back, reused across projects, or maintained independently. It's a one-off hack that lives and dies with one installation.

### Detection Practices

Treat core modifications as a defect to detect, not just a rule to follow:

| Method | How it works | When to run |
|--------|-------------|-------------|
| **Checksum verification** | Compare file checksums against the official distribution. Any mismatch is a modification. | After every deployment, weekly in production |
| **Version control diffing** | Keep the CMS core in version control (or use Composer/package manager). `git diff` or `composer status` reveals modifications. | Pre-commit, CI |
| **File integrity monitoring** | Use the CMS's built-in integrity checker (e.g., WordPress `wp core verify-checksums`, Drupal `core:requirements`) or external file integrity monitoring (AIDE, OSSEC). | Weekly automated scan |
| **Code review rule** | Any PR that touches a file in the CMS core directory or a contributed extension directory is automatically flagged. | Every PR |

### Platform-Specific Integrity Commands

```bash
# WordPress — verify core file integrity
wp core verify-checksums

# WordPress — verify plugin file integrity
wp plugin verify-checksums --all

# Drupal — check core requirements (includes file integrity)
drush core:requirements --severity=2

# Generic — compare against clean distribution
diff -rq /path/to/clean-cms /path/to/deployed-cms --exclude=sites --exclude=wp-content
```

### What to Do Instead of Modifying Core

Every CMS platform provides extension mechanisms specifically designed to alter core behavior without modifying core files:

| Need | Wrong approach | Right approach |
|------|---------------|----------------|
| Change how a feature works | Edit the core file that implements it | Use hooks, filters, events, or alter functions provided by the CMS |
| Fix a core bug | Patch the core file directly | Apply a managed patch (Composer patches, documented patch files) with an upstream issue link. Remove when the fix is released. |
| Change how a template renders | Edit the core template file | Use the CMS's template override mechanism (child themes, template suggestions) |
| Add functionality to core | Add code to a core module/plugin file | Create a custom extension that hooks into the relevant extension point |
| Change core configuration | Edit core config files | Use the CMS's configuration system or settings API |

### Managed Patching (When You Must)

Sometimes a core or contributed extension bug genuinely blocks your project and the fix isn't released yet. In that case, use a **managed patch** — not a direct modification:

1. **File the issue upstream** (or find the existing one). Get the official patch or create one.
2. **Apply via a patch manager** (e.g., `cweagans/composer-patches` for Composer-based CMS platforms). The patch is version-controlled, documented, and visible.
3. **Document in an ADR** (§7) — what was patched, why, the upstream issue link, and a review date.
4. **Track for removal.** When the upstream fix is released, remove the patch and update. Stale patches that outlive their upstream fix are another form of invisible modification.

### Core Integrity Audit Checklist

- [ ] CMS core files verified against official checksums (no modifications detected).
- [ ] Contributed/third-party extension files verified against their distribution (no modifications).
- [ ] Any managed patches documented with upstream issue links and review dates.
- [ ] CI or deployment pipeline includes core integrity verification.
- [ ] Team/agents instructed that core modification is a blocked practice.

---

## Common CMS Anti-Patterns

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **"Just install an extension"** | Solving every requirement with a third-party extension instead of evaluating whether a small amount of custom code would suffice. Each extension adds attack surface, performance overhead, and maintenance burden. | Evaluate before installing (§25.1). If the functionality is simple and specific to your site, custom code is often better. |
| **Extension bloat** | 30+ active extensions for 10 actual features. Many overlap, creating conflicts and performance drag. | Audit the inventory quarterly (§25.1). Fewer extensions = smaller attack surface + fewer update cycles. |
| **Modifying CMS core or third-party extension files** | Updates overwrite the changes (or the team avoids updates, leaving known vulnerabilities unpatched). Modifications are invisible to future developers and AI agents. Breaks upgrade paths. | Use hooks, events, template overrides, or managed patches (§25.9). Run integrity verification to detect modifications. |
| **No staging environment** | Testing changes directly in production. "It's just a small change" until it takes the site down. | Maintain a staging environment that mirrors production (§25.6). Test all changes there first. |
| **Configuration drift** | Making configuration changes directly in production that aren't captured in code. The next deployment either overwrites them or conflicts. | All configuration changes happen in development, get exported/committed, and deploy through the pipeline (§25.4). |
| **Ignoring update notifications** | Letting extensions and core fall behind on updates. Every unpatched version is a known vulnerability waiting to be exploited. | Apply security updates within 48 hours. Batch other updates weekly (§25.2). |

---

## Mapping to Core Guardrail Sections

| Core Section | CMS Equivalent |
|---|---|
| §2 Specs | §25.4 Content/configuration/code separation, extension architecture |
| §3 Testing | §25.8 CMS testing layers |
| §3 Type Assumptions | §25.3 Security fundamentals — input sanitization, output escaping |
| §6 Consistency | §25.5 Theme architecture, asset loading standards |
| §7 ADRs | Extension selection decisions (§25.1), architecture splits (§25.5) |
| §8 Acknowledged Gaps | §25.1 Abandoned extension risks, known conflicts |
| §11 File Size | §25.5 Template decomposition |
| §12 Change Tracking | §25.6 Deployment pipeline |
| §13 Dead Code | §25.1 Extension inventory — unused extensions are dead code with attack surface |
| §6 Consistency | §25.9 Core integrity — no modifications to core or third-party files |
| §4 Observability | §25.7 Production monitoring — error logging, uptime, performance |

---

## CMS Checklist (extends §15)

### Before Every CMS Change
- [ ] Output escaping verified for all dynamic data in templates (§25.3).
- [ ] CSRF protection present on all forms; handlers verify it (§25.3).
- [ ] Permission checks present on all privileged actions (§25.3).
- [ ] Database queries use parameterized queries or CMS API (§25.3).
- [ ] Assets loaded via CMS asset system, conditionally where possible (§25.5).

### Before Every Extension Change
- [ ] Extension inventory updated — purpose, version, alternatives documented (§25.1).
- [ ] New extensions evaluated against selection criteria (§25.1).
- [ ] Extension tested in staging after activation (§25.1).
- [ ] Extension update tested in staging before production (§25.2).

### Before Every CMS Change (additional)
- [ ] No core or third-party extension files modified — use hooks, overrides, or managed patches (§25.9).

### Periodic
- [ ] Core and extension file integrity verified against official checksums (weekly) (§25.9).
- [ ] Security scan run against all extensions (weekly) (§25.8).
- [ ] Extension inventory reviewed — abandoned extensions flagged (quarterly) (§25.1).
- [ ] Managed patches reviewed — remove patches where upstream fix is released (quarterly) (§25.9).
- [ ] Core and extension updates applied (weekly for security, batched for others) (§25.2).
- [ ] Backup verification — confirm backups are restorable, not just present (monthly).
- [ ] Error logs reviewed — recurring errors identified and addressed (weekly) (§25.7).
- [ ] Scheduled task health verified (monthly) (§25.7).
