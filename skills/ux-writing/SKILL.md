---
name: ux-writing
description: "UX Writing and Microcopy: labels, error messages, empty states, tooltips, onboarding copy, tone of voice. Use when writing user-facing text in interfaces to ensure clarity, consistency, and accessibility."
risk: safe
source: self
date_added: "2026-08-02"
---

# UX Writing & Microcopy

## When to Use

- Writing labels, buttons, tooltips, error messages
- Designing empty states with helpful copy
- Establishing a consistent tone of voice across an app
- Reviewing UI text for clarity and accessibility

---

## Core Principles

1. **Be clear, not clever** — Users need to act, not appreciate your wordplay
2. **Be concise** — Every word earns its place
3. **Be human** — Write like a person, not a legal document
4. **Be consistent** — Same thing, same words, everywhere
5. **Be inclusive** — Write for all literacy levels, abilities, and cultures

---

## Label Writing Rules

### Button Labels

Use verb + noun when context is ambiguous. Use verb alone when context is clear.

```html
<!-- GOOD: Clear action -->
<button>Save changes</button>
<button>Cancel</button>
<button>Delete account</button>

<!-- GOOD: Context makes verb sufficient -->
<dialog>
  <p>Discard unsaved changes?</p>
  <button>Discard</button>      <!-- Context = modal -->
  <button>Keep editing</button>
</dialog>

<!-- BAD: Vague -->
<button>Submit</button>          <!-- Submit what?
<button>OK</button>              <!-- OK to what?
<button>Click here</button>     <!-- Obvious, wastes space
```

### Form Labels

```html
<!-- GOOD: Specific, with helper text -->
<label for="username">Username</label>
<small>3-20 characters, letters and numbers only</small>
<input id="username" />

<!-- GOOD: Friendly but precise -->
<label for="email">Email address</label>
<small>We'll send your receipt here</small>

<!-- BAD: Missing context -->
<label>Name</label>              <!-- First? Last? Full?

<!-- BAD: Placeholder as label (disappears on focus) -->
<input placeholder="Enter your email" />
```

### Navigation Labels

```html
<!-- GOOD: Noun phrases for navigation items -->
<nav>
  <a>Dashboard</a>
  <a>Orders</a>
  <a>Settings</a>
</nav>

<!-- BAD: Verb phrases for navigation (save for buttons) -->
<nav>
  <a>View Dashboard</a>        <!-- Just "Dashboard"
  <a>Manage Orders</a>          <!-- Just "Orders"
</nav>
```

---

## Error Messages

### Anatomy of a Good Error Message

```
[What happened] + [Why it happened] + [How to fix it]
```

### Error Message Patterns

```html
<!-- GOOD: Specific, actionable -->
<div role="alert">
  <p><strong>Password too short</strong></p>
  <p>Your password must be at least 8 characters. You've entered 5.</p>
</div>

<!-- GOOD: Form field error -->
<label for="email">Email</label>
<input id="email" type="email" aria-describedby="email-error" />
<span id="email-error" class="error">
  Please enter a valid email address like name@example.com
</span>

<!-- BAD: Generic, unhelpful -->
<div role="alert">
  <p>Error</p>                <!-- What error?
</div>

<!-- BAD: Blaming the user -->
<div role="alert">
  <p>You entered an invalid email.</p>    <!-- Avoid "you" for errors
</div>

<!-- BAD: Technical jargon -->
<div role="alert">
  <p>ValidationException: Email format mismatch</p>
</div>
```

### Error Message Do's and Don'ts

| Do | Don't |
|----|-------|
| "Please enter a valid email" | "Invalid email" |
| "Password must be 8+ characters" | "Error 422" |
| "File is too large (max 5MB)" | "Upload failed" |
| "Something went wrong. Try again." | "Unexpected error occurred" |
| "That username is taken" | "Username already exists" |
| "We couldn't save your changes" | "Save failed" |

### Error Tone by Severity

```typescript
// Transient / Recoverable → Friendly, calm
"Having trouble connecting. We'll keep trying..."

// User input error → Helpful, specific
"That date has already passed. Please choose today or later."

// System error → Apologetic, clear
"Something went wrong on our end. Your data is safe. Try again in a moment."

// Account/Security → Serious, direct
"We couldn't verify your identity. Please check your credentials."
```

---

## Empty States

### Types of Empty States

```html
<!-- 1. First-use empty state (teaching) -->
<div class="empty-state">
  <app-illustration name="welcome" />
  <h2>Welcome to Orders</h2>
  <p>Create your first order to see it here.</p>
  <button (click)="createOrder()">Create order</button>
</div>

<!-- 2. No results (search/filter) -->
<div class="empty-state">
  <app-illustration name="search" />
  <h2>No results for "{{ query() }}"</h2>
  <p>Try different keywords or check for typos.</p>
</div>

<!-- 3. Empty collection (cleared data) -->
<div class="empty-state">
  <app-illustration name="empty" />
  <h2>All caught up!</h2>
  <p>No pending tasks. Nice work.</p>
</div>

<!-- 4. Error empty state (failed to load) -->
<div class="empty-state">
  <app-illustration name="error" />
  <h2>Couldn't load orders</h2>
  <p>Check your connection and try again.</p>
  <button (click)="retry()">Retry</button>
</div>
```

### Empty State Checklist

- [ ] Clear illustration or icon (not a blank screen)
- [ ] Headline that explains the state (not just "No data")
- [ ] Body copy that tells what to do next
- [ ] Primary action when possible (create, retry, learn more)
- [ ] Tone matches context (celebratory for "all done", helpful for "no results")

---

## Tooltips and Inline Help

### Tooltip Rules

```html
<!-- GOOD: Supplementary info, not required knowledge -->
<label for="phone">
  Phone number
  <span class="tooltip" title="We'll only call if there's an issue with your order">
    ℹ️
  </span>
</label>

<!-- BAD: Critical info hidden in tooltip -->
<label for="ssn">
  SSN
  <span class="tooltip" title="Required for tax purposes. Format: XXX-XX-XXXX">
    ℹ️
  </span>
</label>
<!-- If they need it to fill the field, it should be a label/helper, not a tooltip -->
```

### Helper Text Patterns

```html
<!-- Helper text (visible) -->
<label for="password">Password</label>
<small id="password-help">At least 8 characters with one number and one uppercase letter</small>
<input id="password" aria-describedby="password-help" />

<!-- Contextual example -->
<label for="amount">Amount</label>
<small>e.g., 15000 for $15,000</small>
<input id="amount" type="number" />
```

---

## Tone of Voice Framework

### Tone Dimensions

| Dimension | Low | High |
|-----------|-----|------|
| Formal ↔ Casual | "Please verify your identity" | "Double-check it's you" |
| Serious ↔ Playful | "Action required" | "Heads up!" |
| Respectful ↔ Enthusiastic | "Your request was processed" | "You're all set!" |
| Urgent ↔ Calm | "Do this now" | "When you get a chance..." |

### Tone by Context

```typescript
// Success messages → Brief, positive, specific
"Order placed! You'll get a confirmation email shortly."
// NOT: "Success! Your request has been processed successfully."

// Warnings → Calm, informative, suggest alternative
"This action can't be undone. Consider downloading your data first."
// NOT: "WARNING: IRREVERSIBLE ACTION!"

// Empty states → Helpful, inviting
"You haven't placed any orders yet. Start shopping to see them here."
// NOT: "No records found."

// Onboarding → Friendly, encouraging
"Almost done! Just one more step."
// NOT: "Step 3 of 4: Complete profile"

// Loading → Reassuring
"Finding the best routes for you..."
// NOT: "Loading..." or "Please wait..."
```

### Brand Voice Consistency

Define these for your app and enforce them in code:

```typescript
// brand-voice.ts
export const VOICE = {
  tone: 'professional-casual',     // Not stiff, not sloppy
  contractions: true,               // "you'll" not "you will"
  exclamations: 'sparingly',        // 1-2 per screen max
  firstPerson: false,               // "Your order" not "Our order"
  secondPerson: true,               // "You can..." not "Users can..."
} as const;
```

---

## Numbers, Dates, and Currency

```html
<!-- GOOD: Locale-aware formatting -->
<span>{{ price() | currency }}</span>          <!-- $12.50 / 12,50 € -->
<span>{{ date() | date:'mediumDate' }}</span>  <!-- Aug 2, 2026 -->
<span>{{ quantity() | number }}</span>         <!-- 1,234 -->

<!-- GOOD: Round numbers for quick scanning -->
<p>Over 10,000 happy customers</p>
<!-- NOT: "10,847 happy customers" unless precision matters -->
```

### Unit Formatting

```html
<!-- GOOD: Space between number and unit -->
<span>5 kg</span>        <!-- Correct (SI standard) -->
<span>5MB</span>          <!-- Wrong (ambiguous) -->
<span>5 MB</span>         <!-- Correct -->
<span>2 hours</span>      <!-- Correct -->
<span>2h</span>           <!-- Acceptable in compact UI -->
```

---

## Accessibility in Copy

```html
<!-- GOOD: Accessible labels -->
<button aria-label="Close dialog">
  <app-icon name="close" />
</button>

<!-- GOOD: Descriptive link text -->
<a routerLink="/orders">View all orders</a>
<!-- NOT: <a routerLink="/orders">Click here</a> -->

<!-- GOOD: Screen reader context -->
<span class="sr-only">Status: </span><span>Active</span>

<!-- GOOD: Form errors linked to inputs -->
<label for="name">Name</label>
<input id="name" aria-describedby="name-error" aria-invalid="true" />
<span id="name-error" role="alert">Name is required</span>
```

---

## Internationalization (i18n) Considerations

```html
<!-- GOOD: Structured for translation -->
<!-- Use Angular i18n or ngx-translate -->
<h2 i18n="@@orderSuccessTitle">Order placed!</h2>
<p i18n="@@orderSuccessBody">You'll get a confirmation email shortly.</p>

<!-- BAD: String concatenation (untranslatable) -->
<p>{{ firstName }} placed {{ count }} orders</p>
<!-- Languages with different word order will break this -->

<!-- GOOD: ICU message format -->
<p i18n="@@orderCount">{count, plural, =0 {No orders} one {One order} other {{count} orders}}</p>
```

---

## Checklist

Before shipping any UI text:

- [ ] Button labels are verb + noun (or verb alone if context is clear)
- [ ] Error messages say what happened + how to fix it
- [ ] Empty states have illustration + headline + action
- [ ] Tone is consistent across screens (defined brand voice)
- [ ] No jargon — user vocabulary, not system vocabulary
- [ ] Tooltips are supplementary, not critical info
- [ ] Numbers, dates, currency are locale-formatted
- [ ] All interactive elements have accessible labels
- [ ] Text is translatable (no string concatenation, no images with text)
- [ ] Readable at a glance (short sentences, < 15 words per line)

## Limitations

- UX writing guidelines are general — adapt tone to your specific audience and brand
- Test copy with real users; what seems clear to you may confuse others
- Localization may change text length significantly (German words are ~30% longer than English)
- This skill covers English-language patterns; other languages may have different conventions
