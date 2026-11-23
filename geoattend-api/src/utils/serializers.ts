import { env } from '../config/env';
import type { Role } from './jwt';

/** Shape of a user row with the relations we load. */
export interface UserRecord {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  role: Role;
  isActive: boolean;
  employee: {
    employeeCode: string;
    position: string | null;
    status: 'active' | 'inactive';
    department: { name: string } | null;
    workplace: { name: string } | null;
  } | null;
  headedDepartments: { name: string }[];
}

/** Pass as `include` whenever a user will be serialized. */
export const userInclude = {
  employee: { include: { department: true, workplace: true } },
  headedDepartments: true,
} as const;

/** JSON the Flutter `AppUser.fromJson` expects. */
export function serializeUser(u: UserRecord) {
  const defaultTitle = u.role === 'admin' ? 'Administrator' : u.role === 'hod' ? 'HOD/Officer' : '';
  return {
    id: u.id,
    name: u.name,
    email: u.email,
    phone: u.phone ?? '',
    role: u.role,
    isActive: u.isActive,
    employeeId: u.employee?.employeeCode ?? '',
    department: u.employee?.department?.name ?? u.headedDepartments[0]?.name ?? '',
    position: u.employee?.position ?? defaultTitle,
    workplace: u.employee?.workplace?.name ?? '',
    organisation: env.COMPANY_NAME,
  };
}
