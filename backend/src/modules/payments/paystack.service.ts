import crypto from 'node:crypto';
import { env } from '../../config/env';
import { BadRequestError } from '../../lib/errors';
import { logger } from '../../lib/logger';

const PAYSTACK_BASE = 'https://api.paystack.co';

interface InitializeTransactionArgs {
  email: string;
  amountKobo: number;
  reference: string;
  metadata: Record<string, unknown>;
}

interface PaystackInitializeResponse {
  status: boolean;
  message: string;
  data: { authorization_url: string; access_code: string; reference: string };
}

interface PaystackVerifyResponse {
  status: boolean;
  message: string;
  data: {
    status: 'success' | 'failed' | 'abandoned';
    reference: string;
    amount: number;
    metadata: Record<string, unknown>;
  };
}

class PaystackService {
  private readonly secretKey = env.PAYSTACK_SECRET_KEY;

  async initializeTransaction(args: InitializeTransactionArgs): Promise<PaystackInitializeResponse> {
    const res = await fetch(`${PAYSTACK_BASE}/transaction/initialize`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: args.email,
        amount: args.amountKobo,
        reference: args.reference,
        metadata: args.metadata,
        callback_url: env.PLATFORM_CALLBACK_URL,
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      logger.error({ status: res.status, body }, 'Paystack initialize failed');
      throw new BadRequestError('Could not initialize payment with Paystack');
    }

    return res.json() as Promise<PaystackInitializeResponse>;
  }

  // Always re-verify server-side after a webhook OR a client "I paid" callback.
  // Never trust the client's word that a payment succeeded.
  async verifyTransaction(reference: string): Promise<PaystackVerifyResponse> {
    const res = await fetch(`${PAYSTACK_BASE}/transaction/verify/${encodeURIComponent(reference)}`, {
      headers: { Authorization: `Bearer ${this.secretKey}` },
    });

    if (!res.ok) {
      throw new BadRequestError('Could not verify payment with Paystack');
    }

    return res.json() as Promise<PaystackVerifyResponse>;
  }

  // Paystack signs webhook payloads with HMAC-SHA512 of the raw body using your secret key.
  // This MUST run against the raw (unparsed) request body — see server.ts webhook route setup.
  verifyWebhookSignature(rawBody: Buffer, signatureHeader: string | undefined): boolean {
    if (!signatureHeader) return false;
    const hash = crypto.createHmac('sha512', this.secretKey).update(rawBody).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(signatureHeader));
  }
}

export const paystackService = new PaystackService();
