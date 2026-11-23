import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { asyncHandler } from '../../utils/asyncHandler';
import * as service from './admin.service';

export const adminRouter = Router();
adminRouter.use(requireAuth, requireRole('admin'));

adminRouter.get('/overview', asyncHandler(async (_req, res) => res.json({ data: await service.overview() })));
