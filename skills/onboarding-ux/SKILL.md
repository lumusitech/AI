---
name: onboarding-ux
description: "Onboarding and First Experience Design: progressive disclosure, empty-to-populated transitions, first-use tutorials, reducing friction. Use when designing first-time user experiences, onboarding flows, or reducing time-to-value."
risk: safe
source: self
date_added: "2026-08-02"
---

# Onboarding & First Experience Design

## When to Use

- Designing first-time user experiences
- Reducing drop-off in registration/setup flows
- Transitioning empty states to populated ones
- Deciding between onboarding patterns (tutorial, checklist, progressive)

---

## Core Principles

1. **Time to value < 60 seconds** — Show the app's core value immediately
2. **Show, don't tell** — Let users do, not just read
3. **Progressive disclosure** — Reveal complexity as needed, not all at once
4. **Respect the user's time** — Every onboarding step must earn its existence
5. **Allow skipping** — Never trap users in onboarding

---

## Onboarding Patterns

### 1. Value-First (Best for most apps)

Skip setup. Show the core experience immediately. Prompt setup only when needed.

```html
<!-- GOOD: User sees value immediately, setup prompted contextually -->
<div class="dashboard">
  <app-welcome-banner />
  <app-sample-data />

  @if (!user().hasCompletedSetup) {
    <app-setup-checklist
      [steps]="setupSteps()"
      (complete)="onSetupComplete()"
      (dismiss)="dismissSetup()"
    />
  }
</div>

<!-- BAD: Wall of setup before seeing anything -->
<div class="onboarding">
  <h1>Welcome! Let's set up your account</h1>
  <app-profile-form />
  <app-team-setup />
  <app-integration-connect />
  <app-preferences />
  <app-tutorial />
</div>
```

### 2. Interactive Checklist

Shows progress, allows non-linear completion, respects user autonomy.

```typescript
@Component({
  template: `
    <div class="checklist">
      <h2>Get started with {{ appName }}</h2>
      <p class="subtitle">
        {{ completedCount() }} of {{ steps.length }} complete
      </p>

      @for (step of steps; track step.id) {
        <div
          class="checklist-item"
          [class.completed]="isCompleted(step.id)"
          [class.current]="isCurrent(step.id)"
        >
          <button
            (click)="completeStep(step.id)"
            [disabled]="isCompleted(step.id)"
          >
            @if (isCompleted(step.id)) {
              <app-icon name="check-circle" />
            } @else {
              <app-icon name="circle" />
            }
            {{ step.label }}
          </button>
          <p class="step-hint">{{ step.hint }}</p>
        </div>
      }

      <button (click)="skipAll()" class="skip-btn">
        Skip setup
      </button>
    </div>
  `,
})
export class OnboardingChecklistComponent {
  steps = [
    { id: 'profile', label: 'Complete your profile', hint: 'Add a photo and bio' },
    { id: 'invite', label: 'Invite a team member', hint: 'Collaborate is better together' },
    { id: 'project', label: 'Create your first project', hint: 'Takes about 2 minutes' },
    { id: 'connect', label: 'Connect a tool', hint: 'Import data from GitHub, Jira, etc.' },
  ];

  completedSteps = signal<Set<string>>(new Set());
  completedCount = computed(() => this.completedSteps().size);
  isCompleted = (id: string) => this.completedSteps().has(id);
  isCurrent = (id: string) => !this.isCompleted(id);

  completeStep(id: string) {
    this.completedSteps.update(s => new Set([...s, id]));
  }
}
```

### 3. Empty-to-Populated Transition

The most critical moment: first load. An empty app is confusing. Guide the user to create the first item.

```html
<!-- GOOD: Empty state with clear CTA and visual example -->
<div class="empty-state onboarding">
  <app-illustration name="getting-started" />
  <h2>Create your first project</h2>
  <p>Projects help you organize your work. Create one to get started.</p>
  <button (click)="createProject()" class="btn-primary">
    Create project
  </button>
  <p class="hint">
    <a (click)="importFromGitHub()">Or import from GitHub →</a>
  </p>
</div>

<!-- GOOD: After first item, transition to list view -->
@if (projects().length === 0) {
  <app-empty-state />
} @else {
  <div class="project-list">
    <div class="project-list-header">
      <h2>Projects</h2>
      <button (click)="createProject()">New project</button>
    </div>
    @for (project of projects(); track project.id) {
      <app-project-card [project]="project" />
    }
  </div>
}
```

### 4. Guided Tour (Use Sparingly)

Only for complex UIs where spatial layout matters. Max 5 steps. Always dismissable.

```typescript
@Component({
  template: `
    @if (activeStep() !== null) {
      <div class="guided-tour">
        <div class="tour-overlay" (click)="dismiss()" />
        <div
          class="tour-tooltip"
          [style.top]="activeStep()!.position.top"
          [style.left]="activeStep()!.position.left"
        >
          <p>{{ activeStep()!.text }}</p>
          <div class="tour-actions">
            <button (click)="dismiss()">Skip all</button>
            <span>{{ currentIndex() + 1 }}/{{ steps.length }}</span>
            <button (click)="next()">
              {{ isLast() ? 'Got it' : 'Next' }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
})
export class GuidedTourComponent {
  steps = [
    { text: 'This is your dashboard. All your projects appear here.', position: { top: '100px', left: '50%' } },
    { text: 'Click here to create a new project.', position: { top: '60px', right: '20px' } },
    { text: 'Your notifications appear here.', position: { top: '60px', right: '80px' } },
  ];

  currentIndex = signal(0);
  activeStep = computed(() => this.steps[this.currentIndex()] ?? null);
  isLast = computed(() => this.currentIndex() === this.steps.length - 1);
}
```

---

## Registration Flow Patterns

### Minimal Registration

Collect only what you need NOW. Get the rest later.

```html
<!-- GOOD: 2 fields to start, profile completed later -->
<form (ngSubmit)="register()">
  <input
    type="email"
    formControlName="email"
    placeholder="Email"
    autocomplete="email"
  />
  <input
    type="password"
    formControlName="password"
    placeholder="Password"
    autocomplete="new-password"
  />
  <button type="submit" [disabled]="loading()">
    {{ loading() ? 'Creating account...' : 'Get started' }}
  </button>
</form>

<!-- Later, contextually: "Complete your profile to let teammates find you" -->
```

### Social Login

```html
<!-- GOOD: Social login as primary, email as fallback -->
<div class="auth-options">
  <button (click)="loginWithGoogle()" class="social-btn google">
    <app-icon name="google" /> Continue with Google
  </button>
  <button (click)="loginWithGitHub()" class="social-btn github">
    <app-icon name="github" /> Continue with GitHub
  </button>

  <div class="divider">or</div>

  <form (ngSubmit)="registerWithEmail()">
    <input type="email" formControlName="email" placeholder="Email" />
    <button type="submit">Continue with email</button>
  </form>
</div>
```

### Passwordless / Magic Link

```html
<!-- GOOD: No password to remember -->
<form (ngSubmit)="sendMagicLink()">
  <label for="email">Enter your email</label>
  <input id="email" type="email" formControlName="email" />
  <button type="submit" [disabled]="sent()">
    {{ sent() ? 'Check your inbox!' : 'Send login link' }}
  </button>
</form>
```

---

## Time-to-Value Patterns

### First Item Fast

```typescript
// Goal: User creates their first item within 60 seconds of signup
const ONBOARDING_FLOW = {
  steps: [
    { action: 'signup', target: '< 30 seconds', method: 'social login' },
    { action: 'create_first', target: '< 60 seconds', method: 'guided form with defaults' },
    { action: 'see_value', target: '< 90 seconds', method: 'show result immediately' },
  ],
  // If any step exceeds target, offer skip/help
};
```

### Default Values > Empty Fields

```html
<!-- GOOD: Pre-filled with sensible defaults -->
<form [formGroup]="projectForm">
  <input formControlName="name" placeholder="My first project" />
  <select formControlName="template">
    <option value="blank">Blank project</option>
    <option value="kanban" selected>Kanban board (recommended)</option>
    <option value="scrum">Scrum board</option>
  </select>
</form>

<!-- BAD: Every field empty, user stares at blank form -->
<form>
  <input placeholder="Project name" />
  <select>
    <option value="">Select template...</option>
  </select>
</form>
```

---

## Anti-Patterns

### Tutorial Overload
```html
<!-- WRONG: 10-step wizard before first use -->
<mat-stepper>
  <mat-step label="Welcome">...</mat-step>
  <mat-step label="Profile">...</mat-step>
  <mat-step label="Team">...</mat-step>
  <mat-step label="Integration">...</mat-step>
  <mat-step label="Preferences">...</mat-step>
  <mat-step label="Tutorial">...</mat-step>
  <mat-step label="Tips">...</mat-step>
  <mat-step label="Tour">...</mat-step>
  <mat-step label="Upgrade">...</mat-step>
  <mat-step label="Done">...</mat-step>
</mat-stepper>
```

### Forced Tour
```html
<!-- WRONG: Cannot dismiss, blocks interaction -->
<div class="tour-overlay" (click)="$event.stopPropagation()">
  <div class="tour-tooltip">Click Next to continue</div>
</div>
```

### Empty Empty State
```html
<!-- WRONG: No guidance, user is lost -->
<div class="empty">
  <p>No data</p>
</div>
```

---

## Onboarding Completion Signals

Track these metrics to validate onboarding effectiveness:

```typescript
interface OnboardingMetrics {
  signupToFirstItem: number;    // Target: < 60 seconds
  completionRate: number;       // % who finish onboarding
  skipRate: number;             // % who skip steps (high = steps are friction)
  dropOffStep: string;          // Where users abandon
  timeToComplete: number;       // Total onboarding time
  day1Retention: number;        // Come back tomorrow
}
```

---

## Checklist

Before shipping onboarding:

- [ ] Time to first value < 60 seconds
- [ ] Social login available (reduces signup friction by 50%+)
- [ ] Empty state has clear CTA (not just "No data")
- [ ] Skip option available for every onboarding step
- [ ] Default values pre-filled (don't start with empty forms)
- [ ] Progress visible for multi-step flows
- [ ] No more than 3 fields in initial registration
- [ ] Guided tour has ≤ 5 steps, is dismissable
- [ ] First-use checklist is non-linear (complete in any order)
- [ ] Metrics tracked (signup-to-first-item, completion rate)

## Limitations

- Onboarding patterns depend heavily on app complexity — simple apps need less onboarding
- B2B/SaaS apps typically need more onboarding than consumer apps
- A/B test onboarding flows; what works for one audience may not work for another
- Mobile onboarding has different constraints (smaller screens, shorter attention spans)
