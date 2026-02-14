# WordPress Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §20**

This extension covers WordPress development — themes, plugins, and site builds. WordPress powers ~40% of the web but has a uniquely dangerous risk profile: no auto-escaping in templates, a massive plugin ecosystem of variable quality, and a culture of "just install a plugin" that accumulates invisible technical debt and security exposure. The core guardrails template assumes modern application development patterns; WordPress requires specific adaptations.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CMS / WordPress layer.

---

## 20.1 Security Discipline — WordPress Is the #1 CMS Attack Target

WordPress security is not optional hardening — it's survival. The platform's popularity makes it the single most targeted CMS. Most WordPress compromises exploit known vulnerabilities in unpatched plugins, not zero-day exploits in core.

### Output Escaping — The Most Critical Rule

WordPress templates have **no auto-escaping**. Unlike React, Vue, or Jinja2, every piece of dynamic output must be manually escaped. One missed `esc_html()` is a stored XSS vulnerability.

| Context | Function | Example |
|---------|----------|---------|
| HTML content | `esc_html()` | `<p><?php echo esc_html( $user_input ); ?></p>` |
| HTML attributes | `esc_attr()` | `<input value="<?php echo esc_attr( $value ); ?>">` |
| URLs | `esc_url()` | `<a href="<?php echo esc_url( $link ); ?>">` |
| JavaScript | `esc_js()` | `<script>var x = '<?php echo esc_js( $val ); ?>';</script>` |
| Rich HTML (allow specific tags) | `wp_kses()` / `wp_kses_post()` | User-submitted content where some HTML is allowed |
| Translation strings | `esc_html__()`, `esc_attr__()` | Translated text that goes into HTML |

**Rule: Never echo unescaped data. No exceptions.** Treat every `echo $variable` without an escaping function as a bug.

### Input Sanitization

Sanitize at the boundary — when data enters the system:

| Data type | Function |
|-----------|----------|
| Plain text | `sanitize_text_field()` |
| Email | `sanitize_email()` |
| URL | `esc_url_raw()` (for database storage) |
| Filename | `sanitize_file_name()` |
| HTML class | `sanitize_html_class()` |
| Integer | `absint()` or `intval()` |
| Array of values | `array_map( 'sanitize_text_field', $array )` |

### Nonce Verification

Every form submission and AJAX handler must verify a nonce. Without it, CSRF attacks can trick authenticated users into performing actions.

```php
// In the form
wp_nonce_field( 'my_action_nonce', '_my_nonce' );

// In the handler — BEFORE any processing
if ( ! wp_verify_nonce( $_POST['_my_nonce'], 'my_action_nonce' ) ) {
    wp_die( 'Security check failed.' );
}
```

**For AJAX:** Use `check_ajax_referer( 'my_action_nonce', '_my_nonce' )`.

### Capability Checks

Never assume a user has permission because they reached a handler. Always verify:

```php
if ( ! current_user_can( 'edit_posts' ) ) {
    wp_die( 'Unauthorized.' );
}
```

Check capabilities, not roles. `current_user_can( 'manage_options' )` is correct; checking `$user->role === 'administrator'` is fragile and bypassable.

### Database Security

- **Always use `$wpdb->prepare()` for SQL with user input.** No exceptions. Raw string concatenation in SQL is SQL injection.
- **Prefer WordPress API functions** (`get_posts()`, `WP_Query`, `get_option()`) over direct database queries. The API handles escaping and caching.
- **When direct queries are necessary**, parameterize everything:

```php
// CORRECT
$wpdb->get_results( $wpdb->prepare(
    "SELECT * FROM {$wpdb->posts} WHERE post_author = %d AND post_status = %s",
    $author_id,
    'publish'
) );

// WRONG — SQL injection vulnerability
$wpdb->get_results( "SELECT * FROM {$wpdb->posts} WHERE post_author = {$author_id}" );
```

### File Upload Security

- Validate MIME type server-side (not just file extension — extensions can be spoofed).
- Use `wp_check_filetype()` and restrict to expected types.
- Never allow PHP file uploads. Ever.
- Store uploads in `wp-content/uploads/` using `wp_handle_upload()` — never custom directories without `.htaccess` protection.

### Security Audit Checklist

Run this against every theme and custom plugin:

- [ ] Every `echo` of dynamic data uses the appropriate `esc_*()` function.
- [ ] Every form has a nonce field; every handler verifies it.
- [ ] Every privileged action checks `current_user_can()`.
- [ ] Every SQL query with variables uses `$wpdb->prepare()`.
- [ ] No `eval()`, `assert()`, `preg_replace()` with `/e` modifier, or `extract()` on user input.
- [ ] File uploads validated for MIME type, not just extension.
- [ ] No secrets hardcoded (API keys, passwords) — all in `wp-config.php` or environment variables.
- [ ] `DISALLOW_FILE_EDIT` set to `true` in `wp-config.php` (prevents code editing from admin panel).
- [ ] Debug mode (`WP_DEBUG`) disabled in production.
- [ ] Directory listing disabled (`.htaccess` or server config).

---

## 20.2 Plugin Audit and Management

Every plugin is a dependency you didn't write, can't fully control, and must keep updated. A WordPress site with 30 plugins has 30 potential attack vectors, 30 potential performance bottlenecks, and 30 potential sources of conflict.

### Plugin Inventory

Maintain a living inventory of every active plugin:

| Field | Why it matters |
|-------|---------------|
| **Plugin name** | Identification |
| **Version** | Track what's deployed vs. what's available |
| **Purpose** | One-line justification for why it exists |
| **Author / source** | WordPress.org repo, premium vendor, custom-built |
| **Last updated (by author)** | Plugins not updated in 2+ years are security risks |
| **Alternatives considered** | Prevents re-evaluation; documents why this plugin over others |
| **Can it be removed?** | Periodic reassessment — is it still needed? |
| **Known conflicts** | Documented interactions with other active plugins |

### Plugin Selection Criteria

Before installing any plugin, evaluate:

- [ ] **Active maintenance** — updated within the last 6 months? Responds to support requests?
- [ ] **Download count and ratings** — not definitive, but <1,000 installs on a 3-year-old plugin is a warning sign.
- [ ] **Security history** — search WPScan Vulnerability Database for past CVEs.
- [ ] **Performance impact** — does it load assets on every page, or only where needed?
- [ ] **Code quality** — if it's critical to the site, review the source code. Look for raw SQL, missing nonces, unescaped output.
- [ ] **Can you build it instead?** — 20 lines of custom code in a plugin is often better than a 5,000-line third-party plugin that does 50 things you don't need.

### Plugin Conflict Testing

Plugin conflicts are the most common source of WordPress bugs. Two plugins hooking the same filter with incompatible transforms, or two plugins loading different versions of the same JavaScript library, create bugs that are invisible until they collide.

**Testing discipline:**
- Enable one plugin at a time in staging. Test core functionality after each activation.
- After enabling all plugins, run a full regression pass on critical user flows.
- Document known conflicts in the plugin inventory.
- When a conflict is found, determine which plugin's behavior is correct and use `remove_filter()` / `remove_action()` to unhook the other — never edit the plugin files directly.

### Update Management

- **Core minor updates** (e.g., 6.5.1 → 6.5.2): Security patches. Auto-update is generally safe. Apply within 48 hours of release.
- **Core major updates** (e.g., 6.5 → 6.6): Test in staging first. Check plugin compatibility announcements. Apply within 2 weeks.
- **Plugin updates**: Test in staging. Review the changelog. Apply weekly or more frequently for security fixes.
- **Theme updates**: If using a child theme (you should be), parent theme updates are safe. Test in staging.
- **PHP version updates**: Test everything. PHP minor versions rarely break WordPress, but plugin compatibility varies.

**Update checklist:**
- [ ] Staging environment mirrors production (same plugins, same data).
- [ ] Full backup taken before applying updates to production.
- [ ] Updates applied to staging first and tested.
- [ ] Critical user flows verified after update.
- [ ] Rollback plan documented (restore backup, revert plugin version).

### Abandoned Plugin Protocol

When a plugin hasn't been updated in 12+ months:

1. Check if the plugin has known vulnerabilities (WPScan database).
2. Search for maintained forks or alternatives.
3. If no alternative exists, evaluate whether the functionality can be built custom.
4. If you must keep it, document the risk in acknowledged gaps (§8) with a review date.
5. Consider hiring a security review of the plugin code if it handles sensitive data.

---

## 20.3 Theme Architecture

### Child Theme Rule

**Never edit a parent theme directly.** Parent theme updates will overwrite your changes. Always use a child theme.

```
wp-content/themes/
├── parent-theme/          ← Do NOT edit
└── parent-theme-child/    ← All customizations go here
    ├── style.css
    ├── functions.php
    └── template-parts/    ← Override specific templates
```

### Theme vs. Plugin Separation

| Belongs in the theme | Belongs in a plugin |
|---------------------|---------------------|
| Presentation: templates, styles, layouts | Business logic: custom post types, taxonomies, shortcodes |
| Theme-specific JavaScript (animations, UI interactions) | Data processing, API integrations, custom database tables |
| Template tags that only make sense in this theme | Functionality that should survive a theme switch |

**The test:** If switching themes would break core site functionality, that functionality is in the wrong place. It should be in a plugin.

### functions.php Discipline

`functions.php` is the most commonly bloated file in WordPress. Apply §11 (File Size Budgets):

- Split into focused includes: `inc/custom-post-types.php`, `inc/enqueue.php`, `inc/customizer.php`.
- `functions.php` itself should only contain `require` statements.
- Each include file has a single responsibility.

---

## 20.4 Hook System Discipline

WordPress's hook system (actions and filters) is its primary extension mechanism — and its primary source of debugging complexity.

### Rules

- **Prefix everything.** All custom functions, hooks, and global variables must use a project prefix. `get_user_data()` will collide with another plugin's `get_user_data()`. Use `myproject_get_user_data()`.
- **Document hook priority.** When using a non-default priority (not 10), comment why: `add_filter( 'the_content', 'myproject_filter', 20 ); // After shortcodes process at priority 11`.
- **Never remove core hooks without an ADR.** Removing a core WordPress hook can break expectations for other plugins and future WordPress updates. Document the decision.
- **Use `has_filter()` / `has_action()` defensively.** Before removing a hook, verify it exists. Before relying on a filter's output, verify the filter is registered.

### Debugging Hooks

When behavior is unexpected, the hook system is usually the cause:

1. **Identify which hooks fire.** Use Query Monitor plugin or `add_action( 'all', function( $tag ) { error_log( $tag ); } );` temporarily.
2. **Check priority order.** Multiple callbacks on the same hook execute in priority order. A filter at priority 20 overrides one at priority 10.
3. **Check return values.** Filters must return a value. A filter callback that forgets to `return` silently nullifies the data.

---

## 20.5 Database and Performance

### wp_options Bloat

The `wp_options` table is loaded on every page request (autoloaded rows). Plugins that store large serialized arrays with `autoload = 'yes'` slow down every page.

**Audit practices:**
- Query autoloaded options size: `SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload = 'yes';`
- Anything over 1MB of autoloaded data is a performance problem.
- Identify the largest autoloaded options and determine if they should be non-autoloaded or stored elsewhere.
- Transient data (`_transient_*`) should have expiration times. Orphaned transients without expiration accumulate indefinitely.

### Query Performance

- **Use `WP_Query` with specific fields.** `'fields' => 'ids'` when you only need IDs. `'no_found_rows' => true` when you don't need pagination counts.
- **Avoid `meta_query` on unindexed meta keys** in large databases. Consider custom tables for high-query-volume data.
- **Use object caching** (Redis, Memcached) for production sites. WordPress's default object cache is per-request only.
- **Use the Transients API** for caching expensive operations (external API calls, complex queries). Always set an expiration.

### Asset Loading

```php
// CORRECT — conditional loading, proper dependencies
function myproject_enqueue_scripts() {
    if ( is_singular( 'product' ) ) {
        wp_enqueue_script( 'myproject-product', get_stylesheet_directory_uri() . '/js/product.js', array( 'jquery' ), '1.0.0', true );
    }
}
add_action( 'wp_enqueue_scripts', 'myproject_enqueue_scripts' );

// WRONG — loads on every page, inline, no versioning
function myproject_bad_scripts() {
    echo '<script src="' . get_stylesheet_directory_uri() . '/js/everything.js"></script>';
}
```

**Rules:**
- Always use `wp_enqueue_script()` / `wp_enqueue_style()` — never inline `<script>` or `<link>` tags.
- Load assets conditionally — only on pages that need them.
- Specify dependencies explicitly so WordPress loads scripts in the correct order.
- Use versioning for cache busting (file version, not random strings).

---

## 20.6 Deployment and Environment

### What to Version Control

| Include | Exclude |
|---------|---------|
| Custom themes (child theme) | `wp-content/uploads/` (user media) |
| Custom plugins | `wp-config.php` with production secrets |
| `wp-config.php` template (with placeholders) | `.htaccess` (environment-specific) |
| `composer.json` / `composer.lock` (if using Composer for plugins) | Database dumps |
| Build configs (Webpack, Gulp, etc.) | Node modules, vendor directories |

### Environment Configuration

```php
// wp-config.php — environment-specific settings
define( 'WP_ENVIRONMENT_TYPE', 'production' ); // 'local', 'development', 'staging', 'production'

// Development only
if ( wp_get_environment_type() === 'development' ) {
    define( 'WP_DEBUG', true );
    define( 'WP_DEBUG_LOG', true );
    define( 'WP_DEBUG_DISPLAY', true );
    define( 'SCRIPT_DEBUG', true );
}

// Production always
define( 'DISALLOW_FILE_EDIT', true );   // No code editing in admin
define( 'DISALLOW_FILE_MODS', false );  // Set true to prevent plugin/theme installs from admin
```

### Database Sync

WordPress stores content, configuration, and site URLs in the database. Moving between environments requires URL rewriting:

```bash
# WP-CLI — search-replace for environment migration
wp search-replace 'https://staging.example.com' 'https://example.com' --all-tables --dry-run
```

**Rules:**
- Always run `--dry-run` first to review changes.
- Always back up before running search-replace on production.
- Use `--all-tables` to catch serialized data in non-standard tables.
- Never manually edit serialized data — `wp search-replace` handles serialized strings correctly; manual edits corrupt them.

---

## 20.7 WordPress Testing Layers

| Layer | What it catches | Tool | When to run |
|-------|----------------|------|-------------|
| **PHP lint** | Syntax errors | `php -l`, PHP_CodeSniffer with WordPress standards | Pre-commit |
| **WordPress coding standards** | WordPress-specific anti-patterns, escaping violations | PHPCS with `WordPress` ruleset | Pre-commit / CI |
| **Security scan** | Known plugin/theme vulnerabilities, misconfigurations | WPScan, Wordfence, Sucuri | Weekly + after updates |
| **Plugin conflict test** | Incompatibilities between active plugins | Manual in staging, Query Monitor | After plugin updates |
| **Unit tests** | Custom plugin/theme logic | PHPUnit + WP test framework (`WP_UnitTestCase`) | CI on every PR |
| **E2E tests** | User flows (login, forms, checkout, admin workflows) | Playwright, Cypress | CI on every PR |
| **Performance audit** | Page load time, query count, asset size | Query Monitor, Lighthouse, GTmetrix | Before release |
| **Accessibility scan** | WCAG compliance | axe-core, Lighthouse | Before release |

**Minimum viable WordPress CI:** PHP lint + PHPCS with WordPress standards + security scan + unit tests on every PR.

---

## Mapping to Core Guardrail Sections

| Core Section | WordPress Equivalent |
|---|---|
| §2 Specs | Theme/plugin architecture decisions (§20.3), hook documentation |
| §3 Testing | §20.7 WordPress-specific testing layers |
| §3 Type Assumptions | §20.1 Input sanitization / output escaping at every boundary |
| §6 Consistency | §20.4 Hook discipline (prefixing, priority), §20.5 Asset loading standards |
| §7 ADRs | Plugin selection decisions, hook removal decisions, architecture splits |
| §8 Acknowledged Gaps | §20.2 Abandoned plugin risks, known plugin conflicts |
| §11 File Size | §20.3 functions.php decomposition |
| §13 Dead Code | §20.2 Plugin inventory — unused plugins are dead code with attack surface |

---

## WordPress Checklist (extends §15)

### Before Every WordPress Change
- [ ] Output escaping verified on every `echo` of dynamic data (§20.1).
- [ ] Nonce fields present on all forms; handlers verify them (§20.1).
- [ ] Capability checks present on all privileged actions (§20.1).
- [ ] Database queries use `$wpdb->prepare()` or WordPress API functions (§20.1).
- [ ] Custom functions and hooks use project prefix (§20.4).
- [ ] Assets loaded conditionally with `wp_enqueue_*()` (§20.5).

### Before Every Plugin Change
- [ ] Plugin inventory updated — purpose, version, alternatives documented (§20.2).
- [ ] New plugins evaluated against selection criteria (§20.2).
- [ ] Plugin conflict test run in staging after activation (§20.2).
- [ ] Plugin update tested in staging before production (§20.2).

### Periodic
- [ ] Security scan run against all plugins and themes (weekly) (§20.7).
- [ ] Plugin inventory reviewed — abandoned plugins identified (monthly) (§20.2).
- [ ] `wp_options` autoload size audited (monthly) (§20.5).
- [ ] Core, plugin, and theme updates applied (weekly) (§20.2).
- [ ] Backup verification — confirm backups are restorable, not just present (monthly).
- [ ] User accounts audited — remove inactive admin accounts, verify MFA enabled (quarterly).
