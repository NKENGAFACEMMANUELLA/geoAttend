import rateLimit from 'express-rate-limit';

const tooMany = { message: 'Too many attempts. Please wait a few minutes and try again.' };

export const loginLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: tooMany,
});

export const codeLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: tooMany,
});
