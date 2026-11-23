import { Router } from 'express';
import { prisma } from '../../lib/prisma';
import { requireAuth } from '../../middleware/auth';
import { asyncHandler } from '../../utils/asyncHandler';

export const notificationsRouter = Router();
notificationsRouter.use(requireAuth);

interface Row { id: string; type: string; title: string; message: string; isRead: boolean; createdAt: Date }
const toDto = (n: Row) => ({
  id: n.id, type: n.type, title: n.title, message: n.message, read: n.isRead, createdAt: n.createdAt.toISOString(),
});

notificationsRouter.get('/', asyncHandler(async (req, res) => {
  const rows = await prisma.notification.findMany({
    where: { userId: req.auth!.userId }, orderBy: { createdAt: 'desc' }, take: 50,
  });
  res.json({ data: (rows as Row[]).map(toDto) });
}));

// Registered before "/:id/read" so "read-all" is not read as an id.
notificationsRouter.post('/read-all', asyncHandler(async (req, res) => {
  await prisma.notification.updateMany({ where: { userId: req.auth!.userId, isRead: false }, data: { isRead: true } });
  res.json({ data: { message: 'All notifications marked as read.' } });
}));

notificationsRouter.post('/:id/read', asyncHandler(async (req, res) => {
  await prisma.notification.updateMany({ where: { id: req.params.id, userId: req.auth!.userId }, data: { isRead: true } });
  res.json({ data: { message: 'Marked as read.' } });
}));
