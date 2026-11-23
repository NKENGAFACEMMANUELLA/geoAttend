import { prisma } from '../../lib/prisma';
import { audit } from '../../utils/audit';
import { HttpError } from '../../utils/httpError';
import type { Role } from '../../utils/jwt';
import { notify } from '../../utils/notify';
import { localMinutes, localYmd, ymd } from '../../utils/time';
import { DEFAULT_SCHEDULE, statusForClockIn } from '../attendance/attendance.rules';

type Status = 'pending' | 'approved' | 'rejected';

const include = {
  attendance: true,
  employee: { include: { user: true, department: true, schedule: true } },
} as const;

interface CorrectionRow {
  id: string;
  attendanceId: string;
  requestedClockIn: Date;
  requestedClockOut: Date;
  reason: string;
  status: Status;
  attendance: { date: Date; clockInTime: Date | null };
  employee: {
    userId: string;
    employeeCode: string;
    user: { name: string };
    department: { hodUserId: string | null } | null;
    schedule: { startTime: string; gracePeriodMinutes: number } | null;
  };
}

/** JSON the Flutter `CorrectionRequest.fromJson` expects. */
const toDto = (c: CorrectionRow) => ({
  id: c.id,
  date: ymd(c.attendance.date),
  existingClockIn: c.attendance.clockInTime ? c.attendance.clockInTime.toISOString() : null,
  requestedClockIn: c.requestedClockIn.toISOString(),
  requestedClockOut: c.requestedClockOut.toISOString(),
  reason: c.reason,
  status: c.status,
  employeeName: c.employee.user.name,
  employeeId: c.employee.employeeCode,
});

export async function submit(
  userId: string,
  input: { date: string; requestedClockIn: string; requestedClockOut: string; reason: string },
) {
  const emp = await prisma.employee.findUnique({ where: { userId }, include: { user: true, department: true } });
  if (!emp) throw new HttpError(403, 'Only employees can request corrections.');

  const reqIn = new Date(input.requestedClockIn);
  const reqOut = new Date(input.requestedClockOut);
  if (localYmd(reqIn) !== input.date || localYmd(reqOut) !== input.date) {
    throw new HttpError(422, 'The requested times must be on the selected day.');
  }
  if (reqOut <= reqIn) throw new HttpError(422, 'Clock-out must be after clock-in.');

  const attendance = await prisma.attendance.findUnique({
    where: { employeeId_date: { employeeId: emp.id, date: new Date(`${input.date}T00:00:00Z`) } },
  });
  if (!attendance) throw new HttpError(404, 'There is no attendance record for that day.');

  const pending = await prisma.attendanceCorrection.count({ where: { attendanceId: attendance.id, status: 'pending' } });
  if (pending > 0) throw new HttpError(409, 'You already have a pending correction for that day.');

  const created = await prisma.attendanceCorrection.create({
    data: {
      attendanceId: attendance.id, employeeId: emp.id,
      requestedClockIn: reqIn, requestedClockOut: reqOut, reason: input.reason,
    },
    include,
  });
  const hod = emp.department?.hodUserId;
  if (hod && hod !== userId) {
    await notify(hod, 'correction_request', 'New Correction Request', `${emp.user.name} requested a correction`);
  }
  await audit(userId, 'REQUEST_CORRECTION', 'attendance_corrections', created.id);
  return toDto(created);
}

export async function mine(userId: string) {
  const rows = await prisma.attendanceCorrection.findMany({
    where: { employee: { userId } }, include, orderBy: { createdAt: 'desc' },
  });
  return (rows as CorrectionRow[]).map(toDto);
}

/** HOD: their department's requests (pending, plus decided in the last 30 days). Admin: all pending. */
export async function forApproval(userId: string, role: Role) {
  const since = new Date(Date.now() - 30 * 86_400_000);
  const scope = role === 'hod' ? { employee: { department: { hodUserId: userId }, NOT: { userId } } } : {};
  const rows = await prisma.attendanceCorrection.findMany({
    where: { ...scope, OR: [{ status: 'pending' }, { decidedAt: { gte: since } }] },
    include, orderBy: { createdAt: 'desc' },
  });
  return (rows as CorrectionRow[]).map(toDto);
}

export async function decide(id: string, userId: string, role: Role, approved: boolean) {
  const c = (await prisma.attendanceCorrection.findUnique({ where: { id }, include })) as CorrectionRow | null;
  if (!c) throw new HttpError(404, 'Correction request not found.');
  if (role === 'hod' && (c.employee.department?.hodUserId !== userId || c.employee.userId === userId)) {
    throw new HttpError(403, 'You can only review requests from your own department.');
  }
  if (c.status !== 'pending') throw new HttpError(409, 'This request has already been decided.');

  const decision = { status: approved ? ('approved' as const) : ('rejected' as const), reviewerId: userId, decidedAt: new Date() };
  if (approved) {
    const status = statusForClockIn(localMinutes(c.requestedClockIn), c.employee.schedule ?? DEFAULT_SCHEDULE);
    await prisma.$transaction([
      prisma.attendance.update({
        where: { id: c.attendanceId },
        data: { clockInTime: c.requestedClockIn, clockOutTime: c.requestedClockOut, status, syncStatus: 'synced' },
      }),
      prisma.attendanceCorrection.update({ where: { id }, data: decision }),
    ]);
  } else {
    await prisma.attendanceCorrection.update({ where: { id }, data: decision });
  }
  await notify(
    c.employee.userId,
    approved ? 'correction_approved' : 'correction_rejected',
    approved ? 'Correction Request Approved' : 'Correction Request Rejected',
    approved ? 'Your attendance has been corrected' : 'Your correction has been rejected',
  );
  await audit(userId, approved ? 'APPROVE_CORRECTION' : 'REJECT_CORRECTION', 'attendance_corrections', id);
  return { message: approved ? 'Correction approved.' : 'Correction rejected.' };
}
