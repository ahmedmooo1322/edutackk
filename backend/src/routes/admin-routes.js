import { Router } from 'express';
import { addStory, adjustBalance, dashboard, requests, storyStatus, userStatus, users } from '../controllers/admin-controller.js';
import { reviewDeposit, reviewWithdrawal } from '../controllers/wallet-controller.js';
import { authenticate, requireAdmin } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { adjustmentSchema, adminStatusSchema, paginateSchema, requestReviewSchema, storySchema } from '../validators/schemas.js';

export const adminRouter = Router();
adminRouter.use(authenticate, requireAdmin);
adminRouter.get('/dashboard', asyncHandler(dashboard));
adminRouter.get('/users', validate(paginateSchema), asyncHandler(users));
adminRouter.patch('/users/:userId/status', validate(adminStatusSchema), asyncHandler(userStatus));
adminRouter.post('/wallet/adjustments', validate(adjustmentSchema), asyncHandler(adjustBalance));
adminRouter.get('/requests/:kind', validate(paginateSchema), asyncHandler(requests));
adminRouter.post('/deposits/:requestId/review', validate(requestReviewSchema), asyncHandler(reviewDeposit));
adminRouter.post('/withdrawals/:requestId/review', validate(requestReviewSchema), asyncHandler(reviewWithdrawal));
adminRouter.post('/stories', validate(storySchema), asyncHandler(addStory));
adminRouter.patch('/stories/:storyId/status', asyncHandler(storyStatus));

