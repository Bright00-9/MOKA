import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  await prisma.pricingConfig.upsert({
    where: { id: 'singleton' },
    update: {},
    create: {
      id: 'singleton',
      jobApplicationFeeKobo: 500000, // GHS 50.00 flat fee for a provider to apply to any job
      starTierUnlockKobo: {
        '1': 0,        // tier 1 (new/unverified providers) — free access
        '2': 1000000,  // GHS 100.00
        '3': 2000000,  // GHS 200.00
        '4': 3500000,  // GHS 350.00
        '5': 5000000,  // GHS 500.00 — top-tier providers
      },
    },
  });
  console.log('Seeded PricingConfig singleton.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
