import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { asyncHandler } from '../../utils/asyncHandler';
import { assignHodSchema, createDepartmentSchema, updateDepartmentSchema } from './departments.schema';
import * as service from './departments.service';

export const departmentsRouter = Router();
departmentsRouter.use(requireAuth);

departmentsRouter.get('/', requireRole('admin', 'hod'), asyncHandler(async (_req, res) => res.json({ data: await service.list() })));

// Must stay above "/:id" so "hod-candidates" is not read as an id.
departmentsRouter.get('/hod-candidates', requireRole('admin'), asyncHandler(async (_req, res) => res.json({ data: await service.hodCandidates() })));

departmentsRouter.get('/:id', requireRole('admin', 'hod'), asyncHandler(async (req, res) => res.json({ data: await service.get(req.params.id) })));

departmentsRouter.post(
  '/',
  requireRole('admin'),
  validate(createDepartmentSchema),
  asyncHandler(async (req, res) => res.status(201).json({ data: await service.create(req.body, req.auth!.userId) })),
);
departmentsRouter.patch(
  '/:id',
  requireRole('admin'),
  validate(updateDepartmentSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.update(req.params.id, req.body, req.auth!.userId) })),
);
departmentsRouter.put(
  '/:id/hod',
  requireRole('admin'),
  validate(assignHodSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.assignHod(req.params.id, req.body.userId, req.auth!.userId) })),
);
