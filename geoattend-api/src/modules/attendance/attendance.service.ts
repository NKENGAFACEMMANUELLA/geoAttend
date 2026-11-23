import { env } from '../../config/env';
import { prisma } from '../../lib/prisma';
import { audit } from '../../utils/audit';
import { haversineMeters } from '../../utils/geo';
import { HttpError } from '../../utils/httpError';
import { notify } from '../../utils/notify';
import { localMinutes, localToday, localYmd, ymd } from '../../utils/time';
import { DEFAULT_SCHEDULE, statusForClockIn } from './attendance.rules';

type Status = 'present' | 'late' | 'absent' | 'leave';

interface GeoInput {
  latitude: number;
  longitude: number;
  accuracy?: number;
  mocked?: boolean;
}

const ctxInclude = { workplace: true, schedule: true, department: true, user: true } as const;

async function employeeFor(userId: string) {
  const emp = await prisma.employee.findUnique({ where: { userId }, include: ctxInclude });
  if (!emp || emp.status !== 'active') throw new HttpError(403, 'Only active employees can use attendance.');
  return emp;
}
type EmployeeCtx = Awaited<ReturnType<typeof employeeFor>>;

/** The server's own geofence check. The phone only reports coordinates. */
function evaluate(emp: EmployeeCtx, input: GeoInput) {
  const wp = emp.workplace;
  if (!wp) throw new HttpError(422, 'No workplace is assigned to you yet. Please contact your administrator.');
  if (!wp.isActive) throw new HttpError(422, `${wp.name} is currently inactive. Please contact your administrator.`);
  if (input.mocked) {
    throw new HttpError(422, 'Fake location detected. Turn off mock-location apps and try again.', 'MOCK_LOCATION');
  }
  if (input.accuracy !== undefined && input.accuracy > env.MAX_GPS_ACCURACY_METERS) {
    throw new HttpError(
      422,
      `GPS signal is too weak (accuracy ${Math.round(input.accuracy)} m). Move to an open area and retry.`,
    );
  }
  const distance = haversineMeters(input.latitude, input.longitude, wp.latitude, wp.longitude);
  return { wp, distance, radius: wp.geofenceRadiusMeters };
}

async function evaluateAudited(emp: EmployeeCtx, input: GeoInput) {
  try {
    return evaluate(emp, input);
  } catch (e) {
    if (e instanceof HttpError && e.code === 'MOCK_LOCATION') {
      await audit(emp.userId, 'MOCK_LOCATION_BLOCKED', 'attendance');
    }
    throw e;
  }
}

interface AttendanceRow {
  date: Date;
  status: Status;
  clockInTime: Date | null;
  clockOutTime: Date | null;
  locationVerified: boolean;
  source: 'online' | 'offline';
}

/** JSON the Flutter `AttendanceRecord.fromJson` expects. */
const toDto = (a: AttendanceRow, workplace: string) => ({
  date: ymd(a.date),
  status: a.status,
  clockIn: a.clockInTime ? a.clockInTime.toISOString() : null,
  clockOut: a.clockOutTime ? a.clockOutTime.toISOString() : null,
  workplace,
  locationVerified: a.locationVerified,
  source: a.source === 'offline' ? 'Offline' : 'Online',
});

const workplaceName = (emp: EmployeeCtx) => emp.workplace?.name ?? '';

export async function verifyLocation(userId: string, input: GeoInput) {
  const emp = await employeeFor(userId);
  const { wp, distance, radius } = await evaluateAudited(emp, input);
  return {
    workplaceName: wp.name,
    distanceMeters: Math.round(distance * 10) / 10,
    radiusMeters: radius,
    inRange: distance <= radius,
  };
}

async function onApprovedLeave(employeeId: string, date: Date) {
  const n = await prisma.leaveRequest.count({
    where: { employeeId, status: 'approved', startDate: { lte: date }, endDate: { gte: date } },
  });
  return n > 0;
}

export async function clockIn(userId: string, input: GeoInput, now = new Date()) {
  const emp = await employeeFor(userId);
  const { wp, distance, radius } = await evaluateAudited(emp, input);
  if (distance > radius) throw new HttpError(422, `You are outside the allowed area for ${wp.name}.`);

  const date = localToday(now);
  if (await onApprovedLeave(emp.id, date)) throw new HttpError(409, 'You are on approved leave today.');
  const existing = await prisma.attendance.findUnique({ where: { employeeId_date: { employeeId: emp.id, date } } });
  if (existing?.clockInTime) throw new HttpError(409, 'You have already clocked in today.');

  const status = statusForClockIn(localMinutes(now), emp.schedule ?? DEFAULT_SCHEDULE);
  const data = {
    clockInTime: now,
    status,
    syncStatus: 'synced' as const,
    source: 'online' as const,
    latitude: input.latitude,
    longitude: input.longitude,
    distanceMeters: distance,
    locationVerified: true,
  };
  const record = existing
    ? await prisma.attendance.update({ where: { id: existing.id }, data })
    : await prisma.attendance.create({ data: { employeeId: emp.id, date, ...data } });

  await afterClockIn(emp, record.clockInTime ?? now, status);
  return toDto(record, workplaceName(emp));
}

/** Notifies the employee, and the department head when the employee is late. */
async function afterClockIn(emp: EmployeeCtx, at: Date, status: Status) {
  const time = at.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', timeZone: env.TIMEZONE });
  await notify(emp.userId, 'clock_in', 'Clock-In Successful', `Your clock-in was recorded at ${time}`);
  const hod = emp.department?.hodUserId;
  if (status === 'late' && hod && hod !== emp.userId) {
    await notify(hod, 'attendance_alert', 'Attendance Alert', `${emp.user.name} is late`);
  }
}

export async function clockOut(userId: string, input: GeoInput, now = new Date()) {
  const emp = await employeeFor(userId);
  const { wp, distance, radius } = await evaluateAudited(emp, input);
  if (distance > radius) throw new HttpError(422, `You are outside the allowed area for ${wp.name}.`);

  const date = localToday(now);
  const rec = await prisma.attendance.findUnique({ where: { employeeId_date: { employeeId: emp.id, date } } });
  if (!rec?.clockInTime) throw new HttpError(409, 'Clock in first before clocking out.');
  if (rec.clockOutTime) throw new HttpError(409, 'You have already clocked out today.');

  const updated = await prisma.attendance.update({ where: { id: rec.id }, data: { clockOutTime: now } });
  return toDto(updated, workplaceName(emp));
}

/** Today's record plus the last 90 days (approved leave days are included as "leave"). */
export async function mine(userId: string) {
  const emp = await employeeFor(userId);
  const today = localToday();
  const from = new Date(today.getTime() - 90 * 86_400_000);

  const [rows, leaves] = await Promise.all([
    prisma.attendance.findMany({
      where: { employeeId: emp.id, date: { gte: from, lte: today } },
      orderBy: { date: 'desc' },
    }),
    prisma.leaveRequest.findMany({
      where: { employeeId: emp.id, status: 'approved', startDate: { lte: today }, endDate: { gte: from } },
    }),
  ]);

  const history = (rows as AttendanceRow[]).map((r) => toDto(r, workplaceName(emp)));
  const have = new Set(history.map((h) => h.date));
  for (const l of leaves as { startDate: Date; endDate: Date }[]) {
    for (let t = Math.max(l.startDate.getTime(), from.getTime()); t <= Math.min(l.endDate.getTime(), today.getTime()); t += 86_400_000) {
      const day = new Date(t);
      const dow = day.getUTCDay();
      if (dow === 0 || dow === 6 || have.has(ymd(day))) continue;
      have.add(ymd(day));
      history.push({
        date: ymd(day), status: 'leave', clockIn: null, clockOut: null,
        workplace: workplaceName(emp), locationVerified: false, source: 'Online',
      });
    }
  }
  history.sort((a, b) => (a.date < b.date ? 1 : -1));
  return { today: history.find((h) => h.date === ymd(today) && h.status !== 'leave') ?? null, history };
}

interface SyncItem extends GeoInput {
  clientId: string;
  type: 'in' | 'out';
  capturedAt: string;
}

/**
 * Offline clock-ins/outs captured on the phone. Each one is checked with the same
 * rules as an online one, using the time the employee actually did it.
 * Safe to retry: a record already stored is reported as synced.
 */
export async function sync(userId: string, items: SyncItem[], now = new Date()) {
  const emp = await employeeFor(userId);
  const results: { clientId: string; status: 'synced' | 'rejected'; message?: string }[] = [];
  const ordered = [...items].sort((a, b) => a.capturedAt.localeCompare(b.capturedAt));

  for (const item of ordered) {
    const reject = (message: string) => results.push({ clientId: item.clientId, status: 'rejected', message });
    try {
      const at = new Date(item.capturedAt);
      if (at.getTime() > now.getTime() + 5 * 60_000) { reject('The recorded time is in the future.'); continue; }
      if (now.getTime() - at.getTime() > env.OFFLINE_MAX_DAYS * 86_400_000) {
        reject(`Too old to sync (more than ${env.OFFLINE_MAX_DAYS} days).`); continue;
      }
      const { wp, distance, radius } = await evaluateAudited(emp, item);
      if (distance > radius) { reject(`Outside the allowed area for ${wp.name}.`); continue; }

      const date = localToday(at);
      const existing = await prisma.attendance.findUnique({ where: { employeeId_date: { employeeId: emp.id, date } } });

      if (item.type === 'in') {
        if (existing?.clockInTime) {
          results.push({ clientId: item.clientId, status: 'synced' }); // already stored (retry)
          continue;
        }
        if (await onApprovedLeave(emp.id, date)) { reject('You were on approved leave that day.'); continue; }
        const status = statusForClockIn(localMinutes(at), emp.schedule ?? DEFAULT_SCHEDULE);
        const data = {
          clockInTime: at, status, syncStatus: 'synced' as const, source: 'offline' as const,
          latitude: item.latitude, longitude: item.longitude, distanceMeters: distance, locationVerified: true,
        };
        if (existing) await prisma.attendance.update({ where: { id: existing.id }, data });
        else await prisma.attendance.create({ data: { employeeId: emp.id, date, ...data } });
        if (localYmd(now) === localYmd(at)) await afterClockIn(emp, at, status);
      } else {
        if (!existing?.clockInTime) { reject('No clock-in found for that day.'); continue; }
        if (existing.clockOutTime) { results.push({ clientId: item.clientId, status: 'synced' }); continue; }
        if (at <= existing.clockInTime) { reject('Clock-out is before clock-in.'); continue; }
        await prisma.attendance.update({ where: { id: existing.id }, data: { clockOutTime: at } });
      }
      results.push({ clientId: item.clientId, status: 'synced' });
    } catch (e) {
      reject(e instanceof HttpError ? e.message : 'Could not process this record.');
    }
  }
  await audit(userId, 'OFFLINE_SYNC', 'attendance');
  return { results };
}
