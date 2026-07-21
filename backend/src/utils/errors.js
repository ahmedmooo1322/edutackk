export class AppError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const notFound = (message = 'Not found') => new AppError(404, 'NOT_FOUND', message);
export const forbidden = (message = 'Forbidden') => new AppError(403, 'FORBIDDEN', message);
export const conflict = (message = 'Conflict') => new AppError(409, 'CONFLICT', message);

