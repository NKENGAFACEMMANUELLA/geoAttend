import { z } from 'zod';

export const createDepartmentSchema = z.object({
  name: z.string().trim().min(2, 'Department name is required').max(100),
  description: z.string().trim().max(300).optional(),
  hodUserId: z.string().min(1).optional(),
});

export const updateDepartmentSchema = z.object({
  name: z.string().trim().min(2, 'Department name is required').max(100).optional(),
  description: z.string().trim().max(300).optional(),
  active: z.boolean().optional(),
});

export const assignHodSchema = z.object({ userId: z.string().min(1, 'Choose a HOD') });
