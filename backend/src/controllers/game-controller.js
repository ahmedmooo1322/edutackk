import { pool } from '../config/database.js';
import { createGameRepository } from '../repositories/game-repository.js';
import { startGame, getGame, submitChoice, resumeGame, abandonGame } from '../services/game-service.js';
import { page, success } from '../utils/response.js';

export async function start(req, res) { return success(res, await startGame(req.auth.userId, req.validated.body.stake, req.ip), 201); }
export async function get(req, res) { return success(res, await getGame(req.auth.userId, req.validated.params.gameId)); }
export async function choice(req, res) { return success(res, await submitChoice(req.auth.userId, req.validated.params.gameId, req.validated.body.choiceNumber, req.ip)); }
export async function resume(req, res) { return success(res, await resumeGame(req.auth.userId)); }
export async function abandon(req, res) { return success(res, await abandonGame(req.auth.userId, req.validated.params.gameId, req.ip)); }
export async function history(req, res) { const { page: number, limit } = req.validated.query; return page(res, await createGameRepository(pool).history(req.auth.userId, limit, (number - 1) * limit), { page: number, limit }); }
