---
name: web-push-notifications
description: "Web Push Notifications: VAPID keys, Push API, service worker handlers, permission UX, subscription persistence in Spring Boot, web-push library, FCM Android, iOS 16.4+. Use when adding push notifications to an Angular PWA."
risk: safe
source: self
date_added: "2026-08-02"
---

# Web Push Notifications — Angular + Spring Boot

## When to Use

- Adding push notifications to an Angular PWA
- Sending push notifications from a Spring Boot backend
- Managing VAPID keys and subscription storage
- Implementing permission request flows

---

## Architecture

```
Angular Frontend                 Spring Boot Backend
─────────────                   ───────────────────
1. Request permission    →
2. Get PushSubscription  →
3. Send subscription     →  POST /api/subscriptions
                           Store subscription
                           Generate VAPID keys
                           ─────────────────────────
                           When event occurs:
                           ← 4. Send push notification
                              POST to FCM/GCM endpoint
                              Using VAPID signature
5. Service Worker
   receives push event
6. Show notification
```

---

## Frontend (Angular)

### VAPID Key Generation

```bash
# Generate VAPID keys (run once, store securely)
npx web-push generate-vapid-keys

# Output:
# Public Key:  BNcRdreALRFXTkOOUHKyEtK1... (safe for client)
# Private Key: VpTgqL2mN3xR4sT5... (server only, NEVER expose to client)
```

### Push Subscription

```typescript
@Injectable({ providedIn: 'root' })
export class PushNotificationService {
  private readonly VAPID_PUBLIC_KEY = 'BNcRdreALRFXTkOOUHKyEtK1...';

  constructor(private http: HttpClient) {}

  async requestPermission(): Promise<NotificationPermission> {
    if (!('Notification' in window)) {
      console.warn('Notifications not supported');
      return 'denied';
    }

    return await Notification.requestPermission();
  }

  async subscribe(): Promise<PushSubscription | null> {
    const permission = await this.requestPermission();
    if (permission !== 'granted') return null;

    const registration = await navigator.serviceWorker.ready;

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.VAPID_PUBLIC_KEY),
    });

    // Send subscription to backend
    await this.http.post('/api/subscriptions', subscription.toJSON()).toPromise();

    return subscription;
  }

  async unsubscribe(): Promise<void> {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();
    if (subscription) {
      await subscription.unsubscribe();
      await this.http.delete('/api/subscriptions').toPromise();
    }
  }

  private urlBase64ToUint8Array(base64String: string): Uint8Array {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = window.atob(base64);
    return Uint8Array.from([...rawData].map(c => c.charCodeAt(0)));
  }
}
```

### Service Worker Handler

```typescript
// src/sw-push.ts (service worker file)
/// <reference lib="webworker" />

import { pushSubscription, pushReceived, notificationClick } from '@angular/service-worker/worker';

self.addEventListener('push', (event: PushEvent) => {
  const data = event.data?.json() ?? {};

  const title = data.title || 'New Notification';
  const options: NotificationOptions = {
    body: data.body || '',
    icon: data.icon || '/assets/icons/icon-192x192.png',
    badge: data.badge || '/assets/icons/badge-72x72.png',
    tag: data.tag || 'default',
    data: data.url || '/',
    actions: data.actions || [],
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

self.addEventListener('notificationclick', (event: NotificationEvent) => {
  event.notification.close();

  const url = event.notification.data?.url || '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window' }).then(clients => {
      // Focus existing window or open new one
      for (const client of clients) {
        if (client.url.includes(url) && 'focus' in client) {
          return client.focus();
        }
      }
      return self.clients.openWindow(url);
    })
  );
});
```

### Permission UX — Best Practices

```typescript
@Component({
  template: `
    @if (permission() === 'default') {
      <!-- Don't ask immediately — show value first -->
      <div class="notification-prompt">
        <app-icon name="notifications" />
        <h3>Stay updated</h3>
        <p>Get notified when new orders arrive or tasks are assigned to you.</p>
        <button (click)="enable()">Enable notifications</button>
        <button (click)="dismiss()" class="text-btn">Not now</button>
      </div>
    }

    @if (permission() === 'denied') {
      <div class="notification-blocked">
        <p>Notifications are blocked. Enable them in your browser settings.</p>
        <a href="chrome://settings/content/notifications" target="_blank">
          Open settings
        </a>
      </div>
    }

    @if (permission() === 'granted') {
      <button (click)="toggleNotifications()">
        {{ enabled() ? '🔔 On' : '🔕 Off' }}
      </button>
    }
  `,
})
export class NotificationPreferencesComponent {
  permission = signal<NotificationPermission>(
    'Notification' in window ? Notification.permission : 'denied'
  );
  enabled = signal(false);

  constructor(private pushService: PushNotificationService) {}

  async enable() {
    const sub = await this.pushService.subscribe();
    if (sub) {
      this.permission.set('granted');
      this.enabled.set(true);
    }
  }

  async toggleNotifications() {
    if (this.enabled()) {
      await this.pushService.unsubscribe();
      this.enabled.set(false);
    } else {
      await this.pushService.subscribe();
      this.enabled.set(true);
    }
  }

  dismiss() {
    // Don't ask again for this session
  }
}
```

---

## Backend (Spring Boot)

### Subscription Storage

```java
@Entity
@Table(name = "push_subscriptions")
public class PushSubscriptionEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private String endpoint;

    @Column(nullable = false)
    private String p256dh;

    @Column(nullable = false)
    private String auth;

    @Column
    private String expirationTime;

    private Instant createdAt;
}

@Repository
public interface PushSubscriptionRepository extends JpaRepository<PushSubscriptionEntity, Long> {
    List<PushSubscriptionEntity> findByUserId(String userId);
    void deleteByEndpoint(String endpoint);
}
```

### Send Push Notification

```java
@Service
@Slf4j
public class PushNotificationService {

    private final PushNotificationManager pushManager;

    public PushNotificationService(
            @Value("${vapid.public-key}") String publicKey,
            @Value("${vapid.private-key}") String privateKey,
            @Value("${vapid.subject}") String subject) {

        this.pushManager = PushNotificationManager.builder()
            .vapidPublicKey(publicKey)
            .vapidPrivateKey(privateKey)
            .vapidSubject(subject)
            .build();
    }

    public void sendToUser(String userId, String title, String body, String url) {
        List<PushSubscriptionEntity> subscriptions = subscriptionRepo.findByUserId(userId);

        for (PushSubscriptionEntity sub : subscriptions) {
            try {
                PushSubscription subscription = PushSubscription.builder()
                    .endpoint(sub.getEndpoint())
                    .keys(PushSubscription.Keys.builder()
                        .p256dh(sub.getP256dh())
                        .auth(sub.getAuth())
                        .build())
                    .build();

                WebPushMessage message = WebPushMessage.builder()
                    .title(title)
                    .body(body)
                    .icon("/assets/icons/icon-192x192.png")
                    .badge("/assets/icons/badge-72x72.png")
                    .tag("notification-" + userId)
                    .data(Map.of("url", url))
                    .build();

                pushManager.send(subscription, message);

            } catch (Exception e) {
                log.warn("Failed to send push to subscription {}: {}", sub.getEndpoint(), e.getMessage());
                // Remove invalid subscription
                if (e.getMessage().contains("410") || e.getMessage().contains("404")) {
                    subscriptionRepo.deleteByEndpoint(sub.getEndpoint());
                }
            }
        }
    }
}
```

### Maven Dependencies

```xml
<dependency>
    <groupId>nl.martijndwars</groupId>
    <artifactId>web-push</artifactId>
    <version>6.1.0</version>
</dependency>

<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-jdk18on</artifactId>
    <version>1.78</version>
</dependency>
```

### application.yml

```yaml
vapid:
  public-key: ${VAPID_PUBLIC_KEY}
  private-key: ${VAPID_PRIVATE_KEY}
  subject: mailto:admin@myapp.com
```

---

## Platform Support

| Platform | Push Notifications | Notes |
|----------|-------------------|-------|
| Chrome (Desktop) | ✅ Full | Best support |
| Chrome (Android) | ✅ Full | Via FCM |
| Firefox | ✅ Full | Direct push |
| Safari (macOS) | ✅ Full | Since Safari 16 |
| Safari (iOS) | ✅ 16.4+ | Must be installed as PWA |
| Edge | ✅ Full | Chromium-based |
| Opera | ✅ Full | Chromium-based |

---

## iOS Specifics

```html
<!-- iOS 16.4+ requires installed PWA (standalone mode) -->
<!-- Check if running as PWA -->
<script>
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
  const isIOSPWA = isIOS && isStandalone;
</script>
```

```typescript
// Only show notification prompt on iOS if installed as PWA
if (isIOS && !isStandalone) {
  // Show "Add to Home Screen" prompt instead
  showAddToHomeScreenPrompt();
}
```

---

## Testing

```bash
# Test push locally with web-push CLI
npx web-push send-notification \
  --endpoint="https://fcm.googleapis.com/fcm/send/..." \
  --key="BNcRdreALRFXTkOOUHKyEtK1..." \
  --auth="auth-secret" \
  --payload='{"title":"Test","body":"Hello!"}'

# Chrome DevTools → Application → Service Workers → Push
# Click "Push" to simulate a push event
```

---

## Checklist

Before shipping push notifications:

- [ ] VAPID keys generated and stored securely (private key on server only)
- [ ] Service worker handles push and notificationclick events
- [ ] Permission request shows value BEFORE asking (not on page load)
- [ ] Denied state handled gracefully (link to settings)
- [ ] Subscriptions stored with endpoint + p256dh + auth
- [ ] Invalid subscriptions auto-removed on 404/410
- [ ] Notification has icon, badge, and tag
- [ ] Click opens/focuses relevant page
- [ ] iOS: "Add to Home Screen" shown before notification prompt
- [ ] Test on Chrome, Firefox, Safari

## Limitations

- iOS requires PWA installation before push notifications (iOS 16.4+)
- Push notifications don't work if service worker is not registered
- Subscription expires — handle 410 Gone by re-subscribing
- Notification limits vary by platform (Chrome: ~100 per app per day)
- Background execution is limited on mobile — don't rely on real-time delivery
