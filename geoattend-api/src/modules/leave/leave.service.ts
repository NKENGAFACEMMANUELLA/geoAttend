import { prisma } from '../../lib/prisma';
import { audit } from '../../utils/audit';
import { HttpError } from '../../utils/httpError';
import type { Role } from '../../utils/jwt';
import { adminIds, notify } from '../../utils/notify';
import { localToday, ymd } from '../../utils/time';

type LeaveStatus = 'pending_hod' | 'pending_hr' | 'approved' | 'rejected';
type Shown = 'pending' | 'approved' | 'rejected';

const include = {
  employee: { include: { user: true, department: { include: { hod: true } } } },
} as const;

interface LeaveRow {
  id: string;
  leaveType: string;
  startDate: Date;
  endDate: Date;
  reason: string;
  status: LeaveStatus;
  hodReviewerId: string | null;
  hrReviewerId: string | null;
  createdAt: Date;
  employee: {
    userId: string;
    employeeCode: string;
    user: { name: string };
    department: { name: string; hodUserId: string | null; hod: { name: string } | null } | null;
  };
}

const overall = (s: LeaveStatus): Shown => (s === 'approved' || s === 'rejected' ? s : 'pending');

/** JSON the Flutter `LeaveRequest.fromJson` expects. [shown] is the status from the viewer's point of view. */
function toDto(l: LeaveRow, shown?: Shown) {
  const hodName = l.employee.department?.hod?.name ?? 'HOD';
  const approver =
    l.status === 'pending_hod' ? hodName : l.status === 'rejected' && !l.hrReviewerId ? hodName : 'HR / Admin';
  return {
    id: l.id,
    employeeName: l.employee.user.name,
    employeeId: l.employee.employeeCode,
    department: l.employee.department?.name ?? '',
    type: l.leaveType,
    start: ymd(l.startDate),
    end: ymd(l.endDate),
    submittedAt: l.createdAt.toISOString(),
    reason: l.reason,
    status: shown ?? overall(l.status),
    stage: l.status === 'pending_hod' ? 'hod' : l.status === 'pending_hr' ? 'hr' : 'done',
    approver,
  };
}

const asDate = (d: string) => new Date(`${d}T00:00:00Z`);

export async function submit(userId: string, input: { type: string; start: string; end: string; reason: string }) {
  const emp = await prisma.employee.findUnique({ where: { userId }, include: { user: true, department: true } });
  if (!emp) throw new HttpError(403, 'Only employees can request leave.');

  const start = asDate(input.start);
  const end = asDate(input.end);
  if (start < localToday()) throw new HttpError(422, 'The start date cannot be in the past.');
  if (end < start) throw new HttpError(422, 'The end date must be on or after the start date.');

  const overlap = await prisma.leaveRequest.count({
    where: {
      employeeId: emp.id,
      status: { in: ['pending_hod', 'pending_hr', 'approved'] },
      startDate: { lte: end },
      endDate: { gte: start },
    },
  });
  if (overlap > 0) throw new HttpError(409, 'You already have a leave request for these dates.');

  // Two-stage approval: HOD first. No HOD (or the HOD is asking) -> straight to HR.
  const hodId = emp.department?.hodUserId ?? null;
  const toHod = !!hodId && hodId !== userId;
  const created = await prisma.leaveRequest.create({
    data: {
      employeeId: emp.id, leaveType: input.type, startDate: start, endDate: end,
      reason: input.reason, status: toHod ? 'pending_hod' : 'pending_hr',
    },
    include,
  });
  if (toHod) await notify(hodId!, 'leave_request', 'New Leave Request', `${emp.user.name} applied for ${input.type}`);
  else await notify(await adminIds(), 'leave_request', 'New Leave Request', `${emp.user.name} applied for ${input.type}`);
  await audit(userId, 'REQUEST_LEAVE', 'leave_requests', created.id);
  return toDto(created);
}

export async function mine(userId: string) {
  const rows = await prisma.leaveRequest.findMany({
    where: { employee: { userId } }, include, orderBy: { createdAt: 'desc' },
  });
  return (rows as LeaveRow[]).map((r) => toDto(r));
}

/** HOD: requests from their department. Admin (HR): requests the HOD already approved. */
export async function forApproval(userId: string, role: Role) {
  const since = new Date(Date.now() - 30 * 86_400_000);
  if (role === 'hod') {
    const rows = await prisma.leaveRequest.findMany({
      where: {
        employee: { department: { hodUserId: userId }, NOT: { userId } },
        OR: [{ status: 'pending_hod' }, { hodReviewerId: userId, hodDecidedAt: { gte: since } }],
      },
      include, orderBy: { createdAt: 'desc' },
    });
    return (rows as LeaveRow[]).map((r) =>
      toDto(r, r.status === 'pending_hod' ? 'pending' : r.status === 'rejected' && !r.hrReviewerId ? 'rejected' : 'approved'),
    );
  }
  const rows = await prisma.leaveRequest.findMany({
    where: { OR: [{ status: 'pending_hr' }, { hrReviewerId: userId, hrDecidedAt: { gte: since } }] },
    include, orderBy: { createdAt: 'desc' },
  });
  return (rows as LeaveRow[]).map((r) => toDto(r));
}

export async function decide(id: string, userId: string, role: Role, approved: boolean) {
  const l = (await prisma.leaveRequest.findUnique({ where: { id }, include })) as LeaveRow | null;
  if (!l) throw new HttpError(404, 'Leave request not found.');
  const who = l.employee.user.name;
  const now = new Date();

  if (role === 'hod') {
    if (l.employee.department?.hodUserId !== userId || l.employee.userId === userId) {
      throw new HttpError(403, 'You can only review requests from your own department.');
    }
    if (l.status !== 'pending_hod') throw new HttpError(409, 'This request is no longer waiting for your review.');
    await prisma.leaveRequest.update({
      where: { id },
      data: { status: approved ? 'pending_hr' : 'rejected', hodReviewerId: userId, hodDecidedAt: now },
    });
    if (approved) await notify(await adminIds(), 'leave_request', 'Leave Awaiting HR', `${who}: ${l.leaveType} approved by HOD`);
    else await notify(l.employee.userId, 'leave_rejected', 'Leave Request Rejected', `Your ${l.leaveType} request was rejected`);
  } else {
    if (l.status !== 'pending_hr') throw new HttpError(409, 'This request is not waiting for HR approval.');
    await prisma.leaveRequest.update({
      where: { id },
      data: { status: approved ? 'approved' : 'rejected', hrReviewerId: userId, hrDecidedAt: now },
    });
    await notify(
      l.employee.userId,
      approved ? 'leave_approved' : 'leave_rejected',
      approved ? 'Leave Request Approved' : 'Leave Request Rejected',
      approved ? 'Your leave request has been approved' : `Your ${l.leaveType} request was rejected`,
    );
  }
  await audit(userId, approved ? 'APPROVE_LEAVE' : 'REJECT_LEAVE', 'leave_requests', id);
  return { message: approved ? 'Request approved.' : 'Request rejected.' };
}

export async function cancel(id: string, userId: string) {
  const l = await prisma.leaveRequest.findUnique({ where: { id }, include: { employee: true } });
  if (!l || l.employee.userId !== userId) throw new HttpError(404, 'Leave request not found.');
  if (l.status !== 'pending_hod' && l.status !== 'pending_hr') {
    throw new HttpError(409, 'Only requests that are still pending can be cancelled.');
  }
  await prisma.leaveRequest.delete({ where: { id } });
  await audit(userId, 'CANCEL_LEAVE', 'leave_requests', id);
  return { message: 'Request cancelled.' };
}
