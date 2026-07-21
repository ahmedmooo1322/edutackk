import { pool, inTransaction } from '../config/database.js';
import { createUserRepository } from '../repositories/user-repository.js';
import { audit } from '../repositories/audit-repository.js';
import { assertActive, hashPassword, issueRefreshToken, refreshExpiry, signAccessToken, verifyPassword } from '../services/auth-service.js';
import { AppError, conflict } from '../utils/errors.js';
import { id, digest } from '../utils/crypto.js';
import { success } from '../utils/response.js';
import { sendPasswordReset } from '../services/mail-service.js';

async function tokensFor(db, user) {
  const accessToken = await signAccessToken(user);
  const refresh = issueRefreshToken();
  await db.query('INSERT INTO refresh_tokens (id,user_id,token_hash,expires_at) VALUES (?,?,?,?)', [id(), user.id, refresh.tokenHash, refreshExpiry()]);
  return { accessToken, refreshToken: refresh.raw };
}
export async function register(req, res) {
  const { email, displayName, password } = req.validated.body;
  const result = await inTransaction(async (db) => {
    const users = createUserRepository(db);
    if (await users.findByEmail(email)) throw conflict('Email is already registered');
    const userId = await users.create({ email, displayName, passwordHash: await hashPassword(password) });
    const user = await users.findById(userId);
    await audit(db, { actorUserId: userId, action: 'auth.registered', entityType: 'user', entityId: String(userId), ip: req.ip });
    return { user, ...(await tokensFor(db, user)) };
  });
  return success(res, result, 201);
}
export async function login(req, res) {
  const { email, password } = req.validated.body;
  const result = await inTransaction(async (db) => {
    const users = createUserRepository(db);
    const user = await users.findByEmail(email);
    if (!user || !(await verifyPassword(user.password_hash, password))) throw new AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
    assertActive(user);
    await audit(db, { actorUserId: user.id, action: 'auth.login', entityType: 'user', entityId: String(user.id), ip: req.ip });
    return { user: await users.findById(user.id), ...(await tokensFor(db, user)) };
  });
  return success(res, result);
}
export async function refresh(req, res) {
  const tokenHash = digest(req.validated.body.refreshToken);
  const result = await inTransaction(async (db) => {
    const rows = await db.query(`SELECT r.id,r.user_id,u.id,u.status,u.display_name,ro.code role_code FROM refresh_tokens r JOIN users u ON u.id=r.user_id JOIN roles ro ON ro.id=u.role_id WHERE r.token_hash=? AND r.revoked_at IS NULL AND r.expires_at>NOW(3) FOR UPDATE`, [tokenHash]);
    const stored = rows[0];
    if (!stored) throw new AppError(401, 'INVALID_REFRESH_TOKEN', 'Invalid or expired refresh token');
    assertActive(stored);
    await db.query('UPDATE refresh_tokens SET revoked_at=NOW(3) WHERE id=?', [stored.id]);
    return tokensFor(db, stored);
  });
  return success(res, result);
}
export async function logout(req, res) { await pool.query('UPDATE refresh_tokens SET revoked_at=NOW(3) WHERE token_hash=?', [digest(req.validated.body.refreshToken)]); return success(res, { loggedOut: true }); }
export async function me(req, res) { const user = await createUserRepository(pool).findById(req.auth.userId); return success(res, user); }
export async function forgotPassword(req, res) { const user = await createUserRepository(pool).findByEmail(req.validated.body.email); if (user) { const raw = `${id()}${id()}`; await inTransaction(async (db) => { await db.query('DELETE FROM password_reset_tokens WHERE user_id=?', [user.id]); await db.query('INSERT INTO password_reset_tokens (id,user_id,token_hash,expires_at) VALUES (?,?,?,DATE_ADD(NOW(3), INTERVAL 1 HOUR))', [id(), user.id, digest(raw)]); }); await sendPasswordReset(user.email, raw); } return success(res, { accepted: true }); }
export async function resetPassword(req, res) { const { token, password } = req.validated.body; await inTransaction(async (db) => { const reset = (await db.query('SELECT * FROM password_reset_tokens WHERE token_hash=? AND used_at IS NULL AND expires_at>NOW(3) FOR UPDATE', [digest(token)]))[0]; if (!reset) throw new AppError(400, 'INVALID_RESET_TOKEN', 'Reset link is invalid or expired'); await createUserRepository(db).updatePassword(reset.user_id, await hashPassword(password)); await db.query('UPDATE password_reset_tokens SET used_at=NOW(3) WHERE id=?', [reset.id]); await db.query('UPDATE refresh_tokens SET revoked_at=NOW(3) WHERE user_id=? AND revoked_at IS NULL', [reset.user_id]); await audit(db, { actorUserId: reset.user_id, action: 'auth.password_reset', entityType: 'user', entityId: String(reset.user_id), ip: req.ip }); }); return success(res, { reset: true }); }
