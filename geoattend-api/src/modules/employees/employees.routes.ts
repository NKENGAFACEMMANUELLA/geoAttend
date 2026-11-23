import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { asyncHandler } from '../../utils/asyncHandler';
import { createEmployeeSchema, updateEmployeeSchema } from './employees.schema';
import * as service from './employees.service';

export const employeesRouter = Router();
employeesRouter.use(requireAuth, requireRole('admin'));

employeesRouter.get('/', asyncHandler(async (_req, res) => res.json({ data: await service.list() })));
employeesRouter.get('/:id', asyncHandler(async (req, res) => res.json({ data: await service.get(req.params.id) })));
employeesRouter.post(
  '/',
  validate(createEmployeeSchema),
  asyncHandler(async (req, res) => res.status(201).json({ data: await service.create(req.body, req.auth!.userId) })),
);
employeesRouter.patch(
  '/:id',
  validate(updateEmployeeSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.update(req.params.id, req.body, req.auth!.userId) })),
);
