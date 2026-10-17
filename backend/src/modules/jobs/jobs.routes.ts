import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../lib/prisma';
import { requireAuth, requireRole, AuthedRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { NotFoundError, ForbiddenError } from '../../lib/errors';

const router = Router();

const createJobSchema = z.object({
  body: z.object({
    title: z.string().min(5).max(120),
    description: z.string().min(20).max(2000),
    category: z.string().min(2).max(50),
    location: z.string().min(2).max(120),
    budgetMin: z.number().int().positive().optional(),
    budgetMax: z.number().int().positive().optional(),
    requiredStarLevel: z.number().int().min(1).max(5).optional(),
  }),
});

router.post('/', requireAuth, requireRole('CUSTOMER'), validate(createJobSchema), async (req: AuthedRequest, res) => {
  const job = await prisma.job.create({
    data: { ...req.body, customerId: req.user!.id },
  });
  res.status(201).json(job);
});

// Providers see only OPEN jobs; a job's required star level is informational here —
// actual gating happens when the provider tries to apply (see applications module).
router.get('/', requireAuth, async (req: AuthedRequest, res) => {
  const { status, category } = req.query as { status?: string; category?: string };
  const jobs = await prisma.job.findMany({
    where: {
      ...(req.user!.role === 'CUSTOMER' ? { customerId: req.user!.id } : { status: status ?? 'OPEN' }),
      ...(category ? { category } : {}),
    },
    orderBy: { createdAt: 'desc' },
    include: { _count: { select: { applications: true } } },
    take: 50,
  });
  res.json(jobs);
});

router.get('/:id', requireAuth, async (req: AuthedRequest, res) => {
  const job = await prisma.job.findUnique({
    where: { id: req.params.id },
    include: {
      applications: {
        where: req.user!.role === 'CUSTOMER' ? { status: 'APPLIED' } : { providerId: req.user!.id },
        include: { provider: { select: { id: true, fullName: true, starLevel: true, verified: true, bio: true } } },
      },
    },
  });
  if (!job) throw new NotFoundError('Job not found');
  if (req.user!.role === 'CUSTOMER' && job.customerId !== req.user!.id) {
    throw new ForbiddenError('Not your job');
  }
  res.json(job);
});

export default router;
