import { prisma } from '../../lib/prisma';
import { env } from '../../config/env';
import { HttpError } from '../../utils/httpError';
import { signAccessToken, signResetToken, verifyResetToken, type Role } from '../../utils/jwt';
import {
  DUMMY_HASH, addDays, addMinutes, hashPassword, randomCode, randomToken,
  safeEqual, sha256, verifyPassword,
} from '../../utils/crypto';
import { serializeUser, userInclude, type UserRecord } from '../../utils/serializers';
import { sendResetCode } from '../../utils/mailer';
import { audit } from '../../utils/audit';

const SESSION_EXPIRED = 'Your session has expired. Please sign in again.';
const roleName: Record<Role, string> = { employee: 'employee', hod: 'HOD', admin: 'admin' };

const findByEmail = (email: string) =>
  prisma.user.findUnique({ where: { email }, include: userInclude });
const findById = (id: string) => prisma.user.findUnique({ where: { id }, include: userInclude });

/** Creates the access + refresh token pair the app stores. */
async function issueSession(user: UserRecord) {
  const accessToken = signAccessToken(user.id, user.role);
  const refreshToken = randomToken();
  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      tokenHash: sha256(refreshToken),
      expiresAt: addDays(new Date(), env.REFRESH_TOKEN_DAYS),
    },
  });
  return { accessToken, refreshToken, user: serializeUser(user) };
}

const revokeAllSessions = (userId: string) =>
  prisma.refreshToken.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } });

export async function login(input: { email: string; password: string; portal?: Role }) {
  const user = await findByEmail(input.email);
  const ok = await verifyPassword(input.password, user?.passwordHash ?? DUMMY_HASH);
  if (!user || !ok) throw new HttpError(401, 'Incorrect email or password.');

  if (!user.isActive || user.employee?.status === 'inactive') {
    throw new HttpError(403, 'Your account is inactive. Please contact your administrator.');
  }
  if (input.portal && input.portal !== user.role) {
    throw new HttpError(
      403,
      `This is not a ${roleName[input.portal]} account. Please use the ${roleName[user.role as Role]} login.`,
    );
  }
  await audit(user.id, 'LOGIN', 'users', user.id);
  return issueSession(user);
}

export async function register(input: { name: string; email: string; employeeId: string; password: string }) {
  if (await prisma.user.findUnique({ where: { email: input.email } })) {
    throw new HttpError(409, 'An account with this email already exists.');
  }
  if (await prisma.employee.findUnique({ where: { employeeCode: input.employeeId } })) {
    throw new HttpError(409, 'This employee ID is already registered.');
  }
  const user = await prisma.user.create({
    data: {
      name: input.name,
      email: input.email,
      passwordHash: await hashPassword(input.password),
      role: 'employee',
      // Department, workplace and schedule are assigned later by an admin.
      employee: { create: { employeeCode: input.employeeId } },
    },
  });
  await audit(user.id, 'REGISTER', 'users', user.id);
  return { message: 'Account created. You can now sign in.' };
}

export async function refresh(token: string) {
  const record = await prisma.refreshToken.findUnique({ where: { tokenHash: sha256(token) } });
  if (!record) throw new HttpError(401, SESSION_EXPIRED);

  if (record.revokedAt) {
    // Re-use of an old token after the grace window means it may have been stolen.
    if (Date.now() - record.revokedAt.getTime() > 10_000) await revokeAllSessions(record.userId);
    throw new HttpError(401, SESSION_EXPIRED);
  }
  if (record.expiresAt < new Date()) throw new HttpError(401, SESSION_EXPIRED);

  const user = await findById(record.userId);
  if (!user || !user.isActive) throw new HttpError(401, SESSION_EXPIRED);

  await prisma.refreshToken.update({ where: { id: record.id }, data: { revokedAt: new Date() } });
  return issueSession(user);
}

export async function logout(token: string) {
  await prisma.refreshToken.updateMany({
    where: { tokenHash: sha256(token), revokedAt: null },
    data: { revokedAt: new Date() },
  });
  return { message: 'Signed out.' };
}

export async function forgotPassword(email: string) {
  const user = await findByEmail(email);
  if (user && user.isActive) {
    const code = randomCode();
    await prisma.passwordResetCode.updateMany({
      where: { userId: user.id, usedAt: null },
      data: { usedAt: new Date() },
    });
    await prisma.passwordResetCode.create({
      data: {
        userId: user.id,
        codeHash: sha256(code + user.id),
        expiresAt: addMinutes(new Date(), env.RESET_CODE_MINUTES),
      },
    });
    // Do not make the user wait for the mail server.
    sendResetCode(user.email, user.name, code, env.RESET_CODE_MINUTES).catch((e) =>
      console.error('Could not send reset email', e),
    );
  }
  // Same answer whether or not the email exists.
  return { message: 'If an account exists for that email, a code has been sent.' };
}

export async function verifyResetCode(email: string, code: string) {
  const invalid = new HttpError(400, 'Invalid or expired code.');
  const user = await findByEmail(email);
  if (!user) throw invalid;

  const record = await prisma.passwordResetCode.findFirst({
    where: { userId: user.id, usedAt: null, expiresAt: { gt: new Date() } },
    orderBy: { createdAt: 'desc' },
  });
  if (!record) throw invalid;
  if (record.attempts >= 5) throw new HttpError(429, 'Too many attempts. Please request a new code.');

  if (!safeEqual(record.codeHash, sha256(code + user.id))) {
    await prisma.passwordResetCode.update({ where: { id: record.id }, data: { attempts: { increment: 1 } } });
    throw invalid;
  }
  await prisma.passwordResetCode.update({ where: { id: record.id }, data: { usedAt: new Date() } });
  return { resetToken: signResetToken(user.id) };
}

export async function resetPassword(resetToken: string, newPassword: string) {
  let userId: string;
  try {
    userId = verifyResetToken(resetToken);
  } catch {
    throw new HttpError(400, 'This reset link has expired. Please start again.');
  }
  await prisma.user.update({ where: { id: userId }, data: { passwordHash: await hashPassword(newPassword) } });
  await revokeAllSessions(userId);
  await audit(userId, 'PASSWORD_RESET', 'users', userId);
  return { message: 'Password updated. Please sign in.' };
}

export async function me(userId: string) {
  const user = await findById(userId);
  if (!user) throw new HttpError(404, 'Account not found.');
  return serializeUser(user);
}

export async function updateMe(userId: string, input: { name?: string; phone?: string }) {
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(input.name !== undefined && { name: input.name }),
      ...(input.phone !== undefined && { phone: input.phone || null }),
    },
    include: userInclude,
  });
  await audit(userId, 'UPDATE_PROFILE', 'users', userId);
  return serializeUser(user);
}

export async function changePassword(userId: string, currentPassword: string, newPassword: string) {
  const user = await findById(userId);
  if (!user) throw new HttpError(404, 'Account not found.');
  if (!(await verifyPassword(currentPassword, user.passwordHash))) {
    throw new HttpError(400, 'Your current password is incorrect.');
  }
  await prisma.user.update({ where: { id: userId }, data: { passwordHash: await hashPassword(newPassword) } });
  await revokeAllSessions(userId);
  await audit(userId, 'PASSWORD_CHANGE', 'users', userId);
  return issueSession(user); // fresh tokens, other devices are signed out
}
