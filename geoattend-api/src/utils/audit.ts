import { prisma } from '../lib/prisma';

/** Records who did what. Never blocks or fails the request. */
export async function audit(userId: string | null, action: string, targetTable: string, targetId?: string) {
  try {
    await prisma.auditLog.create({ data: { userId, action, targetTable, targetId } });
  } catch (e) {
    console.error('audit log failed', e);
  }
}
