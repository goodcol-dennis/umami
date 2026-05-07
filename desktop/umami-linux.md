# Desktop Linux Guardrails

**Extension of [Desktop Application Guardrails](../umami-desktop.md) — §28**

This extension covers Linux-specific desktop development — GTK4/libadwaita, Wayland/X11 input handling, XDG compliance, DBus integration, and the Linux-specific E2E testing toolchain. It applies to both native GUI apps and SPA wrappers running on Linux.

**Apply this extension when** the project is a desktop application targeting Linux. Load it alongside the parent [umami-desktop.md](../umami-desktop.md) (§27). If the project wraps a web app in WebKitGTK, also load [umami-spa-wrapper.md](umami-spa-wrapper.md) (§29).

> **Scope note:** Linux is currently the only OS-specific sub-extension under §27. That asymmetry reflects contributor experience, not a claim that Linux deserves special treatment. Projects targeting macOS or Windows should still load §27 for cross-platform desktop guardrails; OS-specific patterns for those platforms belong in new sibling sub-extensions, not in this file. PRs welcome.

**Loading order:**
1. [umami.md](../umami.md) — core guardrails
2. [umami-desktop.md](../umami-desktop.md) — desktop-generic practices (§27)
3. This file (`desktop/umami-linux.md`) — Linux platform details (§28)
4. Optionally, [desktop/umami-spa-wrapper.md](umami-spa-wrapper.md) — SPA wrapper pattern (§29)

---

## 28.1 Toolkit Selection

Linux desktop apps typically use one of these toolkits. The choice affects everything downstream — testing infrastructure, packaging, OS integration depth.

| Toolkit | Language | Rendering | When to use |
|---------|----------|-----------|-------------|
| **GTK4 + libadwaita** | Python (PyGObject), Rust (gtk4-rs), C | Native GNOME widgets, Wayland-first | GNOME-native apps, follows HIG, deep OS integration (notifications, portals, header bars) |
| **Qt 6** | C++, Python (PyQt/PySide) | Native or custom widgets | Cross-platform apps, KDE integration |
| **Immediate-mode (egui, Dear ImGui)** | Rust, C++ | GPU-rendered, no retained widget tree | Custom UIs that don't fit native widgets, tools, prototypes; trades native look-and-feel for layout flexibility |

**Document the choice in `CLAUDE.md`** with the exact version pins:

```
| Component | Version |
|-----------|---------|
| GTK       | 4.0 (`gi.require_version("Gtk", "4.0")`) |
| libadwaita| 1 (`gi.require_version("Adw", "1")`)      |
```

This prevents agents from importing the wrong version or using deprecated API surfaces.

---

## 28.2 Wayland and X11

Wayland is the default on modern GNOME and KDE. X11 is the fallback. Both affect input handling and E2E testing.

### Wayland Considerations

| Issue | Impact | Mitigation |
|-------|--------|------------|
| **No global hotkeys** | Can't register system-wide shortcuts from userspace | Use DBus or portal APIs if needed |
| **Input injection requires `wtype`** | `xdotool` doesn't work under Wayland | Use `wtype` for keyboard, `wlrctl` for mouse in E2E tests |
| **Key repeat quirks** | Some toolkits (egui) mark the initial keypress as `repeat: true` | Deduplicate per-key per-frame; take last state |
| **Clipboard via portals** | GNOME portal clipboard provides `application/vnd.portal.files` + `text/uri-list`, not raw `image/*` | Parse file URIs and read the actual files; don't assume image textures in clipboard |
| **DMA-BUF renderer issues** | `WEBKIT_DISABLE_DMABUF_RENDERER=1` causes severe keyboard/rendering lag on some GPU/driver combinations | Never set this env var — shader warnings are cosmetic. Document the GPU in `CLAUDE.md` so agents don't cargo-cult this workaround. |

### X11 Fallback for Testing

When Wayland E2E is unreliable, X11 via Xvfb provides a stable alternative:

```bash
export DISPLAY=:99
export GDK_BACKEND=x11
Xvfb :99 -screen 0 1280x800x24 &
```

Use `xdotool` for input injection under X11. This is especially useful for GTK4 apps where `GDK_BACKEND=x11` forces the X11 backend.

---

## 28.3 Headless E2E Toolchain (Linux-Specific)

The §27.3 F11/F12 test protocol is framework-agnostic. On Linux, the toolchain is:

| Tool | Purpose | Install |
|------|---------|---------|
| **cage** | Headless Wayland compositor (wlroots-based) | `sudo apt install cage` |
| **wtype** | Keyboard input injection (Wayland) | `sudo apt install wtype` |
| **wlrctl** | Mouse/pointer control (Wayland) | `sudo apt install wlrctl` |
| **Xvfb** | Virtual X11 framebuffer (fallback) | `sudo apt install xvfb` |
| **xdotool** | Input injection (X11) | `sudo apt install xdotool` |

### Cage Session Management

Starting a headless cage session follows the same pattern across projects:

1. Snapshot existing Wayland sockets in `$XDG_RUNTIME_DIR`
2. Start `cage -d -- /path/to/app` (with appropriate env vars)
3. Poll for a new socket (diff against snapshot)
4. Export `WAYLAND_DISPLAY` to the new socket name
5. Send a warmup keypress (first `wtype` call creates the virtual keyboard device)
6. Wait for app initialization

**Rust implementation:** Use a `HeadlessSession` struct with `start()`, `wtype_raw()`, `wlrctl()` methods, and a `Drop` impl that kills the cage process.

**Bash implementation:** Use a `start_session()` function with a `cleanup()` trap on EXIT.

### Timing Constants

These are starting points — tune per-project based on app complexity:

| Constant | Typical value | Purpose |
|----------|---------------|---------|
| Warmup delay | 1000–4000ms | Time for compositor + app to initialize |
| Command delay | 400–600ms | Time for app to process an F11 command |
| Short delay | 200–300ms | After a keypress before reading state |
| State dump timeout | 2000ms | Max wait for F12 state file to appear |

---

## 28.4 GTK4 + libadwaita Patterns

### Window Structure

The standard GNOME app window:

```
Adw.ApplicationWindow
  └── Adw.ToolbarView
        ├── Adw.HeaderBar (top)
        └── [content widget] (center)
```

This gives you native GNOME window controls (close/maximize/minimize), correct CSD (client-side decorations), and automatic dark mode support.

### GObject Introspection Version Pinning (Python)

Always pin GI versions before importing:

```python
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("WebKit", "6.0")  # if using WebKitGTK
```

This prevents silent loading of GTK3 or other incompatible versions.

### Action Registration

Use GIO actions for all keyboard-triggered operations. Register actions on the window, bind them to keyboard shortcuts via `ShortcutController`. This separates "what the action does" from "how it's triggered" and makes actions testable via the F11 command protocol.

### File Dialogs

Use `rfd` (Rust) or the GTK4 `FileDialog` API. Both respect the XDG portal on sandboxed systems (Flatpak, Snap) and fall back to native dialogs otherwise.

---

## 28.5 egui/eframe Patterns

### Immediate Mode Considerations

egui redraws every frame. This means:
- **No retained widget state** — the UI is rebuilt from application state each frame
- **Input events are per-frame** — deduplicate keypresses that span multiple frames
- **Performance-sensitive** — debug builds may be too slow for real-time or graphics-heavy apps. Document a `--release` requirement explicitly when it applies.

### eframe on Linux

eframe handles Wayland/X11 window creation via `winit`. Known issues:
- Wayland key repeat (see §28.2)
- No native file dialogs — use `rfd` crate
- No native system tray — eframe is a pure window, no background daemon

---

## 28.6 DBus Integration

DBus is the standard IPC mechanism on Linux desktops. Common use cases for desktop apps:

| Feature | DBus interface | Notes |
|---------|---------------|-------|
| **Dock badge** (unread count) | `com.canonical.Unity.LauncherEntry` | Works on GNOME with Ubuntu patches; object path must match app ID |
| **Notifications** | `org.freedesktop.Notifications` | Or use `Gio.Notification` which wraps DBus |
| **Media keys** | `org.mpris.MediaPlayer2` | For media player apps |
| **Single instance** | `org.freedesktop.Application` | Prevent duplicate launches |

### Dock Badge Pattern

```
DBus signal: com.canonical.Unity.LauncherEntry.Update
Object path: /com/example/AppName  (matches App ID with dots → slashes)
Properties:  { "count": N, "count-visible": true }
Desktop file: application://appname.desktop
```

The badge count is typically parsed from the window title (many web apps set the title to `"AppName (N)"` for unread counts).

---

## 28.7 Audio (When Applicable)

Most desktop apps don't need real-time audio guidance. For the minority that do (players, voice, instrument apps, DAWs), the universal Linux principles are:

- **Backend layering** — modern Linux audio is PipeWire with PulseAudio and ALSA shims underneath. Use a cross-toolkit library (e.g., `cpal` for Rust, `miniaudio` for C) rather than calling backends directly; it isolates the app from which daemon happens to be running.
- **Real-time thread discipline** — the audio callback must not allocate, lock, or do I/O. Cross the thread boundary with lock-free queues (single-producer/single-consumer ring buffers for the common case).
- **Buffer-size trade-off** — small buffers reduce latency but raise xrun risk; large buffers are safe but feel laggy for interactive use. Document the chosen default in acknowledged gaps (§8) and make it tunable.

Apps with substantial audio surface area (multi-stream mixing, MIDI routing, plugin hosting) should consider a dedicated audio extension rather than relying on this section.

---

## 28.8 FFI and Native Library Integration

Rust desktop apps often wrap C/C++ libraries via FFI (e.g., system libraries, codec libraries, hardware SDKs, mature C++ engines without Rust equivalents).

| Practice | Why |
|----------|-----|
| Use `cc` crate for build-time compilation of C/C++ wrappers | Keeps the build self-contained; `build.rs` handles compilation |
| Write flat C wrappers around C++ APIs | Rust FFI only speaks C ABI; a thin `wrapper.cpp` with `extern "C"` functions is the bridge |
| Pin the C++ standard version in `build.rs` | e.g., `.flag("-std=c++17")` — prevents surprises across compilers |
| Document system library dependencies | `libasound2-dev`, `libgtk-4-dev`, etc. in `CLAUDE.md` with install commands |
| Keep FFI bindings hand-written for small surfaces | `bindgen` is overkill for 5-10 function wrappers; hand-written FFI is easier to audit |

---

## 28.9 Cargo Workspace Patterns

For multi-crate Rust desktop projects, one common shape is a core/GUI split:

| Crate | Contains | Testable headless? |
|-------|----------|-------------------|
| `{app}-core` | Domain logic, state machine, message types, anything compositor-free | Yes — no GUI dependency |
| `{app}-gui` | Toolkit-specific UI, widgets, layout | No — requires compositor |
| `src/main.rs` | Entry point, thread wiring, CLI args | Integration test only |

**Why split:** The core crate can be tested exhaustively without a display server. Unit tests, property-based tests, and state machine tests all run in CI without cage or Xvfb.

This is one workspace shape, not the only one — small apps may stay single-crate, and apps with multiple frontends (GUI + CLI + library) may split further. The principle is: keep anything that doesn't need a display server out of the GUI crate so CI can exercise it cheaply.

### Pre-Commit Hook Pattern

```bash
cargo fmt -- --check
cargo clippy -- -D warnings
cargo test --release --workspace --lib --test unit_tests --test integration_tests
# E2E tests are NOT in pre-commit — they require cage and are slow
```

E2E tests run manually or in CI with a headless compositor, not in pre-commit.

---

## 28.10 Pre-Commit Checklist (Linux Additions)

Add these to the project's §15 and §27.9 checklist:

- [ ] App launches on Wayland without env var workarounds
- [ ] No `WEBKIT_DISABLE_DMABUF_RENDERER`, `GSK_RENDERER`, or `LIBGL_ALWAYS_SOFTWARE` in committed code
- [ ] System dependencies documented in `CLAUDE.md` with install commands
- [ ] `.desktop` entry and icon are installable via `install.sh`
- [ ] Data directories use XDG paths, not hardcoded `~/.config/` or `~/.local/`
- [ ] If Rust: `cargo fmt`, `cargo clippy -- -D warnings`, `cargo test` all pass
- [ ] If Python: no `gi.require_version()` calls missing for imported modules
