---
name: mercadopago
description: Integration patterns for MercadoPago LATAM (Checkout Pro, Checkout API, Pix, Subscriptions, Webhook Security, Node/Java SDKs).
version: 2.0.0
last_updated: 2026-08-01
---

# 💳 MercadoPago Integration Guide (LATAM)

This skill provides verified code patterns for integrating MercadoPago payment workflows in Node.js / TypeScript and Java / Spring Boot.

## 🚀 Key Integration Workflows

### 1. Checkout Pro (Preference Creation)

#### TypeScript / Node.js SDK (v2+)
```typescript
import { MercadoPagoConfig, Preference } from 'mercadopago';

const client = new MercadoPagoConfig({ 
  accessToken: process.env.MERCADOPAGO_ACCESS_TOKEN! 
});

export async function createCheckoutPreference(itemTitle: string, price: number) {
  const preference = new Preference(client);
  const result = await preference.create({
    body: {
      items: [
        {
          id: 'item-123',
          title: itemTitle,
          quantity: 1,
          unit_price: price,
          currency_id: 'COP' // o BRL, ARS, MXN, CLP
        }
      ],
      back_urls: {
        success: 'https://example.com/payment/success',
        failure: 'https://example.com/payment/failure',
        pending: 'https://example.com/payment/pending'
      },
      auto_return: 'approved',
      notification_url: 'https://example.com/api/webhooks/mercadopago'
    }
  });

  return { initPoint: result.init_point, id: result.id };
}
```

### 2. Instant Payments / Pix / Direct API Payments

#### TypeScript / Node.js
```typescript
import { Payment } from 'mercadopago';

export async function createPixPayment(amount: number, email: string) {
  const payment = new Payment(client);
  const response = await payment.create({
    body: {
      transaction_amount: amount,
      description: 'Pago de servicio',
      payment_method_id: 'pix',
      payer: { email }
    },
    requestOptions: {
      idempotencyKey: `pix-${Date.now()}-${Math.random()}`
    }
  });

  return {
    status: response.status,
    qrCode: response.point_of_interaction?.transaction_data?.qr_code,
    qrCodeBase64: response.point_of_interaction?.transaction_data?.qr_code_base64
  };
}
```

### 3. Webhook Handling & Signature Validation (`x-signature`)
Always validate MercadoPago webhook headers to prevent spoofing attacks:
```typescript
import crypto from 'crypto';

export function verifyWebhookSignature(
  xSignature: string,
  requestId: string,
  dataId: string,
  secret: string
): boolean {
  if (!xSignature) return false;

  const parts = xSignature.split(',');
  let ts = '';
  let v1 = '';

  for (const part of parts) {
    const [key, val] = part.split('=');
    if (key.trim() === 'ts') ts = val.trim();
    if (key.trim() === 'v1') v1 = val.trim();
  }

  const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
  const hmac = crypto.createHmac('sha256', secret).update(manifest).digest('hex');

  return hmac === v1;
}
```
