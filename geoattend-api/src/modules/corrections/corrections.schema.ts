import { z } from 'zod';

const instant = z.string().datetime({ offset: true });

export const submitCorrectionSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use the format YYYY-MM-DD'),
  requestedClockIn: instant,
  requestedClockOut: instant,
  reason: z.string().trim().max(500).default(''),
});

export const correctionDecisionSchema = z.object({ approved: z.boolean() });
