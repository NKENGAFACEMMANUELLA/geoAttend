import { z } from 'zod';

const position = {
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  accuracy: z.coerce.number().min(0).optional(),
  /** Android reports when the position comes from a mock-location app. */
  mocked: z.boolean().optional(),
};

export const locationSchema = z.object(position);

export const syncSchema = z.object({
  records: z
    .array(
      z.object({
        clientId: z.string().min(1).max(100),
        type: z.enum(['in', 'out']),
        capturedAt: z.string().datetime({ offset: true }),
        ...position,
      }),
    )
    .min(1)
    .max(100),
});
