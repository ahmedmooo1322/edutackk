import { Router } from 'express';
import { balance, requestDeposit, requestWithdrawal, transactions } from '../controllers/wallet-controller.js';
import { authenticate } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { paginateSchema, walletRequestSchema } from '../validators/schemas.js';

export const walletRouter = Router();
walletRouter.use(authenticate);
walletRouter.get('/balance', asyncHandler(balance));
walletRouter.get('/transactions', validate(paginateSchema), asyncHandler(transactions));
walletRouter.post('/deposits', validate(walletRequestSchema), asyncHandler(requestDeposit));
walletRouter.post('/withdrawals', validate(walletRequestSchema), asyncHandler(requestWithdrawal));

