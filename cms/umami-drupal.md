# Drupal Guardrails

**Extension of [CMS Guardrails](../umami-cms.md) (§25), which extends [Rapid Development Guardrails](../umami.md) — §21**

This extension covers Drupal-specific development — custom and contributed modules, themes, configuration management, and site builds. It builds on the shared CMS guardrails (§25) with Drupal-specific implementation details. For general CMS practices (extension audits, update management, security fundamentals, deployment discipline), see §25.

Drupal differs from other CMS platforms in key architectural ways: Symfony-based request handling, Twig auto-escaping, a formal configuration management system, a sophisticated caching layer, and Composer-based dependency management. These differences require distinct guardrails.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CMS / Drupal layer.

**Loading order:** Load all three layers:
1. [`umami.md`](../umami.md) — core guardrails
2. [`umami-cms.md`](../umami-cms.md) — CMS-generic practices (§25)
3. This file — Drupal-specific implementation

---

## 21.1 Drupal Security Implementation

Drupal has a dedicated Security Team and a formal Security Advisory (SA) process. The platform's security posture is strong by default — but only if developers use the APIs correctly. See §25.3 for general CMS security principles; this section covers Drupal's specific implementation.

### Twig Auto-Escaping — What It Does and Doesn't Cover

Drupal's Twig templates auto-escape by default. `{{ variable }}` is safe in most contexts. However:

| Context | Auto-escaped? | What to do |
|---------|--------------|------------|
| HTML content / attributes | Yes | Safe by default |
| URLs in `href` / `src` | Partially | Use `{{ url }}` or `{{ path() }}`. Validate user URLs for `javascript:` injection |
| Raw HTML (`{{ variable\|raw }}`) | **No** | Avoid `\|raw` unless already sanitized. Every `\|raw` is a potential XSS vector |
| JavaScript context | **No** | Use `drupalSettings` to pass data from PHP to JS — never inject into `<script>` |
| CSS context | **No** | Never allow user input in inline styles |

**Rule: Audit every use of `|raw` in templates.** Each one needs a comment explaining why it's safe.

### Form API and CSRF Protection

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

### Entity Query Access

**Always call `->accessCheck(TRUE)` on entity queries** unless you explicitly need to bypass access (admin operations, cron). Drupal 10+ requires this call.

### Database Security

- **Use the Database API** — `\Drupal::database()->select()`, `->insert()`, etc. It handles parameterization.
- **For raw SQL**, use placeholders: `$db->query('SELECT * FROM {table} WHERE uid = :uid', [':uid' => $uid])`.
- **Entity queries** (`\Drupal::entityQuery()`) are preferred for entity data — they respect access control.

---

## 21.2 Drupal Module Specifics

The general extension audit framework is in §25.1. This section covers Drupal-specific module concerns.

### Security Coverage

Drupal's Security Team reviews opted-in modules — a significant quality signal:

- **Covered modules** (green shield on drupal.org): Security Team monitors and coordinates disclosure. Prefer these.
- **Uncovered modules**: No Security Team oversight. Audit the code yourself or document the risk in §8.

### Module-Specific Selection Criteria

In addition to §25.1:
- [ ] **Security coverage** — green shield on drupal.org?
- [ ] **Drupal version compatibility** — stable release for your major version?
- [ ] **Dependency chain** — what other modules does it require?
- [ ] **Existing core solutions** — Views, Layout Builder, Media, Content Moderation are all core. Check before adding contrib.

### Update Specifics

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

---

## 21.3 Configuration Management

Drupal's configuration management system is one of its strongest features — and one of the most common sources of deployment problems when misused. Configuration is exportable as YAML files that can be version-controlled.

### The Configuration Workflow

```
Development → Export config → Commit to git → Deploy → Import config
```

```bash
drush config:export    # Export to sync directory
git diff config/sync/  # Review changes
drush config:import    # Import on target environment
```

### Rules

- **All configuration changes happen in code, not in production.** Never make config changes directly in production.
- **The `config/sync/` directory is version-controlled.** This is your configuration source of truth.
- **Review config diffs before committing.** `drush config:export` may include unrelated changes.
- **Never edit YAML config files by hand** unless you understand the schema. Use the admin UI, then export.
- **Config split for environment-specific settings.** Use Config Split to separate dev-only modules (Devel, Kint) from production config.

### Config vs. Content

| Configuration (version-controlled) | Content (database only) |
|-------------------------------------|------------------------|
| Content types, fields, view modes | Nodes, taxonomy terms, media entities |
| Views, blocks, menus (structure) | Menu links (content), block content |
| Permissions, roles | User accounts |
| Module settings, workflows | Webform submissions, log entries |

---

## 21.4 Caching Architecture

Drupal's caching system uses cache tags, cache contexts, and cache max-age for fine-grained control. Misusing or bypassing caching creates performance problems or stale content.

### Cache Metadata

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

### Rules

- **Never set `max-age` to 0 as a shortcut.** It bubbles up and can disable page caching entirely. Use cache tags instead.
- **Always declare cache tags** on render arrays displaying entity data.
- **Use cache contexts** when output varies by user role, language, URL, etc.
- **Debug with `http.response.debug_cacheability_headers`** in `development.services.yml`.

---

## 21.5 Theming and Render System

Drupal's render arrays → Twig templates pipeline is the correct extension point. Bypassing it bypasses caching, access control, and alter hooks.

### Rules

- **Never echo/print directly.** Return render arrays. Let Drupal's render pipeline handle output.
- **Use render arrays, not HTML strings.** `'#markup'` is a last resort. Use `'#theme'`, `'#type'`, or custom theme hooks.
- **Preprocess functions add variables to templates** — they should not contain business logic.
- **Custom theme hooks** (`hook_theme()`) for reusable template patterns.

### Template Override Discipline

- Use Drupal's template naming conventions. Enable Twig debugging for template suggestions.
- **Never modify templates in contributed themes or modules.** Override in your custom theme.
- All CSS and JavaScript declared in `*.libraries.yml`. Attach libraries to render arrays.

---

## 21.6 Coding Standards and Service Architecture

### Coding Standards

```bash
phpcs --standard=Drupal,DrupalPractice web/modules/custom/
phpcbf --standard=Drupal,DrupalPractice web/modules/custom/
```

Enforce in CI. Coding standards violations should fail the build.

### Service Architecture

- **Controllers**: thin — delegate to services.
- **Services**: business logic, defined in `mymodule.services.yml`, injected via constructors.
- **Event subscribers**: replace many hooks.
- **Plugins** (Blocks, Fields, Formatters): annotated, auto-discovered.

**Anti-patterns:**
- Business logic in `.module` files → use services.
- Static `\Drupal::service()` in services/controllers → use dependency injection.
- God services → one service = one responsibility.

### Update Hooks

Schema and data migrations use `hook_update_N()`:
- Numbers are sequential and never reused.
- Each has a descriptive docblock.
- Must be idempotent. Use `$sandbox` for large data migrations.

---

## 21.7 Drupal Deployment Pipeline

### Recommended Flow

```bash
drush state:set system.maintenance_mode 1   # Maintenance mode (optional)
git pull origin main
composer install --no-dev --optimize-autoloader
drush updatedb -y
drush config:import -y
drush cache:rebuild
drush state:set system.maintenance_mode 0
```

### Composer Discipline

- `composer.lock` is committed to git.
- Use `composer require` to add modules — never download manually.
- Use `composer update drupal/module_name --with-dependencies` — never bare `composer update`.
- Use `cweagans/composer-patches` for patches. Document each with an issue link. Remove when upstream fixes land.

### Drush as Operational Standard

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

---

## 21.8 Drupal Testing Layers

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

---

## 21.9 Drupal Production Monitoring

Extends §25.7 with Drupal-specific implementation:

### Logging

**Use Syslog in production, not Database Logging.** `dblog` writes to the database — every log write is a database insert competing with content queries.

```bash
drush pm:install syslog
drush pm:uninstall dblog
```

Route syslog to centralized logging (Loki, Elasticsearch, CloudWatch). Use `watchdog` severity levels consistently.

### Health Monitoring

- **`drush core:requirements --severity=2`** — automated status report checking.
- **Cron**: use external trigger (`*/5 * * * * drush cron`), not poor-man's-cron.
- **Cache hit rates**: use Webprofiler (dev) to identify uncacheable responses.

---

## Drupal-Specific Anti-Patterns

These are in addition to the common CMS anti-patterns in §25.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Config changes in production** | Next `drush config:import` overwrites them, or config drift makes imports fail. | All config: dev → export → commit → deploy → import (§21.3). |
| **Bypassing the render system** | Echoing HTML bypasses caching, access control, alter hooks, and auto-escaping. | Return render arrays (§21.5). |
| **Untargeted `composer update`** | Updates everything simultaneously — impossible to isolate regressions. | `composer update drupal/module_name --with-dependencies` (§21.7). |
| **`max-age: 0` as a shortcut** | Disables page caching entirely (bubbles up). | Use cache tags (§21.4). |
| **Static `\Drupal::` calls in services** | Makes code untestable, hides dependencies. | Dependency injection (§21.6). |

---

## Drupal Checklist (extends §25 CMS Checklist)

### Before Every Drupal Change
- [ ] Routes have access requirements, no unescaped `|raw` without justification, entity queries use `->accessCheck()` (§21.1).
- [ ] Configuration exported and committed after admin UI changes (§21.3).
- [ ] Cache metadata declared on all render arrays with entity data (§21.4).
- [ ] Coding standards pass: `phpcs --standard=Drupal,DrupalPractice` (§21.6).
- [ ] Custom services use dependency injection, not static `\Drupal::` calls (§21.6).

### Before Every Deployment
- [ ] `drush config:status` shows no unexpected differences (§21.3).
- [ ] `composer.lock` committed and matches production (§21.7).
- [ ] Database updates tested in staging (§21.7).
- [ ] Config import tested in staging (§21.7).
- [ ] Security advisories reviewed for all contrib modules (§21.2).
