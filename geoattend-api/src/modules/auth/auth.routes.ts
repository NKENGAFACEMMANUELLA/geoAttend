import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { codeLimiter, loginLimiter } from '../../middleware/rateLimit';
import { validate } from '../../middleware/validate';
import * as c from './auth.controller';
import * as s from './auth.schema';

export const authRouter = Router();

authRouter.post('/login', loginLimiter, validate(s.loginSchema), c.login);
authRouter.post('/register', loginLimiter, validate(s.registerSchema), c.register);
authRouter.post('/refresh', validate(s.refreshSchema), c.refresh);
authRouter.post('/logout', validate(s.refreshSchema), c.logout);

authRouter.post('/forgot', codeLimiter, validate(s.forgotSchema), c.forgot);
authRouter.post('/verify-code', codeLimiter, validate(s.verifyCodeSchema), c.verifyCode);
authRouter.post('/reset', codeLimiter, validate(s.resetSchema), c.reset);

authRouter.get('/me', requireAuth, c.me);
authRouter.patch('/me', requireAuth, validate(s.updateMeSchema), c.updateMe);
authRouter.post('/change-password', requireAuth, validate(s.changePasswordSchema), c.changePassword);
