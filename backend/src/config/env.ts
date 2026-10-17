import { z } from 'zod';
import 'dotenv/config';

// Fail fast on boot if required config is missing — this is the #1 cause of
// "works on my machine, breaks in prod" for apps handling money and notifications.
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(4000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  PAYSTACK_SECRET_KEY: z.string().min(1, 'PAYSTACK_SECRET_KEY is required'),
  PAYSTACK_WEBHOOK_SECRET: z.string().min(1, 'PAYSTACK_WEBHOOK_SECRET is required'),
  FIREBASE_PROJECT_ID: z.string().min(1),
  FIREBASE_CLIENT_EMAIL: z.string().min(1),
  FIREBASE_PRIVATE_KEY: z.string().min(1),
  CORS_ORIGINS: z.string().default('*'),
  PLATFORM_CALLBACK_URL: z.string().url(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('❌ Invalid environment configuration:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
