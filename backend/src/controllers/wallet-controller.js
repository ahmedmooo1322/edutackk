import { inTransaction, pool } from '../config/database.js';
import { createUserRepository } from '../repositories/user-repository.js';
import { createWalletService } from '../services/wallet-service.js';
import { id } from '../utils/crypto.js';
import { conflict, notFound } from '../utils/errors.js';
import { notify, audit } from '../repositories/audit-repository.js';
import { page, success } from '../utils/response.js';

export async function balance(req, res) { const user = await createUserRepository(pool).findById(req.auth.userId); return success(res, { balance: user.balance }); }
export async function transactions(req, res) { const { page: number, limit } = req.validated.query; const rows = await pool.query('SELECT id,type,amount,balance_after,reference_type,reference_id,description_ar,created_at FROM wallet_transactions WHERE user_id=? ORDER BY created_at DESC LIMIT ? OFFSET ?', [req.auth.userId, limit, (number - 1) * limit]); return page(res, rows, { page: number, limit }); }
export async function requestDeposit(req, res) {
  const { amount, reference } = req.validated.body;
  const requestId = id();
  await pool.query('INSERT INTO deposit_requests (id,user_id,amount,proof_reference) VALUES (?,?,?,?)', [requestId, req.auth.userId, amount, reference]);
  return success(res, { id: requestId, status: 'pending' }, 201);
}
export async function requestWithdrawal(req, res) {
  const { amount, reference } = req.validated.body;
  const requestId = id();
  await inTransaction(async (db) => {
    const wallet = createWalletService(db, createUserRepository(db));
    await wallet.changeBalance({ userId: req.auth.userId, amount: -amount, type: 'withdrawal_hold', description: 'حجز رصيد لطلب سحب', referenceType: 'withdrawal_requests', referenceId: requestId });
    await db.query('INSERT INTO withdrawal_requests (id,user_id,amount,payout_reference) VALUES (?,?,?,?)', [requestId, req.auth.userId, amount, reference]);
  });
  return success(res, { id: requestId, status: 'pending' }, 201);
}
async function review(req, res, kind) {
  const { requestId } = req.validated.params;
  const { action, note } = req.validated.body;
  const payload = await inTransaction(async (db) => {
    const table = kind === 'deposit' ? 'deposit_requests' : 'withdrawal_requests';
    const row = (await db.query(`SELECT * FROM ${table} WHERE id=? FOR UPDATE`, [requestId]))[0];
    if (!row) throw notFound('Request not found');
    if (row.status !== 'pending') throw conflict('Request has already been reviewed');
    const status = action === 'approve' ? 'approved' : 'rejected';
    await db.query(`UPDATE ${table} SET status=?,reviewed_by=?,review_note_ar=?,reviewed_at=NOW(3) WHERE id=?`, [status, req.auth.userId, note || null, requestId]);
    if (kind === 'deposit' && action === 'approve') {
      const users = createUserRepository(db);
      const wallet = createWalletService(db, users);
      await wallet.changeBalance({ userId: row.user_id, amount: row.amount, type: 'deposit_approved', description: 'تمت الموافقة على الإيداع', referenceType: table, referenceId: requestId, createdBy: req.auth.userId });
    }
    if (kind === 'withdrawal' && action === 'reject') {
      const wallet = createWalletService(db, createUserRepository(db));
      await wallet.changeBalance({ userId: row.user_id, amount: row.amount, type: 'withdrawal_rejected_refund', description: 'إرجاع رصيد طلب سحب مرفوض', referenceType: table, referenceId: requestId, createdBy: req.auth.userId });
    }
    await notify(db, row.user_id, 'تحديث المحفظة', action === 'approve' ? 'تمت الموافقة على طلبك.' : 'تم رفض طلبك.', `${kind}_${status}`);
    await audit(db, { actorUserId: req.auth.userId, action: `${kind}.reviewed`, entityType: table, entityId: requestId, metadata: { action, amount: row.amount }, ip: req.ip });
    return { id: requestId, status };
  });
  return success(res, payload);
}
export const reviewDeposit = (req, res) => review(req, res, 'deposit');
export const reviewWithdrawal = (req, res) => review(req, res, 'withdrawal');
