/* Demo data that mirrors the Flutter mock repositories.
   Run:  npx prisma db seed   (safe to run more than once) */
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { localToday, zonedTime } from '../src/utils/time';

const prisma = new PrismaClient();

const DEMO_PASSWORDS = { admin: 'Admin@123', hod: 'Hod@1234', employee: 'Employee@123' };

async function main() {
  const schedule = await prisma.schedule.upsert({
    where: { name: 'Standard Day' },
    update: {},
    create: { name: 'Standard Day', startTime: '08:00', endTime: '17:00', gracePeriodMinutes: 15 },
  });

  const workplaces = [
    { name: 'Main Office', address: 'Buea, Cameroon', latitude: 4.1527, longitude: 9.241, geofenceRadiusMeters: 100, isActive: true },
    { name: 'Branch Office', address: 'Limbe, Cameroon', latitude: 4.0186, longitude: 9.204, geofenceRadiusMeters: 150, isActive: true },
    { name: 'Remote Office', address: 'Yaounde, Cameroon', latitude: 3.848, longitude: 11.5021, geofenceRadiusMeters: 100, isActive: false },
  ];
  const wp: Record<string, string> = {};
  for (const w of workplaces) {
    const row = await prisma.workplace.upsert({ where: { name: w.name }, update: {}, create: w });
    wp[w.name] = row.id;
  }

  const departments = ['IT', 'Marketing', 'Finance', 'Application', 'Customer Service', 'Sales'];
  const dept: Record<string, string> = {};
  for (const name of departments) {
    const row = await prisma.department.upsert({ where: { name }, update: {}, create: { name } });
    dept[name] = row.id;
  }

  const hash = {
    admin: await bcrypt.hash(DEMO_PASSWORDS.admin, 10),
    hod: await bcrypt.hash(DEMO_PASSWORDS.hod, 10),
    employee: await bcrypt.hash(DEMO_PASSWORDS.employee, 10),
  };

  // Admin (no employee record)
  await prisma.user.upsert({
    where: { email: 'admin@geoattend.app' },
    update: {},
    create: { name: 'Admin', email: 'admin@geoattend.app', phone: '+237 677 000 001', passwordHash: hash.admin, role: 'admin' },
  });

  // HOD of Sales
  const hod = await prisma.user.upsert({
    where: { email: 'james.wilson@geoattend.app' },
    update: {},
    create: {
      name: 'James Wilson', email: 'james.wilson@geoattend.app', phone: '+237 677 000 002',
      passwordHash: hash.hod, role: 'hod',
      employee: {
        create: {
          employeeCode: 'HOD001', position: 'HOD/Officer', departmentId: dept['Sales'],
          workplaceId: wp['Main Office'], scheduleId: schedule.id,
        },
      },
    },
  });
  await prisma.department.update({ where: { id: dept['Sales'] }, data: { hodUserId: hod.id } });

  // Employees (the first one is the demo employee login)
  const people = [
    ['Emmanuella Atefaec', 'emmanuella@geoattend.app', 'EMP0013', 'IT', 'Software Engineer', 'Main Office'],
    ['Sarah Kim', 'sarah.kim@geoattend.app', 'EMP024', 'Sales', 'Senior Analyst', 'Main Office'],
    ['David Lee', 'david.lee@geoattend.app', 'EMP031', 'Sales', 'Junior Analyst', 'Main Office'],
    ['Michael Brown', 'michael.brown@geoattend.app', 'EMP045', 'Sales', 'Analyst', 'Main Office'],
    ['Emily Davis', 'emily.davis@geoattend.app', 'EMP052', 'Sales', 'Sales Executive', 'Main Office'],
    ['Akwi Joy', 'akwi.joy@geoattend.app', 'EMP018', 'Marketing', 'Marketing Officer', 'Main Office'],
    ['Atabong Joel', 'joel.atabong@geoattend.app', 'EMP001', 'Marketing', 'Software Engineer', 'Main Office'],
    ['Alice Besingi', 'alice.besingi@geoattend.app', 'EMP066', 'Finance', 'Accountant', 'Main Office'],
    ['Amboh Queency', 'amboh.queency@geoattend.app', 'EMP071', 'Customer Service', 'Support Agent', 'Branch Office'],
  ] as const;

  let n = 0;
  for (const [name, email, code, department, position, workplace] of people) {
    n += 1;
    await prisma.user.upsert({
      where: { email },
      update: {},
      create: {
        name, email, phone: `+237 677 100 ${String(n).padStart(3, '0')}`,
        passwordHash: hash.employee, role: 'employee',
        employee: {
          create: {
            employeeCode: code, position, departmentId: dept[department],
            workplaceId: wp[workplace], scheduleId: schedule.id,
          },
        },
      },
    });
  }

  await seedActivity(prisma);

  console.log('Seed complete. Demo logins:');
  console.log(`  Admin    admin@geoattend.app            ${DEMO_PASSWORDS.admin}`);
  console.log(`  HOD      james.wilson@geoattend.app     ${DEMO_PASSWORDS.hod}`);
  console.log(`  Employee emmanuella@geoattend.app       ${DEMO_PASSWORDS.employee}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());


/** Attendance history, a few requests and notifications so every screen has something to show. */
async function seedActivity(db: PrismaClient) {
  const today = localToday();
  const day = (offset: number) => new Date(today.getTime() + offset * 86_400_000);
  const emps = await db.employee.findMany({ include: { user: true, department: true } });
  const byEmail = (email: string) => emps.find((e: { user: { email: string } }) => e.user.email === email);

  // 30 days of clock-ins (present or late). Missing weekdays show up as absent automatically.
  const cycle = ['present', 'present', 'present', 'late', 'present', 'absent', 'present', 'present'] as const;
  let index = 0;
  for (const e of emps) {
    index += 1;
    for (let back = 1; back <= 30; back++) {
      const d = day(-back);
      if (d.getUTCDay() === 0 || d.getUTCDay() === 6) continue;
      const kind = cycle[(index + d.getUTCDate()) % cycle.length];
      if (kind === 'absent') continue;
      const late = kind === 'late';
      await db.attendance.upsert({
        where: { employeeId_date: { employeeId: e.id, date: d } },
        update: {},
        create: {
          employeeId: e.id, date: d, status: late ? 'late' : 'present',
          clockInTime: zonedTime(d, late ? 8 : 7, late ? 20 + (index * 4) % 30 : 50 + (index * 3) % 14),
          clockOutTime: zonedTime(d, 17, back % 6),
          latitude: 4.1527, longitude: 9.241, distanceMeters: 12, locationVerified: true,
        },
      });
    }
  }

  const sarah = byEmail('sarah.kim@geoattend.app');
  const david = byEmail('david.lee@geoattend.app');
  const michael = byEmail('michael.brown@geoattend.app');

  const ensureLeave = async (
    e: typeof sarah, type: string, from: number, to: number, status: 'pending_hod' | 'approved', reason: string,
  ) => {
    if (!e) return;
    const exists = await db.leaveRequest.findFirst({ where: { employeeId: e.id, startDate: day(from) } });
    if (!exists) {
      await db.leaveRequest.create({
        data: { employeeId: e.id, leaveType: type, startDate: day(from), endDate: day(to), status, reason },
      });
    }
  };
  await ensureLeave(sarah, 'Annual Leave', 2, 4, 'pending_hod', 'Personal reasons');
  await ensureLeave(david, 'Sick Leave', 1, 1, 'pending_hod', 'Not feeling well');
  await ensureLeave(michael, 'Annual Leave', -9, -8, 'approved', 'Family visit');

  // One pending correction for the HOD to review (Sarah's most recent clock-in)
  if (sarah) {
    const recent = await db.attendance.findFirst({
      where: { employeeId: sarah.id }, orderBy: { date: 'desc' },
    });
    if (recent && (await db.attendanceCorrection.count({ where: { attendanceId: recent.id } })) === 0) {
      await db.attendanceCorrection.create({
        data: {
          attendanceId: recent.id, employeeId: sarah.id,
          requestedClockIn: zonedTime(recent.date, 7, 45), requestedClockOut: zonedTime(recent.date, 17, 0),
          reason: 'System error',
        },
      });
    }
  }

  // Notifications (only the first time)
  const seedNotes = async (
    email: string,
    notes: { type: 'clock_in' | 'leave_request' | 'leave_approved' | 'correction_request' | 'attendance_alert'; title: string; message: string; isRead?: boolean }[],
  ) => {
    const u = await db.user.findUnique({ where: { email } });
    if (!u || (await db.notification.count({ where: { userId: u.id } })) > 0) return;
    await db.notification.createMany({ data: notes.map((n) => ({ userId: u.id, ...n })) });
  };
  await seedNotes('emmanuella@geoattend.app', [
    { type: 'leave_approved', title: 'Leave Request Approved', message: 'Your leave request has been approved' },
    { type: 'clock_in', title: 'Clock-In Successful', message: 'Your clock-in was recorded at 8:02 AM', isRead: true },
  ]);
  await seedNotes('james.wilson@geoattend.app', [
    { type: 'leave_request', title: 'New Leave Request', message: 'Sarah Kim applied for Annual Leave' },
    { type: 'leave_request', title: 'New Leave Request', message: 'David Lee applied for Sick Leave' },
    { type: 'correction_request', title: 'New Correction Request', message: 'Sarah Kim requested a correction' },
  ]);
  await seedNotes('admin@geoattend.app', [
    { type: 'attendance_alert', title: 'Welcome to GeoAttend', message: 'Your workspace is ready. Add employees and set the geofence.' },
  ]);
}
