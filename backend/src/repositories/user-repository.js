export function createUserRepository(db) {
  return {
    findByEmail: async (email) => (await db.query('SELECT u.*, r.code role_code FROM users u JOIN roles r ON r.id=u.role_id WHERE u.email=?', [email]))[0],
    findById: async (userId) => (await db.query('SELECT u.id,u.email,u.display_name,u.status,u.balance,u.created_at,r.code role_code FROM users u JOIN roles r ON r.id=u.role_id WHERE u.id=?', [userId]))[0],
    create: async ({ email, displayName, passwordHash }) => {
      const result = await db.query('INSERT INTO users (email, display_name, password_hash) VALUES (?, ?, ?)', [email, displayName, passwordHash]);
      return result.insertId;
    },
    lock: async (userId) => (await db.query('SELECT id,balance,status FROM users WHERE id=? FOR UPDATE', [userId]))[0],
    setBalance: (userId, balance) => db.query('UPDATE users SET balance=? WHERE id=?', [balance, userId]),
    updatePassword: (userId, passwordHash) => db.query('UPDATE users SET password_hash=?, password_changed_at=NOW(3) WHERE id=?', [passwordHash, userId]),
    setStatus: (userId, status) => db.query('UPDATE users SET status=? WHERE id=?', [status, userId]),
    list: async (limit, offset, search) => db.query('SELECT id,email,display_name,status,balance,created_at FROM users WHERE (? IS NULL OR email LIKE ? OR display_name LIKE ?) ORDER BY id DESC LIMIT ? OFFSET ?', [search, search ? `%${search}%` : null, search ? `%${search}%` : null, limit, offset])
  };
}

