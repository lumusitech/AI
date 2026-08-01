---
name: angular-22
description: Best practices, architecture, state management, and modern UI patterns for Angular 22+ (Zoneless, Signals, Control Flow, LinkedSignal, Resource API).
version: 22.0.0
last_updated: 2026-08-01
---

# 🅰️ Angular 22+ Engineering Guide

This skill provides expert patterns for developing modern Angular applications using modern Signals, Zoneless change detection, and standalone components.

## 🚀 Core Architectural Rules

### 1. Zoneless Change Detection
All Angular 22+ apps must be bootstrapped without Zone.js:
```typescript
import { provideExperimentalZonelessChangeDetection } from '@angular/core';

export const appConfig: ApplicationConfig = {
  providers: [
    provideExperimentalZonelessChangeDetection(),
    provideRouter(routes),
    provideHttpClient()
  ]
};
```

### 2. Signals-First State Management
- Prefer native Signals (`signal()`, `computed()`, `linkedSignal()`) over RxJS BehaviorSubjects.
- Use `linkedSignal()` to create signals that automatically reset or derive default state when a source signal changes:
```typescript
import { signal, computed, linkedSignal } from '@angular/core';

// Primary input signal
const selectedCategoryId = signal<string>('cat-1');

// Derived signal linked to category changes
const selectedItemId = linkedSignal({
  source: selectedCategoryId,
  computation: (catId) => defaultItemIdForCategory(catId)
});
```

### 3. Async Resource API (`resource` / `rxResource`)
Use Angular's native `resource()` API for async data fetching without RxJS subscriptions or async pipes:
```typescript
import { resource } from '@angular/core';

export class UserProfileComponent {
  userId = input.required<string>();

  userResource = resource({
    request: () => ({ id: this.userId() }),
    loader: async ({ request, abortSignal }) => {
      const res = await fetch(`/api/users/${request.id}`, { signal: abortSignal });
      return await res.json();
    }
  });

  // Accessing values:
  // userResource.value()
  // userResource.isLoading()
  // userResource.error()
}
```

### 4. Modern Control Flow & Signal Inputs
Use native block syntax and signal inputs:
```html
@if (userResource.isLoading()) {
  <app-spinner />
} @else if (userResource.value(); as user) {
  <div class="user-card">
    <h2>{{ user.name }}</h2>
    @for (role of user.roles; track role.id) {
      <span class="badge">{{ role.name }}</span>
    } @empty {
      <p>No roles assigned</p>
    }
  </div>
}
```

### 5. Signal Inputs, Outputs, and Models
```typescript
@Component({
  selector: 'app-counter',
  standalone: true,
  template: `<button (click)="value.set(value() + 1)">Count: {{ value() }}</button>`
})
export class CounterComponent {
  // Two-way binding signal model
  value = model<number>(0);
  
  // Standard signal input
  label = input<string>('Default Label');
  
  // Signal output
  valueChange = output<number>();
}
```
