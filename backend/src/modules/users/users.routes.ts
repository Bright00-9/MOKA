import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../lib/prisma';
import { requireAuth, AuthedRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { NotFoundError } from '../../lib/errors';

const router = Router();

router.get('/me', requireAuth, async (req: AuthedRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: {
      id: true, email: true, phone: true, fullName: true, role: true,
      starLevel: true, bio: true, skills: true, verified: true, createdAt: true,
    },
  });
  if (!user) throw new NotFoundError('User not found');
  res.json(user);
});

const fcmTokenSchema = z.object({ body: z.object({ fcmToken: z.string().min(1) }) });

router.patch('/me/fcm-token', requireAuth, validate(fcmTokenSchema), async (req: AuthedRequest, res) => {
  await prisma.user.update({ where: { id: req.user!.id }, data: { fcmToken: req.body.fcmToken } });
  res.status(204).send();
});

// Public-ish directory: shows WHO exists at a star tier, but contact details (email/phone)
// stay redacted until the customer has an ACTIVE unlock for that tier — enforced here,
// not just in the UI, since the UI can be bypassed.
router.get('/providers', requireAuth, async (req: AuthedRequest, res) => {
  const starLevel = req.query.starLevel ? Number(req.query.starLevel) : undefined;

  const providers = await prisma.user.findMany({
    where: { role: 'PROVIDER', ...(starLevel ? { starLevel } : {}) },
    select: {
      id: true, fullName: true, starLevel: true, bio: true, skills: true, verified: true,
      email: true, phone: true,
    },
    take: 50,
  });

  let unlockedTiers = new Set<number>();
  if (req.user!.role === 'CUSTOMER') {
    const unlocks = await prisma.starTierUnlock.findMany({
      where: {
        customerId: req.user!.id,
        status: 'ACTIVE',
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      },
      select: { starLevel: true },
    });
    unlockedTiers = new Set(unlocks.map((u) => u.starLevel));
  }

  // Strip contact details server-side for any tier the customer hasn't paid to unlock.
  // Never rely on the client to hide what it was never sent, and never send what it
  // shouldn't have — redact in the response payload itself.
  const result = providers.map(({ email, phone, ...rest }) => {
    const unlocked = req.user!.role !== 'CUSTOMER' || unlockedTiers.has(rest.starLevel ?? 1);
    return { ...rest, contactUnlocked: unlocked, ...(unlocked ? { email, phone } : {}) };
  });

  res.json(result);
});

export default router;
