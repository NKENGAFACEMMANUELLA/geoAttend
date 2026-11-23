import type { ErrorRequestHandler, RequestHandler } from 'express';
import { ZodError } from 'zod';
import { HttpError } from '../utils/httpError';

export const notFound: RequestHandler = (req, res) => {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.originalUrl}` });
};

// Express recognises error handlers by their 4 parameters.
export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof ZodError) {
    const issues = err.issues.map((i) => ({ field: i.path.join('.'), message: i.message }));
    return res.status(422).json({ message: issues[0]?.message ?? 'Invalid input.', errors: issues });
  }
  if (err instanceof HttpError) {
    return res.status(err.status).json({ message: err.message, code: err.code });
  }
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'The request body is not valid JSON.' });
  }
  if (err?.code === 'P2002') {
    const target = String(err.meta?.target ?? '');
    const message = target.includes('email')
      ? 'An account with this email already exists.'
      : target.includes('employee_code')
        ? 'This employee ID is already registered.'
        : target.includes('name')
          ? 'That name is already in use.'
          : 'That value is already in use.';
    return res.status(409).json({ message });
  }
  if (err?.code === 'P2025') {
    return res.status(404).json({ message: 'That record no longer exists.' });
  }
  console.error(err);
  return res.status(500).json({ message: 'Something went wrong on our side. Please try again.' });
};
