import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { validate } from '../../middleware/validate';
import { registerSchema, loginSchema } from './auth.schema';
import { authService } from './auth.service';

const router = Router();

// Auth endpoints are a classic brute-force / credential-stuffing target — rate limit tightly.
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: true, legacyHeaders: false });

router.post('/register', authLimiter, validate(registerSchema), async (req, res) => {
  const result = await authService.register(req.body);
  res.status(201).json(result);
});

router.post('/login', authLimiter, validate(loginSchema), async (req, res) => {
  const result = await authService.login(req.body);
  res.status(200).json(result);
});

export default router;
