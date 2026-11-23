import { prisma } from '../../lib/prisma';
import { audit } from '../../utils/audit';
import { hashPassword, randomToken } from '../../utils/crypto';
import { HttpError } from '../../utils/httpError';

const include = { user: true, department: true, workplace: true } as const;

interface EmployeeRow {
  id: string;
  employeeCode: string;
  position: string | null;
  status: 'active' | 'inactive';
  user: { id: string; name: string; email: string; phone: string | null; isActive: boolean };
  department: { name: string } | null;
  workplace: { name: string } | null;
}

/** JSON the Flutter `Employee.fromJson` expects. */
const toDto = (e: EmployeeRow) => ({
  id: e.id,
  userId: e.user.id,
  name: e.user.name,
  code: e.employeeCode,
  email: e.user.email,
  phone: e.user.phone ?? '',
  department: e.department?.name ?? '',
  position: e.position ?? '',
  workplace: e.workplace?.name ?? '',
  active: e.status === 'active' && e.user.isActive,
});

/** undefined = leave unchanged, null = unassign, string = id of the named record. */
async function departmentId(name: string | undefined): Promise<string | null | undefined> {
  if (name === undefined) return undefined;
  if (name === '') return null;
  const d = await prisma.department.findUnique({ where: { name } });
  if (!d) throw new HttpError(422, `Unknown department: ${name}`);
  return d.id;
}

async function workplaceId(name: string | undefined): Promise<string | null | undefined> {
  if (name === undefined) return undefined;
  if (name === '') return null;
  const w = await prisma.workplace.findUnique({ where: { name } });
  if (!w) throw new HttpError(422, `Unknown workplace: ${name}`);
  return w.id;
}

export async function list() {
  const rows = await prisma.employee.findMany({ include, orderBy: { user: { name: 'asc' } } });
  return rows.map(toDto);
}

export async function get(id: string) {
  const e = await prisma.employee.findUnique({ where: { id }, include });
  if (!e) throw new HttpError(404, 'Employee not found.');
  return toDto(e);
}

/**
 * Admin adds an employee. The account gets a random password nobody knows;
 * the employee sets their own through "Forgot Password" (code sent by email).
 */
export async function create(
  input: {
    name: string; code: string; email: string; phone: string;
    department?: string; position?: string; workplace?: string;
  },
  adminId: string,
) {
  const [dept, wp, schedule] = await Promise.all([
    departmentId(input.department),
    workplaceId(input.workplace),
    prisma.schedule.findFirst({ orderBy: { name: 'asc' } }),
  ]);

  const user = await prisma.user.create({
    data: {
      name: input.name,
      email: input.email,
      phone: input.phone,
      passwordHash: await hashPassword(randomToken(24)),
      role: 'employee',
      employee: {
        create: {
          employeeCode: input.code,
          position: input.position || null,
          departmentId: dept ?? null,
          workplaceId: wp ?? null,
          scheduleId: schedule?.id ?? null,
        },
      },
    },
    include: { employee: true },
  });
  await audit(adminId, 'CREATE_EMPLOYEE', 'employees', user.employee!.id);
  return get(user.employee!.id);
}

export async function update(
  id: string,
  input: {
    name?: string; code?: string; email?: string; phone?: string;
    department?: string; position?: string; workplace?: string; active?: boolean;
  },
  adminId: string,
) {
  const emp = await prisma.employee.findUnique({ where: { id } });
  if (!emp) throw new HttpError(404, 'Employee not found.');

  const [dept, wp] = await Promise.all([departmentId(input.department), workplaceId(input.workplace)]);

  await prisma.$transaction([
    prisma.user.update({
      where: { id: emp.userId },
      data: { name: input.name, email: input.email, phone: input.phone, isActive: input.active },
    }),
    prisma.employee.update({
      where: { id },
      data: {
        employeeCode: input.code,
        position: input.position === undefined ? undefined : input.position || null,
        departmentId: dept,
        workplaceId: wp,
        status: input.active === undefined ? undefined : input.active ? 'active' : 'inactive',
      },
    }),
  ]);

  // A deactivated person is signed out everywhere.
  if (input.active === false) {
    await prisma.refreshToken.updateMany({
      where: { userId: emp.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
  await audit(adminId, 'UPDATE_EMPLOYEE', 'employees', id);
  return get(id);
}
