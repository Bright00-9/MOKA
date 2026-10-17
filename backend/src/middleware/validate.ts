import { NextFunction, Request, Response } from 'express';
import { AnyZodObject } from 'zod';

// Wraps a zod schema so route handlers get fully-typed, pre-validated req.body/query/params.
// Validation errors are ZodErrors, caught centrally by errorHandler.
export function validate(schema: AnyZodObject) {
  return (req: Request, _res: Response, next: NextFunction) => {
    const parsed = schema.parse({
      body: req.body,
      query: req.query,
      params: req.params,
    });
    req.body = parsed.body ?? req.body;
    next();
  };
}
