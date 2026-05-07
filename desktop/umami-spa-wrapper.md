# SPA Wrapper Guardrails

**Extension of [Desktop Linux Guardrails](umami-linux.md) — §29**

This extension covers the specific pattern of wrapping a web application in a native desktop shell using WebKitGTK — turning web-only services (messaging apps, SaaS tools, dashboards) into first-class GNOME desktop applications without Electron.

**Apply this extension when** the project wraps an existing web application in a GTK4/WebKitGTK window. This pattern is distinct from building a web frontend (§17) — you don't control the web app's code, you control the shell around it.

> **Status — narrowest extension in the corpus.** §29 documents one specific build pattern, not a generic application domain on equal footing with §17 (web), §18 (data), §27 (desktop). Most desktop projects do not need §29; they should stop at §27 (and optionally §28). Load this file only when the project literally is a WebKitGTK SPA wrapper. It exists in the public template because the trade-offs it documents (session persistence, ITP, navigation policy, clipboard bridge, notification forwarding, dock badge wiring) recur for everyone who builds this kind of app, and the failure modes are non-obvious enough to be worth recording. Treat it as a worked example of how §27 and §28 compose for a concrete pattern rather than a peer extension.

**Loading order:**
1. [umami.md](../umami.md) — core guardrails
2. [umami-desktop.md](../umami-desktop.md) — desktop-generic practices (§27)
3. [desktop/umami-linux.md](umami-linux.md) — Linux platform details (§28)
4. This file (`desktop/umami-spa-wrapper.md`) — SPA wrapper pattern (§29)

---

## 29.1 Architecture Pattern

An SPA wrapper is a single-file Python app that embeds a `WebKit.WebView` inside a GTK4/libadwaita window. The web app runs inside WebKitGTK's renderer process; the Python host provides native OS integration that the web app can't do from a browser tab.

### Standard Stack

| Component | Role |
|-----------|------|
| `Adw.ApplicationWindow` + `Adw.ToolbarView` + `Adw.HeaderBar` | Native GNOME window chrome |
| `WebKit.WebView` with `WebKit.NetworkSession` | Web renderer with persistent storage |
| `WebKit.WebsitePolicies` | Autoplay, media permissions |
| `WebKit.UserContentManager` | JavaScript injection (user scripts), message handlers for bridge APIs |
| `Gio.Notification` | Native notification forwarding |
| DBus `com.canonical.Unity.LauncherEntry` | Dock badge (unread count) |

### Single-File Rule

All logic lives in `{app}.py`. The file set is:

```
{app}/
├── CLAUDE.md           # Project instructions
├── {app}.py            # Single-file app (all logic)
├── {app}.svg           # App icon
├── {app}.desktop       # GNOME desktop entry
├── install.sh          # Install icon + desktop entry
└── .gitignore
```

Do not split into modules unless the file exceeds 400 lines (see §27.2). The SPA wrappers for messaging apps typically stay well under this budget.

---

## 29.2 Session Persistence

The most critical requirement for an SPA wrapper is that **login survives restarts**. Users should not re-authenticate (or re-scan a QR code) every time they launch the app.

### What Must Persist

| Store | Contains | Persistence mechanism |
|-------|----------|----------------------|
| **Cookies** | Auth tokens, session IDs | SQLite cookie jar via `NetworkSession` |
| **IndexedDB** | App data, offline cache | `NetworkSession.new(data_directory=...)` |
| **localStorage** | User preferences, tokens | Same `data_directory` |
| **Service workers** | Offline support, push notifications | Same `data_directory` |

### Required Configuration

```python
session = WebKit.NetworkSession.new(
    data_directory=DATA_DIR,      # e.g., ~/.local/share/{app}-web/
    cache_directory=CACHE_DIR     # e.g., ~/.cache/{app}-web/
)
```

### ITP (Intelligent Tracking Prevention)

WebKitGTK enables ITP by default. ITP classifies many auth tokens as "tracking cookies" and **purges them after 7 days or on restart**. This silently logs users out.

**Rule:** Always disable ITP for SPA wrappers:

```python
session.get_website_data_manager().set_itp_enabled(False)
```

### Cookie Accept Policy

SSO flows (Google, Microsoft, Okta, etc.) require third-party cookies. Set the policy to `ALWAYS`:

```python
session.get_cookie_manager().set_accept_policy(WebKit.CookieAcceptPolicy.ALWAYS)
```

Without this, SSO redirects silently fail because the identity provider can't set cookies in the WebView's context.

---

## 29.3 Navigation Policy

An SPA wrapper must distinguish between in-app navigation and external links. The wrong policy either breaks the app (blocking legitimate requests) or defeats the purpose of the wrapper (opening everything in a browser).

### Decision Logic

```
1. Non-navigation decisions (resource loads, responses) → allow
2. App domains (*.service.com, *.service-cdn.com) → allow
3. SSO/OAuth provider domains → allow (see §29.4)
4. blob: and data: URIs → allow
5. All other http/https → open in system browser, reject in WebView
```

### Implementation

Handle the `decide-policy` signal for `NAVIGATION_ACTION` and `NEW_WINDOW_ACTION`. Also handle the `create` signal for `window.open()` / `target="_blank"` links that fire before the policy decision.

Open external links via `Gio.AppInfo.launch_default_for_uri()`.

### Domain Allow-Lists

Document the app's domain list in `CLAUDE.md`:

```markdown
## Allowed Domains
- *.slack.com, *.slack-edge.com, *.slack-imgs.com, *.slack-files.com
- SSO: accounts.google.com, login.microsoftonline.com, ...
```

This prevents agents from accidentally breaking navigation policy when adding features.

---

## 29.4 SSO/OAuth In-App Flow

Many web apps delegate authentication to external identity providers. These flows **must complete inside the WebView** — if the SSO redirect opens in an external browser, the auth token lands in the wrong context and the WebView never receives it.

### SSO Provider Domains to Allow

| Provider | Domains |
|----------|---------|
| Google | `accounts.google.com`, `*.google.com` |
| Microsoft | `login.microsoftonline.com`, `login.live.com`, `*.microsoft.com` |
| Apple | `appleid.apple.com` |
| Okta | `*.okta.com`, `*.oktapreview.com` |
| OneLogin | `*.onelogin.com` |
| Duo | `*.duosecurity.com` |
| Auth0 | `*.auth0.com` |
| Salesforce | `*.salesforce.com`, `*.force.com` |

### target="_blank" Handling

SSO links often use `target="_blank"`. The `create` signal fires when WebKitGTK is asked to open a new window. For SSO domains, load the URL in the existing WebView instead of opening the system browser. For non-SSO external domains, open in the system browser.

---

## 29.5 Clipboard Bridge

WebKitGTK does **not** expose clipboard images to the web Clipboard API. When a user copies an image from the desktop and pastes into the web app, the web app receives nothing. A bridge is required.

### Bridge Architecture

```
1. JS user script intercepts `paste` events in the WebView
2. JS sends a message to Python via UserContentManager message handler
3. Python reads the GTK clipboard (Gdk.Clipboard)
4. Python base64-encodes the file/image data
5. Python calls a JS function to inject the data back into the web app
6. JS creates a synthetic event that the web app's paste handler consumes
```

### Platform-Specific Clipboard Behavior

On GNOME with the portal (Wayland), the clipboard does **not** contain raw `image/*` textures when a screenshot or file is copied. Instead it contains:

| MIME type | Content |
|-----------|---------|
| `application/vnd.portal.files` | Portal file descriptor |
| `text/uri-list` | File URI(s) |
| `text/plain;charset=utf-8` | File path as text |

**Rule:** Always try `text/uri-list` first, parse the file path, read the file from disk, and base64-encode it. Do not assume `image/*` MIME types will be present.

### Injection Method (Varies by Web App)

Different web apps consume clipboard data differently:

| Web app pattern | Injection method |
|-----------------|-----------------|
| Accepts `drop` events on the composer | Create `File` via `DataTransfer`, dispatch synthetic `drop` event |
| Has a visible `<input type="file">` | Set `.files` on the input via `DataTransfer`, dispatch `change` event |
| Accepts `ClipboardEvent('paste')` | Create synthetic paste event with `DataTransfer` containing the file |

**Warning:** `ClipboardEvent.clipboardData` is read-only in WebKit — creating a `ClipboardEvent` and setting its data does not work in all cases. Test each web app's specific paste handler.

**Warning:** Some web apps have multiple `<input type="file">` elements for different purposes (photos vs. documents vs. stickers). Check the `accept` attribute to target the correct one.

---

## 29.6 Notification Forwarding

Web apps request notification permission via the Notification API. The wrapper must bridge these to native GNOME notifications.

### Implementation

1. **Auto-grant permission:** Handle the `permission-request` signal; accept `NotificationPermissionRequest` automatically.
2. **Patch `Notification.permission`:** Inject a user script that ensures `Notification.permission` returns `"granted"` — some web apps check this property directly and disable notification UI if it's not granted.
3. **Forward notifications:** Handle the `show-notification` signal on the WebView. Create a `Gio.Notification` with the title and body, send via `app.send_notification()`.

---

## 29.7 Dock Badge (Unread Count)

Most messaging web apps encode the unread count in the page title:

| App | Title format |
|-----|-------------|
| Slack | `(N) Slack \| workspace` or `* Slack \| workspace` |
| Telegram | `Telegram (N)` |
| WhatsApp | `WhatsApp (N)` |

### Implementation

1. Watch the `notify::title` signal on the WebView
2. Parse the count with a regex (handle both `(N)` prefix and suffix patterns)
3. Map `*` prefix (Slack's "unread but no mentions") to badge count 1
4. Send via `com.canonical.Unity.LauncherEntry` DBus signal (see §28.6)

---

## 29.8 Audio and Media Permissions

WebKitGTK's default settings break audio and video playback in most web apps.

### Required Settings

```python
# On WebView construction:
policies = WebKit.WebsitePolicies(autoplay=WebKit.AutoplayPolicy.ALLOW)
webview = WebKit.WebView(website_policies=policies)

# On WebKit.Settings:
settings.set_enable_webaudio(True)
settings.set_enable_encrypted_media(True)  # DRM content (calls, media)
```

### Navigation Policy for Media

The navigation policy (§29.3) must explicitly allow:
- `blob:` URIs — used for in-memory audio/video
- `data:` URIs — used for inline media
- Non-navigation policy decisions must call `decision.use()` — resource loads (scripts, images, audio chunks) should never be blocked

### Permission Auto-Grant

Auto-grant these permissions via the `permission-request` signal:

| Permission | Why |
|------------|-----|
| `NotificationPermissionRequest` | Notifications (§29.6) |
| `MediaKeySystemPermissionRequest` | Encrypted media / DRM |
| `UserMediaPermissionRequest` | Camera/microphone for calls |
| `ClipboardPermissionRequest` | Clipboard access (if available in WebKitGTK version) |

---

## 29.9 Context Menu

WebKitGTK provides a default right-click context menu (Back, Forward, Copy, etc.). Most web apps have their own context menus that this overrides.

**Rule:** Suppress the WebKitGTK context menu by returning `True` from the `context-menu` signal. This lets the web app's own context menu work.

---

## 29.10 Debug Mode

SPA wrappers should support a `--dev` flag for debugging:

| Feature | Production | `--dev` mode |
|---------|-----------|--------------|
| `console.log` output | Suppressed | Printed to stdout |
| WebKit developer extras | Disabled | Enabled (Web Inspector) |
| `print()` debug logging | None | Enabled |

**Critical rule:** Never commit code with debug features enabled. No `set_enable_developer_extras(True)`, no `set_enable_write_console_messages_to_stdout(True)`, no stray `print()` calls in the production path.

---

## 29.11 Never Monkey-Patch Browser APIs

When debugging audio, clipboard, or other browser API issues, it's tempting to override native constructors in user scripts:

```javascript
// DO NOT DO THIS
const _OrigAudioContext = window.AudioContext;
window.AudioContext = function(...args) { console.log('AudioContext created'); ... };
```

This breaks web apps that depend on the native constructor's exact behavior (prototype chain, instanceof checks, internal slots). Debug hooks that wrap browser APIs must be removed before committing.

---

## 29.12 Pre-Commit Checklist (SPA Wrapper Additions)

Add these to the project's §15, §27.9, and §28.10 checklists:

- [ ] App launches and loads the target web app without errors
- [ ] Login persists across restarts (cookies, IndexedDB, localStorage survive)
- [ ] SSO/OAuth flows complete inside the WebView (don't open in external browser)
- [ ] External links open in the system browser (don't load in WebView)
- [ ] No `console.log`, `print()`, `set_enable_developer_extras(True)` in committed code
- [ ] No monkey-patched browser APIs (AudioContext, Notification, URL.createObjectURL)
- [ ] Clipboard paste works for images (if implemented)
- [ ] Notifications forward to native GNOME notifications (if implemented)
- [ ] Dock badge updates with unread count (if implemented)
