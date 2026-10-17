import { Router, Request } from 'express';
import { prisma } from '../../lib/prisma';
import { paystackService } from './paystack.service';
import { fcmService } from '../notifications/fcm.service';
import { logger } from '../../lib/logger';
import { requireAuth, AuthedRequest } from '../../middleware/auth';
import { NotFoundError } from '../../lib/errors';

const router = Router();

// IMPORTANT: this route must receive the RAW body, not JSON-parsed, so the HMAC
// signature check is against exactly the bytes Paystack signed. server.ts registers
// express.raw() for this exact path BEFORE the global express.json() middleware.
router.post('/webhooks/paystack', async (req: Request, res) => {
  const signature = req.headers['x-paystack-signature'] as string | undefined;
  const rawBody = req.body as Buffer;

  if (!paystackService.verifyWebhookSignature(rawBody, signature)) {
    logger.warn('Rejected Paystack webhook with invalid signature');
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Ack immediately — Paystack retries on non-2xx/timeout. Do the real work after acking
  // only if that work is fast and idempotent, which ours is (see idempotency note below).
  res.status(200).json({ received: true });

  const event = JSON.parse(rawBody.toString('utf8'));

  if (event.event !== 'charge.success') {
    logger.info({ event: event.event }, 'Ignoring non-charge Paystack event');
    return;
  }

  const reference: string = event.data.reference;

  try {
    // Always re-verify with Paystack's API rather than trusting the webhook body alone —
    // this defends against a forged-but-somehow-signed payload and against replays.
    const verification = await paystackService.verifyTransaction(reference);
    if (verification.data.status !== 'success') return;

    await reconcilePayment(reference, event.data);
  } catch (err) {
    logger.error({ err, reference }, 'Failed to reconcile Paystack webhook');
    // Paystack does not retry on our internal errors after we've already 200'd, so this
    // failure needs to surface via monitoring/alerting in production, not just this log line.
  }
  return;
});

async function reconcilePayment(reference: string, rawWebhookData: unknown) {
  const payment = await prisma.payment.findUnique({
    where: { paystackRef: reference },
    include: { starTierUnlock: true, jobApplication: { include: { job: true } } },
  });
  if (!payment) {
    logger.warn({ reference }, 'Webhook for unknown payment reference');
    return;
  }

  // Idempotency: if we already marked this SUCCESS (e.g. webhook fired twice), stop here.
  if (payment.status === 'SUCCESS') return;

  await prisma.payment.update({
    where: { id: payment.id },
    data: { status: 'SUCCESS', rawWebhookData: rawWebhookData as object },
  });

  if (payment.starTierUnlock) {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // unlocks last 30 days
    await prisma.starTierUnlock.update({
      where: { id: payment.starTierUnlock.id },
      data: { status: 'ACTIVE', expiresAt },
    });
    await fcmService.sendToUser({
      userId: payment.userId,
      title: 'Star tier unlocked',
      body: `You now have 30 days of access to tier ${payment.starTierUnlock.starLevel} providers.`,
      data: { unlockId: payment.starTierUnlock.id },
    });
  }

  if (payment.jobApplication) {
    await prisma.jobApplication.update({ where: { id: payment.jobApplication.id }, data: { status: 'APPLIED' } });
    await fcmService.sendToUser({
      userId: payment.jobApplication.job.customerId,
      title: 'New application received',
      body: `A provider applied to "${payment.jobApplication.job.title}".`,
      data: { jobId: payment.jobApplication.jobId, applicationId: payment.jobApplication.id },
    });
  }
}

// Client-side polling fallback for right after Paystack's redirect — webhooks can lag
// by a few seconds, so the app can call this to check status instead of guessing.
router.get('/payments/:reference/status', requireAuth, async (req: AuthedRequest, res) => {
  const payment = await prisma.payment.findUnique({ where: { paystackRef: req.params.reference } });
  if (!payment || payment.userId !== req.user!.id) throw new NotFoundError('Payment not found');
  res.json({ status: payment.status });
});

export default router;
