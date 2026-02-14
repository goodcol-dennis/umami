# Web Frontend Guardrails

**Extension of [Rapid Development Guardrails](umami.md) — §17**

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

Performance is a feature that degrades silently. Without budgets, bundle sizes creep, render times increase, and no single change looks like the problem — but the cumulative effect is noticeable.

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

## Mapping to Core Guardrail Sections

| Core Section | Web Frontend Equivalent |
|---|---|
| §2 Specs | §17.7 Component contracts (props, states, error handling) |
| §3 Testing | §17.1 Visual regression + §17.4 E2E browser tests + §17.5 Accessibility |
| §6 Consistency | §17.2 Design system + §17.3 Style audit |
| §7 Documentation | §17.3 Living style audit, design system docs |
| §11 File Size | §17.6 Performance budgets (bundle size, image weight) |

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
