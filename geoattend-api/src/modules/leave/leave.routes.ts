import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { asyncHandler } from '../../utils/asyncHandler';
import { decisionSchema, submitLeaveSchema } from './leave.schema';
import * as service from './leave.service';

export const leaveRouter = Router();
leaveRouter.use(requireAuth);

leaveRouter.post('/', requireRole('employee'), validate(submitLeaveSchema),
  asyncHandler(async (req, res) => res.status(201).json({ data: await service.submit(req.auth!.userId, req.body) })));
leaveRouter.get('/mine', requireRole('employee'),
  asyncHandler(async (req, res) => res.json({ data: await service.mine(req.auth!.userId) })));
leaveRouter.get('/pending', requireRole('hod', 'admin'),
  asyncHandler(async (req, res) => res.json({ data: await service.forApproval(req.auth!.userId, req.auth!.role) })));
leaveRouter.patch('/:id/decision', requireRole('hod', 'admin'), validate(decisionSchema),
  asyncHandler(async (req, res) =>
    res.json({ data: await service.decide(req.params.id, req.auth!.userId, req.auth!.role, req.body.approved) })));
leaveRouter.delete('/:id', requireRole('employee'),
  asyncHandler(async (req, res) => res.json({ data: await service.cancel(req.params.id, req.auth!.userId) })));
