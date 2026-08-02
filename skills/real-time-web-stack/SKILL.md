---
name: real-time-web-stack
description: "Real-time web stack: WebSocket (STOMP), Server-Sent Events (SseEmitter), and polling in Spring Boot + Angular 22. Covers reconnection strategies, heartbeats, Signal integration, and choosing between transport protocols."
risk: safe
source: self
date_added: "2026-08-02"
---

# Real-Time Web Stack — Spring Boot + Angular 22

## When to Use

- Choosing between WebSocket, SSE, and polling for a feature
- Implementing real-time updates in Angular with Spring Boot
- Handling reconnection and connection health
- Integrating real-time data with Angular Signals

---

## Transport Protocol Decision Tree

```
Need bidirectional communication?
  → Yes: WebSocket (STOMP)
  → No: Continue

Need server-initiated updates?
  → Yes: Continue
  → No: REST polling or form submission

Updates are frequent (every few seconds)?
  → Yes: WebSocket (STOMP)
  → No: Continue

Updates are occasional (every 30s+)?
  → Yes: Server-Sent Events (SSE)
  → No: Continue

One-way server → client updates?
  → Yes: Server-Sent Events (SSE)
  → No: Polling with interval
```

| Protocol | Direction | Use Case | Complexity |
|----------|-----------|----------|------------|
| WebSocket | Bidirectional | Chat, collaboration, live editing | High |
| SSE | Server → Client | Notifications, dashboards, feeds | Medium |
| Polling | Client → Server | Status checks, low-frequency updates | Low |

---

## WebSocket with STOMP (Spring Boot)

### Configuration

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue")
            .setHeartbeatTime(25_000);  // 25s heartbeat
        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
            .setAllowedOrigins("*")  // Restrict in production
            .withSockJS();
    }
}
```

### Message Handling

```java
@Controller
public class ChatController {

    @MessageMapping("/chat.send")
    @SendTo("/topic/messages")
    public ChatMessage send(ChatMessage message) {
        message.setTimestamp(Instant.now());
        return message;
    }

    @MessageMapping("/chat.join")
    @SendTo("/topic/messages")
    public ChatMessage join(ChatMessage message, SimpMessageHeaderAccessor headerAccessor) {
        headerAccessor.getSessionAttributes().put("username", message.getSender());
        message.setType(ChatMessage.Type.JOIN);
        message.setContent(message.getSender() + " joined the chat");
        return message;
    }

    // Send to specific user
    @MessageMapping("/chat.private")
    public void sendPrivate(ChatMessage message, SimpMessageHeaderAccessor headerAccessor) {
        String sender = (String) headerAccessor.getSessionAttributes().get("username");
        message.setSender(sender);
        messagingTemplate.convertAndSendToUser(
            message.getRecipient(),
            "/queue/private",
            message
        );
    }
}
```

### Message Model

```java
public record ChatMessage(
    String id,
    Type type,
    String content,
    String sender,
    String recipient,
    Instant timestamp
) {
    public enum Type { CHAT, JOIN, LEAVE, TYPING }
}
```

---

## Server-Sent Events (Spring Boot)

### SseEmitter Endpoint

```java
@RestController
@RequestMapping("/api/events")
public class SseController {

    private final CopyOnWriteArrayList<SseEmitter> emitters = new CopyOnWriteArrayList<>();

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream() {
        SseEmitter emitter = new SseEmitter(0L); // No timeout
        emitters.add(emitter);

        emitter.onCompletion(() -> emitters.remove(emitter));
        emitter.onTimeout(() -> emitters.remove(emitter));
        emitter.onError(e -> emitters.remove(emitter));

        // Send initial connection event
        try {
            emitter.send(SseEmitter.event()
                .name("connected")
                .data(Map.of("status", "connected", "timestamp", Instant.now())));
        } catch (IOException e) {
            emitters.remove(emitter);
        }

        return emitter;
    }

    // Called from service layer to push updates
    public void broadcast(String eventName, Object data) {
        List<SseEmitter> deadEmitters = new ArrayList<>();

        for (SseEmitter emitter : emitters) {
            try {
                emitter.send(SseEmitter.event()
                    .name(eventName)
                    .data(data));
            } catch (IOException e) {
                deadEmitters.add(emitter);
            }
        }

        emitters.removeAll(deadEmitters);
    }
}
```

### With Virtual Threads (Spring Boot 4.x / Java 21+)

```java
@RestController
@RequestMapping("/api/events")
public class SseControllerVirtual {

    private final ConcurrentHashMap<String, SseEmitter> userEmitters = new ConcurrentHashMap<>();

    @GetMapping(value = "/stream/{userId}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@PathVariable String userId) {
        SseEmitter emitter = new SseEmitter(0L);
        userEmitters.put(userId, emitter);

        emitter.onCompletion(() -> userEmitters.remove(userId));
        emitter.onTimeout(() -> userEmitters.remove(userId));

        return emitter;
    }

    // Virtual threads handle many concurrent SSE connections efficiently
    @Async
    public void sendToUser(String userId, Object data) {
        SseEmitter emitter = userEmitters.get(userId);
        if (emitter != null) {
            try {
                emitter.send(SseEmitter.event()
                    .name("update")
                    .data(data));
            } catch (IOException e) {
                userEmitters.remove(userId);
            }
        }
    }
}
```

---

## Angular Client

### WebSocket with STOMP

```typescript
// ws.service.ts
@Injectable({ providedIn: 'root' })
export class WebSocketService {
  private client: Client | null = null;
  private connected = signal(false);

  private messagesSubject = new Subject<ChatMessage>();
  messages$ = this.messagesSubject.asObservable();

  connect() {
    this.client = new Client({
      brokerURL: 'ws://localhost:8080/ws',
      connectHeaders: {},
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
      reconnectDelay: 5000,  // Auto-reconnect every 5s
      onConnect: () => {
        this.connected.set(true);

        this.client?.subscribe('/topic/messages', (message) => {
          const payload = JSON.parse(message.body) as ChatMessage;
          this.messagesSubject.next(payload);
        });
      },
      onDisconnect: () => {
        this.connected.set(false);
      },
      onStompError: (frame) => {
        console.error('STOMP error:', frame.headers['message']);
        this.connected.set(false);
      },
    });

    this.client.activate();
  }

  send(message: ChatMessage) {
    this.client?.publish({
      destination: '/app/chat.send',
      body: JSON.stringify(message),
    });
  }

  disconnect() {
    this.client?.deactivate();
  }
}
```

### Server-Sent Events

```typescript
// sse.service.ts
@Injectable({ providedIn: 'root' })
export class SseService {
  private eventSource: EventSource | null = null;

  connect(url: string): Observable<{ event: string; data: unknown }> {
    return new Observable(subscriber => {
      this.eventSource = new EventSource(url);

      // Generic message handler
      this.eventSource.onmessage = (event) => {
        subscriber.next({ event: 'message', data: JSON.parse(event.data) });
      };

      // Named event handler
      const eventNames = ['update', 'connected', 'notification'];
      for (const name of eventNames) {
        this.eventSource.addEventListener(name, (event: MessageEvent) => {
          subscriber.next({ event: name, data: JSON.parse(event.data) });
        });
      }

      this.eventSource.onerror = (error) => {
        console.error('SSE error:', error);
        // EventSource auto-reconnects, but we can handle specific errors
      };

      return () => {
        this.eventSource?.close();
      };
    });
  }

  disconnect() {
    this.eventSource?.close();
  }
}
```

### Polling with Signal

```typescript
@Component({
  template: `
    @if (loading()) {
      <app-spinner />
    } @else if (error()) {
      <app-error-state [error]="error()!" (retry)="load()" />
    } @else {
      <app-data-list [data]="data()" />
    }
  `,
})
export class DataComponent implements OnInit {
  private http = inject(HttpClient);
  private intervalMs = 30000; // 30 seconds

  data = signal<Data[]>([]);
  loading = signal(true);
  error = signal<Error | null>(null);

  ngOnInit() {
    this.load();

    // Poll every 30s — only if tab is visible
    interval(this.intervalMs).pipe(
      filter(() => document.visibilityState === 'visible'),
      switchMap(() => this.http.get<Data[]>('/api/data')),
    ).subscribe({
      next: (data) => this.data.set(data),
      error: (err) => this.error.set(err),
    });
  }

  load() {
    this.loading.set(true);
    this.http.get<Data[]>('/api/data').subscribe({
      next: (data) => { this.data.set(data); this.loading.set(false); },
      error: (err) => { this.error.set(err); this.loading.set(false); },
    });
  }
}
```

---

## Reconnection Strategies

### WebSocket Reconnection

```typescript
@Injectable({ providedIn: 'root' })
export class ResilientWebSocket {
  private retryCount = 0;
  private maxRetries = 10;
  private baseDelay = 1000;

  connect() {
    const client = new Client({
      brokerURL: 'ws://localhost:8080/ws',
      reconnectDelay: this.getReconnectDelay(),
      onConnect: () => {
        this.retryCount = 0; // Reset on successful connection
      },
      onDisconnect: () => {
        this.retryCount++;
        if (this.retryCount < this.maxRetries) {
          client.reconnectDelay = this.getReconnectDelay();
        }
      },
    });

    client.activate();
  }

  private getReconnectDelay(): number {
    // Exponential backoff with jitter
    const delay = Math.min(
      this.baseDelay * Math.pow(2, this.retryCount),
      30000  // Max 30 seconds
    );
    return delay + Math.random() * 1000; // Add jitter
  }
}
```

### SSE Reconnection

```typescript
// SSE auto-reconnects by default, but we can handle state
connect(url: string): Observable<Event> {
  return new Observable(subscriber => {
    const eventSource = new EventSource(url);

    eventSource.onopen = () => {
      this.connected.set(true);
      this.retryCount = 0;
    };

    eventSource.onerror = () => {
      this.connected.set(false);
      this.retryCount++;
      // EventSource auto-reconnects with browser's built-in retry
    };

    eventSource.onmessage = (event) => {
      subscriber.next(JSON.parse(event.data));
    };

    return () => eventSource.close();
  });
}
```

---

## Heartbeat Monitoring

```typescript
// Server sends heartbeat every 25s
// Client checks for heartbeat timeout
@Injectable({ providedIn: 'root' })
export class HeartbeatMonitor {
  private lastHeartbeat = signal(Date.now());
  private heartbeatTimeout = 35000; // 35s (server sends every 25s)
  private status = signal<'connected' | 'reconnecting' | 'disconnected'>('connected');

  startMonitoring() {
    setInterval(() => {
      const elapsed = Date.now() - this.lastHeartbeat();

      if (elapsed > this.heartbeatTimeout) {
        this.status.set('disconnected');
        // Trigger reconnection
      }
    }, 5000);
  }

  onHeartbeat() {
    this.lastHeartbeat.set(Date.now());
    this.status.set('connected');
  }
}
```

---

## Integrating with Angular Signals

```typescript
// Store real-time data in a Signal store
@Injectable({ providedIn: 'root' })
export class RealtimeStore {
  private wsService = inject(WebSocketService);

  messages = signal<ChatMessage[]>([]);
  onlineUsers = signal<Set<string>>(new Set());

  constructor() {
    this.wsService.messages$.subscribe(message => {
      this.messages.update(msgs => [...msgs, message]);
    });
  }

  // Computed from real-time data
  messageCount = computed(() => this.messages().length);
  lastMessage = computed(() => this.messages().at(-1) ?? null);
}
```

---

## Checklist

Before shipping real-time features:

- [ ] Transport protocol chosen (WebSocket vs SSE vs polling)
- [ ] Connection established and verified
- [ ] Reconnection strategy implemented (exponential backoff + jitter)
- [ ] Heartbeat monitoring active (detect stale connections)
- [ ] Error handling for all connection states
- [ ] Graceful degradation (polling fallback if WebSocket fails)
- [ ] Messages not lost during reconnection
- [ ] Memory cleanup on component destroy (unsubscribe from observables)
- [ ] Tab visibility handling (pause updates when tab hidden)
- [ ] Test with network throttling (Chrome DevTools)

## Limitations

- WebSocket requires sticky sessions in load-balanced environments (or use Redis pub/sub)
- SSE is HTTP-based — easier to proxy but limited to server→client
- Mobile browsers aggressively kill background WebSocket connections
- High-frequency updates (>100/s) may cause UI lag — batch or throttle
- Virtual threads (Spring Boot 4.x) handle many concurrent connections efficiently
