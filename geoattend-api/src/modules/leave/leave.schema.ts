import { z } from 'zod';

export const LEAVE_TYPES = [
  'Annual Leave', 'Sick Leave', 'Personal Leave', 'Maternity / Paternity Leave', 'Unpaid Leave',
] as const;

const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use the format YYYY-MM-DD');

export const submitLeaveSchema = z.object({
  type: z.enum(LEAVE_TYPES, { errorMap: () => ({ message: 'Choose a leave type' }) }),
  start: day,
  end: day,
  reason: z.string().trim().max(500).default(''),
});

export const decisionSchema = z.object({ approved: z.boolean() });
