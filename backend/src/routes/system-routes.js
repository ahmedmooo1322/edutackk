import { Router } from 'express';
import { env } from '../config/env.js';
import { success } from '../utils/response.js';
export const systemRouter = Router();
systemRouter.get('/public-config', (_req, res) => success(res, { coinName: env.COIN_NAME, minGameEntry: env.MIN_GAME_ENTRY, maxGameEntry: env.MAX_GAME_ENTRY, levelCountdownSeconds: env.LEVEL_COUNTDOWN_SECONDS }));

