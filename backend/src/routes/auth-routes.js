import { Router } from 'express';
import { forgotPassword, login, logout, me, refresh, register, resetPassword } from '../controllers/auth-controller.js';
import { authenticate } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { forgotPasswordSchema, loginSchema, refreshSchema, registerSchema, resetPasswordSchema } from '../validators/schemas.js';

export const authRouter = Router();
authRouter.post('/register', validate(registerSchema), asyncHandler(register));
authRouter.post('/login', validate(loginSchema), asyncHandler(login));
authRouter.post('/refresh', validate(refreshSchema), asyncHandler(refresh));
authRouter.post('/logout', validate(refreshSchema), asyncHandler(logout));
authRouter.post('/forgot-password', validate(forgotPasswordSchema), asyncHandler(forgotPassword));
authRouter.post('/reset-password', validate(resetPasswordSchema), asyncHandler(resetPassword));
authRouter.get('/me', authenticate, asyncHandler(me));
