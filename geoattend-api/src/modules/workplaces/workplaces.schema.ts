import { z } from 'zod';

const fields = {
  name: z.string().trim().min(2, 'Workplace name is required').max(100),
  address: z.string().trim().max(200).default(''),
  latitude: z.coerce.number().min(-90, 'Latitude must be between -90 and 90').max(90, 'Latitude must be between -90 and 90'),
  longitude: z.coerce.number().min(-180, 'Longitude must be between -180 and 180').max(180, 'Longitude must be between -180 and 180'),
  radius: z.coerce.number().int('Radius must be a whole number').min(50, 'Radius must be between 50 and 500 meters').max(500, 'Radius must be between 50 and 500 meters'),
  active: z.boolean().optional(),
};

export const createWorkplaceSchema = z.object(fields);
export const updateWorkplaceSchema = z.object(fields).partial();
