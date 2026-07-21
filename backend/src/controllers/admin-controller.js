import { inTransaction, pool } from '../config/database.js';
import { env } from '../config/env.js';
import { createUserRepository } from '../repositories/user-repository.js';
import { createWalletService } from '../services/wallet-service.js';
import { createStory } from '../services/story-service.js';
import { audit } from '../repositories/audit-repository.js';
import { AppError, notFound } from '../utils/errors.js';
import { page, success } from '../utils/response.js';

export async function dashboard(_req, res) {
  const rows = await pool.query(`SELECT
    (SELECT COUNT(*) FROM users) users,
    (SELECT COUNT(*) FROM users WHERE status='active') active_users,
    (SELECT COUNT(*) FROM games WHERE status='active') active_games,
    (SELECT COUNT(*) FROM games WHERE status='completed') completed_games,
    (SELECT COUNT(*) FROM deposit_requests WHERE status='pending') pending_deposits,
    (SELECT COUNT(*) FROM withdrawal_requests WHERE status='pending') pending_withdrawals,
    (SELECT COUNT(*) FROM stories WHERE status='published') published_stories`);
  return success(res, { ...rows[0], settings: { coinName: env.COIN_NAME, countdownSeconds: env.LEVEL_COUNTDOWN_SECONDS, minStake: env.MIN_GAME_ENTRY, maxStake: env.MAX_GAME_ENTRY } });
}
export async function users(req, res) { const { page: number, limit } = req.validated.query; const search = typeof req.query.search === 'string' ? req.query.search.trim().slice(0, 80) || null : null; return page(res, await createUserRepository(pool).list(limit, (number - 1) * limit, search), { page: number, limit }); }
export async function userStatus(req, res) {
  const { userId } = req.validated.params; const { status } = req.validated.body;
  if (userId === req.auth.userId) throw new AppError(422, 'INVALID_ACTION', 'Administrators cannot change their own status');
  await inTransaction(async (db) => { const usersRepo = createUserRepository(db); if (!await usersRepo.findById(userId)) throw notFound('User not found'); await usersRepo.setStatus(userId, status); await audit(db, { actorUserId: req.auth.userId, action: `user.${status}`, entityType: 'user', entityId: String(userId), ip: req.ip }); });
  return success(res, { id: userId, status });
}
export async function adjustBalance(req, res) {
  const { userId, amount, reason } = req.validated.body;
  const result = await inTransaction(async (db) => { const wallet = createWalletService(db, createUserRepository(db)); const change = await wallet.changeBalance({ userId, amount, type: amount > 0 ? 'admin_credit' : 'admin_debit', description: reason, referenceType: 'admin_adjustment', referenceId: String(req.auth.userId), createdBy: req.auth.userId }); await audit(db, { actorUserId: req.auth.userId, action: 'wallet.adjusted', entityType: 'user', entityId: String(userId), metadata: { amount, reason }, ip: req.ip }); return change; });
  return success(res, result);
}
export async function addStory(req, res) { const storyId = await inTransaction(async (db) => { const created = await createStory(db, req.validated.body, req.auth.userId); await audit(db, { actorUserId: req.auth.userId, action: 'story.created', entityType: 'story', entityId: String(created), ip: req.ip }); return created; }); return success(res, { id: storyId }, 201); }
export async function storyStatus(req, res) { const storyId = Number(req.params.storyId); const status = req.body.status; if (!Number.isInteger(storyId) || !['draft', 'published', 'archived'].includes(status)) throw new AppError(422, 'VALIDATION_ERROR', 'Invalid story update'); const result = await pool.query('UPDATE stories SET status=?,published_at=CASE WHEN ?=\'published\' THEN NOW(3) ELSE published_at END WHERE id=?', [status, status, storyId]); if (!result.affectedRows) throw notFound('Story not found'); await audit(pool, { actorUserId: req.auth.userId, action: `story.${status}`, entityType: 'story', entityId: String(storyId), ip: req.ip }); return success(res, { id: storyId, status }); }
export async function requests(req, res) { const kind = req.params.kind; if (!['deposits', 'withdrawals'].includes(kind)) throw notFound('Request type not found'); const { page: number, limit } = req.validated.query; const table = kind === 'deposits' ? 'deposit_requests' : 'withdrawal_requests'; const rows = await pool.query(`SELECT r.*,u.email,u.display_name FROM ${table} r JOIN users u ON u.id=r.user_id ORDER BY r.created_at DESC LIMIT ? OFFSET ?`, [limit, (number - 1) * limit]); return page(res, rows, { page: number, limit }); }
