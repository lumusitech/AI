---
name: ux-design
description: "User-Centered Design: Nielsen heuristics, task flows, information architecture, usability evaluation. Use when designing interfaces, evaluating usability, or applying UX principles beyond visual aesthetics."
risk: safe
source: self
date_added: "2026-08-02"
---

# UX Design — User-Centered Design Principles

## When to Use

- Designing new screens, flows, or features
- Evaluating existing interfaces for usability issues
- Deciding between interaction patterns
- Conducting heuristic evaluations or usability reviews

---

## Nielsen's 10 Usability Heuristics

Use as a checklist when evaluating any UI:

### 1. Visibility of System Status

The system should always keep users informed about what is going on through appropriate feedback within reasonable time.

```html
<!-- GOOD: Clear status feedback -->
<mat-progress-bar mode="indeterminate" *ngIf="saving()" />
<p class="text-sm text-gray-500">Saving your changes...</p>

<!-- BAD: No feedback, user guesses -->
<button (click)="save()">Save</button>
<!-- Nothing happens for 3 seconds -->
```

- Show progress for operations > 1 second
- Display percentages for uploads/downloads
- Use optimistic UI where safe

### 2. Match Between System and Real World

Use language, concepts, and conventions familiar to the user — not technical jargon.

```html
<!-- GOOD: User language -->
<label for="phone">Phone number</label>
<small>We'll only use this to send your receipt</small>

<!-- BAD: System language -->
<label for="tel">Telephone URI (E.164)</label>
<small>Data collection for transactional messaging</small>
```

- Use terms your users actually say out loud
- Follow platform conventions (iOS/Android patterns)
- Icons with text labels beat icons alone

### 3. User Control and Freedom

Users often perform actions by mistake. Provide a clearly marked "emergency exit" to leave the unwanted state.

```html
<!-- GOOD: Undo is better than confirmation dialogs -->
<app-toast message="Item deleted">
  <button (click)="undo()">Undo</button>
</app-toast>

<!-- GOOD: Explicit cancel -->
<button (click)="cancel()">Cancel</button>
<button (click)="save()" class="btn-primary">Save</button>

<!-- BAD: No way out -->
<dialog open>
  <p>Are you sure you want to delete this? This action cannot be undone.</p>
  <button (click)="delete()">Yes, delete forever</button>
</dialog>
```

- Prefer undo over confirmation dialogs
- Always provide escape routes (back, cancel, close)
- Allow users to edit submitted data

### 4. Consistency and Standards

Follow platform conventions. Users should not have to wonder whether different words, situations, or actions mean the same thing.

```html
<!-- GOOD: Consistent naming across app -->
<button>Add to cart</button>    <!-- Product page -->
<button>Add to cart</button>    <!-- Search results -->

<!-- BAD: Inconsistent naming -->
<button>Add to cart</button>    <!-- Product page -->
<button>Buy now</button>         <!-- Search results (same action) -->
```

- Reuse component patterns across the app
- Follow Material Design (Android) or HIG (iOS) conventions
- Consistent button placement (primary action always in same position)

### 5. Error Prevention

Good design prevents problems from occurring in the first place.

```html
<!-- GOOD: Prevent invalid input -->
<label for="cc">Credit card number</label>
<input
  id="cc"
  type="tel"
  maxlength="19"
  inputmode="numeric"
  pattern="[0-9 ]{13,19}"
  placeholder="1234 5678 9012 3456"
/>

<!-- GOOD: Disable action until valid -->
<button [disabled]="!form.valid || saving()">
  {{ saving() ? 'Processing...' : 'Pay' }}
</button>
```

- Disable submit until form is valid
- Use appropriate input types (email, tel, url)
- Set constraints (min/max, maxlength, patterns)
- Confirm destructive actions with undo, not just confirmation

### 6. Recognition Rather Than Recall

Minimize memory load by making elements, actions, and options visible.

```html
<!-- GOOD: Show recent searches -->
<div class="recent-searches">
  <h4>Recent</h4>
  @for (query of recentSearches(); track query) {
    <button (click)="search(query)">{{ query }}</button>
  }
</div>

<!-- GOOD: Inline help instead of placeholder -->
<label for="password">
  Password
  <small>At least 8 characters with one number</small>
</label>
<input id="password" type="password" />

<!-- BAD: Placeholder as only label -->
<input type="password" placeholder="Enter password" />
```

- Show recently used items, searches, or actions
- Provide inline help and examples
- Make labels visible (not just placeholders)

### 7. Flexibility and Efficiency of Use

Accelerators for expert users that do not encumber novice users.

```html
<!-- GOOD: Keyboard shortcut shown in tooltip -->
<button (click)="save()" title="Save (Ctrl+S)">
  Save
</button>

<!-- GOOD: Recent/saved items for power users -->
<div class="recent-templates">
  <h4>Quick start</h4>
  @for (template of recentTemplates(); track template.id) {
    <button (click)="createFromTemplate(template)">
      {{ template.name }}
    </button>
  }
</div>
```

- Keyboard shortcuts for frequent actions
- Saved preferences and defaults
- Customizable dashboards for power users

### 8. Aesthetic and Minimalist Design

Interfaces should not contain information that is irrelevant or rarely needed. Every extra unit of information in a dialog competes with the relevant units.

```html
<!-- GOOD: Focused form, one purpose per screen -->
<h2>Shipping address</h2>
<app-address-form (save)="onAddressSaved()" />

<!-- BAD: Everything on one screen -->
<h2>Checkout</h2>
<app-address-form />
<app-payment-form />
<app-shipping-options />
<app-gift-options />
<app-loyalty-points />
<app-newsletter-signup />
```

- One primary action per screen
- Progressive disclosure (show details when needed)
- Remove clutter: if it doesn't help the user, remove it

### 9. Help Users Recognize, Diagnose, and Recover from Errors

Error messages should be expressed in plain language (no error codes), precisely indicate the problem, and constructively suggest a solution.

```html
<!-- GOOD: Clear, actionable error -->
<div class="error" role="alert">
  <p><strong>Could not save your profile</strong></p>
  <p>The email address "invalid@" is not valid. Please check the format.</p>
  <button (click)="fixEmail()">Edit email</button>
</div>

<!-- BAD: Useless error -->
<div class="error">
  Error 422: Validation failed
</div>
```

- State what went wrong in plain language
- Point to the exact field that caused the error
- Suggest how to fix it

### 10. Help and Documentation

It is best if the system does not need any additional explanation. However, documentation may be needed.

- Contextual tooltips on complex features
- Empty states that teach (not just "No data")
- Progressive onboarding (not a 10-step wizard on first load)

---

## Task Flow Design

### Task Flow Template

```
Goal: [What the user wants to accomplish]
User: [Who is doing this]
Context: [Where/when this happens]

Steps:
1. Entry point → How the user starts
2. [Action] → What they do
3. [Decision] → What choices they make
4. [Completion] → How they know they're done

Errors at each step:
- What can go wrong
- How the user recovers
```

### Flow Complexity Guidelines

| Complexity | Steps | Example |
|-----------|-------|---------|
| Simple | 1-2 | Like a post, toggle setting |
| Moderate | 3-5 | Add item to cart, checkout |
| Complex | 6-8 | Complete registration, file taxes |
| Consider splitting | 9+ | Break into multiple screens |

### Progressive Disclosure Pattern

```html
<!-- Step 1: Essential info only -->
<form [formGroup]="checkoutForm">
  <app-address-form formControlName="address" />

  <!-- Step 2: Revealed after address is valid -->
  @if (checkoutForm.get('address')?.valid) {
    <app-shipping-options formControlName="shipping" />
  }

  <!-- Step 3: Revealed after shipping selected -->
  @if (checkoutForm.get('shipping')?.value) {
    <app-payment-form formControlName="payment" />
  }
</form>
```

---

## Information Architecture

### Card Sorting Rules

- 5-9 items per category (Miller's Law)
- Group by user mental model, not backend structure
- Use open card sorting for discovery, closed for validation

### Navigation Patterns

| Pattern | Best For | Example |
|---------|----------|---------|
| Hub & Spoke | 3-5 independent sections | Mobile app with tab bar |
| Flat | All items at same level | E-commerce categories |
| Tag/Combination | Multi-faceted data | Filters + sort |
| Dashboard | Overview → detail | Analytics, admin |

### Labeling Rules

- Use user's language, not internal jargon
- 1-3 words per label
- Test with tree testing before committing
- Avoid clever names — be specific

---

## Heuristic Evaluation Process

### Running a Heuristic Evaluation

1. **Define scope**: Which screens/flows to evaluate
2. **Assign reviewers**: 3-5 evaluators (3 catches ~75% of issues)
3. **Evaluate independently**: Each evaluator checks all 10 heuristics
4. **Severity rating** (per issue):
   - 0: Not a usability problem
   - 1: Cosmetic — fix if time allows
   - 2: Minor — low priority
   - 3: Major — high priority, fix before launch
   - 4: Catastrophic — users cannot complete task
5. **Aggregate and deduplicate**: Merge similar findings
6. **Prioritize by severity × frequency**

### Usability Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Task success rate | > 85% | Can user complete the task? |
| Time on task | Context-dependent | Stopwatch from start to goal |
| Error rate | < 15% | Wrong inputs / total inputs |
| Satisfaction (SUS) | > 68 (above average) | Post-task questionnaire |

---

## Anti-Patterns

### Overwhelming the User
- Too many options on one screen
- Long forms without progress indicators
- Technical jargon in labels

### Breaking Mental Models
- Unconventional navigation (e.g., swipe right to delete on web)
- Inconsistent button placement
- Changing patterns between screens

### Ignoring Context
- Designing for desktop on mobile
- Not considering slow connections
- Assuming always-on connectivity

---

## Checklist

Before shipping any UI:

- [ ] System status visible (loading, saving, progress)
- [ ] Language matches user's vocabulary
- [ ] Undo/escape available for destructive actions
- [ ] Consistent naming and placement across screens
- [ ] Input validated with clear error messages
- [ ] Recent/important items visible (not buried)
- [ ] One primary action per screen
- [ ] Error messages are plain language + actionable
- [ ] Keyboard shortcuts available for power users
- [ ] Tested with real users or heuristic evaluation

## Limitations

- Heuristics are guidelines, not absolute rules — context matters
- Nielsen's heuristics work best for traditional UIs; emerging patterns (conversational, spatial) may need additional evaluation criteria
- Always validate heuristic findings with real user testing when possible
