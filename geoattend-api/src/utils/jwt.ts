import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export type Role = 'employee' | 'hod' | 'admin';

interface AccessPayload {
  sub: string;
  role: Role;
}

export const signAccessToken = (userId: string, role: Role) =>
  jwt.sign({ role }, env.JWT_SECRET, {
    subject: userId,
    expiresIn: env.ACCESS_TOKEN_TTL as jwt.SignOptions['expiresIn'],
  });

export const verifyAccessToken = (token: string): AccessPayload => {
  const p = jwt.verify(token, env.JWT_SECRET) as jwt.JwtPayload;
  if (p.purpose || !p.sub) throw new Error('Not an access token');
  return { sub: p.sub, role: p.role as Role };
};

/** Short-lived token proving the 4-digit code was entered correctly. */
export const signResetToken = (userId: string) =>
  jwt.sign({ purpose: 'password-reset' }, env.JWT_SECRET, { subject: userId, expiresIn: '10m' });

export const verifyResetToken = (token: string): string => {
  const p = jwt.verify(token, env.JWT_SECRET) as jwt.JwtPayload;
  if (p.purpose !== 'password-reset' || !p.sub) throw new Error('Not a reset token');
  return p.sub;
};
