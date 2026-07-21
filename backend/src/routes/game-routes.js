import { Router } from 'express';
import { abandon, choice, get, history, resume, start } from '../controllers/game-controller.js';
import { authenticate } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { choiceSchema, gameIdSchema, paginateSchema, startGameSchema } from '../validators/schemas.js';

export const gameRouter = Router();
gameRouter.use(authenticate);
gameRouter.post('/', validate(startGameSchema), asyncHandler(start));
gameRouter.get('/resume', asyncHandler(resume));
gameRouter.get('/history', validate(paginateSchema), asyncHandler(history));
gameRouter.get('/:gameId', validate(gameIdSchema), asyncHandler(get));
gameRouter.post('/:gameId/choice', validate(choiceSchema), asyncHandler(choice));
gameRouter.post('/:gameId/abandon', validate(gameIdSchema), asyncHandler(abandon));

