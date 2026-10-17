import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { UnauthorizedError, ForbiddenError } from '../lib/errors';
import { Role } from '@prisma/client';

export interface AuthedRequest extends Request {
  user?: { id: string; role: Role };
}

export function requireAuth(req: AuthedRequest, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw new UnauthorizedError('Missing or malformed Authorization header');
  }
  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as { sub: string; role: Role };
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch {
    throw new UnauthorizedError('Invalid or expired token');
  }
}

// Usage: router.post('/jobs', requireAuth, requireRole('CUSTOMER'), handler)
export function requireRole(...roles: Role[]) {
  return (req: AuthedRequest, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      throw new ForbiddenError(`Requires one of roles: ${roles.join(', ')}`);
    }
    next();
  };
}
