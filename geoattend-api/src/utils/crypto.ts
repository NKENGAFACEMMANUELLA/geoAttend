import bcrypt from 'bcryptjs';
import crypto from 'crypto';

export const sha256 = (value: string) => crypto.createHash('sha256').update(value).digest('hex');

export const randomToken = (bytes = 48) => crypto.randomBytes(bytes).toString('base64url');

export const randomCode = () => String(crypto.randomInt(1000, 10000)); // 4 digits

export const safeEqual = (a: string, b: string) => {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && crypto.timingSafeEqual(ab, bb);
};

export const hashPassword = (plain: string) => bcrypt.hash(plain, 10);
export const verifyPassword = (plain: string, hash: string) => bcrypt.compare(plain, hash);

/** Compared when the email does not exist, so response time does not reveal accounts. */
export const DUMMY_HASH = bcrypt.hashSync('not-a-real-password-1', 10);

export const addDays = (d: Date, days: number) => new Date(d.getTime() + days * 86_400_000);
export const addMinutes = (d: Date, minutes: number) => new Date(d.getTime() + minutes * 60_000);
