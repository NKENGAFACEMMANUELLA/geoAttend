import { env } from '../../config/env';
import { prisma } from '../../lib/prisma';
import { isWeekdayLocal, localHour, localToday } from '../../utils/time';

interface RecentRow {
  status: string;
  clockInTime: Date | null;
  employee: {
    employeeCode: string;
    position: string | null;
    user: { name: string };
    department: { name: string } | null;
  };
}

/**
 * Numbers for the admin dashboard (today, company time zone).
 * Until the end-of-day "mark absent" job exists (Phase 5), people with no
 * record are counted absent after ABSENT_AFTER_HOUR on weekdays.
 */
export async function overview() {
  const today = localToday();
  const activeEmployees = { status: 'active' as const, user: { isActive: true } };

  const [total, byStatus, approvedLeave, recent] = await Promise.all([
    prisma.employee.count({ where: activeEmployees }),
    prisma.attendance.groupBy({ by: ['status'], where: { date: today }, _count: { _all: true } }),
    prisma.leaveRequest.count({
      where: { status: 'approved', startDate: { lte: today }, endDate: { gte: today }, employee: activeEmployees },
    }),
    prisma.attendance.findMany({
      where: { date: today },
      orderBy: { createdAt: 'desc' },
      take: 3,
      include: { employee: { include: { user: true, department: true } } },
    }),
  ]);

  const count = (s: string) => byStatus.find((r: { status: string }) => r.status === s)?._count._all ?? 0;
  const present = count('present');
  const late = count('late');
  const onLeave = Math.max(count('leave'), approvedLeave);
  const noShowCounted = isWeekdayLocal() && localHour() >= env.ABSENT_AFTER_HOUR;
  const absent = noShowCounted ? Math.max(0, total - present - late - onLeave) : count('absent');

  return {
    employees: total,
    present,
    late,
    absent,
    onLeave,
    recent: (recent as RecentRow[]).map((a) => ({
      name: a.employee.user.name,
      employeeId: a.employee.employeeCode,
      position: a.employee.position ?? '',
      department: a.employee.department?.name ?? '',
      status: a.status,
      time: a.clockInTime ? a.clockInTime.toISOString() : null,
    })),
  };
}
