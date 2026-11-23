import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireRole } from '../../middleware/auth';
import { asyncHandler } from '../../utils/asyncHandler';
import { REPORT_TYPES } from './engine';
import * as service from './team.service';

const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use the format YYYY-MM-DD');
const teamQuery = z.object({ date: day.optional(), department: z.string().trim().min(1).optional() });
const reportQuery = teamQuery.extend({ type: z.enum(REPORT_TYPES, { errorMap: () => ({ message: 'Choose a report type' }) }) });

export const teamRouter = Router();
teamRouter.use(requireAuth, requireRole('hod', 'admin'));
teamRouter.get('/attendance', asyncHandler(async (req, res) => {
  const q = teamQuery.parse(req.query);
  res.json({ data: await service.teamAttendance(req.auth!.role, req.auth!.userId, q) });
}));

export const reportsRouter = Router();
reportsRouter.use(requireAuth, requireRole('hod', 'admin'));
reportsRouter.get('/', asyncHandler(async (req, res) => {
  const q = reportQuery.parse(req.query);
  res.json({ data: await service.report(req.auth!.role, req.auth!.userId, q) });
}));
