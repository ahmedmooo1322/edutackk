import { pool } from '../config/database.js';
import { page, success } from '../utils/response.js';
export async function listNotifications(req, res) { const { page: number, limit } = req.validated.query; const rows = await pool.query('SELECT id,title_ar,body_ar,type,read_at,created_at FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT ? OFFSET ?', [req.auth.userId, limit, (number - 1) * limit]); return page(res, rows, { page: number, limit }); }
export async function markRead(req, res) { await pool.query('UPDATE notifications SET read_at=COALESCE(read_at,NOW(3)) WHERE id=? AND user_id=?', [req.params.notificationId, req.auth.userId]); return success(res, { id: req.params.notificationId, read: true }); }
