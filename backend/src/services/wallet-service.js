import { id } from '../utils/crypto.js';
import { AppError } from '../utils/errors.js';

export function createWalletService(db, users) {
  async function changeBalance({ userId, amount, type, description, referenceType = null, referenceId = null, createdBy = null }) {
    if (!Number.isSafeInteger(amount) || amount === 0) throw new AppError(422, 'INVALID_AMOUNT', 'Amount must be a non-zero integer');
    const user = await users.lock(userId);
    if (!user || user.status !== 'active') throw new AppError(403, 'ACCOUNT_UNAVAILABLE', 'Account is unavailable');
    const balanceAfter = user.balance + amount;
    if (balanceAfter < 0) throw new AppError(409, 'INSUFFICIENT_BALANCE', 'Insufficient coin balance');
    await users.setBalance(userId, balanceAfter);
    const transactionId = id();
    await db.query('INSERT INTO wallet_transactions (id,user_id,type,amount,balance_after,reference_type,reference_id,description_ar,created_by) VALUES (?,?,?,?,?,?,?,?,?)', [transactionId, userId, type, amount, balanceAfter, referenceType, referenceId, description, createdBy]);
    return { transactionId, balanceAfter };
  }
  return { changeBalance };
}

