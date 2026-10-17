import { Router } from 'express';
import { z } from 'zod';
import { randomUUID } from 'node:crypto';
import { prisma } from '../../lib/prisma';
import { requireAuth, requireRole, AuthedRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { paystackService } from '../payments/paystack.service';
import { pricingService } from '../payments/pricing.service';
import { BadRequestError } from '../../lib/errors';

const router = Router();

const createUnlockSchema = z.object({ body: z.object({ starLevel: z.number().int().min(1).max(5) }) });

// Customer pays the platform directly for access to a star tier — this money never
// touches a provider's account. It's purely a platform access fee.
router.post('/', requireAuth, requireRole('CUSTOMER'), validate(createUnlockSchema), async (req: AuthedRequest, res) => {
  const { starLevel } = req.body as { starLevel: number };
  const amountKobo = await pricingService.getStarTierUnlockFee(starLevel);

  if (amountKobo === 0) {
    // Tier 1 is free access in the default pricing table — no payment needed.
    const unlock = await prisma.starTierUnlock.create({
      data: { customerId: req.user!.id, starLevel, status: 'ACTIVE' },
    });
    return res.status(201).json({ unlock, requiresPayment: false });
  }

  const customer = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  const reference = `unlock_${randomUUID()}`;

  const payment = await prisma.payment.create({
    data: {
      userId: req.user!.id,
      purpose: 'STAR_TIER_UNLOCK',
      amountKobo,
      paystackRef: reference,
      status: 'INITIATED',
    },
  });

  const unlock = await prisma.starTierUnlock.create({
    data: { customerId: req.user!.id, starLevel, status: 'PENDING_PAYMENT', paymentId: payment.id },
  });

  const init = await paystackService.initializeTransaction({
    email: customer.email,
    amountKobo,
    reference,
    metadata: { purpose: 'STAR_TIER_UNLOCK', unlockId: unlock.id, starLevel },
  });

  if (!init.status) throw new BadRequestError('Payment initialization failed');

  return res.status(201).json({
    unlock,
    payment: { reference, authorizationUrl: init.data.authorization_url },
  });
});

router.get('/', requireAuth, requireRole('CUSTOMER'), async (req: AuthedRequest, res) => {
  const unlocks = await prisma.starTierUnlock.findMany({
    where: { customerId: req.user!.id },
    orderBy: { createdAt: 'desc' },
  });
  res.json(unlocks);
});

export default router;
