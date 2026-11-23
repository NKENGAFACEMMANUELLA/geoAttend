import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  ACCESS_TOKEN_TTL: z.string().default('15m'),
  REFRESH_TOKEN_DAYS: z.coerce.number().default(30),
  RESET_CODE_MINUTES: z.coerce.number().default(3),
  TIMEZONE: z.string().default('Africa/Douala'),
  ABSENT_AFTER_HOUR: z.coerce.number().default(12),
  OFFLINE_MAX_DAYS: z.coerce.number().default(7),
  MAX_GPS_ACCURACY_METERS: z.coerce.number().default(150),
  COMPANY_NAME: z.string().default('TTNet LTD'),
  CORS_ORIGIN: z.string().default('*'),
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().default(587),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  MAIL_FROM: z.string().default('GeoAttend <no-reply@geoattend.app>'),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
export const isProd = env.NODE_ENV === 'production';
