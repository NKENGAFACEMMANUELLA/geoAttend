import { prisma } from '../lib/prisma';

export type NotificationKind =
  | 'clock_in' | 'leave_request' | 'leave_approved' | 'leave_rejected'
  | 'correction_request' | 'correction_approved' | 'correction_rejected'
  | 'reminder' | 'attendance_alert';

/** Creates in-app notifications. Never fails the request that triggered it. */
export async function notify(to: string | string[], type: NotificationKind, title: string, message: string) {
  const ids = [...new Set(Array.isArray(to) ? to : [to])];
  if (ids.length === 0) return;
  try {
    await prisma.notification.createMany({ data: ids.map((userId) => ({ userId, type, title, message })) });
  } catch (e) {
    console.error('notification failed', e);
  }
}

export async function adminIds(): Promise<string[]> {
  const admins = await prisma.user.findMany({ where: { role: 'admin', isActive: true }, select: { id: true } });
  return admins.map((a: { id: string }) => a.id);
}
