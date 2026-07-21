import { asyncHandler } from './async-handler.js';
import { AppError, forbidden } from '../utils/errors.js';
import { verifyAccessToken } from '../services/auth-service.js';
import { pool } from '../config/database.js';
import { createUserRepository } from '../repositories/user-repository.js';

export const authenticate = asyncHandler(async (req, _res, next) => {
  const [scheme, token] = (req.get('authorization') || '').split(' ');
  if (scheme !== 'Bearer' || !token) throw new AppError(401, 'UNAUTHORIZED', 'Bearer token required');
  const { payload } = await verifyAccessToken(token);
  const user = await createUserRepository(pool).findById(Number(payload.sub));
  if (!user || user.status !== 'active') throw new AppError(401, 'UNAUTHORIZED', 'Account is unavailable');
  req.auth = { userId: user.id, role: user.role_code };
  next();
});
export const requireAdmin = (req, _res, next) => req.auth?.role === 'admin' ? next() : next(forbidden('Administrator permission required'));
