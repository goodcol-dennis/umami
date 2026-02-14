# Drupal Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §21**

This extension covers Drupal development — custom and contributed modules, themes, configuration management, and site builds. Drupal shares some CMS-level concerns with WordPress (module/plugin audits, update management) but differs fundamentally in architecture: Symfony-based request handling, Twig templating with auto-escaping, a formal configuration management system, a sophisticated caching layer, and Composer-based dependency management. These differences require distinct guardrails.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CMS / Drupal layer.

---

## 21.1 Security Discipline

Drupal has a dedicated Security Team and a formal Security Advisory (SA) process. The platform's security posture is strong by default — but only if developers use the APIs correctly. Bypassing Drupal's render pipeline, Form API, or access system reintroduces the vulnerabilities the framework was designed to prevent.

### Twig Auto-Escaping — What It Does and Doesn't Cover

Unlike WordPress, Drupal's Twig templates **auto-escape output by default**. `{{ variable }}` is safe in most HTML contexts. However, auto-escaping does not cover every case:

| Context | Auto-escaped? | What to do |
|---------|--------------|------------|
| HTML content (`{{ variable }}`) | Yes | Safe by default |
| HTML attributes (`{{ variable }}`) | Yes | Safe by default — Twig escapes for attribute context |
| URLs in `href` / `src` | Partially | Use `{{ url }}` or `{{ path() }}` for route-generated URLs. Validate user-supplied URLs to prevent `javascript:` injection |
| Raw HTML output (`{{ variable\|raw }}`) | **No** | Avoid `\|raw` unless the value has already been sanitized. Every `\|raw` is a potential XSS vector |
| JavaScript context | **No** | Never inject variables directly into `<script>` blocks. Use `drupalSettings` (`drupal_add_js` / `#attached`) to pass data from PHP to JavaScript |
| CSS context | **No** | Never allow user input in inline styles. Use CSS classes and Drupal's library system |

**Rule: Audit every use of `|raw` in templates.** Each one should have a comment explaining why it's safe — "this value was sanitized by `Xss::filter()` in the preprocess function."

### Form API and CSRF Protection

Drupal's Form API handles CSRF tokens automatically for any form built through the API. The risk is when developers bypass it:

- **Always use the Form API** for forms. Don't build raw `<form>` HTML in templates.
- **Custom AJAX callbacks** must use proper access callbacks and CSRF token validation.
- **Custom routes** must define `_permission` or `_access_check` requirements in the route definition — never rely on hiding the URL.

### Access Control

```yaml
# routing.yml — CORRECT: access check defined
mymodule.admin_page:
  path: '/admin/mymodule/settings'
  defaults:
    _controller: '\Drupal\mymodule\Controller\AdminController::settings'
  requirements:
    _permission: 'administer mymodule'

# WRONG: no access check — anyone who guesses the URL can access it
mymodule.admin_page:
  path: '/admin/mymodule/settings'
  defaults:
    _controller: '\Drupal\mymodule\Controller\AdminController::settings'
```

**Rules:**
- Every route must have an access requirement (`_permission`, `_role`, `_access`, or a custom `_access_check` service).
- Use granular permissions. `administer site configuration` is too broad for module-specific settings — define custom permissions in `mymodule.permissions.yml`.
- Entity access: use `$entity->access('view')`, `$entity->access('update')` — never assume the current user has permission because they reached the code.

### Database Security

- **Use the Database API** — `\Drupal::database()->select()`, `->insert()`, `->update()`, `->merge()`. The API handles parameterization.
- **Never concatenate user input into SQL.** The Database API uses parameterized queries by default — let it.
- **If you must use raw SQL** via `->query()`, use placeholders: `$db->query('SELECT * FROM {users_field_data} WHERE uid = :uid', [':uid' => $uid])`.
- **Entity queries** (`\Drupal::entityQuery()`) are the preferred way to query entities. They respect access control when `->accessCheck(TRUE)` is set.

**Rule: Always call `->accessCheck(TRUE)` on entity queries** unless you explicitly need to bypass access (admin operations, cron tasks). Drupal 10+ requires this call — omitting it throws a deprecation warning that will become an error.

### Security Audit Checklist

- [ ] Every route has an access requirement in `routing.yml`.
- [ ] Every `|raw` in Twig templates has a documented justification.
- [ ] All forms use the Form API — no raw HTML forms.
- [ ] Entity queries call `->accessCheck(TRUE)` (or `FALSE` with documented justification).
- [ ] No user input concatenated into database queries.
- [ ] `drupalSettings` used to pass data to JavaScript — no inline `<script>` with PHP variables.
- [ ] Custom permissions defined for module-specific operations (not reusing broad core permissions).
- [ ] File uploads validated for allowed extensions via Form API `#upload_validators`.
- [ ] Security advisories reviewed for all contributed modules (see §21.2).

---

## 21.2 Module Audit and Management

Drupal's contributed module ecosystem is smaller and more curated than WordPress's plugin ecosystem, but the same risks apply: every contributed module is code you didn't write and must keep updated.

### Module Inventory

Maintain a living inventory of every enabled module (core and contributed):

| Field | Why it matters |
|-------|---------------|
| **Module name (machine name)** | Identification — use the machine name, not the human name |
| **Version** | Track deployed version vs. available version |
| **Type** | Core / Contributed / Custom |
| **Purpose** | One-line justification for why it's enabled |
| **Maintainer / project page** | drupal.org project link; check issue queue activity |
| **Security coverage** | Does the module have Drupal Security Team coverage? (indicated by the green shield on drupal.org) |
| **Last release date** | Modules with no release in 12+ months may be abandoned |
| **Alternatives considered** | Prevents re-evaluation; documents why this module over others |
| **Can it be removed?** | Periodic reassessment |

### Security Coverage

Drupal's Security Team reviews and issues advisories for modules that opt into "security advisory coverage." This is a significant quality signal:

- **Covered modules** (green shield on drupal.org): Security Team monitors for vulnerabilities and coordinates disclosure. Prefer these.
- **Uncovered modules**: No Security Team oversight. Use with caution. Audit the code yourself or accept the risk and document it in acknowledged gaps (§8).
- **Custom modules**: You are the security team. Apply §21.1 rigorously.

### Module Selection Criteria

Before adding any contributed module:

- [ ] **Security coverage** — does it have the green shield?
- [ ] **Active maintenance** — recent releases? Responsive issue queue?
- [ ] **Drupal version compatibility** — does it support your Drupal major version? Is it a stable release or dev/alpha/beta?
- [ ] **Dependency chain** — what other modules does it require? Each dependency is another module to maintain and update.
- [ ] **Can you build it?** — for simple functionality, a 50-line custom module is often better than a contributed module that does 20 things you don't need.
- [ ] **Existing core solutions** — Drupal core is feature-rich. Check if Views, Layout Builder, Media, or another core module already does what you need before adding contrib.

### Update Management

- **Security updates**: Apply within 48 hours of advisory publication. Drupal Security Advisories are published on Wednesdays. Subscribe to the mailing list.
- **Core minor updates** (e.g., 10.2.x → 10.3.x): Test in staging. Review release notes for API changes. Apply within 2 weeks.
- **Core major updates** (e.g., 10 → 11): Plan as a project. Check contributed module compatibility. Use the Upgrade Status module.
- **Contributed module updates**: Review changelog. Test in staging. Apply weekly.

```bash
# Check for available updates
composer outdated drupal/*

# Apply a specific module update
composer update drupal/module_name --with-dependencies

# Run database updates after code update
drush updatedb
drush cache:rebuild
```

### Abandoned Module Protocol

When a contributed module shows no activity for 12+ months:

1. Check the drupal.org issue queue — is there a maintainer transition in progress?
2. Check for maintained forks or successor modules.
3. Evaluate whether the functionality can be built as a custom module.
4. If you must keep it, document the risk in acknowledged gaps (§8). Set a review date.
5. Consider applying for co-maintainership if the module is critical to your project.

---

## 21.3 Configuration Management

Drupal's configuration management system is one of its strongest architectural features — and one of the most common sources of deployment problems when misused. Configuration (site settings, content types, views, permissions) is exportable as YAML files that can be version-controlled and deployed across environments.

### The Configuration Workflow

```
Development → Export config → Commit to git → Deploy → Import config
```

```bash
# Export configuration to sync directory
drush config:export

# Review changes
git diff config/sync/

# Import configuration on target environment
drush config:import
```

### Rules

- **All configuration changes happen in code, not in production.** Change config in dev, export, commit, deploy, import. Never make config changes directly in production — they will be overwritten on the next deployment.
- **The `config/sync/` directory is version-controlled.** This is your configuration source of truth.
- **Review config diffs before committing.** `drush config:export` may include unrelated changes (UUIDs from content editing, automatic timestamp updates). Review the diff and only commit intentional changes.
- **Never edit YAML config files by hand** unless you understand the schema. Use the admin UI to make changes, then export. Hand-edited YAML with syntax errors or schema violations will fail on import.
- **Config split for environment-specific settings.** Use the Config Split module to separate dev-only modules (Devel, Kint, Stage File Proxy) from production config. Never deploy development modules to production.

### Config vs. Content

| Configuration (version-controlled) | Content (database only) |
|-------------------------------------|------------------------|
| Content types, fields, view modes | Nodes, taxonomy terms, media entities |
| Views, blocks, menus (structure) | Menu links (content), block content |
| Permissions, roles | User accounts |
| Module settings, site configuration | Webform submissions, log entries |
| Workflows, pathauto patterns | URL aliases (generated) |

**The line:** If it defines *structure or behavior*, it's configuration. If it defines *what users see*, it's content.

### Configuration Audit

- [ ] `config/sync/` is committed to git and up to date.
- [ ] Config split is configured for environment-specific modules.
- [ ] No configuration changes are made directly in production.
- [ ] Config import is part of the deployment pipeline (automated or documented).
- [ ] `config:import --diff` reviewed before every deployment.

---

## 21.4 Caching Architecture

Drupal's caching system is sophisticated — cache tags, cache contexts, and cache max-age provide fine-grained control. Misusing or bypassing caching creates performance problems or stale content bugs.

### Cache Metadata

Every render array in Drupal should declare its cacheability:

| Property | What it controls | Example |
|----------|-----------------|---------|
| **Cache tags** | *What data* does this depend on? Invalidate when the data changes. | `node:42`, `user:1`, `config:system.site` |
| **Cache contexts** | *What context* varies the output? (Creates separate cache entries per context.) | `user.roles`, `url.query_args`, `languages` |
| **Cache max-age** | How long is this valid? | `0` (never cache), `3600` (1 hour), `Cache::PERMANENT` |

```php
// CORRECT — cache metadata declared
$build['content'] = [
  '#markup' => $this->t('Hello, @name', ['@name' => $user->getDisplayName()]),
  '#cache' => [
    'tags' => ['user:' . $user->id()],
    'contexts' => ['user'],
    'max-age' => 3600,
  ],
];

// WRONG — no cache metadata. Drupal may cache this forever or not at all.
$build['content'] = [
  '#markup' => $this->t('Hello, @name', ['@name' => $user->getDisplayName()]),
];
```

### Rules

- **Never set `max-age` to 0 as a shortcut.** `max-age: 0` means "never cache this render element" and bubbles up — it can disable caching for the entire page. Use it only when the content genuinely cannot be cached (e.g., real-time data).
- **Always declare cache tags** on render arrays that display entity data. This ensures the cache invalidates when the entity is updated.
- **Use cache contexts** when output varies by user role, language, URL, or any request-specific variable.
- **Debug with the `cache_debug` header.** In `development.services.yml`, enable `http.response.debug_cacheability_headers: true` to see cache metadata in response headers.

### Performance Anti-Patterns

| Anti-Pattern | Consequence | Fix |
|--------------|-------------|-----|
| `max-age: 0` everywhere | Entire pages uncacheable; page cache disabled | Use proper cache tags instead — let Drupal invalidate when data changes |
| Missing cache tags on entity displays | Stale content served after entity update | Add `'tags' => $entity->getCacheTags()` |
| Loading entities in preprocess hooks without caching | N+1 query patterns on listing pages | Use Views or entity queries with proper access and caching |
| Disabling page cache for authenticated users | Massive performance degradation on logged-in sections | Use Dynamic Page Cache (core), BigPipe (core), or cache contexts |

---

## 21.5 Theming and Render System

Drupal's render system — render arrays → Twig templates — is fundamentally different from WordPress's PHP template approach. The render system is the correct extension point; bypassing it bypasses caching, access control, and alter hooks.

### Rules

- **Never echo/print directly from a controller or preprocess function.** Return render arrays. Let Drupal's render pipeline handle the output.
- **Use render arrays, not HTML strings.** `'#markup' => '<div>...</div>'` is a last resort. Use `'#theme' => 'item_list'`, `'#type' => 'table'`, or custom theme hooks with Twig templates.
- **Preprocess functions add variables to templates** — they should not contain business logic. Keep logic in services; pass results to templates via preprocess.
- **Custom theme hooks** (`hook_theme()`) for reusable template patterns. Don't duplicate Twig markup across templates — create a theme hook and include it.

### Template Override Discipline

```
themes/custom/mytheme/
├── mytheme.info.yml
├── mytheme.theme              ← Preprocess functions only
├── templates/
│   ├── node--article.html.twig       ← Override specific content type
│   ├── block--system-branding.html.twig
│   └── field--field-hero-image.html.twig
├── css/
├── js/
└── mytheme.libraries.yml      ← Asset declarations
```

**Rules:**
- Use Drupal's template naming conventions for overrides. Template suggestions tell you exactly what file name Drupal looks for.
- Enable Twig debugging in `development.services.yml` to see template suggestions in HTML comments.
- **Never modify templates in contributed themes or modules.** Override in your custom theme.
- Keep templates focused on presentation. If a template needs data, add it in a preprocess function — don't put PHP logic in Twig.

### Asset Management

```yaml
# mytheme.libraries.yml — CORRECT: declared library with dependencies
global-styling:
  css:
    theme:
      css/style.css: {}
  js:
    js/main.js: {}
  dependencies:
    - core/drupal
    - core/jquery
```

**Rules:**
- All CSS and JavaScript declared in `*.libraries.yml`. Never use inline `<script>` or `<link>` tags in templates.
- Attach libraries to render arrays: `$build['#attached']['library'][] = 'mytheme/global-styling';`
- Use library dependencies to ensure load order — don't rely on weight or template position.
- Conditionally attach libraries — only load JavaScript on pages that need it.

---

## 21.6 Coding Standards and Architecture

### Drupal Coding Standards

Drupal has strict, enforced coding standards checked by PHP_CodeSniffer with the `Drupal` and `DrupalPractice` rulesets.

```bash
# Check coding standards
phpcs --standard=Drupal,DrupalPractice web/modules/custom/

# Auto-fix what can be fixed
phpcbf --standard=Drupal,DrupalPractice web/modules/custom/
```

**Enforce in CI.** Coding standards violations should fail the build.

### Service Architecture

Drupal uses Symfony's dependency injection container. Custom code should follow the service pattern:

- **Controllers** handle HTTP requests and return responses/render arrays. They should be thin — delegate to services.
- **Services** contain business logic. Defined in `mymodule.services.yml`, injected via constructors.
- **Event subscribers** react to system events (Symfony events replacing many hooks).
- **Plugins** (Blocks, Fields, Formatters, etc.) extend Drupal's plugin system. Annotated, discovered automatically.

**Anti-patterns:**
- Business logic in `.module` files. Use services.
- Static calls to `\Drupal::service()` in services/controllers. Use dependency injection.
- God services that do everything. One service = one responsibility.

### Update Hooks

Schema and data migrations use `hook_update_N()` in `mymodule.install`:

```php
/**
 * Migrate field_old to field_new on article nodes.
 */
function mymodule_update_9001(&$sandbox) {
  // Migration logic here
}
```

**Rules:**
- Update hook numbers are sequential and never reused.
- Each update hook has a descriptive docblock explaining what it does and why.
- Update hooks must be idempotent — safe to run multiple times.
- Test update hooks in staging before production. Run `drush updatedb` after code deployment.
- For large data migrations, use batch processing via `$sandbox`.

---

## 21.7 Deployment Pipeline

### Recommended Deployment Flow

```bash
# 1. Put site in maintenance mode (optional, for major updates)
drush state:set system.maintenance_mode 1

# 2. Pull latest code
git pull origin main

# 3. Install/update dependencies
composer install --no-dev --optimize-autoloader

# 4. Run database updates
drush updatedb -y

# 5. Import configuration
drush config:import -y

# 6. Rebuild caches
drush cache:rebuild

# 7. Take site out of maintenance mode
drush state:set system.maintenance_mode 0
```

### Composer Discipline

Drupal uses Composer for all dependency management — core, contributed modules, themes, and PHP libraries.

**Rules:**
- `composer.lock` is committed to git. It ensures reproducible installs across environments.
- Use `composer require` to add modules — never download and place manually.
- Use `composer update drupal/module_name --with-dependencies` for targeted updates — never `composer update` (updates everything).
- Patch management: use `cweagans/composer-patches` for contributed module patches. Document each patch with an issue link. Remove patches when the upstream fix is released.
- Pin Drupal core constraint to a minor version range: `"drupal/core-recommended": "^10.2"`.

### Drush as Operational Standard

Drush is the standard CLI for Drupal operations. All repeatable operations should be Drush commands:

```bash
drush cr                     # Cache rebuild
drush cex                    # Config export
drush cim                    # Config import
drush updb                   # Run database updates
drush uli                    # Generate one-time login link
drush sql:dump > backup.sql  # Database backup
drush watchdog:show          # View recent log entries
```

**Rule: If you can do it with Drush, do it with Drush.** Manual admin UI clicks are unrepeatable and undocumented. Drush commands can be scripted, version-controlled, and included in deployment pipelines.

---

## 21.8 Drupal Testing Layers

| Layer | What it catches | Tool | When to run |
|-------|----------------|------|-------------|
| **Coding standards** | Style violations, deprecated API usage | PHPCS with `Drupal` + `DrupalPractice` | Pre-commit / CI |
| **Static analysis** | Type errors, undefined methods, dead code | PHPStan with `phpstan-drupal` | CI on every PR |
| **Unit tests** | Service logic, utilities, data transforms | PHPUnit (`UnitTestCase`) | CI on every PR |
| **Kernel tests** | Service container, database, entity operations | PHPUnit (`KernelTestBase`) | CI on every PR |
| **Functional tests** | Full HTTP requests, form submissions, page rendering | PHPUnit (`BrowserTestBase`) | CI on every PR |
| **JavaScript tests** | Frontend interactions, AJAX behaviors | Nightwatch.js (core) or Cypress | CI on every PR |
| **Security scan** | Known vulnerabilities in contrib modules | `drush pm:security` / Drupal Security Advisories | Weekly + after updates |
| **Config validation** | Config sync integrity | `drush config:status` | Before every deployment |
| **Performance** | Page load, cache hit rates, query count | Webprofiler module, Blackfire | Before release |

**Minimum viable Drupal CI:** Coding standards + static analysis + unit/kernel tests + `drush config:status` + security scan on every PR.

---

## Mapping to Core Guardrail Sections

| Core Section | Drupal Equivalent |
|---|---|
| §2 Specs | §21.3 Config management (configuration as specification), entity/field architecture |
| §3 Testing | §21.8 Drupal testing layers (unit, kernel, functional, JS) |
| §3 Type Assumptions | §21.1 Twig auto-escaping contexts, Form API, database parameterization |
| §4 Runtime Validation | §21.4 Cache metadata (tags, contexts, max-age) — ensures correct output |
| §5 State Tracking | §21.3 Config sync (version-controlled YAML), §21.6 Update hooks |
| §6 Consistency | §21.6 Coding standards (PHPCS), service architecture, Composer discipline |
| §7 ADRs | Module selection decisions, architecture choices, config split strategy |
| §8 Acknowledged Gaps | §21.2 Uncovered modules, abandoned module risks |
| §11 File Size | §21.5 Template/preprocess separation, §21.6 service decomposition |
| §12 Change Tracking | §21.7 Deployment pipeline, Drush scripted operations |
| §13 Dead Code | §21.2 Module inventory — disabled but installed modules are dead code with attack surface |

---

## Drupal Checklist (extends §15)

### Before Every Drupal Change
- [ ] Security: routes have access requirements, no unescaped `|raw` without justification, entity queries use `->accessCheck()` (§21.1).
- [ ] Configuration exported and committed after admin UI changes (§21.3).
- [ ] Cache metadata declared on all render arrays with entity data (§21.4).
- [ ] Coding standards pass: `phpcs --standard=Drupal,DrupalPractice` (§21.6).
- [ ] Custom functions use dependency injection, not static `\Drupal::` calls (§21.6).

### Before Every Module Change
- [ ] Module inventory updated — purpose, version, security coverage documented (§21.2).
- [ ] New contributed modules checked for security coverage (green shield) (§21.2).
- [ ] Dependency chain reviewed — what does the new module require? (§21.2)
- [ ] Module update tested in staging before production (§21.2).
- [ ] `drush updatedb` run after module updates (§21.7).

### Before Every Deployment
- [ ] `drush config:status` shows no unexpected differences (§21.3).
- [ ] `composer.lock` committed and matches production composer install (§21.7).
- [ ] Database updates tested in staging (`drush updatedb`) (§21.7).
- [ ] Config import tested in staging (`drush config:import`) (§21.7).
- [ ] Cache rebuild verified (`drush cache:rebuild`) (§21.7).
- [ ] Security advisories reviewed for all contrib modules (§21.2).

### Periodic
- [ ] Security advisories reviewed — Drupal SA published Wednesdays (weekly) (§21.2).
- [ ] Module inventory reviewed — abandoned or uncovered modules flagged (quarterly) (§21.2).
- [ ] Composer patches reviewed — remove patches where upstream fix is released (quarterly) (§21.7).
- [ ] Performance audit — cache hit rates, slow queries, uncacheable pages (quarterly) (§21.4).
