# Web Frontend Guardrails

**Extension of [Rapid Development Guardrails](../umami.md) — §17**

This extension covers browser-based web applications — SPAs, SSR apps, static sites, and web dashboards. The core template covers testing, specs, and process discipline generically. This extension adds the visual, accessibility, and performance dimensions unique to frontend work.

**Apply this extension when** the §0.2 system shape questionnaire identifies a Web Frontend layer.

---

## 17.1 Visual Regression Testing

The core template (§3) mentions visual regression as a test layer. This section specifies the discipline around it.

**What it is:** Automated screenshot comparison between a known-good baseline and the current state. Catches unintended cosmetic changes — misalignment, color drift, font substitution, z-index collisions — that no unit test will find.

**Rules:**
- Baseline screenshots are **version-controlled artifacts** checked into git, not generated on the fly.
- Update baselines **only for intentional changes**. Every baseline update should correspond to a deliberate design decision — never a side effect of a bug fix.
- Run visual regression before committing any UI change. No exceptions.
- Set a pixel-diff tolerance appropriate to your stack (anti-aliasing causes 1-2px differences across environments).
- Organize baselines to mirror the component tree — finding the baseline for a component should be as easy as finding the component itself.

**Tooling (examples, not prescriptions):** Playwright screenshots, Chromatic, Percy, BackstopJS, Storybook visual tests.

**When to defer:** If the UI layer doesn't exist yet (e.g., API-first projects), defer this entirely. Don't build visual testing infrastructure for a UI that hasn't been designed.

---

## 17.2 Design System Enforcement

A design system prevents the UI from diverging across contributors. Without one, every developer (and every AI agent) invents their own spacing, color palette, and component patterns.

**What to codify:**

| Category | What to specify | Why |
|----------|----------------|-----|
| **Colors** | Named tokens (e.g., `--color-primary`, `--color-error`) | Prevents hex values scattered across files; enables theme changes from one place |
| **Typography** | Font stack, size scale, line heights, weight usage | Prevents 14 different font sizes across the app |
| **Spacing** | Scale (4px base, or 8px base) and named tokens | Prevents arbitrary margins/padding |
| **Component patterns** | Button variants, form inputs, card layouts, modals | Prevents multiple implementations of the same concept |
| **Responsive breakpoints** | Named breakpoints with specific pixel values | Prevents inconsistent mobile behavior |

**Enforcement:**
- All visual values via CSS custom properties or theme tokens — never hardcoded hex, px, or font-family in component files.
- A living style guide or Storybook that shows every component in every variant.
- Style audit file (§7) that tracks violations and their resolution status.

---

## 17.3 CSS / Style Audit Discipline

The core template (§7) introduces living audit files. For web projects, the style audit is one of the most impactful.

**What to track:**

```markdown
## Style Audit

### Resolved
- [x] Hardcoded #333 in Header.tsx → replaced with var(--color-text-primary)
- [x] Inconsistent button padding across forms → standardized to design system

### Open
- [ ] SEVERITY:MEDIUM — Dashboard cards use 3 different border-radius values
- [ ] SEVERITY:LOW — Footer links don't match navigation link styles

### Banned Patterns
- No inline styles except for dynamic values (e.g., calculated widths)
- No `!important` without a comment explaining why
- No z-index values outside the defined scale
```

**Maintenance:** Update the audit when issues are found or resolved. Review it before any UI PR. The audit prevents cosmetic drift from accumulating silently.

---

## 17.4 E2E Browser Testing

Unit tests verify logic. E2E browser tests verify that **users can actually do things** — navigate, fill forms, see feedback, complete flows.

**What to cover (prioritized by value):**

| Priority | What to test | Why |
|----------|-------------|-----|
| **Critical** | Auth flows (login, logout, session expiry) | Broken auth = no access to anything |
| **Critical** | Primary user journeys (the 3-5 things users do most) | Broken core flows = product is useless |
| **High** | Form submission + validation feedback | Users must see errors and know how to fix them |
| **High** | Navigation between major sections | Broken links and dead routes are immediately visible |
| **Medium** | Edge cases (empty states, error pages, loading states) | These are what users see when things go wrong |
| **Low** | Cosmetic-only flows | Visual regression covers this better |

**Rules:**
- Hard timeouts on every test (individual + suite-level). Browser tests that hang waste CI minutes and block merges.
- Tests should be deterministic — no flaky assertions on animations, timing, or external APIs. Mock external dependencies.
- Test against a consistent viewport. Document the viewport size in the test config.
- Use data-testid attributes for selectors, not CSS classes or DOM structure. Classes change; test IDs don't.

---

## 17.5 Accessibility Testing

Accessibility is not a feature — it's a quality bar. Catching violations early prevents expensive retrofitting later.

**Testing layers:**

| Layer | What it catches | When to run |
|-------|----------------|-------------|
| **Automated lint** (eslint-plugin-jsx-a11y, axe-linter) | Missing alt text, missing labels, invalid ARIA | On save / pre-commit |
| **Automated scan** (axe-core, Lighthouse CI) | Color contrast, focus order, semantic HTML, landmark regions | CI on every PR |
| **Manual audit** | Keyboard navigation, screen reader behavior, cognitive load | Before major releases |

**Minimum bar:**
- Every interactive element is keyboard-accessible.
- Every image has alt text (or `alt=""` for decorative images).
- Every form input has a visible label (not just placeholder text).
- Color is never the sole indicator of state (error, success, active).
- WCAG 2.1 AA contrast ratios on all text.

---

## 17.6 Performance Budgets

Without budgets, bundle sizes creep and render times increase. No single PR looks like the problem; the cumulative effect does. Budgets catch what code review can't.

**What to budget:**

| Metric | What it measures | Suggested budget |
|--------|-----------------|-----------------|
| **Bundle size** (JS, gzipped) | Total download cost | Set per-route; alert if a route exceeds its baseline by >10% |
| **Largest Contentful Paint (LCP)** | Time to main content visible | < 2.5s on 4G |
| **Cumulative Layout Shift (CLS)** | Visual stability during load | < 0.1 |
| **First Input Delay (FID) / INP** | Responsiveness to interaction | < 200ms |
| **Image weight** | Total image payload per page | Set per-page; enforce with build-time image optimization |

**Enforcement:**
- Bundle analyzer in CI that fails the build if a route exceeds its budget.
- Lighthouse CI score thresholds (performance, accessibility, best practices).
- No un-optimized images committed — enforce WebP/AVIF conversion or responsive `srcset`.

---

## 17.7 Component Contract Patterns

The core template (§2) covers specification-first development. For web frontends, component contracts have specific patterns:

**Every shared component should define:**
- **Props interface** — typed inputs with required vs. optional clearly marked.
- **Default state** — what the component renders with no data or in its initial state.
- **Error state** — what happens when data is invalid, missing, or fails to load.
- **Loading state** — what the component shows while waiting for async data.
- **Empty state** — what appears when the data set is valid but contains no items.

**Anti-patterns:**
- Components that crash on `null` or `undefined` props instead of rendering an empty/error state.
- Components that accept `any` or untyped props — defeats the purpose of a contract.
- Components with implicit dependencies on global state or context that aren't documented in the interface.

---

## 17.8 Frontend Observability

Performance budgets (§17.6) set targets in the lab. Frontend observability measures what users actually experience in production — different devices, different networks, different usage patterns.

### Real User Monitoring (RUM)

Lab testing (Lighthouse, bundler analysis) catches regressions before deploy. RUM captures what happens after deploy — on real devices, real networks, under real load.

**What to measure in production:**

| Signal | What it tells you | Lab equivalent |
|--------|-------------------|----------------|
| **LCP** (Largest Contentful Paint) | How fast content appears for real users | Lighthouse LCP score |
| **INP** (Interaction to Next Paint) | How responsive the page feels when users interact | Lighthouse FID/INP |
| **CLS** (Cumulative Layout Shift) | How stable the page is during load | Lighthouse CLS score |
| **TTFB** (Time to First Byte) | Server and network latency real users experience | Dev tools network tab |

**Rules:**
- Measure Core Web Vitals from real users, not just synthetic tests. A page that scores 100 in Lighthouse on your dev machine may have a 4s LCP on a mid-range phone over 3G.
- Segment RUM data by device type, connection speed, and geography. Aggregate p75 hides that your mobile users on slow connections have a terrible experience.
- Set alerts when field metrics degrade beyond your performance budgets (§17.6). A 20% LCP regression that persists for 24 hours should trigger investigation.

### Client-Side Error Tracking

JavaScript errors in production are invisible unless you capture them. Users don't file bug reports for a broken dropdown — they leave.

**What to capture:**
- **Unhandled exceptions** — `window.onerror`, `unhandledrejection`. Include the stack trace, browser, OS, and URL.
- **Failed API calls** — responses with 4xx/5xx status or network failures. Include the endpoint, status, and request context (not the request body — it may contain PII).
- **Console errors** — framework-specific errors (React error boundaries, Vue error handlers) that don't bubble to `window.onerror`.

**Rules:**
- Never include PII, auth tokens, or request/response bodies in error telemetry.
- Group errors by stack trace, not by message — the same root cause with slightly different inputs should be one issue, not thousands.
- Track error-free session rate as a health metric. A sudden drop correlates with a bad deploy.

**Tooling (examples, not prescriptions):** Sentry, LogRocket, Datadog RUM, OpenTelemetry browser SDK, web-vitals library.

---

## 17.9 Source Map and Build Output Discipline

The core template (§4) covers build output hygiene as a general security concern. For web frontends, source maps are the highest-risk artifact — they expose the entire original source tree (file paths, comments, internal logic) to anyone who opens browser devtools.

**Source map rules:**

| Environment | Source map setting | Why |
|---|---|---|
| **Local development** | Full source maps (`eval-source-map`, `inline-source-map`, or equivalent) | You need them for debugging |
| **CI/staging** | Full source maps, but not served publicly | Useful for debugging staging issues |
| **Production** | No source maps, OR upload to error-tracking only | Source maps in production expose your codebase to the public |

**If you need production debugging without public source maps:**
- Upload source maps to your error-tracking service (Sentry, Datadog, Bugsnag) during the build step, then **delete them from the deploy directory** before deployment.
- The error tracker uses them to symbolicate stack traces; users never see them.
- Never rely on the web server to block access to `.map` files — misconfiguration or CDN caching can bypass server rules.

**Build output scanning:**
- Add a CI step that checks the deploy directory for `*.map` files, `.env*` files, and files exceeding an expected size (a 10MB JS bundle probably contains something it shouldn't).
- Verify that `devtool` (webpack), `sourcemap` (Vite/Rollup), or the equivalent setting is disabled or set to a non-emitting value in the production build config.
- Check that `NODE_ENV=production` (or framework equivalent) is set — many frameworks include additional debug code, component names, and verbose error messages in development mode.

**`.gitignore` for web projects (minimum):**
```
dist/
build/
out/
.next/
*.map
.env*
node_modules/
```

**Anti-pattern:** Committing build output to the repo "for convenience" (e.g., committing `dist/` so it can be served directly). Build artifacts in git history persist even after deletion, and source maps, debug builds, or baked-in secrets may be recoverable from older commits.

---

## Common Web Frontend Anti-Patterns

When building or reviewing frontend code, flag these if you see them.

| Anti-pattern | Why it's harmful | What to do instead |
|---|---|---|
| **Testing the wrong layer** | Writing unit tests for layout bugs or visual regression tests for business logic. Each test layer has a purpose (§17.1, §17.4) — mismatched tests catch nothing and waste maintenance effort. | Visual issues → visual regression. User flows → E2E. Logic → unit tests. Match the test to the failure mode it's designed to catch. |
| **Accessibility as afterthought** | Building the full UI then trying to retrofit accessibility. Semantic HTML, keyboard navigation, and ARIA attributes are 10x harder to add after the fact than to include from the start. | Start with semantic HTML and keyboard navigation. Add ARIA only when native semantics aren't sufficient. Run automated a11y checks from the first PR, not the last (§17.5). |
| **Component proliferation** | 12 button variants, 8 card layouts, 5 modal patterns — each slightly different. Every new variant adds maintenance cost and visual inconsistency. | Use a design system (§17.2). When asked for a "slightly different" component, first check if an existing variant works. Add variants only when the design system genuinely needs them. |
| **Premature performance optimization** | Code-splitting a 50KB bundle, adding a CDN for 3 images, implementing virtual scrolling for a list of 20 items. Optimization without measurement is guesswork. | Measure first (§17.6). Set budgets, monitor with RUM (§17.8), optimize the bottlenecks the data shows — not the ones you imagine. |
| **"It works on my machine"** | Developing and testing only on a high-end MacBook with fast WiFi. Real users have mid-range phones on 3G connections. | Test on representative devices and connections. Use Chrome DevTools throttling as a minimum. Monitor Core Web Vitals by device type in production (§17.8). |
| **Framework churn** | Rewriting to the latest framework instead of shipping features. The cost of a framework migration is paid in months; the benefit of shipping features is immediate. | Evaluate framework changes through the lens of §7 (ADRs) — document the problem the current framework can't solve, not the features the new framework offers. |

---

## Mapping to Core Guardrail Sections

| Core Section | Web Frontend Equivalent |
|---|---|
| §2 Specs | §17.7 Component contracts (props, states, error handling) |
| §3 Testing | §17.1 Visual regression + §17.4 E2E browser tests + §17.5 Accessibility |
| §6 Consistency | §17.2 Design system + §17.3 Style audit |
| §7 Documentation | §17.3 Living style audit, design system docs |
| §11 File Size | §17.6 Performance budgets (bundle size, image weight) |
| §4 Observability | §17.8 Frontend observability — RUM, error tracking, production performance |
| §4 Build output hygiene | §17.9 Source map discipline — production source map policy, build scanning |

---

## Web Frontend Checklist (extends §15)

### Before Every UI Change
- [ ] Design system consulted — using existing tokens and components, not inventing new ones.
- [ ] Visual regression baselines current (run visual tests before and after).
- [ ] Accessibility lint passing (no new violations introduced).

### Before Every UI PR
- [ ] E2E tests pass for affected user flows.
- [ ] Accessibility scan passes (axe-core / Lighthouse).
- [ ] Bundle size within budget (no route exceeds its threshold).
- [ ] Style audit updated if new patterns introduced or violations found.
- [ ] Responsive behavior verified at all defined breakpoints.
- [ ] Loading, empty, and error states verified for new components.
- [ ] Error boundaries in place for new async components (§17.8).
- [ ] Production build contains no source maps unless uploaded to error-tracking only (§17.9).
- [ ] No `.env` files, debug flags, or secrets in build output directory (§17.9).

### After Deploy
- [ ] RUM metrics checked — no Core Web Vitals regression vs. pre-deploy baseline (§17.8).
- [ ] Client-side error rate stable — no spike in unhandled exceptions (§17.8).
