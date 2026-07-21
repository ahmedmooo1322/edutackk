import { inTransaction, pool } from '../src/config/database.js';
import { env } from '../src/config/env.js';
import { createUserRepository } from '../src/repositories/user-repository.js';
import { hashPassword } from '../src/services/auth-service.js';

try {
  await inTransaction(async (db) => {
    const users = createUserRepository(db);
    const existing = await users.findByEmail(env.ADMIN_EMAIL.toLowerCase());
    if (existing) return;
    const userId = await users.create({ email: env.ADMIN_EMAIL.toLowerCase(), displayName: 'مدير النظام', passwordHash: await hashPassword(env.ADMIN_PASSWORD) });
    await db.query("UPDATE users SET role_id=(SELECT id FROM roles WHERE code='admin') WHERE id=?", [userId]);
  });
  process.stdout.write('Administrator account is ready.\n');
} finally { await pool.end(); }

