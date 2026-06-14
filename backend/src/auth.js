import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import { db, getSetting } from './db.js';

export const JWT_SECRET = process.env.JWT_SECRET || 'pink-flamingo-dev-secret';

export function maxAdminSessions() {
  const n = parseInt(getSetting('admin_max_sessions', '1'), 10);
  return Number.isFinite(n) && n > 0 ? n : 1;
}

/// Create a new admin session (jti), enforce the active-session limit by
/// dropping the OLDEST sessions, and return a signed token carrying the jti.
export function startSession(admin, label = null) {
  const jti = randomUUID();
  db.prepare(
    'INSERT INTO admin_sessions (id, admin_id, label) VALUES (?, ?, ?)',
  ).run(jti, admin.id, label);

  // Keep only the newest `max` sessions for this admin (newest just inserted).
  const max = maxAdminSessions();
  const rows = db
    .prepare('SELECT id FROM admin_sessions WHERE admin_id = ? ORDER BY rowid DESC')
    .all(admin.id);
  if (rows.length > max) {
    const keep = rows.slice(0, max).map((r) => r.id);
    const placeholders = keep.map(() => '?').join(',');
    db.prepare(
      `DELETE FROM admin_sessions WHERE admin_id = ? AND id NOT IN (${placeholders})`,
    ).run(admin.id, ...keep);
  }

  const token = jwt.sign(
    { id: admin.id, username: admin.username, jti },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
  return token;
}

export function endSession(jti) {
  if (jti) db.prepare('DELETE FROM admin_sessions WHERE id = ?').run(jti);
}

/// Express middleware: valid token AND the session must still be active
/// (it may have been kicked by a newer login or by lowering the limit).
export function requireAdmin(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Token ausente.' });
  let decoded;
  try {
    decoded = jwt.verify(token, JWT_SECRET);
  } catch {
    return res.status(401).json({ error: 'Token inválido ou expirado.' });
  }
  const active = db.prepare('SELECT 1 FROM admin_sessions WHERE id = ?').get(decoded.jti);
  if (!active) {
    return res.status(401).json({
      error: 'Sessão encerrada (login em outro dispositivo ou limite reduzido).',
      code: 'SESSION_REVOKED',
    });
  }
  req.admin = decoded;
  next();
}
