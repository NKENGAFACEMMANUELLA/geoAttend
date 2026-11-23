import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { asyncHandler } from '../../utils/asyncHandler';
import { locationSchema, syncSchema } from './attendance.schema';
import * as service from './attendance.service';

export const attendanceRouter = Router();
attendanceRouter.use(requireAuth, requireRole('employee'));

attendanceRouter.get('/me', asyncHandler(async (req, res) => res.json({ data: await service.mine(req.auth!.userId) })));
attendanceRouter.post('/verify-location', validate(locationSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.verifyLocation(req.auth!.userId, req.body) })));
attendanceRouter.post('/clock-in', validate(locationSchema),
  asyncHandler(async (req, res) => res.status(201).json({ data: await service.clockIn(req.auth!.userId, req.body) })));
attendanceRouter.post('/clock-out', validate(locationSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.clockOut(req.auth!.userId, req.body) })));
attendanceRouter.post('/sync', validate(syncSchema),
  asyncHandler(async (req, res) => res.json({ data: await service.sync(req.auth!.userId, req.body.records) })));
