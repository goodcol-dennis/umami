# Desktop Application Guardrails

**Extension of [Rapid Development Guardrails](../../umami.md) — §27**

This extension covers practices common to all desktop applications — native GUI apps, SPA wrappers, and hybrid approaches across any platform. Desktop apps share a distinct risk profile: tight coupling to OS APIs, multi-threaded architectures where GUI and worker threads must coordinate safely, hardware integration (audio, input devices, GPUs), and E2E testing that requires a running compositor or display server.

**Apply this extension when** the §0.2 system shape questionnaire identifies a desktop application layer. Then apply the platform-specific sub-extension ([Linux](umami-linux.md) §28, macOS and Windows forthcoming) for implementation details. If the project is a web-app-in-native-shell wrapper, also apply [SPA Wrapper](umami-spa-wrapper.md) §29.

**Loading order:** A desktop project loads at least two layers:
1. [umami.md](../../umami.md) — core guardrails
2. This file (`umami-desktop.md`) — desktop-generic practices
3. A platform-specific file (e.g., `desktop/umami-linux.md`) — platform implementation details
4. Optionally, a pattern-specific file (e.g., `desktop/umami-spa-wrapper.md`) — if the project wraps a web app

---

## 27.1 GUI Thread Model

Every desktop framework enforces a rule: **UI mutations happen on the main thread.** Violating this produces silent corruption, intermittent crashes, or platform-specific undefined behavior. The specific mechanism varies (GTK main loop, egui frame callback, Cocoa run loop, Win32 message pump), but the discipline is universal.

### Thread Architecture Documentation

Document the thread model in `CLAUDE.md` or a top-level architecture doc. At minimum:

| What to document | Why |
|------------------|-----|
| Which thread owns the GUI event loop | Prevents agents from scheduling UI work on worker threads |
| What communication mechanism connects threads | Lock-free queues, channels, message passing, signals — name the specific type and crate/library |
| What data crosses thread boundaries | Messages should be `Copy`/`Clone`/serializable — no shared mutable state |
| Which operations block and which are async | Blocking the GUI thread freezes the app; blocking a worker thread may starve the pipeline |

### Message-Passing Over Shared State

Prefer explicit message-passing between threads over shared mutable state behind locks. Lock-free ring buffers (SPSC or MPSC) or typed channels make the communication contract visible in the type system and eliminate deadlock risk.

**Pattern:** Define message enums for each direction of communication.

```
GUI → Worker:  enum WorkerCommand { Start, Stop, SetParam(id, value), ... }
Worker → GUI:  enum GuiUpdate { Progress(f32), PeakLevel(f32), Error(String), ... }
```

All message types should be `Copy` (or cheaply cloneable) so the send path never allocates.

**Anti-pattern:** `Arc<Mutex<SharedState>>` for high-frequency updates. Mutex contention on the GUI thread causes frame drops; contention on the audio thread causes glitches.

---

## 27.2 Single-File App Discipline

For small desktop apps (wrappers, utilities, single-purpose tools), a single-file architecture reduces cognitive overhead and eliminates premature module boundaries.

**Rule:** All logic lives in one file until it exceeds **400 lines**. Only then split into modules, and only along natural seam boundaries (e.g., separate the audio engine from the GUI).

**Why this works for agents:** A single file fits entirely in context. Agents don't need to chase imports or build a mental model of module dependencies. When the file grows past the budget, the split points are obvious because the code has matured enough to reveal its natural structure.

**When to split earlier:** If the project has genuinely independent subsystems (e.g., an audio engine and a GUI that communicate only via messages), splitting from the start is fine — the independence is the seam, not the line count.

---

## 27.3 Headless E2E Testing

Desktop E2E testing is harder than web E2E — there's no Playwright equivalent that works across all frameworks. The pattern that works: **run the app inside a headless compositor, inject input, dump state, assert on state.**

### The F11/F12 Test Protocol

Build a test-command interface into the app, activated by a `--test` flag or compile-time feature:

| Key | Purpose | Mechanism |
|-----|---------|-----------|
| **F11** | Inject a test command | App reads a command from a temp file (`/tmp/{app}-input.txt`), parses and executes it |
| **F12** | Dump current state | App writes observable state to a temp file (`/tmp/{app}-state.txt`) as `key=value` pairs |

This protocol is framework-agnostic — it works with GTK, egui, Qt, or any toolkit that can handle keyboard shortcuts and file I/O. The test harness (bash script or Rust test binary) orchestrates the sequence: start app, wait for warmup, send commands via F11, assert state via F12.

**Why F11/F12:** These keys are rarely used by applications, don't conflict with common shortcuts, and are easy to inject via `wtype`, `xdotool`, or platform equivalents.

### Test Harness Structure

A desktop E2E test harness needs:

1. **Session management** — start a headless compositor, launch the app, detect when it's ready
2. **Input injection** — keyboard (`wtype`, `xdotool`) and mouse (`wlrctl`, `xdotool`) input into the headless session
3. **State queries** — trigger state dump, parse the result, assert on values
4. **Cleanup** — kill the compositor and app, remove temp files
5. **Timing** — warmup delays (compositor + app init), command delays (time for the app to process), and state dump timeouts

### Test Priority Tiers

| Tier | What to test | Example |
|------|-------------|---------|
| **P0 — Launch** | App starts, window appears, no crash | Process alive, title set, initial state valid |
| **P1 — Core interaction** | Primary user actions work | Navigation, input handling, mode switching |
| **P2 — Integration** | OS integration features work | Clipboard, notifications, file dialogs, deep links |
| **P3 — Edge cases** | Unusual inputs, error recovery | Invalid commands, rapid input, resize |

### Known Limitations

Headless E2E for desktop apps is inherently less reliable than web E2E:
- **Timing is approximate.** Warmup and command delays depend on hardware, compositor, and toolkit. Expect to tune these per-project.
- **Input injection is fragile.** Some toolkits don't process injected input identically to real hardware input (e.g., egui on Wayland marks injected keys as `repeat: true`).
- **Not all features are testable headless.** Audio output, GPU rendering, and hardware-specific behavior need a real display and real hardware.

Document these limitations in the project's acknowledged gaps (§8) rather than pretending headless E2E covers everything.

---

## 27.4 Headless Unit and Integration Testing

Not all testing requires a compositor. Isolate testable logic from the GUI framework wherever possible.

**Pattern: Headless harness.** If the app has an engine (audio, document model, computation), test it without the GUI. Create a test harness that wires the engine to mock inputs and captures outputs.

| Component | Test headless? | How |
|-----------|---------------|-----|
| Business logic, algorithms | Yes | Standard unit tests |
| Audio/signal processing | Yes | Generate samples, assert properties (no NaN, no clipping, silence after reset) |
| State machine / model | Yes | Drive state transitions, assert invariants |
| GUI layout / rendering | No | Requires compositor — use E2E |
| OS integration (clipboard, notifications) | Partially | Mock the OS API or test via E2E |

**Property-based testing** is especially valuable for engines that process continuous data (audio, image, physics). Assert invariants that must hold for any valid input:
- Output is always finite (no NaN, no infinity)
- Output is within valid range (no clipping beyond ±1.0 for audio)
- Reset produces silence / clean state
- State is consistent after any sequence of valid operations

---

## 27.5 App Identity and Packaging

Desktop apps need OS-level identity for window management, notifications, file associations, and dock/taskbar integration.

| Artifact | Purpose | Convention |
|----------|---------|------------|
| **App ID** | Unique reverse-DNS identifier | `com.example.AppName` — used for DBus, `.desktop` entries, macOS bundle ID, Windows registry |
| **Desktop entry / manifest** | OS app registration | `.desktop` (Linux), `Info.plist` (macOS), app manifest (Windows) |
| **Icon** | App branding | SVG preferred (scales to any size), with PNG fallbacks for platforms that need them |
| **Install script** | Register the app | Copy icon, install desktop entry, register MIME types if applicable |

**Test mode identity:** When the app runs in test mode (`--test`), use a separate App ID (e.g., `com.example.AppName.Test`) so test instances don't collide with production instances in the session bus, cookie stores, or data directories.

---

## 27.6 Data Directory Discipline

Desktop apps store persistent data (settings, session state, caches) in platform-specific locations. Never hardcode paths.

| Platform | Convention | Example |
|----------|-----------|---------|
| Linux | XDG Base Directory spec | `$XDG_DATA_HOME/{app}/`, `$XDG_CONFIG_HOME/{app}/`, `$XDG_CACHE_HOME/{app}/` |
| macOS | `~/Library/Application Support/` | `~/Library/Application Support/{app}/` |
| Windows | `%APPDATA%` | `%APPDATA%\{app}\` |

**Rule:** Use the platform's standard API to resolve these paths (`GLib.get_user_data_dir()`, `dirs::data_dir()`, `NSSearchPathForDirectoriesInDomains`, etc.). Never assume `~/.config/` or `~/Library/` directly.

---

## 27.7 Permission and Capability Model

Desktop apps integrate with OS capabilities (camera, microphone, notifications, clipboard, location). Each platform handles permissions differently, but the discipline is the same:

1. **Request only what you need.** Don't request microphone access for a text editor.
2. **Auto-grant in test mode** where the platform allows it — E2E tests shouldn't block on permission dialogs.
3. **Document granted permissions** in `CLAUDE.md` so agents know what the app can and cannot do.
4. **Handle denial gracefully.** The user may revoke permissions at any time; the app must not crash.

---

## 27.8 Build and Run Discipline

| Practice | Why |
|----------|-----|
| Document the exact build and run commands in `CLAUDE.md` | Agents should never guess; the command table is authoritative |
| Flag debug vs. release requirements | Some apps (especially audio/real-time) are unusable in debug builds due to performance — document this explicitly |
| Pin system dependencies | List required system packages with versions; don't assume they're installed |
| Separate build-time from runtime dependencies | FFI wrappers, code generators, and build scripts are build-time only |

---

## 27.9 Pre-Commit Checklist (Desktop Additions)

Add these to the project's §15 checklist:

- [ ] App launches without errors (manual or E2E)
- [ ] No debug logging in production code (`console.log`, `print()`, `dbg!()`, `set_enable_developer_extras(True)`)
- [ ] No environment variable hacks that mask bugs (`WEBKIT_DISABLE_DMABUF_RENDERER`, `GSK_RENDERER`, `LIBGL_ALWAYS_SOFTWARE`)
- [ ] No unrelated files modified (scope discipline — desktop projects often live alongside sibling projects)
- [ ] If E2E tests exist, they pass (or failures are documented in acknowledged gaps)
- [ ] `.gitignore` excludes local data directories, build artifacts, and `__pycache__`
