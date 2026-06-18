import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import { db, getSetting } from './db.js';

export const JWT_SECRET = process.env.JWT_SECRET || 'pink-flamingo-dev-secret';

export function maxAdminSessions() {
  const n = parseInt(getSetting('admin_max_sessions', '1'), 10);
  return Number.isFinite(n) && n > 0 ? n : 1;
}

/// Create a new admin session (jti) and return a signed token carrying it.
///
/// Limite de sessões POR TIPO DE CLIENTE (`label`):
///   • 'app'  → apenas 1 sessão. Um novo login no app derruba o anterior,
///              garantindo "1 acesso admin no app".
///   • 'web'  → ilimitado. Vários navegadores/abas ao mesmo tempo, e NUNCA
///              são derrubados pelo login do app (eram a causa do 401 no site).
export function startSession(admin, client = 'web') {
  const label = client === 'app' ? 'app' : 'web';
  const jti = randomUUID();
  db.prepare(
    'INSERT INTO admin_sessions (id, admin_id, label) VALUES (?, ?, ?)',
  ).run(jti, admin.id, label);

  if (label === 'app') {
    // Mantém só a sessão de app recém-criada; remove sessões de app antigas.
    db.prepare(
      "DELETE FROM admin_sessions WHERE admin_id = ? AND label = 'app' AND id <> ?",
    ).run(admin.id, jti);
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
