import { id } from '../utils/crypto.js';
export function audit(db, { actorUserId = null, action, entityType, entityId = null, metadata = null, ip = null }) {
  return db.query('INSERT INTO audit_logs (actor_user_id,action,entity_type,entity_id,metadata_json,ip_address) VALUES (?,?,?,?,?,?)', [actorUserId, action, entityType, entityId, metadata ? JSON.stringify(metadata) : null, ip]);
}
export function notify(db, userId, title, body, type) { return db.query('INSERT INTO notifications (id,user_id,title_ar,body_ar,type) VALUES (?,?,?,?,?)', [id(), userId, title, body, type]); }
