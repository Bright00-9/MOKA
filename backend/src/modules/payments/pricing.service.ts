import { prisma } from '../../lib/prisma';

// Fees live in the DB (PricingConfig singleton row), not in code, so the platform
// can change pricing without a redeploy. Falls back to sane defaults if unseeded.
const DEFAULTS = {
  jobApplicationFeeKobo: 500000, // GHS 50.00
  starTierUnlockKobo: { '1': 0, '2': 1000000, '3': 2000000, '4': 3500000, '5': 5000000 } as Record<string, number>,
};

export const pricingService = {
  async getJobApplicationFee(): Promise<number> {
    const config = await prisma.pricingConfig.findUnique({ where: { id: 'singleton' } });
    return config?.jobApplicationFeeKobo ?? DEFAULTS.jobApplicationFeeKobo;
  },

  async getStarTierUnlockFee(starLevel: number): Promise<number> {
    const config = await prisma.pricingConfig.findUnique({ where: { id: 'singleton' } });
    const table = (config?.starTierUnlockKobo as Record<string, number>) ?? DEFAULTS.starTierUnlockKobo;
    return table[String(starLevel)] ?? 0;
  },
};
