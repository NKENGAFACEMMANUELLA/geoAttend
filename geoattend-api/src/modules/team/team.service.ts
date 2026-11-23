import { env } from '../../config/env';
import { prisma } from '../../lib/prisma';
import { HttpError } from '../../utils/httpError';
import type { Role } from '../../utils/jwt';
import { localHour, localYmd, ymd } from '../../utils/time';
import {
  buildReport, countOf, dayRows, Lookup, reportRange,
  type DayCtx, type EmpRef, type ReportType,
} from './engine';

interface EmployeeRow {
  id: string;
  employeeCode: string;
  position: string | null;
  hireDate: Date;
  user: { name: string };
  department: { name: string } | null;
}

const asDate = (d: string) => new Date(`${d}T00:00:00Z`);

function context(now = new Date()): DayCtx {
  return { today: localYmd(now), cutoffPassed: localHour(now) >= env.ABSENT_AFTER_HOUR };
}

/** HODs only ever see their own department(s); admins can narrow by department name. */
async function scope(role: Role, userId: string, department?: string) {
  const where: Record<string, unknown> = { status: 'active', user: { isActive: true } };
  if (role === 'hod') where.department = { hodUserId: userId };
  else if (department) where.department = { name: department };

  const rows = (await prisma.employee.findMany({
    where, include: { user: true, department: true }, orderBy: { user: { name: 'asc' } },
  })) as EmployeeRow[];

  const emps: EmpRef[] = rows.map((e) => ({
    id: e.id, name: e.user.name, code: e.employeeCode, position: e.position ?? '',
    department: e.department?.name ?? '', hireDate: ymd(e.hireDate),
  }));
  const names = [...new Set(emps.map((e) => e.department).filter(Boolean))];
  const label = role === 'hod' ? (names.join(', ') || 'My department') : (department ?? 'All departments');
  return { emps, label };
}

async function lookupFor(emps: EmpRef[], from: string, to: string) {
  const ids = emps.map((e) => e.id);
  const [att, leaves] = await Promise.all([
    prisma.attendance.findMany({
      where: { employeeId: { in: ids }, date: { gte: asDate(from), lte: asDate(to) } },
    }),
    prisma.leaveRequest.findMany({
      where: { employeeId: { in: ids }, status: 'approved', startDate: { lte: asDate(to) }, endDate: { gte: asDate(from) } },
    }),
  ]);
  return new Lookup(
    (att as { employeeId: string; date: Date; status: 'present' | 'late' | 'absent' | 'leave'; clockInTime: Date | null }[]).map(
      (a) => ({ employeeId: a.employeeId, date: ymd(a.date), status: a.status, clockIn: a.clockInTime }),
    ),
    (leaves as { employeeId: string; startDate: Date; endDate: Date }[]).map(
      (l) => ({ employeeId: l.employeeId, start: ymd(l.startDate), end: ymd(l.endDate) }),
    ),
  );
}

const clamp = (day: string | undefined, today: string) => (!day || day > today ? today : day);

export async function teamAttendance(role: Role, userId: string, q: { date?: string; department?: string }) {
  const ctx = context();
  const day = clamp(q.date, ctx.today);
  const { emps } = await scope(role, userId, q.department);
  const lookup = await lookupFor(emps, day, day);
  const rows = dayRows(emps, lookup, day, ctx);
  const c = countOf(rows.map((r) => r.status));
  return {
    date: day,
    summary: { present: c.present, late: c.late, absent: c.absent, onLeave: c.onLeave, total: c.total, rate: c.rate },
    rows: rows.map((r) => ({
      name: r.emp.name, employeeId: r.emp.code, position: r.emp.position, department: r.emp.department,
      status: r.status, time: r.clockIn ? r.clockIn.toISOString() : null,
    })),
  };
}

export async function report(role: Role, userId: string, q: { type: ReportType; date?: string; department?: string }) {
  const ctx = context();
  const day = clamp(q.date, ctx.today);
  const { emps, label } = await scope(role, userId, q.department);
  const { from, to } = reportRange(q.type, day, ctx.today);
  const lookup = await lookupFor(emps, from, to);
  const built = buildReport({ type: q.type, day, scope: label, emps, lookup, ctx, generatedAt: new Date() });
  if (!built) throw new HttpError(422, 'There are no working days in this period.');
  return built;
}
