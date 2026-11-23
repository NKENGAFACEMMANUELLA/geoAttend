import { z } from 'zod';

const email = z.string().trim().toLowerCase().email('Enter a valid email address');
const phone = z.string().trim().regex(/^\+?[0-9\s]{8,16}$/, 'Enter a valid phone number');
const code = z.string().trim().min(2, 'Employee ID is required').max(30).transform((v) => v.toUpperCase());

// Department, position and workplace are sent by NAME (the app's dropdowns use names).
// '' means "not assigned".
export const createEmployeeSchema = z.object({
  name: z.string().trim().min(2, 'Full name is required').max(100),
  code,
  email,
  phone,
  department: z.string().trim().optional(),
  position: z.string().trim().max(80).optional(),
  workplace: z.string().trim().optional(),
});

export const updateEmployeeSchema = z.object({
  name: z.string().trim().min(2, 'Full name is required').max(100).optional(),
  code: code.optional(),
  email: email.optional(),
  phone: phone.optional(),
  department: z.string().trim().optional(),
  position: z.string().trim().max(80).optional(),
  workplace: z.string().trim().optional(),
  active: z.boolean().optional(),
});
