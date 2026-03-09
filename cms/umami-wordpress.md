# WordPress Guardrails

**Extension of [CMS Guardrails](../umami-cms.md) (§25), which extends [Rapid Development Guardrails](../umami.md) — §20**

This extension covers WordPress-specific development — themes, plugins, and site builds. It builds on the shared CMS guardrails (§25) with WordPress-specific implementation details. For general CMS practices (extension audits, update management, security fundamentals, deployment discipline), see §25.

**Apply this extension when** the §0.2 system shape questionnaire identifies a CMS / WordPress layer.

**Loading order:** Load all three layers:
1. [`umami.md`](../umami.md) — core guardrails
2. [`umami-cms.md`](../umami-cms.md) — CMS-generic practices (§25)
3. This file — WordPress-specific implementation

---

## 20.1 WordPress Security Implementation

WordPress templates have **no auto-escaping**. Unlike Twig-based CMS platforms, every piece of dynamic output must be manually escaped. This is the single most important WordPress-specific discipline. See §25.3 for the general principles; this section covers the WordPress implementation.

### Output Escaping Functions

| Context | Function | Example |
|---------|----------|---------|
| HTML content | `esc_html()` | `<p><?php echo esc_html( $user_input ); ?></p>` |
| HTML attributes | `esc_attr()` | `<input value="<?php echo esc_attr( $value ); ?>">` |
| URLs | `esc_url()` | `<a href="<?php echo esc_url( $link ); ?>">` |
| JavaScript | `esc_js()` | `<script>var x = '<?php echo esc_js( $val ); ?>';</script>` |
| Rich HTML (allow specific tags) | `wp_kses()` / `wp_kses_post()` | User-submitted content where some HTML is allowed |
| Translation strings | `esc_html__()`, `esc_attr__()` | Translated text that goes into HTML |

**Rule: Never echo unescaped data. No exceptions.** Treat every `echo $variable` without an escaping function as a bug.

### Input Sanitization Functions

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

Every form submission and AJAX handler must verify a nonce (WordPress's CSRF protection — see §25.3):

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

Check capabilities, not roles (per §25.3). `current_user_can( 'manage_options' )` is correct; checking `$user->role === 'administrator'` is fragile and bypassable.

### Database Security

- **Always use `$wpdb->prepare()` for SQL with user input.** No exceptions.
- **Prefer WordPress API functions** (`get_posts()`, `WP_Query`, `get_option()`) over direct database queries. The API handles escaping and caching.
- **When direct queries are necessary:**

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

- Validate MIME type server-side (not just file extension).
- Use `wp_check_filetype()` and restrict to expected types.
- Never allow PHP file uploads.
- Store uploads via `wp_handle_upload()` — never custom directories without `.htaccess` protection.

---

## 20.2 WordPress Plugin Specifics

The general extension audit framework is in §25.1. This section covers WordPress-specific plugin concerns.

### Plugin-Specific Selection Criteria

In addition to the §25.1 criteria:

- [ ] **WordPress.org repo vs. premium** — WordPress.org plugins get basic review; premium plugins may not.
- [ ] **WPScan vulnerability history** — search the WPScan Vulnerability Database for past CVEs.
- [ ] **Asset loading behavior** — does it load CSS/JS on every page, or only where needed?

### Plugin Conflict Testing

Plugin conflicts are the most common source of WordPress bugs. Two plugins hooking the same filter with incompatible transforms create bugs that are invisible until they collide.

- Enable one plugin at a time in staging. Test core functionality after each activation.
- After enabling all plugins, run a full regression pass on critical user flows.
- When a conflict is found, use `remove_filter()` / `remove_action()` to unhook the conflicting callback — never edit plugin files directly.

### Core and Plugin Update Specifics

In addition to the §25.2 update framework:

- **Core minor updates** (e.g., 6.5.1 → 6.5.2): Auto-update is generally safe for security patches.
- **Core major updates** (e.g., 6.5 → 6.6): Check plugin compatibility announcements before updating.
- **Theme updates**: If using a child theme (you should be), parent theme updates are safe. Test in staging.

---

## 20.3 Theme Architecture

### Child Theme Rule

**Never edit a parent theme directly.** Parent theme updates will overwrite your changes (see §25.5 for the principle).

```
wp-content/themes/
├── parent-theme/          ← Do NOT edit
└── parent-theme-child/    ← All customizations go here
    ├── style.css
    ├── functions.php
    └── template-parts/    ← Override specific templates
```

### functions.php Discipline

`functions.php` is the most commonly bloated file in WordPress. Apply §11 (File Size Budgets):

- Split into focused includes: `inc/custom-post-types.php`, `inc/enqueue.php`, `inc/customizer.php`.
- `functions.php` itself should only contain `require` statements.
- Each include file has a single responsibility.

---

## 20.4 Hook System Discipline

WordPress's hook system (actions and filters) is its primary extension mechanism — and its primary source of debugging complexity.

### Rules

- **Prefix everything.** All custom functions, hooks, and global variables must use a project prefix. `get_user_data()` will collide; use `myproject_get_user_data()`.
- **Document hook priority.** When using a non-default priority (not 10), comment why: `add_filter( 'the_content', 'myproject_filter', 20 ); // After shortcodes process at priority 11`.
- **Never remove core hooks without an ADR** (§7). Removing a core hook can break expectations for other plugins and future updates.
- **Use `has_filter()` / `has_action()` defensively** before removing hooks or relying on filter output.

### Debugging Hooks

1. **Identify which hooks fire.** Use Query Monitor plugin or `add_action( 'all', function( $tag ) { error_log( $tag ); } );` temporarily.
2. **Check priority order.** Multiple callbacks on the same hook execute in priority order.
3. **Check return values.** Filters must return a value. A filter callback that forgets to `return` silently nullifies the data.

---

## 20.5 WordPress Performance

### wp_options Bloat

The `wp_options` table is loaded on every page request (autoloaded rows). Plugins that store large serialized arrays with `autoload = 'yes'` slow down every page.

- Query autoloaded options size: `SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload = 'yes';`
- Anything over 1MB of autoloaded data is a performance problem.
- Transient data (`_transient_*`) should have expiration times. Orphaned transients accumulate indefinitely.

### Query Performance

- **Use `WP_Query` with specific fields.** `'fields' => 'ids'` when you only need IDs. `'no_found_rows' => true` when you don't need pagination counts.
- **Avoid `meta_query` on unindexed meta keys** in large databases. Consider custom tables for high-query-volume data.
- **Use object caching** (Redis, Memcached) for production sites.
- **Use the Transients API** for caching expensive operations. Always set an expiration.

### Asset Loading

```php
// CORRECT — conditional loading, proper dependencies
function myproject_enqueue_scripts() {
    if ( is_singular( 'product' ) ) {
        wp_enqueue_script( 'myproject-product', get_stylesheet_directory_uri() . '/js/product.js', array( 'jquery' ), '1.0.0', true );
    }
}
add_action( 'wp_enqueue_scripts', 'myproject_enqueue_scripts' );
```

**Rules:**
- Always use `wp_enqueue_script()` / `wp_enqueue_style()` — never inline tags (per §25.5).
- Load assets conditionally — only on pages that need them.
- Specify dependencies explicitly.
- Use versioning for cache busting.

---

## 20.6 WordPress Deployment

### Version Control (WordPress-specific, extends §25.6)

| Include | Exclude |
|---------|---------|
| Custom themes (child theme) | `wp-content/uploads/` (user media) |
| Custom plugins | `wp-config.php` with production secrets |
| `wp-config.php` template (with placeholders) | `.htaccess` (environment-specific) |
| `composer.json` / `composer.lock` (if using Composer) | Database dumps |

### Environment Configuration

```php
// wp-config.php
define( 'WP_ENVIRONMENT_TYPE', 'production' ); // 'local', 'development', 'staging', 'production'

// Development only
if ( wp_get_environment_type() === 'development' ) {
    define( 'WP_DEBUG', true );
    define( 'WP_DEBUG_LOG', true );
    define( 'WP_DEBUG_DISPLAY', true );
    define( 'SCRIPT_DEBUG', true );
}

// Production always
define( 'DISALLOW_FILE_EDIT', true );
```

### Database URL Rewriting

```bash
# WP-CLI — search-replace for environment migration
wp search-replace 'https://staging.example.com' 'https://example.com' --all-tables --dry-run
```

Always `--dry-run` first. Always back up before production. Use `--all-tables` to catch serialized data. Never manually edit serialized data (per §25.6).

---

## 20.7 WordPress Testing Layers

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

---

## 20.8 WordPress Production Monitoring

Extends §25.7 with WordPress-specific implementation:

### Error Logging

```php
// wp-config.php — production error logging (NOT display)
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );      // Write errors to wp-content/debug.log
define( 'WP_DEBUG_DISPLAY', false ); // Never show errors to visitors
@ini_set( 'display_errors', 0 );
```

### WP-Cron

WordPress's pseudo-cron depends on site visits. For reliable scheduling, configure a real system cron:
```
*/5 * * * * curl -s https://example.com/wp-cron.php > /dev/null 2>&1
```

### Monitoring Tools

- **Query Monitor** — query count, hook execution, asset loading (development/staging).
- **Site Health API** — `/wp-json/wp-site-health/v1/tests/` for automated health checks.
- **Object cache hit rate** — if using Redis/Memcached, monitor hit rates.

---

## WordPress-Specific Anti-Patterns

These are in addition to the common CMS anti-patterns in §25.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Everything in functions.php** | A 2,000-line file with post types, shortcodes, AJAX handlers, and business logic. | Decompose into focused includes (§20.3). |
| **Direct database queries for things APIs handle** | `$wpdb->query()` for operations that `WP_Query` or `get_option()` handle. Bypasses caching, escaping, hooks. | Use WordPress API functions first (§20.1, §20.5). |

---

## WordPress Checklist (extends §25 CMS Checklist)

### Before Every WordPress Change
- [ ] Output escaping verified on every `echo` of dynamic data (§20.1).
- [ ] Nonce fields present on all forms; handlers verify them (§20.1).
- [ ] Capability checks present on all privileged actions (§20.1).
- [ ] Database queries use `$wpdb->prepare()` or WordPress API functions (§20.1).
- [ ] Custom functions and hooks use project prefix (§20.4).
- [ ] Assets loaded conditionally with `wp_enqueue_*()` (§20.5).
