import { Router } from 'express';
import { z } from 'zod';
import { randomUUID } from 'node:crypto';
import { prisma } from '../../lib/prisma';
import { requireAuth, requireRole, AuthedRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { paystackService } from '../payments/paystack.service';
import { pricingService } from '../payments/pricing.service';
import { fcmService } from '../notifications/fcm.service';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../../lib/errors';

const router = Router();

const applySchema = z.object({
  params: z.object({ jobId: z.string().uuid() }),
  body: z.object({ message: z.string().max(500).optional() }),
});

// Provider pays a flat platform fee to apply — this is the provider-side monetization
// mirror of the customer-side star-tier unlock. No money crosses to the customer here either.
router.post('/jobs/:jobId/applications', requireAuth, requireRole('PROVIDER'), validate(applySchema), async (req: AuthedRequest, res) => {
  const job = await prisma.job.findUnique({ where: { id: req.params.jobId } });
  if (!job) throw new NotFoundError('Job not found');
  if (job.status !== 'OPEN') throw new BadRequestError('This job is no longer accepting applications');

  const provider = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });

  if (job.requiredStarLevel && (provider.starLevel ?? 0) < job.requiredStarLevel) {
    throw new ForbiddenError(`This job requires star level ${job.requiredStarLevel} or above`);
  }

  const existing = await prisma.jobApplication.findUnique({
    where: { jobId_providerId: { jobId: job.id, providerId: provider.id } },
  });
  if (existing) throw new ConflictError('You have already applied to this job');

  const amountKobo = await pricingService.getJobApplicationFee();
  const reference = `apply_${randomUUID()}`;

  const payment = await prisma.payment.create({
    data: { userId: provider.id, purpose: 'JOB_APPLICATION_FEE', amountKobo, paystackRef: reference, status: 'INITIATED' },
  });

  const application = await prisma.jobApplication.create({
    data: {
      jobId: job.id,
      providerId: provider.id,
      message: req.body.message,
      status: 'PENDING_PAYMENT',
      paymentId: payment.id,
    },
  });

  const init = await paystackService.initializeTransaction({
    email: provider.email,
    amountKobo,
    reference,
    metadata: { purpose: 'JOB_APPLICATION_FEE', applicationId: application.id, jobId: job.id },
  });

  if (!init.status) throw new BadRequestError('Payment initialization failed');

  res.status(201).json({ application, payment: { reference, authorizationUrl: init.data.authorization_url } });
});

// Provider's own applications across all jobs, most recent first — needed so the
// provider app can show a single "my applications" list instead of checking job-by-job.
router.get('/applications/mine', requireAuth, requireRole('PROVIDER'), async (req: AuthedRequest, res) => {
  const applications = await prisma.jobApplication.findMany({
    where: { providerId: req.user!.id },
    include: { job: { select: { id: true, title: true, category: true, location: true, status: true } } },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  res.json(applications);
});

const decisionSchema = z.object({
  params: z.object({ applicationId: z.string().uuid() }),
  body: z.object({ decision: z.enum(['ACCEPTED', 'REJECTED']) }),
});

// Customer decisions are free — the customer already paid (if needed) for star-tier access;
// accepting/rejecting a specific application carries no additional platform fee.
router.patch('/applications/:applicationId/decision', requireAuth, requireRole('CUSTOMER'), validate(decisionSchema), async (req: AuthedRequest, res) => {
  const application = await prisma.jobApplication.findUnique({
    where: { id: req.params.applicationId },
    include: { job: true, provider: true },
  });
  if (!application) throw new NotFoundError('Application not found');
  if (application.job.customerId !== req.user!.id) throw new ForbiddenError('Not your job');
  if (application.status !== 'APPLIED') throw new BadRequestError('Only paid, live applications can be decided on');

  const { decision } = req.body as { decision: 'ACCEPTED' | 'REJECTED' };

  await prisma.$transaction(async (tx) => {
    await tx.jobApplication.update({ where: { id: application.id }, data: { status: decision } });
    if (decision === 'ACCEPTED') {
      await tx.job.update({
        where: { id: application.jobId },
        data: { status: 'ASSIGNED', assignedProviderId: application.providerId },
      });
      // Reject every other pending application on this job — the slot is filled.
      await tx.jobApplication.updateMany({
        where: { jobId: application.jobId, id: { not: application.id }, status: 'APPLIED' },
        data: { status: 'REJECTED' },
      });
    }
  });

  await fcmService.sendToUser({
    userId: application.providerId,
    title: decision === 'ACCEPTED' ? 'Application accepted!' : 'Application update',
    body:
      decision === 'ACCEPTED'
        ? `You were selected for "${application.job.title}". Contact the customer to arrange the work.`
        : `Your application for "${application.job.title}" was not selected this time.`,
    data: { jobId: application.jobId, decision },
  });

  res.status(200).json({ status: 'ok' });
});

export default router;
