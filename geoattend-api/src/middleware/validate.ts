import type { RequestHandler } from 'express';
import type { ZodTypeAny } from 'zod';

/** Validates and cleans req.body. Failures go to the error handler as ZodError. */
export const validate =
  (schema: ZodTypeAny): RequestHandler =>
  (req, _res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) return next(result.error);
    req.body = result.data;
    next();
  };
