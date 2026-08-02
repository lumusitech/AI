---
name: webhooks
description: "Webhook design and implementation: request/response contracts, idempotency, retries with exponential backoff, HMAC signature verification, replay protection. Use when building webhook receivers or senders in Spring Boot or any backend."
risk: safe
source: self
date_added: "2026-08-02"
---

# Webhooks — Design & Implementation

## When to Use

- Receiving webhooks from third-party services (Stripe, GitHub, MercadoPago)
- Sending webhooks to notify other systems of events
- Building reliable event-driven integrations

---

## Webhook Contract

### Receiver (Spring Boot)

```java
@RestController
@RequestMapping("/webhooks")
public class WebhookController {

    private final WebhookService webhookService;

    @PostMapping("/stripe")
    public ResponseEntity<Void> handleStripe(
            @RequestBody String payload,
            @RequestHeader("Stripe-Signature") String signature) {

        if (!webhookService.verifySignature(payload, signature, "stripe")) {
            return ResponseEntity.status(401).build();
        }

        StripeEvent event = objectMapper.readValue(payload, StripeEvent.class);

        // Idempotency check
        if (webhookService.alreadyProcessed(event.getId())) {
            return ResponseEntity.ok().build(); // 200, not 409
        }

        webhookService.process(event);
        return ResponseEntity.ok().build();
    }
}
```

### Response Rules

| Scenario | Response | Why |
|----------|----------|-----|
| Success | `200 OK` | Sender retries on non-2xx |
| Signature invalid | `401 Unauthorized` | Sender knows to stop |
| Processing error | `200 OK` + log | Retrying won't fix code bugs |
| Payload too large | `413 Payload Too Large` | Sender should reduce payload |
| Rate limited | `429 Too Many Requests` | Sender retries with backoff |

**Never return 5xx for webhook processing errors.** A 500 triggers infinite retries. Process asynchronously and return 200.

---

## Idempotency

### Database Table

```sql
CREATE TABLE webhook_events (
    id VARCHAR(64) PRIMARY KEY,        -- External event ID
    source VARCHAR(32) NOT NULL,       -- stripe, github, mercadopago
    event_type VARCHAR(64) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(16) DEFAULT 'pending',  -- pending, processing, completed, failed
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE INDEX idx_webhook_events_idempotency ON webhook_events(source, id);
```

### Idempotent Processing

```java
@Service
public class WebhookService {

    @Transactional
    public boolean process(StripeEvent event) {
        // Atomic check-and-insert
        int inserted = jdbcTemplate.update("""
            INSERT INTO webhook_events (id, source, event_type, payload)
            VALUES (?, 'stripe', ?, ?::jsonb)
            ON CONFLICT (id) DO NOTHING
            """, event.getId(), event.getType(), event.toJson());

        if (inserted == 0) {
            return false; // Already processed
        }

        // Process the event
        processEvent(event);

        jdbcTemplate.update("""
            UPDATE webhook_events
            SET status = 'completed', processed_at = NOW()
            WHERE id = ? AND source = 'stripe'
            """, event.getId());

        return true;
    }
}
```

---

## Signature Verification

### HMAC Verification (Stripe Pattern)

```java
@Service
public class WebhookService {

    public boolean verifySignature(String payload, String signatureHeader, String source) {
        return switch (source) {
            case "stripe" -> verifyStripeSignature(payload, signatureHeader);
            case "github" -> verifyGitHubSignature(payload, signatureHeader);
            default -> false;
        };
    }

    private boolean verifyStripeSignature(String payload, String signatureHeader) {
        // Stripe: t=timestamp,v1=signature
        String[] parts = signatureHeader.split(",");
        String timestamp = parts[0].replace("t=", "");
        String expectedSig = parts[1].replace("v1=", "");

        String signedPayload = timestamp + "." + payload;
        String computedSig = hmacSha256(signedPayload, webhookSecret);

        return MessageDigest.isEqual(
            expectedSig.getBytes(StandardCharsets.UTF_8),
            computedSig.getBytes(StandardCharsets.UTF_8)
        );
    }

    private boolean verifyGitHubSignature(String payload, String signatureHeader) {
        // GitHub: sha256=hash
        String expectedSig = signatureHeader.replace("sha256=", "");
        String computedSig = "sha256=" + hmacSha256(payload, webhookSecret);
        return MessageDigest.isEqual(
            expectedSig.getBytes(),
            computedSig.getBytes()
        );
    }

    private String hmacSha256(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hash = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Hex.encodeHexString(hash);
        } catch (Exception e) {
            throw new WebhookException("Signature verification failed", e);
        }
    }
}
```

### Replay Protection

```java
// Reject events older than 5 minutes (prevents replay attacks)
private boolean isReplayAttack(String timestamp) {
    long eventTime = Long.parseLong(timestamp);
    long now = Instant.now().getEpochSecond();
    return Math.abs(now - eventTime) > 300; // 5 minutes
}
```

---

## Retries & Backoff

### Exponential Backoff Table

| Attempt | Delay | Cumulative |
|---------|-------|------------|
| 1 | Immediate | 0s |
| 2 | 1s | 1s |
| 3 | 2s | 3s |
| 4 | 4s | 7s |
| 5 | 8s | 15s |
| 6 | 16s | 31s |
| 7 | 32s | 63s |
| 8 | 64s | ~2 min |
| 9 | 128s | ~4 min |
| 10 | 256s | ~8 min |

### Sender Side (Spring Boot)

```java
@Service
public class WebhookSender {

    private final HttpClient client = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper;

    @Async
    @Retryable(
        value = {WebhookDeliveryException.class},
        maxAttempts = 8,
        backoff = @Backoff(delay = 1000, multiplier = 2)
    )
    public void send(WebhookSubscription subscription, Object payload) {
        String body = objectMapper.writeValueAsString(payload);

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(subscription.getUrl()))
            .header("Content-Type", "application/json")
            .header("X-Webhook-Signature", computeSignature(body, subscription.getSecret()))
            .header("X-Webhook-Timestamp", String.valueOf(Instant.now().getEpochSecond()))
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build();

        HttpResponse<Void> response = client.send(request, HttpResponse.BodyHandlers.discarding());

        if (response.statusCode() >= 400) {
            throw new WebhookDeliveryException(
                "Webhook delivery failed: " + response.statusCode()
            );
        }
    }

    @Recover
    public void recover(WebhookDeliveryException e, WebhookSubscription subscription, Object payload) {
        // Log and alert — webhook permanently failed after retries
        log.error("Webhook delivery permanently failed for {}: {}", subscription.getUrl(), e.getMessage());
    }
}
```

---

## Webhook Patterns

### Stripe Pattern (Recommended)

```
1. Generate event → store in webhook_events table
2. Send webhook to all subscribed URLs
3. Retry with exponential backoff on failure
4. After 8 failures → mark as failed, alert operator
5. Receiver verifies signature, checks idempotency, processes
```

### GitHub Pattern

```
1. Event occurs → GitHub sends POST to configured URL
2. Receiver must respond within 10 seconds
3. GitHub retries up to 3 times with exponential backoff
4. Signature: sha256=HMAC-SHA256(secret, payload)
5. X-Hub-Signature-256 header
```

### MercadoPago Pattern

```
1. Payment event → MercadoPago sends notification
2. Receiver queries API for payment details (don't trust notification body alone)
3. Verify webhook_id matches expected format
4. Idempotency by payment_id + action
```

---

## Dev Tools & Testing

### Local Development

```bash
# webhook.site — inspect incoming webhooks
# Visit https://webhook.site, copy the URL as your webhook endpoint

# cloudflared — expose local server to internet
cloudflared tunnel --url http://localhost:8080

# ngrok alternative
ngrok http 8080
```

### Test Payload Generator

```java
@RestController
@RequestMapping("/test/webhooks")
public class TestWebhookController {

    @PostMapping("/stripe")
    public ResponseEntity<Void> simulateStripeWebhook() {
        // Simulate a payment_intent.succeeded event
        Map<String, Object> event = Map.of(
            "id", "evt_test_" + UUID.randomUUID(),
            "type", "payment_intent.succeeded",
            "data", Map.of(
                "object", Map.of(
                    "id", "pi_test_123",
                    "amount", 2000,
                    "currency", "usd"
                )
            )
        );

        webhookService.processStripeEvent(objectMapper.writeValueAsString(event));
        return ResponseEntity.ok().build();
    }
}
```

---

## Checklist

Before shipping webhook integration:

- [ ] Signature verification implemented
- [ ] Idempotency check (event ID unique constraint)
- [ ] Return 200 for all processed events (even failures)
- [ ] Replay protection (reject events > 5 min old)
- [ ] Async processing (return 200, process in background)
- [ ] Retry logic with exponential backoff on sender
- [ ] Dead letter queue for permanently failed deliveries
- [ ] Logging with correlation IDs
- [ ] Rate limiting on receiver endpoint
- [ ] Test endpoint for local development

## Limitations

- Webhooks are unreliable by nature — always design for retries and duplicates
- HMAC verification requires shared secret management (consider Vault, AWS Secrets Manager)
- Some services (Stripe, GitHub) have specific timeout requirements (10s, 30s)
- Cross-origin webhooks may be blocked by firewalls — use cloudflared/ngrok for dev
