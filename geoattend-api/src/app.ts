import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { env } from './config/env';
import { prisma } from './lib/prisma';
import { errorHandler, notFound } from './middleware/errorHandler';
import { adminRouter } from './modules/admin/admin.routes';
import { attendanceRouter } from './modules/attendance/attendance.routes';
import { authRouter } from './modules/auth/auth.routes';
import { correctionsRouter } from './modules/corrections/corrections.routes';
import { leaveRouter } from './modules/leave/leave.routes';
import { notificationsRouter } from './modules/notifications/notifications.routes';
import { reportsRouter, teamRouter } from './modules/team/team.routes';
import { departmentsRouter } from './modules/departments/departments.routes';
import { employeesRouter } from './modules/employees/employees.routes';
import { workplacesRouter } from './modules/workplaces/workplaces.routes';
import { asyncHandler } from './utils/asyncHandler';

export const app = express();

app.set('trust proxy', 1); // Render and most hosts sit behind a proxy
app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',') }));
app.use(express.json({ limit: '100kb' }));

// Open these before a demo: they wake the (sleeping) free server and database.
app.get('/health', (_req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));
app.get(
  '/health/db',
  asyncHandler(async (_req, res) => {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'ok', database: 'up', time: new Date().toISOString() });
  }),
);

app.use('/api/v1/auth', authRouter);
app.use('/api/v1/workplaces', workplacesRouter);
app.use('/api/v1/departments', departmentsRouter);
app.use('/api/v1/employees', employeesRouter);
app.use('/api/v1/admin', adminRouter);
app.use('/api/v1/attendance', attendanceRouter);
app.use('/api/v1/leave', leaveRouter);
app.use('/api/v1/corrections', correctionsRouter);
app.use('/api/v1/notifications', notificationsRouter);
app.use('/api/v1/team', teamRouter);
app.use('/api/v1/reports', reportsRouter);

app.use(notFound);
app.use(errorHandler);
