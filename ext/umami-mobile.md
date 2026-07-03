# Mobile App Guardrails

**Extension of [Rapid Development Guardrails](../umami.md) — §19**

This extension covers native and cross-platform mobile applications (iOS, Android, React Native, Flutter, Kotlin Multiplatform). Mobile development shares many guardrail principles with web, but differs in release mechanics, testing infrastructure, and constraints. You can't hotfix a shipped binary — every release goes through an app store review process, and users update on their own schedule.

**Apply this extension when** the §0.2 system shape questionnaire identifies a Mobile App layer.

**Adopt when (§0.9 default-deny):** the app ships (or is about to ship) through an app store to users who update on their own schedule. An internal prototype side-loaded onto a handful of devices does not warrant release gates and device matrices.
**Cost profile:** Operator-required · Days initial (support matrix, crash reporting, rollout gates) + Recurring discipline per release.
**Kill criterion:** retire any practice below that has produced no finding, no prevented release incident, and no consulted artifact across 2 consecutive release cycles (§0.9 retirement pass).

---

## 19.1 Device and OS Matrix

Web apps run in browsers you control or can detect. Mobile apps run on hardware and OS versions you cannot control and cannot always reproduce.

**Define a support matrix:**

| Dimension | What to specify |
|-----------|----------------|
| **Minimum OS version** | iOS 16+, Android 12+ (or whatever the project decides) |
| **Target devices** | Specific models or screen size categories (phone vs. tablet) |
| **Screen sizes** | Small (iPhone SE), standard (iPhone 15), large (iPad, foldables) |
| **Orientations** | Portrait-only, landscape-only, or both |
| **Connectivity** | WiFi-only, cellular, offline-capable |

**Rules:**
- Document the matrix in the project README or an ADR. Don't leave it implicit.
- Test on real devices, not just simulators. Simulators miss performance issues, touch behavior differences, and hardware-specific bugs.
- When dropping support for an OS version, document the decision in an ADR with the user impact data that justified it.
- Define a device lab (physical or cloud — BrowserStack, Firebase Test Lab, AWS Device Farm) and run E2E tests against it in CI.

---

## 19.2 Release Discipline

Mobile releases are not deploys — they're submissions to a review process you don't control, followed by a rollout to users who update on their own schedule.

**Practices:**
- **Version everything explicitly** — semantic versioning with build numbers. Every binary should be traceable to a git commit.
- **Never force-update unless safety-critical.** Users hate being forced to update, and app store reviewers may reject aggressive force-update prompts.
- **Maintain backward compatibility with your API** for at least N-2 app versions. Users on old versions will call your API for months after a new release.
- **Feature flags for progressive rollout.** Ship the code, enable the feature for 5% of users, monitor, then ramp up. This is the mobile equivalent of canary deploys.
- **Staged rollouts** — Google Play and Apple TestFlight both support percentage-based rollouts. Use them.

**Release checklist:**
- [ ] Changelog written (user-facing, not developer-facing).
- [ ] Version and build number incremented.
- [ ] Tested on minimum and maximum supported OS versions.
- [ ] API backward compatibility verified for N-2 app versions.
- [ ] Crash monitoring dashboard ready to watch post-release.

---

## 19.3 Offline-First Considerations

Declare the app's connectivity stance up front. If it requires connectivity, say so explicitly. If it should work offline, design for it — retroactive offline support is a near-rewrite.

**Offline architecture decisions (capture in an ADR):**
- What data is available offline? (All data? Recent data? User's own data only?)
- How is offline data stored? (SQLite, Realm, Core Data, file system)
- What happens when the user modifies data offline? (Queue changes? Last-write-wins? Conflict resolution?)
- How does sync work when connectivity resumes? (Automatic? Manual? Delta sync?)

**Rules:**
- If the app works offline, test it offline. Toggle airplane mode during E2E tests.
- Show clear UI indicators for offline state — users should never wonder "did this save?"
- Queue failed network requests for retry. Don't silently drop them.
- Handle sync conflicts explicitly. "Last write wins" is a valid strategy — but document it so users know what to expect.

---

## 19.4 Platform-Specific Testing

Each platform has unique behaviors that cross-platform frameworks abstract over — until they don't.

**iOS-specific concerns:**
- App Store review guidelines compliance (privacy labels, data collection disclosures, in-app purchase rules).
- Background task limits (iOS aggressively kills background processes).
- Push notification permission flow (only one chance to show the system prompt — ask at the right moment).
- Keychain for sensitive data (not UserDefaults or file system).

**Android-specific concerns:**
- Permission model (runtime permissions, not install-time). Handle denial and "don't ask again" gracefully.
- Back button and navigation stack behavior.
- Fragment/Activity lifecycle (configuration changes destroy and recreate the UI — state must survive this).
- Battery optimization (Doze mode, app standby can delay background work).
- Multiple launcher activities and deep link handling.

**Cross-platform framework concerns (React Native, Flutter, etc.):**
- Native module compatibility on both platforms after framework upgrades.
- Platform-specific styling differences that the framework doesn't normalize.
- Performance differences between platforms (especially list rendering, animations).
- Build toolchain breakage after Xcode/Gradle/NDK updates.

---

## 19.5 Mobile Performance Budgets

Mobile devices have constrained CPU, memory, and battery. Performance issues that are invisible on a development machine become obvious on a 3-year-old phone.

**What to budget:**

| Metric | What it measures | Why it matters |
|--------|-----------------|---------------|
| **App launch time** (cold start) | Time from tap to interactive | Users abandon apps that take >3s to launch |
| **App binary size** | Download size on the store | Large apps get fewer installs, especially on slow networks |
| **Memory usage** | Peak and average RAM consumption | OS kills apps that use too much memory |
| **Battery drain** | CPU, GPS, network, and wake lock usage | Users uninstall apps that drain battery |
| **Frame rate** | Rendering smoothness (target: 60fps) | Jank is immediately noticeable on touch interfaces |

**Enforcement:**
- Profile on a low-end device, not your development phone. The gap is real.
- Track binary size in CI — alert if it grows >5% between releases.
- Use platform profiling tools (Xcode Instruments, Android Profiler, Flutter DevTools) before every release.

---

## 19.6 App Store Compliance

App store rejection is a unique risk to mobile development — there is no equivalent in web or backend work. A rejected submission costs a release cycle.

**Common rejection reasons to check proactively:**
- [ ] Privacy policy URL is accessible and accurate.
- [ ] Data collection disclosures match actual behavior (Apple App Privacy, Google Data Safety).
- [ ] In-app purchases use the platform's payment system (where required by store policy).
- [ ] No private API usage (iOS).
- [ ] Content guidelines compliance (if user-generated content is involved).
- [ ] Minimum functionality met — the app does something useful on its own (Apple rejects "thin" apps).
- [ ] Login credentials provided for review (if the app requires authentication).
- [ ] Screenshots and descriptions match actual app behavior.

---

## 19.7 Mobile Observability

You can't SSH into a user's phone. Every production issue must be diagnosed from telemetry alone — crash reports, network traces, and performance metrics sent from the device.

### Crash Reporting

**Crash-free rate is the primary health metric.** Track it per app version, per OS version, per device model. A crash-free rate below 99.5% for any version is a signal to investigate; below 99% is a release quality problem.

**What to capture:**
- **Crash stack traces** — symbolicated (iOS dSYMs, Android ProGuard/R8 mapping files). Unsymbolicated crashes are unreadable. Automate symbol upload in your build pipeline.
- **Breadcrumbs** — the sequence of user actions and events leading up to the crash. "User tapped checkout → API call started → network timeout → crash" tells you more than the stack trace alone.
- **ANR / App Hang detection** — on Android, Application Not Responding events. On iOS, watchdog kills and hang detection. These aren't crashes but feel like them to users.

**Rules:**
- Upload symbol files (dSYMs, mapping files) as part of every release build. Missing symbols make crash reports useless.
- Group crashes by root cause, not by individual occurrence. One null pointer in a shared utility may generate thousands of reports.
- Set up alerts on crash-free rate per version. A new release that drops below baseline within 24 hours of staged rollout should pause the rollout.

### Release Health Monitoring

Staged rollouts (§19.2) only protect you if you're watching the metrics during rollout.

**Monitor during every staged rollout:**
- **Crash-free rate** for the new version vs. the previous version.
- **API error rate** from the new version's clients — a new version hitting an API differently may cause server-side errors.
- **User-reported issues** — app store reviews and support tickets spike faster than metrics for UX-level problems.

**Rule:** Define rollout gates. "Advance from 5% to 25% only if crash-free rate is within 0.1% of the previous version after 24 hours." Without explicit gates, rollouts advance on hope rather than evidence.

### Network Performance from the Client

Server-side metrics show how fast the API responds. Client-side network monitoring shows what the user actually experiences — including DNS resolution, TLS handshake, connection reuse, and cellular vs. WiFi differences.

**What to track:**
- API call latency and failure rate as seen from the device.
- Timeout and retry rates — if the app retries frequently, users are waiting.
- Payload sizes — large responses on slow connections degrade the experience.

**Tooling (examples, not prescriptions):** Firebase Crashlytics, Sentry, Datadog Mobile, New Relic Mobile, Instabug.

---

## Common Mobile Anti-Patterns

When building or reviewing mobile code, flag these if you see them.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **"Works on my iPhone"** | Testing only on the latest flagship device. Performance, layout, and behavior differences between a current iPhone and a 3-year-old Android mid-range phone are significant. | Test on low-end devices in your support matrix (§19.1). Profile performance on the slowest supported device, not the fastest (§19.5). |
| **Ignoring offline until launch** | Assuming connectivity, then trying to retrofit offline support. Offline-first architecture requires fundamentally different data management — local storage, sync queues, conflict resolution — that can't be bolted on. | Decide offline strategy during discovery (§19.3). If the app needs offline support, design the data layer for it from the start. If it doesn't, document that decision explicitly. |
| **All permissions on launch** | Requesting camera, location, contacts, and notifications the first time the user opens the app. Users deny everything by default when asked without context. iOS gives you one shot at the system prompt for many permissions. | Request permissions in context — when the user takes an action that needs the permission. Explain why before asking. Handle denial gracefully (§19.4). |
| **Treating mobile like web** | Porting web navigation patterns, layout assumptions, and interaction models to mobile. Mobile has back buttons, gestures, system bars, safe areas, and platform-specific conventions that web doesn't. | Design for the platform. Follow iOS Human Interface Guidelines and Material Design. Use native navigation patterns (§19.4). When using cross-platform frameworks, test platform-specific behavior on both platforms. |
| **Ship and forget** | Releasing a version and moving to the next without monitoring rollout metrics. A crash regression in the first 24 hours of a 5% staged rollout is cheap to catch; at 100% rollout it's a one-star review storm. | Monitor crash-free rate during every staged rollout (§19.7). Define explicit rollout gates — advance only when metrics confirm stability. |
| **Ignoring binary size** | Adding libraries, assets, and embedded data without tracking binary growth. Large apps get fewer installs (especially in markets with slow connections) and users uninstall them to free storage. | Track binary size in CI (§19.5). Alert if it grows >5% between releases. Review dependencies — a 10MB analytics SDK for an app that only needs event tracking is waste. |

---

## Mapping to Core Guardrail Sections

| Core Section | Mobile Equivalent |
|---|---|
| §2 Specs | §19.3 Offline architecture decisions (ADR), §19.1 Support matrix |
| §3 Testing | §19.4 Platform-specific testing, §19.1 Device matrix testing |
| §3 Visual Regression | Screenshot tests on defined device matrix |
| §6 Consistency | §19.5 Performance budgets, §19.1 OS/device constraints |
| §7 ADRs | Platform choices, offline strategy, minimum OS version decisions |
| §8 Acknowledged Gaps | §19.6 App store compliance risks, untested device/OS combinations |
| §12 Change Tracking | §19.2 Release discipline (versioning, changelogs, staged rollout) |
| §4 Observability | §19.7 Mobile observability — crash reporting, release health, network monitoring |

---

## Mobile Checklist (extends §15)

### Before Every Mobile Change
- [ ] Support matrix consulted — change tested on minimum and maximum supported OS.
- [ ] Offline behavior verified if the change involves data or network calls (§19.3).
- [ ] Platform-specific behavior checked on both iOS and Android (§19.4).

### Before Every Release
- [ ] Version and build number incremented (§19.2).
- [ ] Performance profiled on a low-end device (§19.5).
- [ ] Binary size within budget (§19.5).
- [ ] App store compliance checklist passed (§19.6).
- [ ] API backward compatibility verified for N-2 versions (§19.2).
- [ ] Crash monitoring dashboard configured for the new version (§19.7).
- [ ] Symbol files (dSYMs, ProGuard maps) uploaded for the release build (§19.7).
- [ ] Staged rollout configured (not 100% on day one).

### During Staged Rollout
- [ ] Crash-free rate monitored per version — no regression vs. previous release (§19.7).
- [ ] API error rate from new version clients stable (§19.7).
- [ ] Rollout gates defined — advance only when metrics confirm stability (§19.7).
