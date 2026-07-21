import { ZodError } from 'zod';
import { AppError } from '../utils/errors.js';

export function notFoundHandler(_req, _res, next) { next(new AppError(404, 'NOT_FOUND', 'Route not found')); }
export function errorHandler(error, req, res, _next) {
  const normalized = error instanceof ZodError
    ? new AppError(422, 'VALIDATION_ERROR', 'Invalid request data', error.flatten())
    : error;
  const status = normalized instanceof AppError ? normalized.status : 500;
  if (status >= 500) req.log.error({ err: normalized }, 'Unhandled request error');
  return res.status(status).json({
    success: false,
    error: { code: normalized.code || 'INTERNAL_ERROR', message: status >= 500 ? 'Internal server error' : normalized.message, details: normalized.details }
  });
}

