import type { Request, Response } from 'express';
import { asyncHandler } from '../../utils/asyncHandler';
import * as service from './auth.service';

const send = (res: Response, data: unknown, status = 200) => res.status(status).json({ data });

export const login = asyncHandler(async (req: Request, res) => send(res, await service.login(req.body)));
export const register = asyncHandler(async (req, res) => send(res, await service.register(req.body), 201));
export const refresh = asyncHandler(async (req, res) => send(res, await service.refresh(req.body.refreshToken)));
export const logout = asyncHandler(async (req, res) => send(res, await service.logout(req.body.refreshToken)));
export const forgot = asyncHandler(async (req, res) => send(res, await service.forgotPassword(req.body.email)));
export const verifyCode = asyncHandler(async (req, res) =>
  send(res, await service.verifyResetCode(req.body.email, req.body.code)));
export const reset = asyncHandler(async (req, res) =>
  send(res, await service.resetPassword(req.body.resetToken, req.body.newPassword)));

export const me = asyncHandler(async (req, res) => send(res, await service.me(req.auth!.userId)));
export const updateMe = asyncHandler(async (req, res) =>
  send(res, await service.updateMe(req.auth!.userId, req.body)));
export const changePassword = asyncHandler(async (req, res) =>
  send(res, await service.changePassword(req.auth!.userId, req.body.currentPassword, req.body.newPassword)));
