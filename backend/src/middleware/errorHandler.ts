import { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../lib/errors';
import { logger } from '../lib/logger';
import { env } from '../config/env';

// Keep this as the LAST middleware registered in server.ts.
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'Invalid request', details: err.flatten() },
    });
  }

  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error({ err, path: req.path }, err.message);
    }
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }

  // Unknown error — log full detail server-side, return a generic message to the client.
  logger.error({ err, path: req.path }, 'Unhandled error');
  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Something went wrong',
      // Only leak internals outside production to speed up debugging.
      ...(env.NODE_ENV !== 'production' && err instanceof Error ? { debug: err.message } : {}),
    },
  });
}

export function notFoundHandler(req: Request, res: Response) {
  res.status(404).json({ error: { code: 'NOT_FOUND', message: `No route for ${req.method} ${req.path}` } });
}
