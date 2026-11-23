import { prisma } from '../../lib/prisma';
import { audit } from '../../utils/audit';
import { HttpError } from '../../utils/httpError';
import type { Role } from '../../utils/jwt';

interface WorkplaceRow {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  geofenceRadiusMeters: number;
  isActive: boolean;
}

/** JSON the Flutter `Workplace.fromJson` expects. */
const toDto = (w: WorkplaceRow) => ({
  id: w.id,
  name: w.name,
  address: w.address,
  latitude: w.latitude,
  longitude: w.longitude,
  radius: w.geofenceRadiusMeters,
  active: w.isActive,
});

interface WorkplaceInput {
  name?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  radius?: number;
  active?: boolean;
}

/** Admins see every workplace; everyone else only the active ones. */
export async function list(role: Role) {
  const rows = await prisma.workplace.findMany({
    where: role === 'admin' ? {} : { isActive: true },
    orderBy: { name: 'asc' },
  });
  return rows.map(toDto);
}

export async function get(id: string) {
  const w = await prisma.workplace.findUnique({ where: { id } });
  if (!w) throw new HttpError(404, 'Workplace not found.');
  return toDto(w);
}

export async function create(input: Required<Omit<WorkplaceInput, 'active'>> & { active?: boolean }, adminId: string) {
  const w = await prisma.workplace.create({
    data: {
      name: input.name,
      address: input.address,
      latitude: input.latitude,
      longitude: input.longitude,
      geofenceRadiusMeters: input.radius,
      isActive: input.active ?? true,
    },
  });
  await audit(adminId, 'CREATE_WORKPLACE', 'workplaces', w.id);
  return toDto(w);
}

export async function update(id: string, input: WorkplaceInput, adminId: string) {
  // Prisma ignores undefined fields, so a partial body changes only what it contains.
  const w = await prisma.workplace.update({
    where: { id },
    data: {
      name: input.name,
      address: input.address,
      latitude: input.latitude,
      longitude: input.longitude,
      geofenceRadiusMeters: input.radius,
      isActive: input.active,
    },
  });
  await audit(adminId, 'UPDATE_WORKPLACE', 'workplaces', id);
  return toDto(w);
}
