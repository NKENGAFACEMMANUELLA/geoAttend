import { z } from 'zod';

// Same rules as the Flutter app (Validators): 6+ characters with a number.
const email = z.string().trim().toLowerCase().email('Enter a valid email address');
const password = z
  .string()
  .min(6, 'Use at least 6 characters')
  .regex(/\d/, 'Include at least one number');

export const loginSchema = z.object({
  email,
  password: z.string().min(1, 'Password is required'),
  /** Which login screen was used. The server still decides the real role. */
  portal: z.enum(['employee', 'hod', 'admin']).optional(),
});

export const registerSchema = z.object({
  name: z.string().trim().min(2, 'Full name is required').max(100),
  email,
  employeeId: z
    .string()
    .trim()
    .min(2, 'Employee ID is required')
    .max(30)
    .transform((v) => v.toUpperCase()),
  password,
});

export const forgotSchema = z.object({ email });
export const verifyCodeSchema = z.object({ email, code: z.string().regex(/^\d{4}$/, 'Enter the 4-digit code') });
export const resetSchema = z.object({ resetToken: z.string().min(10), newPassword: password });
export const refreshSchema = z.object({ refreshToken: z.string().min(10) });

export const updateMeSchema = z.object({
  name: z.string().trim().min(2, 'Full name is required').max(100).optional(),
  phone: z
    .string()
    .trim()
    .regex(/^\+?[0-9\s]{8,16}$/, 'Enter a valid phone number')
    .or(z.literal(''))
    .optional(),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: password,
});
