import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { asyncHandler } from '../../utils/asyncHandler';
import { correctionDecisionSchema, submitCorrectionSchema } from './corrections.schema';
import * as service from './corrections.service';

export const correctionsRouter = Router();
correctionsRouter.use(requireAuth);

correctionsRouter.post('/', requireRole('employee'), validate(submitCorrectionSchema),
  asyncHandler(async (req, res) => res.status(201).json({ data: await service.submit(req.auth!.userId, req.body) })));
correctionsRouter.get('/mine', requireRole('employee'),
  asyncHandler(async (req, res) => res.json({ data: await service.mine(req.auth!.userId) })));
correctionsRouter.get('/pending', requireRole('hod', 'admin'),
  asyncHandler(async (req, res) => res.json({ data: await service.forApproval(req.auth!.userId, req.auth!.role) })));
correctionsRouter.patch('/:id/decision', requireRole('hod', 'admin'), validate(correctionDecisionSchema),
  asyncHandler(async (req, res) =>
    res.json({ data: await service.decide(req.params.id, req.auth!.userId, req.auth!.role, req.body.approved) })));
