import type { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma';
import { audit } from '../../utils/audit';
import { HttpError } from '../../utils/httpError';

const include = { hod: true, _count: { select: { employees: true } } } as const;

interface DepartmentRow {
  id: string;
  name: string;
  description: string | null;
  isActive: boolean;
  hodUserId: string | null;
  hod: { name: string; email: string } | null;
  _count: { employees: number };
}

/** JSON the Flutter `Department.fromJson` expects. */
const toDto = (d: DepartmentRow) => ({
  id: d.id,
  name: d.name,
  description: d.description ?? '',
  hodUserId: d.hodUserId,
  hodName: d.hod?.name ?? '',
  hodEmail: d.hod?.email ?? '',
  employeeCount: d._count.employees,
  active: d.isActive,
});

export async function list() {
  const rows = await prisma.department.findMany({ include, orderBy: { name: 'asc' } });
  return rows.map(toDto);
}

export async function get(id: string) {
  const d = await prisma.department.findUnique({ where: { id }, include });
  if (!d) throw new HttpError(404, 'Department not found.');
  return toDto(d);
}

/** People who can be made HOD: active employees and current HODs (never admins). */
export function hodCandidates() {
  return prisma.user.findMany({
    where: { isActive: true, role: { in: ['employee', 'hod'] }, employee: { isNot: null } },
    orderBy: { name: 'asc' },
    select: { id: true, name: true, email: true },
  });
}

export async function create(
  input: { name: string; description?: string; hodUserId?: string },
  adminId: string,
) {
  const d = await prisma.department.create({
    data: { name: input.name, description: input.description || null },
  });
  await audit(adminId, 'CREATE_DEPARTMENT', 'departments', d.id);
  if (input.hodUserId) await assignHod(d.id, input.hodUserId, adminId);
  return get(d.id);
}

export async function update(
  id: string,
  input: { name?: string; description?: string; active?: boolean },
  adminId: string,
) {
  await prisma.department.update({
    where: { id },
    data: {
      name: input.name,
      description: input.description === undefined ? undefined : input.description || null,
      isActive: input.active,
    },
  });
  await audit(adminId, 'UPDATE_DEPARTMENT', 'departments', id);
  return get(id);
}

/**
 * Makes [userId] the head of the department.
 * - an employee is promoted to the HOD role and moved into the department
 * - the previous HOD goes back to employee if they head no other department
 */
export async function assignHod(departmentId: string, userId: string, adminId: string) {
  await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const dept = await tx.department.findUnique({ where: { id: departmentId } });
    if (!dept) throw new HttpError(404, 'Department not found.');

    const user = await tx.user.findUnique({ where: { id: userId }, include: { employee: true } });
    if (!user || !user.isActive || user.role === 'admin' || !user.employee) {
      throw new HttpError(422, 'That person cannot be made a HOD.');
    }

    const previous = dept.hodUserId;
    await tx.department.update({ where: { id: departmentId }, data: { hodUserId: userId } });
    if (user.role === 'employee') await tx.user.update({ where: { id: userId }, data: { role: 'hod' } });
    await tx.employee.update({ where: { id: user.employee.id }, data: { departmentId } });

    if (previous && previous !== userId) {
      const stillHeads = await tx.department.count({ where: { hodUserId: previous } });
      if (stillHeads === 0) {
        await tx.user.updateMany({ where: { id: previous, role: 'hod' }, data: { role: 'employee' } });
      }
    }
  });
  await audit(adminId, 'ASSIGN_HOD', 'departments', departmentId);
  return get(departmentId);
}
