---
name: pwa
description: "Progressive Web App implementation with Angular: service workers, manifest.json, Workbox, offline-first caching, installability (beforeinstallprompt), App Shell pattern. Use when adding PWA capabilities to an Angular application."
risk: safe
source: self
date_added: "2026-08-02"
---

# Progressive Web App (PWA) — Angular

## When to Use

- Making an Angular app work offline
- Adding install-to-home-screen capability
- Implementing background sync or push notifications
- Caching API responses and assets for performance

---

## Setup

### Angular PWA Schematic

```bash
# Add PWA to existing project
ng add @angular/pwa

# This creates:
# - src/manifest.webmanifest
# - src/ngsw-config.json
# - src/app/app.config.ts (adds ServiceWorker)
# - ngsw-config.json at project root
# - Updates angular.json with service worker
```

### Key Files

```
src/
├── manifest.webmanifest        # App metadata
├── ngsw-config.json            # Service worker config
├── icons/
│   ├── icon-72x72.png
│   ├── icon-96x96.png
│   ├── icon-128x128.png
│   ├── icon-144x144.png
│   ├── icon-152x152.png
│   ├── icon-192x192.png
│   ├── icon-384x384.png
│   └── icon-512x512.png
└── assets/
    └── icons/
        ├── splash-screen.png
        └── maskable-icon.png
```

---

## Manifest Configuration

### manifest.webmanifest

```json
{
  "name": "My App — Product Name",
  "short_name": "MyApp",
  "description": "Short description for home screen",
  "theme_color": "#1976d2",
  "background_color": "#ffffff",
  "display": "standalone",
  "orientation": "portrait-primary",
  "scope": "/",
  "start_url": "/dashboard",
  "icons": [
    {
      "src": "assets/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "assets/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "assets/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "assets/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

### Display Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `standalone` | Like native app, no browser chrome | Most PWAs |
| `minimal-ui` | Reduced browser controls | Light PWA |
| `fullscreen` | No browser UI at all | Games, immersive |
| `browser` | Normal browser tab | Default, not PWA-like |

---

## Service Worker Configuration

### ngsw-config.json

```json
{
  "$schema": "./node_modules/@angular/service-worker/config/schema.json",
  "index": "/index.html",
  "assetGroups": [
    {
      "name": "app-shell",
      "installMode": "prefetch",
      "resources": {
        "files": [
          "/favicon.ico",
          "/index.html",
          "/manifest.webmanifest",
          "/*.css",
          "/*.js"
        ]
      }
    },
    {
      "name": "assets",
      "installMode": "lazy",
      "updateMode": "prefetch",
      "resources": {
        "files": [
          "/assets/**",
          "/*.(svg|cur|jpg|jpeg|png|apng|webp|avif|gif|otf|ttf|woff|woff2)"
        ]
      }
    }
  ],
  "dataGroups": [
    {
      "name": "api-fresh",
      "urls": ["/api/user/**", "/api/config"],
      "cacheConfig": {
        "strategy": "freshness",
        "timeout": 10000,
        "maxSize": 100,
        "maxAge": "1h"
      }
    },
    {
      "name": "api-performance",
      "urls": ["/api/products/**", "/api/categories"],
      "cacheConfig": {
        "strategy": "performance",
        "maxSize": 200,
        "maxAge": "7d",
        "timeout": "10s"
      }
    }
  ]
}
```

### Caching Strategies

| Strategy | Behavior | Best For |
|----------|----------|----------|
| `freshness` | Network first, fallback to cache | Real-time data (user profile, dashboard) |
| `performance` | Cache first, fallback to network | Static-ish data (product catalog, categories) |
| `prefetch` | Download all assets upfront | App shell, critical assets |
| `lazy` | Download on first request | Non-critical assets (images) |

---

## App Shell Pattern

The App Shell is the minimal HTML/CSS/JS that loads instantly and provides the frame for content.

```typescript
// app.component.ts — Always loads, shows shell while content loads
@Component({
  template: `
    <app-header />
    <main>
      @defer (on viewport) {
        <router-outlet />
      } @placeholder {
        <app-shell-skeleton />
      }
    </main>
    <app-bottom-nav />
  `,
})
export class AppComponent {}
```

```html
<!-- shell-skeleton.component.html -->
<div class="skeleton">
  <div class="skeleton-header" />
  <div class="skeleton-content">
    <div class="skeleton-card" />
    <div class="skeleton-card" />
    <div class="skeleton-card" />
  </div>
</div>
```

---

## Installability

### beforeinstallprompt Event

```typescript
@Component({
  template: `
    @if (canInstall()) {
      <div class="install-banner">
        <p>Install this app on your device for a better experience</p>
        <button (click)="install()">Install</button>
        <button (click)="dismiss()" class="dismiss">Not now</button>
      </div>
    }
  `,
})
export class InstallBannerComponent {
  private prompt = signal<BeforeInstallPromptEvent | null>(null);
  canInstall = signal(false);
  isInstalled = signal(false);

  constructor() {
    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      this.isInstalled.set(true);
      return;
    }

    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      this.prompt.set(e as BeforeInstallPromptEvent);
      this.canInstall.set(true);
    });

    window.addEventListener('appinstalled', () => {
      this.isInstalled.set(true);
      this.canInstall.set(false);
      this.prompt.set(null);
    });
  }

  async install() {
    const prompt = this.prompt();
    if (!prompt) return;

    await prompt.prompt();
    const result = await prompt.userChoice;

    if (result.outcome === 'accepted') {
      this.isInstalled.set(true);
    }

    this.canInstall.set(false);
    this.prompt.set(null);
  }

  dismiss() {
    this.canInstall.set(false);
  }
}
```

---

## Angular Service Worker Registration

### app.config.ts

```typescript
import { ApplicationConfig, isDevMode } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideServiceWorker } from '@angular/service-worker';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      registrationStrategy: 'registerWhenStable:30000',
    }),
  ],
};
```

### Check for Updates

```typescript
@Injectable({ providedIn: 'root' })
export class SwUpdateService {
  private swUpdate = inject(SwUpdate);

  constructor() {
    if (this.swUpdate.isEnabled) {
      // Check for updates every 6 hours
      interval(6 * 60 * 60 * 1000).subscribe(() => {
        this.swUpdate.checkForUpdate();
      });

      // Notify user when update is available
      this.swUpdate.versionUpdates.subscribe((event) => {
        if (event.type === 'VERSION_READY') {
          this.promptUpdate();
        }
      });
    }
  }

  promptUpdate() {
    if (confirm('New version available. Reload?')) {
      window.location.reload();
    }
  }
}
```

---

## Offline Support

### Offline Detection

```typescript
@Component({
  template: `
    @if (!online()) {
      <div class="offline-banner" role="alert">
        You're offline. Some features may be unavailable.
      </div>
    }
  `,
})
export class AppComponent {
  online = signal(navigator.onLine);

  constructor() {
    window.addEventListener('online', () => this.online.set(true));
    window.addEventListener('offline', () => this.online.set(false));
  }
}
```

### Background Sync

```typescript
// Register sync event in service worker
// ngsw-config.json
{
  "dataGroups": [
    {
      "name": "sync-queue",
      "urls": ["/api/sync/**"],
      "cacheConfig": {
        "strategy": "freshness",
        "timeout": 5000,
        "backgroundSync": true,
        "backgroundSyncName": "sync-queue",
        "backgroundSyncMaxAge": "1d"
      }
    }
  ]
}

// In Angular service
@Injectable({ providedIn: 'root' })
export class OfflineQueueService {
  private queue: SyncRequest[] = [];

  add(request: SyncRequest) {
    this.queue.push(request);
    this.scheduleSync();
  }

  private async scheduleSync() {
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register('sync-queue');
    }
  }
}
```

---

## Testing PWA

```bash
# Build for production with service worker
ng build --configuration production

# Serve locally with service worker
npx http-server dist/my-app -p 8080 -c-1

# Verify service worker in Chrome DevTools:
# Application → Service Workers → check "Activated and is running"
# Application → Cache Storage → see cached resources
# Application → Manifest → verify manifest loads

# Lighthouse audit
npx lighthouse http://localhost:8080 --view --only-categories=pwa
```

---

## Checklist

Before shipping PWA:

- [ ] `ng add @angular/pwa` executed
- [ ] manifest.webmanifest has correct name, icons, theme_color
- [ ] ngsw-config.json defines assetGroups and dataGroups
- [ ] App Shell loads instantly (skeleton while content loads)
- [ ] Service worker registered in app.config.ts
- [ ] Update prompt shown when new version available
- [ ] Offline banner displayed when network lost
- [ ] Critical routes work offline (cached)
- [ ] Non-critical routes have graceful offline fallback
- [ ] Lighthouse PWA score ≥ 90

## Limitations

- Service workers have a scope: they only control pages under their directory
- iOS Safari has limited PWA support (no push notifications, limited storage)
- Service workers are killed by the browser after ~5 minutes of inactivity
- Cache storage has limits (~50MB on mobile, varies by browser)
- Background sync is not supported on all browsers
