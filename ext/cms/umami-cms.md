# CMS Guardrails

**Extension of [Rapid Development Guardrails](../../umami.md) — §25**

This extension covers practices common to all content management systems — WordPress, Drupal, and others. CMS platforms share a distinct risk profile: a large ecosystem of third-party extensions (plugins, modules, themes), a culture of composing sites from pre-built components, content/configuration/code boundaries that blur easily, and production environments where non-developers make changes through admin UIs.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CMS layer. Then apply the platform-specific part below (§20 WordPress, §21 Drupal) for implementation details — only when that platform is present.

**Adopt when (§0.9 default-deny):** the CMS site is production-facing with third-party extensions AND either non-developers change it through admin UIs or an update/extension has already broken it. A static brochure site rebuilt from source does not warrant this extension.
**Cost profile:** Operator-required · Days initial (inventory, staging, integrity checks) + Recurring discipline (update cadence).
**Kill criterion:** retire any practice below that has produced no finding, no prevented incident, and no consulted artifact across 2 consecutive review cycles (§0.9 retirement pass).

> **Platform variants (v3.1):** The WordPress (§20) and Drupal (§21) platform variants live in this file as of v3.1 — they were separate files in v3.0. Each applies only when that platform is present; the §0.9 gate above covers them (no separate ledger entry). Section numbers §20 and §21 are retained — existing cross-references resolve unchanged.

**Loading order:** A CMS project loads two layers:
1. [umami.md](../../umami.md) — core guardrails
2. This file (`umami-cms.md`) — CMS-generic practices (§25) plus the platform part that matches the site (§20 WordPress or §21 Drupal)

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

**This checklist is a menu, not a calendar** — schedule only the items whose §0.9 trigger has fired for this project; an unrun scheduled check is worse than an unscheduled one (it reads as coverage that doesn't exist, per the §22 compliance-theater anti-pattern).

- [ ] Core and extension file integrity verified against official checksums (weekly) (§25.9).
- [ ] Security scan run against all extensions (weekly) (§25.8).
- [ ] Extension inventory reviewed — abandoned extensions flagged (quarterly) (§25.1).
- [ ] Managed patches reviewed — remove patches where upstream fix is released (quarterly) (§25.9).
- [ ] Core and extension updates applied (weekly for security, batched for others) (§25.2).
- [ ] Backup verification — confirm backups are restorable, not just present (monthly).
- [ ] Error logs reviewed — recurring errors identified and addressed (weekly) (§25.7).
- [ ] Scheduled task health verified (monthly) (§25.7).

---

## 20. WordPress (platform variant — folded into this file at v3.1)

This part covers WordPress-specific development — themes, plugins, and site builds. It implements the shared CMS guardrails (§25) for WordPress; apply it only when the platform is WordPress. The §0.9 gate at the top of this file covers it — no separate ledger entry. For general CMS practices (extension audits, update management, security fundamentals, deployment discipline), see §25 above.

### 20.1 WordPress Security Implementation

WordPress templates have **no auto-escaping**. Unlike Twig-based CMS platforms, every piece of dynamic output must be manually escaped. This is the single most important WordPress-specific discipline. §25.3 covers the general principles; these are the WordPress rules:

- **Never echo unescaped data. No exceptions.** Treat every `echo $variable` without an escaping function as a bug. Escape for the output context — `esc_html()` for HTML content, `esc_attr()` for attributes, `esc_url()` for URLs, `esc_js()` for JavaScript, `wp_kses()` / `wp_kses_post()` where limited HTML is allowed, `esc_html__()` / `esc_attr__()` for translated strings. Full function-by-context tables: the [official escaping reference](https://developer.wordpress.org/apis/security/escaping/).
- **Sanitize input at the boundary with the type-appropriate function** — `sanitize_text_field()`, `sanitize_email()`, `esc_url_raw()` (for storage), `sanitize_file_name()`, `absint()`; map over arrays (`array_map( 'sanitize_text_field', $array )`). Full table: the [official sanitization reference](https://developer.wordpress.org/apis/security/sanitizing/). Never trust client-side validation alone (§25.3).
- **Every form submission and AJAX handler verifies a nonce before any processing** (WordPress's CSRF protection, per §25.3): `wp_nonce_field()` in the form, `wp_verify_nonce()` at the top of the handler, `check_ajax_referer()` for AJAX.
- **Check capabilities, not roles** (per §25.3): `current_user_can( 'manage_options' )` is correct; checking `$user->role === 'administrator'` is fragile and bypassable.
- **Always use `$wpdb->prepare()` for SQL with user input. No exceptions.** Prefer WordPress API functions (`WP_Query`, `get_posts()`, `get_option()`) over direct database queries — the API handles escaping and caching (per §25.3).
- **File uploads:** validate MIME type server-side (not just extension) with `wp_check_filetype()` and restrict to expected types; never allow PHP file uploads; store uploads via `wp_handle_upload()` — never custom directories without `.htaccess` protection.

### 20.2 WordPress Plugin Specifics

The general extension audit framework is in §25.1. This section covers WordPress-specific plugin concerns.

**Plugin-specific selection criteria** — in addition to the §25.1 criteria:

- [ ] **WordPress.org repo vs. premium** — WordPress.org plugins get basic review; premium plugins may not.
- [ ] **WPScan vulnerability history** — search the WPScan Vulnerability Database for past CVEs.
- [ ] **Asset loading behavior** — does it load CSS/JS on every page, or only where needed?

**Plugin conflict testing.** Plugin conflicts are the most common source of WordPress bugs. Two plugins hooking the same filter with incompatible transforms create bugs that are invisible until they collide.

- Enable one plugin at a time in staging. Test core functionality after each activation.
- After enabling all plugins, run a full regression pass on critical user flows.
- When a conflict is found, use `remove_filter()` / `remove_action()` to unhook the conflicting callback — never edit plugin files directly.

**Core and plugin update specifics** — in addition to the §25.2 update framework:

- **Core minor updates** (e.g., 6.5.1 → 6.5.2): Auto-update is generally safe for security patches.
- **Core major updates** (e.g., 6.5 → 6.6): Check plugin compatibility announcements before updating.
- **Theme updates**: If using a child theme (you should be), parent theme updates are safe. Test in staging.

### 20.3 Theme Architecture

**Child theme rule: never edit a parent theme directly.** Parent theme updates will overwrite your changes (§25.5 covers the principle). All customizations live in a child theme — its `style.css`, its `functions.php`, and template overrides under `template-parts/`.

**functions.php discipline.** `functions.php` is the most commonly bloated file in WordPress. Apply §11 (File Size Budgets):

- Split into focused includes: `inc/custom-post-types.php`, `inc/enqueue.php`, `inc/customizer.php`.
- `functions.php` itself should only contain `require` statements.
- Each include file has a single responsibility.

### 20.4 Hook System Discipline

WordPress's hook system (actions and filters) is its primary extension mechanism — and its primary source of debugging complexity.

#### Rules

- **Prefix everything.** All custom functions, hooks, and global variables must use a project prefix. `get_user_data()` will collide; use `myproject_get_user_data()`.
- **Document hook priority.** When using a non-default priority (not 10), comment why: `add_filter( 'the_content', 'myproject_filter', 20 ); // After shortcodes process at priority 11`.
- **Never remove core hooks without an ADR** (§7). Removing a core hook can break expectations for other plugins and future updates.
- **Use `has_filter()` / `has_action()` defensively** before removing hooks or relying on filter output.

#### Debugging Hooks

1. **Identify which hooks fire.** Use Query Monitor plugin or `add_action( 'all', function( $tag ) { error_log( $tag ); } );` temporarily.
2. **Check priority order.** Multiple callbacks on the same hook execute in priority order.
3. **Check return values.** Filters must return a value. A filter callback that forgets to `return` silently nullifies the data.

### 20.5 WordPress Performance

#### wp_options Bloat

The `wp_options` table is loaded on every page request (autoloaded rows). Plugins that store large serialized arrays with `autoload = 'yes'` slow down every page.

- Query autoloaded options size: `SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload = 'yes';`
- Anything over 1MB of autoloaded data is a performance problem.
- Transient data (`_transient_*`) should have expiration times. Orphaned transients accumulate indefinitely.

#### Query Performance

- **Use `WP_Query` with specific fields.** `'fields' => 'ids'` when you only need IDs. `'no_found_rows' => true` when you don't need pagination counts.
- **Avoid `meta_query` on unindexed meta keys** in large databases. Consider custom tables for high-query-volume data.
- **Use object caching** (Redis, Memcached) for production sites.
- **Use the Transients API** for caching expensive operations. Always set an expiration.

#### Asset Loading

- Always use `wp_enqueue_script()` / `wp_enqueue_style()` on the `wp_enqueue_scripts` hook — never inline tags (per §25.5).
- Load assets conditionally — only on pages that need them (gate on conditionals like `is_singular( 'product' )`).
- Specify dependencies explicitly.
- Use versioning for cache busting.

### 20.6 WordPress Deployment

#### Version Control (WordPress-specific, extends §25.6)

| Include | Exclude |
|---------|---------|
| Custom themes (child theme) | `wp-content/uploads/` (user media) |
| Custom plugins | `wp-config.php` with production secrets |
| `wp-config.php` template (with placeholders) | `.htaccess` (environment-specific) |
| `composer.json` / `composer.lock` (if using Composer) | Database dumps |

#### Environment Configuration

- Set `WP_ENVIRONMENT_TYPE` (`local` / `development` / `staging` / `production`) in `wp-config.php` and branch on `wp_get_environment_type()`.
- Debug flags (`WP_DEBUG`, `WP_DEBUG_LOG`, `WP_DEBUG_DISPLAY`, `SCRIPT_DEBUG`) are enabled in development only.
- Production always defines `DISALLOW_FILE_EDIT` (the §25.3 "code editing from admin panel disabled" rule).

#### Database URL Rewriting

```bash
# WP-CLI — search-replace for environment migration
wp search-replace 'https://staging.example.com' 'https://example.com' --all-tables --dry-run
```

Always `--dry-run` first. Always back up before production. Use `--all-tables` to catch serialized data. Never manually edit serialized data (per §25.6).

### 20.7 WordPress Testing Layers

Extends §25.8 with WordPress-specific tooling:

| Layer | Tool |
|-------|------|
| PHP lint | `php -l`, PHP_CodeSniffer with WordPress standards |
| Coding standards | PHPCS with `WordPress` ruleset |
| Security scan | WPScan, Wordfence, Sucuri |
| Unit tests | PHPUnit + `WP_UnitTestCase` |
| E2E tests | Playwright, Cypress |
| Performance | Query Monitor, Lighthouse, GTmetrix |

**Minimum viable WordPress CI:** PHP lint + PHPCS with WordPress standards + security scan + unit tests on every PR.

### 20.8 WordPress Production Monitoring

Extends §25.7 with WordPress-specific implementation:

#### Error Logging

In production: `WP_DEBUG` and `WP_DEBUG_LOG` enabled (errors written to `wp-content/debug.log`), `WP_DEBUG_DISPLAY` disabled and `display_errors` off — errors are logged, never shown to visitors (per §25.7).

#### WP-Cron

WordPress's pseudo-cron depends on site visits (§25.7). For reliable scheduling, configure a real system cron:
```
*/5 * * * * curl -s https://example.com/wp-cron.php > /dev/null 2>&1
```

#### Monitoring Tools

- **Query Monitor** — query count, hook execution, asset loading (development/staging).
- **Site Health API** — `/wp-json/wp-site-health/v1/tests/` for automated health checks.
- **Object cache hit rate** — if using Redis/Memcached, monitor hit rates.

### WordPress-Specific Anti-Patterns

These are in addition to the common CMS anti-patterns in §25.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Everything in functions.php** | A 2,000-line file with post types, shortcodes, AJAX handlers, and business logic. | Decompose into focused includes (§20.3). |
| **Direct database queries for things APIs handle** | `$wpdb->query()` for operations that `WP_Query` or `get_option()` handle. Bypasses caching, escaping, hooks. | Use WordPress API functions first (§20.1, §20.5). |

### WordPress Checklist (extends §25 CMS Checklist)

#### Before Every WordPress Change
- [ ] Output escaping verified on every `echo` of dynamic data (§20.1).
- [ ] Nonce fields present on all forms; handlers verify them (§20.1).
- [ ] Capability checks present on all privileged actions (§20.1).
- [ ] Database queries use `$wpdb->prepare()` or WordPress API functions (§20.1).
- [ ] Custom functions and hooks use project prefix (§20.4).
- [ ] Assets loaded conditionally with `wp_enqueue_*()` (§20.5).

---

## 21. Drupal (platform variant — folded into this file at v3.1)

This part covers Drupal-specific development — custom and contributed modules, themes, configuration management, and site builds. It implements the shared CMS guardrails (§25) for Drupal; apply it only when the platform is Drupal. The §0.9 gate at the top of this file covers it — no separate ledger entry. For general CMS practices (extension audits, update management, security fundamentals, deployment discipline), see §25 above.

Drupal differs from other CMS platforms in key architectural ways: Symfony-based request handling, Twig auto-escaping, a formal configuration management system, a sophisticated caching layer, and Composer-based dependency management. These differences require distinct guardrails.

### 21.1 Drupal Security Implementation

Drupal has a dedicated Security Team and a formal Security Advisory (SA) process. The platform's security posture is strong by default — but only if developers use the APIs correctly. See §25.3 for general CMS security principles; this section covers Drupal's specific implementation.

#### Twig Auto-Escaping — What It Does and Doesn't Cover

Drupal's Twig templates auto-escape by default. `{{ variable }}` is safe in most contexts. However:

| Context | Auto-escaped? | What to do |
|---------|--------------|------------|
| HTML content / attributes | Yes | Safe by default |
| URLs in `href` / `src` | Partially | Use `{{ url }}` or `{{ path() }}`. Validate user URLs for `javascript:` injection |
| Raw HTML (`{{ variable\|raw }}`) | **No** | Avoid `\|raw` unless already sanitized. Every `\|raw` is a potential XSS vector |
| JavaScript context | **No** | Use `drupalSettings` to pass data from PHP to JS — never inject into `<script>` |
| CSS context | **No** | Never allow user input in inline styles |

**Rule: Audit every use of `|raw` in templates.** Each one needs a comment explaining why it's safe.

#### Form API and CSRF Protection

Drupal's Form API handles CSRF tokens automatically. The risk is bypassing it:
- **Always use the Form API** — don't build raw HTML forms.
- **Custom AJAX callbacks** must use proper access callbacks and CSRF validation.
- **Custom routes** must define access requirements:

```yaml
# CORRECT: access check defined
mymodule.admin_page:
  path: '/admin/mymodule/settings'
  defaults:
    _controller: '\Drupal\mymodule\Controller\AdminController::settings'
  requirements:
    _permission: 'administer mymodule'
```

Every route must have `_permission`, `_role`, `_access`, or a custom `_access_check` service.

#### Entity Query Access

**Always call `->accessCheck(TRUE)` on entity queries** unless you explicitly need to bypass access (admin operations, cron). Drupal 10+ requires this call.

#### Database Security

- **Use the Database API** — `\Drupal::database()->select()`, `->insert()`, etc. It handles parameterization.
- **For raw SQL**, use placeholders: `$db->query('SELECT * FROM {table} WHERE uid = :uid', [':uid' => $uid])`.
- **Entity queries** (`\Drupal::entityQuery()`) are preferred for entity data — they respect access control.

### 21.2 Drupal Module Specifics

The general extension audit framework is in §25.1. This section covers Drupal-specific module concerns.

#### Security Coverage

Drupal's Security Team reviews opted-in modules — a significant quality signal:

- **Covered modules** (green shield on drupal.org): Security Team monitors and coordinates disclosure. Prefer these.
- **Uncovered modules**: No Security Team oversight. Audit the code yourself or document the risk in §8.

#### Module-Specific Selection Criteria

In addition to §25.1:
- [ ] **Security coverage** — green shield on drupal.org?
- [ ] **Drupal version compatibility** — stable release for your major version?
- [ ] **Dependency chain** — what other modules does it require?
- [ ] **Existing core solutions** — Views, Layout Builder, Media, Content Moderation are all core. Check before adding contrib.

#### Update Specifics

In addition to §25.2:
- **Security advisories published Wednesdays.** Subscribe to the mailing list.
- **Use Upgrade Status module** for major version upgrades (e.g., 10 → 11).

```bash
# Check for available updates
composer outdated drupal/*

# Targeted update
composer update drupal/module_name --with-dependencies
drush updatedb
drush cache:rebuild
```

### 21.3 Configuration Management

Drupal's configuration management system is one of its strongest features — and one of the most common sources of deployment problems when misused. Configuration is exportable as YAML files that can be version-controlled.

#### The Configuration Workflow

```
Development → Export config → Commit to git → Deploy → Import config
```

```bash
drush config:export    # Export to sync directory
git diff config/sync/  # Review changes
drush config:import    # Import on target environment
```

#### Rules

- **All configuration changes happen in code, not in production.** Never make config changes directly in production.
- **The `config/sync/` directory is version-controlled.** This is your configuration source of truth.
- **Review config diffs before committing.** `drush config:export` may include unrelated changes.
- **Never edit YAML config files by hand** unless you understand the schema. Use the admin UI, then export.
- **Config split for environment-specific settings.** Use Config Split to separate dev-only modules (Devel, Kint) from production config.

#### Config vs. Content

| Configuration (version-controlled) | Content (database only) |
|-------------------------------------|------------------------|
| Content types, fields, view modes | Nodes, taxonomy terms, media entities |
| Views, blocks, menus (structure) | Menu links (content), block content |
| Permissions, roles | User accounts |
| Module settings, workflows | Webform submissions, log entries |

### 21.4 Caching Architecture

Drupal's caching system uses cache tags, cache contexts, and cache max-age for fine-grained control. Misusing or bypassing caching creates performance problems or stale content.

#### Cache Metadata

Every render array should declare its cacheability:

| Property | What it controls | Example |
|----------|-----------------|---------|
| **Cache tags** | What data does this depend on? | `node:42`, `user:1`, `config:system.site` |
| **Cache contexts** | What context varies the output? | `user.roles`, `url.query_args`, `languages` |
| **Cache max-age** | How long is this valid? | `0` (never), `3600` (1 hour), `Cache::PERMANENT` |

```php
$build['content'] = [
  '#markup' => $this->t('Hello, @name', ['@name' => $user->getDisplayName()]),
  '#cache' => [
    'tags' => ['user:' . $user->id()],
    'contexts' => ['user'],
    'max-age' => 3600,
  ],
];
```

#### Rules

- **Never set `max-age` to 0 as a shortcut.** It bubbles up and can disable page caching entirely. Use cache tags instead.
- **Always declare cache tags** on render arrays displaying entity data.
- **Use cache contexts** when output varies by user role, language, URL, etc.
- **Debug with `http.response.debug_cacheability_headers`** in `development.services.yml`.

### 21.5 Theming and Render System

Drupal's render arrays → Twig templates pipeline is the correct extension point. Bypassing it bypasses caching, access control, and alter hooks.

#### Rules

- **Never echo/print directly.** Return render arrays. Let Drupal's render pipeline handle output.
- **Use render arrays, not HTML strings.** `'#markup'` is a last resort. Use `'#theme'`, `'#type'`, or custom theme hooks.
- **Preprocess functions add variables to templates** — they should not contain business logic.
- **Custom theme hooks** (`hook_theme()`) for reusable template patterns.

#### Template Override Discipline

- Use Drupal's template naming conventions. Enable Twig debugging for template suggestions.
- **Never modify templates in contributed themes or modules** (per §25.5). Override in your custom theme.
- All CSS and JavaScript declared in `*.libraries.yml`. Attach libraries to render arrays.

### 21.6 Coding Standards and Service Architecture

#### Coding Standards

```bash
phpcs --standard=Drupal,DrupalPractice web/modules/custom/
phpcbf --standard=Drupal,DrupalPractice web/modules/custom/
```

Enforce in CI. Coding standards violations should fail the build.

#### Service Architecture

- **Controllers**: thin — delegate to services.
- **Services**: business logic, defined in `mymodule.services.yml`, injected via constructors.
- **Event subscribers**: replace many hooks.
- **Plugins** (Blocks, Fields, Formatters): annotated, auto-discovered.

**Anti-patterns:**
- Business logic in `.module` files → use services.
- Static `\Drupal::service()` in services/controllers → use dependency injection.
- God services → one service = one responsibility.

#### Update Hooks

Schema and data migrations use `hook_update_N()`:
- Numbers are sequential and never reused.
- Each has a descriptive docblock.
- Must be idempotent. Use `$sandbox` for large data migrations.

### 21.7 Drupal Deployment Pipeline

#### Recommended Flow

```bash
drush state:set system.maintenance_mode 1   # Maintenance mode (optional)
git pull origin main
composer install --no-dev --optimize-autoloader
drush updatedb -y
drush config:import -y
drush cache:rebuild
drush state:set system.maintenance_mode 0
```

#### Composer Discipline

- `composer.lock` is committed to git.
- Use `composer require` to add modules — never download manually.
- Use `composer update drupal/module_name --with-dependencies` — never bare `composer update`.
- Use `cweagans/composer-patches` for patches (§25.9 managed patching). Document each with an issue link. Remove when upstream fixes land.

#### Drush as Operational Standard

All repeatable operations should be Drush commands:

```bash
drush cr          # Cache rebuild
drush cex         # Config export
drush cim         # Config import
drush updb        # Database updates
drush uli         # One-time login link
drush sql:dump    # Database backup
```

**Rule: If you can do it with Drush, do it with Drush.** Manual admin clicks are unrepeatable and undocumented.

### 21.8 Drupal Testing Layers

Extends §25.8 with Drupal-specific tooling:

| Layer | Tool |
|-------|------|
| Coding standards | PHPCS with `Drupal` + `DrupalPractice` |
| Static analysis | PHPStan with `phpstan-drupal` |
| Unit tests | PHPUnit (`UnitTestCase`) |
| Kernel tests | PHPUnit (`KernelTestBase`) |
| Functional tests | PHPUnit (`BrowserTestBase`) |
| JavaScript tests | Nightwatch.js (core) or Cypress |
| Security scan | `drush pm:security` / Drupal Security Advisories |
| Config validation | `drush config:status` |
| Performance | Webprofiler module, Blackfire |

**Minimum viable Drupal CI:** Coding standards + static analysis + unit/kernel tests + `drush config:status` + security scan on every PR.

### 21.9 Drupal Production Monitoring

Extends §25.7 with Drupal-specific implementation:

#### Logging

**Use Syslog in production, not Database Logging.** `dblog` writes to the database — every log write is a database insert competing with content queries.

```bash
drush pm:install syslog
drush pm:uninstall dblog
```

Route syslog to centralized logging (Loki, Elasticsearch, CloudWatch). Use `watchdog` severity levels consistently.

#### Health Monitoring

- **`drush core:requirements --severity=2`** — automated status report checking.
- **Cron**: use external trigger (`*/5 * * * * drush cron`), not poor-man's-cron.
- **Cache hit rates**: use Webprofiler (dev) to identify uncacheable responses.

### Drupal-Specific Anti-Patterns

These are in addition to the common CMS anti-patterns in §25.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Config changes in production** | Next `drush config:import` overwrites them, or config drift makes imports fail. | All config: dev → export → commit → deploy → import (§21.3). |
| **Bypassing the render system** | Echoing HTML bypasses caching, access control, alter hooks, and auto-escaping. | Return render arrays (§21.5). |
| **Untargeted `composer update`** | Updates everything simultaneously — impossible to isolate regressions. | `composer update drupal/module_name --with-dependencies` (§21.7). |
| **`max-age: 0` as a shortcut** | Disables page caching entirely (bubbles up). | Use cache tags (§21.4). |
| **Static `\Drupal::` calls in services** | Makes code untestable, hides dependencies. | Dependency injection (§21.6). |

### Drupal Checklist (extends §25 CMS Checklist)

#### Before Every Drupal Change
- [ ] Routes have access requirements, no unescaped `|raw` without justification, entity queries use `->accessCheck()` (§21.1).
- [ ] Configuration exported and committed after admin UI changes (§21.3).
- [ ] Cache metadata declared on all render arrays with entity data (§21.4).
- [ ] Coding standards pass: `phpcs --standard=Drupal,DrupalPractice` (§21.6).
- [ ] Custom services use dependency injection, not static `\Drupal::` calls (§21.6).

#### Before Every Deployment
- [ ] `drush config:status` shows no unexpected differences (§21.3).
- [ ] `composer.lock` committed and matches production (§21.7).
- [ ] Database updates tested in staging (§21.7).
- [ ] Config import tested in staging (§21.7).
- [ ] Security advisories reviewed for all contrib modules (§21.2).
