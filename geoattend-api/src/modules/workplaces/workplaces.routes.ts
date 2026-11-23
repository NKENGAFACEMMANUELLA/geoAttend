import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { asyncHandler } from '../../utils/asyncHandler';
import { createWorkplaceSchema, updateWorkplaceSchema } from './workplaces.schema';
import * as service from './workplaces.service';

export const workplacesRouter = Router();
workplacesRouter.use(requireAuth);

// Everyone signed in can read (the clock-in screen needs the workplace); only admins change them.
workplacesRouter.get('/', asyncHandler(async (req, res) => res.json({ data: await service.list(req.auth!.role) })));
workplacesRouter.get('/:id', asyncHandler(async (req, res) => res.json({ data: await service.get(req.params.id) })));

workplacesRouter.post(
  '/',
  requireRole('admin'),
  validate(createWorkplaceSchema),
  asyncHandler(async (req, res) => res.status(201).json({ data: await service.create(req.body, req.auth!.userId) })),
);
workplacesRouter.patch(
  '/:id',
  requireRole('admin'),
  validate(updateWorkplaceSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.update(req.params.id, req.body, req.auth!.userId) })),
);
