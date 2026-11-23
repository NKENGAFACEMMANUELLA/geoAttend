import type { RequestHandler } from 'express';
import { prisma } from '../lib/prisma';
import { HttpError } from '../utils/httpError';
import { asyncHandler } from '../utils/asyncHandler';
import { verifyAccessToken, type Role } from '../utils/jwt';

/** Requires a valid access token and an active account. Sets req.auth. */
export const requireAuth: RequestHandler = asyncHandler(async (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) throw new HttpError(401, 'Please sign in to continue.');

  let userId: string;
  try {
    userId = verifyAccessToken(header.slice(7)).sub;
  } catch {
    throw new HttpError(401, 'Your session has expired. Please sign in again.', 'TOKEN_EXPIRED');
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, role: true, isActive: true },
  });
  if (!user || !user.isActive) throw new HttpError(401, 'This account is no longer available.');

  req.auth = { userId: user.id, role: user.role as Role };
  next();
});

export const requireRole =
  (...roles: Role[]): RequestHandler =>
  (req, _res, next) => {
    if (!req.auth || !roles.includes(req.auth.role)) {
      return next(new HttpError(403, 'You do not have permission to do that.'));
    }
    next();
  };
