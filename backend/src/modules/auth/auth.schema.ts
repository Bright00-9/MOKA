import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    fullName: z.string().min(2).max(100),
    email: z.string().email(),
    phone: z.string().min(9).max(15).optional(),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    role: z.enum(['CUSTOMER', 'PROVIDER']),
    // Providers start at tier 1 by default; verified/promoted tiers are admin-controlled,
    // never self-declared, since star level is what customers pay to access.
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(1),
  }),
});

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];
