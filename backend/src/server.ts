import 'express-async-errors'; // must be imported before routes are registered
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import pinoHttp from 'pino-http';
import { env } from './config/env';
import { logger } from './lib/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';

import authRoutes from './modules/auth/auth.routes';
import userRoutes from './modules/users/users.routes';
import jobRoutes from './modules/jobs/jobs.routes';
import unlockRoutes from './modules/unlocks/unlocks.routes';
import applicationRoutes from './modules/applications/applications.routes';
import paymentRoutes from './modules/payments/payments.routes';

const app = express();

app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGINS === '*' ? true : env.CORS_ORIGINS.split(',') }));
app.use(pinoHttp({ logger }));

// CRITICAL ORDERING: the Paystack webhook needs the raw request body to verify the
// HMAC signature, so it must be registered with express.raw() BEFORE the global
// express.json() below — otherwise json() consumes the stream first and the signature
// check will always fail against a re-serialized (and therefore different) body.
app.use('/api/payments/webhooks/paystack', express.raw({ type: 'application/json' }));

app.use(express.json());

// General API rate limit — generous, since per-route limits (e.g. auth) are stricter.
app.use(rateLimit({ windowMs: 60 * 1000, limit: 100, standardHeaders: true, legacyHeaders: false }));

app.get('/health', (_req, res) => res.json({ status: 'ok', env: env.NODE_ENV }));

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/unlocks', unlockRoutes);
app.use('/api', applicationRoutes); // mounts /jobs/:jobId/applications and /applications/:id/decision
app.use('/api/payments', paymentRoutes); // mounts /webhooks/paystack and /:reference/status

app.use(notFoundHandler);
app.use(errorHandler);

app.listen(env.PORT, () => {
  logger.info(`Moka backend listening on port ${env.PORT} [${env.NODE_ENV}]`);
});
