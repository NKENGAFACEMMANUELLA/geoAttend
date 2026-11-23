import type { Role } from '../utils/jwt';

declare global {
  namespace Express {
    interface Request {
      auth?: { userId: string; role: Role };
    }
  }
}

export {};
