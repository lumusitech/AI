---
name: mobile-ux-patterns
description: "Mobile UX patterns: touch targets, thumb zones, gestures, bottom navigation, swipe actions, mobile forms, responsive design. Use when building mobile-first web apps, PWAs, or Angular responsive layouts for phones and tablets."
risk: safe
source: self
date_added: "2026-08-02"
---

# Mobile UX Patterns

## When to Use

- Designing mobile-first responsive web apps
- Implementing touch-friendly interfaces
- Building navigation patterns for phones/tablets
- Optimizing forms and inputs for mobile

---

## Core Principles

1. **Thumb-first design** — Primary actions within thumb reach
2. **44px minimum touch targets** — Fitts's Law applied to fingers
3. **Content over chrome** — Maximize screen real estate for content
4. **One-handed operation** — Most users hold phone with one hand
5. **Respect the platform** — Follow Android/iOS conventions in PWAs

---

## Touch Targets

### Minimum Sizes

```css
/* Minimum touch target: 44x44px (Apple HIG) / 48x48dp (Material) */
.touch-target {
  min-width: 44px;
  min-height: 44px;
  /* Or use padding if element is smaller */
  padding: 12px;
}

/* For clickable text/links in content */
.link-in-text {
  /* Ensure line height provides enough tap area */
  line-height: 1.5;
  padding: 4px 0;
}
```

### Spacing Between Targets

```css
/* Minimum 8px between adjacent touch targets */
.nav-item + .nav-item {
  margin-left: 8px;
}

/* Or use gap in flex/grid */
.action-bar {
  display: flex;
  gap: 8px;
}
```

---

## Thumb Zones

### Ergonomic Zones (Right-handed)

```
┌─────────────────────┐
│      HARD           │  ← Top corners: hardest to reach
│  ┌───────────────┐  │
│  │   MEDIUM      │  │  ← Middle area: comfortable
│  │               │  │
│  │   EASY        │  │  ← Bottom third: easiest
│  │               │  │
│  │   EASY        │  │  ← Bottom center: most comfortable
│  └───────────────┘  │
│      HARD           │  ← Top center: awkward reach
└─────────────────────┘
```

### Implementation

```html
<!-- GOOD: Primary actions at bottom -->
<div class="mobile-layout">
  <main class="content">...</main>

  <nav class="bottom-nav">
    <button>Dashboard</button>
    <button>Search</button>
    <button class="fab">+</button>  <!-- Center = most accessible -->
    <button>Messages</button>
    <button>Profile</button>
  </nav>
</div>

<!-- BAD: Primary actions at top (hard to reach one-handed) -->
<header class="top-actions">
  <button>Primary Action</button>
</header>
```

### Bottom Navigation (3-5 items max)

```html
<!-- GOOD: 5 items with icons + labels -->
<nav class="bottom-nav" role="navigation">
  <a routerLink="/home" routerLinkActive="active">
    <app-icon name="home" />
    <span>Home</span>
  </a>
  <a routerLink="/search" routerLinkActive="active">
    <app-icon name="search" />
    <span>Search</span>
  </a>
  <a routerLink="/create" routerLinkActive="active" class="fab">
    <app-icon name="add" />
  </a>
  <a routerLink="/messages" routerLinkActive="active">
    <app-icon name="chat" />
    <span>Messages</span>
  </a>
  <a routerLink="/profile" routerLinkActive="active">
    <app-icon name="person" />
    <span>Profile</span>
  </a>
</nav>
```

---

## Gestures

### Swipe Actions

```html
<!-- GOOD: Swipe to reveal actions -->
<div class="swipeable-item">
  <div class="swipe-actions-left">
    <button class="archive">Archive</button>
  </div>

  <div class="swipe-content">
    <h3>Item title</h3>
    <p>Item description</p>
  </div>

  <div class="swipe-actions-right">
    <button class="delete">Delete</button>
  </div>
</div>

<style>
.swipeable-item {
  position: relative;
  overflow: hidden;
}

.swipe-content {
  transition: transform 0.3s ease;
}

/* Swipe left reveals right actions */
.swipeable-item.swiping-left .swipe-content {
  transform: translateX(-80px);
}

/* Swipe right reveals left actions */
.swipeable-item.swiping-right .swipe-content {
  transform: translateX(80px);
}
</style>
```

### Pull to Refresh

```html
<!-- GOOD: Pull to refresh with visual feedback -->
<div
  class="scrollable-list"
  (touchstart)="onTouchStart($event)"
  (touchmove)="onTouchMove($event)"
  (touchend)="onTouchEnd($event)"
>
  @if (refreshing()) {
    <div class="pull-indicator">
      <app-spinner size="small" />
      <span>Refreshing...</span>
    </div>
  }

  @for (item of items(); track item.id) {
    <app-item-card [item]="item" />
  }
</div>
```

### Long Press

```html
<!-- GOOD: Long press for context menu -->
<div
  class="item"
  (touchstart)="startLongPress(item)"
  (touchend)="cancelLongPress()"
  (touchcancel)="cancelLongPress()"
  [class.long-press-active]="longPressActive()"
>
  {{ item.name }}
</div>
```

---

## Mobile Navigation Patterns

### Pattern Decision Tree

```
Need 3-5 top-level sections?
  → Yes: Bottom navigation bar
  → No: Continue

Need contextual actions?
  → Yes: FAB (Floating Action Button) + bottom sheet
  → No: Continue

Deep hierarchical navigation?
  → Yes: Stack navigation (back button + breadcrumb)
  → No: Continue

Mixed content types?
  → Yes: Tab bar within sections
```

### Stack Navigation

```html
<!-- GOOD: Clear back navigation -->
<header class="mobile-header">
  <button (click)="goBack()" aria-label="Go back">
    <app-icon name="arrow-back" />
  </button>
  <h1>{{ pageTitle() }}</h1>
  <ng-content select="[actions]" />
</header>
```

### Bottom Sheet

```html
<!-- GOOD: Bottom sheet for options/actions -->
<div class="bottom-sheet-overlay" (click)="close()" />
<div class="bottom-sheet" role="dialog">
  <div class="bottom-sheet-handle" />

  <h3>Choose an action</h3>

  <button (click)="share()">
    <app-icon name="share" /> Share
  </button>
  <button (click)="edit()">
    <app-icon name="edit" /> Edit
  </button>
  <button (click)="delete()" class="danger">
    <app-icon name="trash" /> Delete
  </button>
</div>
```

---

## Mobile Forms

### Input Types Matter

```html
<!-- GOOD: Correct input types = correct mobile keyboard -->
<input type="tel" inputmode="tel" placeholder="Phone" />
<input type="email" inputmode="email" placeholder="Email" />
<input type="url" inputmode="url" placeholder="Website" />
<input type="number" inputmode="decimal" placeholder="Price" />
<input type="text" inputmode="numeric" pattern="[0-9]*" placeholder="ZIP code" />

<!-- BAD: Wrong keyboard for the input -->
<input type="text" placeholder="Phone" />       <!-- Shows QWERTY -->
<input type="text" placeholder="Email" />        <!-- No @ shortcut -->
```

### Mobile Form Patterns

```html
<!-- GOOD: Single-column layout, large inputs -->
<form class="mobile-form">
  <div class="form-group">
    <label for="name">Full name</label>
    <input
      id="name"
      type="text"
      autocomplete="name"
      placeholder="John Doe"
    />
  </div>

  <div class="form-group">
    <label for="email">Email</label>
    <input
      id="email"
      type="email"
      autocomplete="email"
      placeholder="john@example.com"
    />
  </div>

  <!-- Fixed bottom submit button -->
  <div class="form-actions-bottom">
    <button type="submit" [disabled]="loading()" class="btn-full-width">
      {{ loading() ? 'Saving...' : 'Save' }}
    </button>
  </div>
</form>

<style>
.mobile-form {
  padding: 16px;
  padding-bottom: 80px; /* Space for fixed button */
}

.form-group {
  margin-bottom: 16px;
}

.mobile-form input {
  width: 100%;
  height: 48px; /* Large touch target */
  font-size: 16px; /* Prevent iOS zoom on focus */
  padding: 12px 16px;
  border: 1px solid #ccc;
  border-radius: 8px;
}

.form-actions-bottom {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 16px;
  background: white;
  border-top: 1px solid #eee;
}
</style>
```

### Prevent iOS Zoom on Input Focus

```css
/* iOS zooms when font-size < 16px. Always use 16px+ for mobile inputs */
@media (max-width: 768px) {
  input, select, textarea {
    font-size: 16px !important;
  }
}
```

---

## Responsive Breakpoints

```scss
// Mobile-first breakpoints
$breakpoints: (
  'mobile': 0,
  'tablet': 768px,
  'desktop': 1024px,
  'wide': 1280px,
);

// Usage
.container {
  padding: 16px;

  @media (min-width: map-get($breakpoints, 'tablet')) {
    padding: 24px 32px;
    max-width: 720px;
    margin: 0 auto;
  }

  @media (min-width: map-get($breakpoints, 'desktop')) {
    max-width: 960px;
  }
}

// Grid: 4 cols mobile, 8 cols tablet, 12 cols desktop
.grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;

  @media (min-width: map-get($breakpoints, 'tablet')) {
    grid-template-columns: repeat(8, 1fr);
  }

  @media (min-width: map-get($breakpoints, 'desktop')) {
    grid-template-columns: repeat(12, 1fr);
  }
}
```

---

## Mobile-Specific UX Considerations

### Safe Areas (Notched Devices)

```css
/* Respect safe areas on notched phones */
.mobile-header {
  padding-top: env(safe-area-inset-top);
}

.bottom-nav {
  padding-bottom: env(safe-area-inset-bottom);
}

/* In viewport meta tag */
/* <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"> */
```

### Offline Awareness

```html
@if (!online()) {
  <div class="offline-banner">
    You're offline. Changes will sync when reconnected.
  </div>
}
```

### Loading Performance

```typescript
// Use @defer for below-the-fold content
@Component({
  template: `
    <header><!-- Critical content: loads immediately --></header>

    @defer (on viewport) {
      <app-heavy-content />
    } @placeholder {
      <div class="skeleton" />
    }
  `,
})
```

---

## Anti-Patterns

### Hover-Dependent UI
```html
<!-- WRONG: Hover doesn't exist on touch devices -->
<button class="action-btn">Save</button>
<style>
.action-btn:hover {
  background: blue; /* Touch users never see this */
}
</style>
```

### Tiny Touch Targets
```html
<!-- WRONG: 16x16px icon with no padding -->
<a><svg width="16" height="16">...</svg></a>

<!-- RIGHT: 44x44px touch area -->
<a class="touch-target" aria-label="Settings">
  <svg width="24" height="24">...</svg>
</a>
```

### Horizontal Scroll for Navigation
```html
<!-- WRONG: Hidden navigation, users won't scroll -->
<div class="horizontal-nav">
  <a>Tab 1</a>
  <a>Tab 2</a>
  <a>Tab 3</a>
  <a>Tab 4</a>
  <a>Tab 5</a>  <!-- Off-screen, invisible -->
</div>

<!-- RIGHT: Bottom nav or tab bar that wraps -->
```

---

## Checklist

Before shipping mobile UI:

- [ ] Touch targets ≥ 44px (Apple) / 48dp (Material)
- [ ] Primary actions in thumb zone (bottom third)
- [ ] Bottom navigation (3-5 items, no overflow)
- [ ] Correct input types (tel, email, number, url)
- [ ] Font-size ≥ 16px on inputs (prevent iOS zoom)
- [ ] Safe area padding for notched devices
- [ ] No hover-dependent interactions
- [ ] Forms are single-column
- [ ] Submit button fixed at bottom of forms
- [ ] Swipe gestures have visible affordances
- [ ] Pull-to-refresh has loading indicator
- [ ] Offline state communicated to user
- [ ] Viewport meta includes `viewport-fit=cover`

## Limitations

- Mobile UX patterns are guidelines — test with real users on actual devices
- Android and iOS have different conventions (back button behavior, navigation patterns)
- Touch gestures can conflict with browser/OS gestures (swipe back, pull refresh)
- Accessibility requirements differ from desktop (no hover, voice control, screen readers)
