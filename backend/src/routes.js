import { Router } from 'express';
import bcrypt from 'bcryptjs';
import multer from 'multer';
import { extname, join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { db, tx, bumpVersion, currentVersion, getSetting, setSetting } from './db.js';
import {
  requireAdmin,
  startSession,
  endSession,
  maxAdminSessions,
} from './auth.js';
import { buildPixPayload } from './pix.js';

// Recebedor Pix: salvo no banco (editável pelo painel), com fallback p/ env.
function pixConfig() {
  return {
    key: getSetting('pix_key', process.env.PIX_KEY || ''),
    name: getSetting('pix_name', process.env.PIX_NAME || 'Pink Flamingo'),
    city: getSetting('pix_city', process.env.PIX_CITY || 'Sao Paulo'),
  };
}

const __dirname = dirname(fileURLToPath(import.meta.url));
export const router = Router();

// ---- Image upload (multer → disk) -----------------------------------------
const storage = multer.diskStorage({
  destination: join(__dirname, '..', 'uploads'),
  filename: (_req, file, cb) => {
    const safe = file.originalname.toLowerCase().replace(/[^a-z0-9.]+/g, '-');
    cb(null, `${Date.now()}-${safe}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    // Accept by mimetype, but also fall back to the file extension: some
    // clients send images as application/octet-stream when they don't set
    // an explicit content type, and we don't want to silently drop those.
    const okMime = /image\/(jpe?g|png|webp|gif)/.test(file.mimetype);
    const okExt = /\.(jpe?g|png|webp|gif)$/i.test(file.originalname);
    cb(null, okMime || okExt);
  },
});

function imageUrl(req, filename) {
  return `${req.protocol}://${req.get('host')}/uploads/${filename}`;
}

// ---- Auth ------------------------------------------------------------------
router.post('/auth/login', (req, res) => {
  const { username, password } = req.body || {};
  const admin = db
    .prepare('SELECT * FROM admins WHERE username = ?')
    .get(username || '');
  if (!admin || !bcrypt.compareSync(password || '', admin.password_hash)) {
    return res.status(401).json({ error: 'Usuário ou senha inválidos.' });
  }
  res.json({ token: startSession(admin), username: admin.username });
});

router.post('/auth/logout', requireAdmin, (req, res) => {
  endSession(req.admin.jti);
  res.json({ ok: true });
});

router.post('/auth/change-password', requireAdmin, (req, res) => {
  const { currentPassword, newPassword } = req.body || {};
  if (!newPassword || newPassword.length < 4) {
    return res.status(400).json({ error: 'A nova senha deve ter ao menos 4 caracteres.' });
  }
  const admin = db.prepare('SELECT * FROM admins WHERE id = ?').get(req.admin.id);
  if (!admin || !bcrypt.compareSync(currentPassword || '', admin.password_hash)) {
    return res.status(401).json({ error: 'Senha atual incorreta.' });
  }
  const hash = bcrypt.hashSync(newPassword, 10);
  db.prepare('UPDATE admins SET password_hash = ? WHERE id = ?').run(hash, admin.id);
  res.json({ ok: true });
});

// Atualiza a conta admin (usuário e/ou senha). Exige a senha atual.
// Há sempre UMA conta admin — não existe rota para criar outras.
router.put('/auth/account', requireAdmin, (req, res) => {
  const { currentPassword, username, newPassword } = req.body || {};
  const admin = db.prepare('SELECT * FROM admins WHERE id = ?').get(req.admin.id);
  if (!admin || !bcrypt.compareSync(currentPassword || '', admin.password_hash)) {
    return res.status(401).json({ error: 'Senha atual incorreta.' });
  }
  let user = admin.username;
  if (username && username.trim() && username.trim() !== admin.username) {
    user = username.trim();
    const exists = db
      .prepare('SELECT 1 FROM admins WHERE username = ? AND id <> ?')
      .get(user, admin.id);
    if (exists) return res.status(409).json({ error: 'Esse usuário já existe.' });
  }
  let hash = admin.password_hash;
  if (newPassword) {
    if (newPassword.length < 4) {
      return res.status(400).json({ error: 'A nova senha deve ter ao menos 4 caracteres.' });
    }
    hash = bcrypt.hashSync(newPassword, 10);
  }
  db.prepare('UPDATE admins SET username = ?, password_hash = ? WHERE id = ?')
    .run(user, hash, admin.id);

  // Optional: max simultaneous admin sessions.
  if (req.body.maxSessions != null) {
    const n = Math.max(1, parseInt(req.body.maxSessions, 10) || 1);
    setSetting('admin_max_sessions', n);
    // Lowering the limit kicks the oldest sessions (keep newest n).
    const rows = db
      .prepare('SELECT id FROM admin_sessions WHERE admin_id = ? ORDER BY rowid DESC')
      .all(admin.id);
    if (rows.length > n) {
      const keep = rows.slice(0, n).map((r) => r.id);
      const ph = keep.map(() => '?').join(',');
      db.prepare(
        `DELETE FROM admin_sessions WHERE admin_id = ? AND id NOT IN (${ph})`,
      ).run(admin.id, ...keep);
    }
  }
  res.json({ ok: true, username: user });
});

// Quem é o admin logado + config de sessões (para o formulário de conta).
router.get('/auth/me', requireAdmin, (req, res) => {
  const admin = db.prepare('SELECT username FROM admins WHERE id = ?').get(req.admin.id);
  const active = db
    .prepare('SELECT COUNT(*) AS n FROM admin_sessions WHERE admin_id = ?')
    .get(req.admin.id).n;
  res.json({
    username: admin ? admin.username : null,
    maxSessions: maxAdminSessions(),
    activeSessions: active,
  });
});

// ---- Configuração do Pix (admin) -------------------------------------------
router.get('/pix-config', requireAdmin, (_req, res) => {
  res.json(pixConfig());
});

router.put('/pix-config', requireAdmin, (req, res) => {
  const { key, name, city } = req.body || {};
  if (key != null) setSetting('pix_key', String(key).trim());
  if (name != null) setSetting('pix_name', String(name).trim());
  if (city != null) setSetting('pix_city', String(city).trim());
  res.json(pixConfig());
});

// ---- Categories ------------------------------------------------------------
router.get('/categories', (_req, res) => {
  const rows = db
    .prepare(
      `SELECT c.name, c.description,
              (SELECT COUNT(*) FROM products p
                WHERE p.category = c.name AND p.deleted_at IS NULL) AS count
       FROM categories c ORDER BY c.name`,
    )
    .all();
  res.json(rows);
});

// ---- Products --------------------------------------------------------------
router.get('/products', (req, res) => {
  const { category, q } = req.query;
  const where = ['deleted_at IS NULL'];
  const params = {};
  if (category) {
    where.push('category = @category');
    params.category = category;
  }
  if (q) {
    where.push('(LOWER(name) LIKE @q OR LOWER(category) LIKE @q)');
    params.q = `%${String(q).toLowerCase()}%`;
  }
  const sql =
    'SELECT id, name, price, category, image_url FROM products' +
    ` WHERE ${where.join(' AND ')}` +
    ' ORDER BY name';
  res.json(db.prepare(sql).all(params));
});

// Cheapest possible check: the central catalog version. The app compares this
// single integer to the one it already has to decide whether to sync.
router.get('/version', (_req, res) => {
  res.json({ version: currentVersion() });
});

// Delta sync: only products changed (or deleted) since the given version.
// `since` omitted → full snapshot (first load). Always returns the current
// central `version` so the client can store it as its new cursor.
router.get('/sync', (req, res) => {
  const since = req.query.since;
  const version = currentVersion();
  let rows;
  if (since != null && since !== '') {
    rows = db
      .prepare(
        `SELECT id, name, price, category, image_url, deleted_at
           FROM products WHERE rev > ?`,
      )
      .all(Number(since));
  } else {
    rows = db
      .prepare(
        `SELECT id, name, price, category, image_url, deleted_at
           FROM products WHERE deleted_at IS NULL`,
      )
      .all();
  }
  const products = rows.map((r) => ({
    id: r.id,
    name: r.name,
    price: r.price,
    category: r.category,
    image_url: r.image_url,
    deleted: r.deleted_at != null,
  }));
  res.json({ version, products });
});

router.get('/products/:id', (req, res) => {
  const row = db
    .prepare(
      'SELECT id, name, price, category, image_url FROM products WHERE id = ? AND deleted_at IS NULL',
    )
    .get(req.params.id);
  if (!row) return res.status(404).json({ error: 'Produto não encontrado.' });
  res.json(row);
});

router.post('/products', requireAdmin, upload.single('image'), (req, res) => {
  const { name, price, category } = req.body;
  if (!name || !category) {
    return res.status(400).json({ error: 'name e category são obrigatórios.' });
  }
  const url = req.file ? imageUrl(req, req.file.filename) : null;
  const id = tx(() => {
    const version = bumpVersion();
    const info = db
      .prepare(
        'INSERT INTO products (name, price, category, image_url, rev) VALUES (?, ?, ?, ?, ?)',
      )
      .run(name, Number(price) || 0, category, url, version);
    return info.lastInsertRowid;
  });
  res.status(201).json(
    db.prepare('SELECT id, name, price, category, image_url FROM products WHERE id = ?').get(id),
  );
});

router.put('/products/:id', requireAdmin, upload.single('image'), (req, res) => {
  const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Produto não encontrado.' });
  const name = req.body.name ?? existing.name;
  const price = req.body.price != null ? Number(req.body.price) : existing.price;
  const category = req.body.category ?? existing.category;
  const url = req.file ? imageUrl(req, req.file.filename) : existing.image_url;
  tx(() => {
    const version = bumpVersion();
    db.prepare('UPDATE products SET name=?, price=?, category=?, image_url=?, rev=? WHERE id=?')
      .run(name, price, category, url, version, req.params.id);
  });
  res.json(
    db.prepare('SELECT id, name, price, category, image_url FROM products WHERE id = ?')
      .get(req.params.id),
  );
});

// Soft-delete so the change propagates through /sync (bumps the version).
router.delete('/products/:id', requireAdmin, (req, res) => {
  tx(() => {
    const version = bumpVersion();
    db.prepare("UPDATE products SET deleted_at=datetime('now'), rev=? WHERE id=?")
      .run(version, req.params.id);
  });
  res.status(204).end();
});

// ---- Kits ------------------------------------------------------------------
router.get('/kits', (_req, res) => {
  res.json(db.prepare('SELECT id, name, image_url FROM kits ORDER BY name').all());
});

router.post('/kits', requireAdmin, upload.single('image'), (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'name é obrigatório.' });
  const url = req.file ? imageUrl(req, req.file.filename) : null;
  const info = db
    .prepare('INSERT INTO kits (name, image_url) VALUES (?, ?)')
    .run(name, url);
  res.status(201).json(
    db.prepare('SELECT id, name, image_url FROM kits WHERE id = ?').get(info.lastInsertRowid),
  );
});

router.delete('/kits/:id', requireAdmin, (req, res) => {
  db.prepare('DELETE FROM kits WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

// ---- Orders ----------------------------------------------------------------
// Customers can create an order (public). Listing/managing is admin-only.
router.post('/orders', (req, res) => {
  const { customerName = '', eventDate = null, items = [] } = req.body || {};
  const id = tx(() => {
    const info = db
      .prepare('INSERT INTO orders (customer_name, event_date) VALUES (?, ?)')
      .run(customerName, eventDate);
    const orderId = info.lastInsertRowid;
    const insItem = db.prepare(
      `INSERT INTO order_items (order_id, product_id, name, price, quantity)
       VALUES (?, ?, ?, ?, ?)`,
    );
    const findProduct = db.prepare(
      'SELECT name, price FROM products WHERE id = ? AND deleted_at IS NULL',
    );
    for (const it of items) {
      // Authoritative pricing: if we know the product, ALWAYS use the current
      // DB price/name — never trust the value sent by the client. This keeps
      // the recorded order correct even if the app showed a stale price.
      const current = it.productId != null ? findProduct.get(it.productId) : null;
      const name = current ? current.name : it.name;
      const price = current ? current.price : (Number(it.price) || 0);
      insItem.run(orderId, it.productId ?? null, name, price,
        Number(it.quantity) || 1);
    }
    return orderId;
  });
  res.status(201).json(getOrder(id));
});

router.get('/orders', requireAdmin, (_req, res) => {
  const orders = db.prepare('SELECT * FROM orders ORDER BY created_at DESC').all();
  res.json(orders.map((o) => withItems(o)));
});

router.get('/orders/:id', requireAdmin, (req, res) => {
  const order = getOrder(req.params.id);
  if (!order) return res.status(404).json({ error: 'Pedido não encontrado.' });
  res.json(order);
});

router.patch('/orders/:id', requireAdmin, (req, res) => {
  const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(req.params.id);
  if (!order) return res.status(404).json({ error: 'Pedido não encontrado.' });
  const done = req.body.done != null ? (req.body.done ? 1 : 0) : order.done;
  const paid = req.body.paid != null ? (req.body.paid ? 1 : 0) : order.paid;
  const customerName = req.body.customerName ?? order.customer_name;
  const eventDate = req.body.eventDate ?? order.event_date;
  db.prepare('UPDATE orders SET done=?, paid=?, customer_name=?, event_date=? WHERE id=?')
    .run(done, paid, customerName, eventDate, req.params.id);
  res.json(getOrder(req.params.id));
});

router.delete('/orders/:id', requireAdmin, (req, res) => {
  db.prepare('DELETE FROM orders WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

function withItems(order) {
  const items = db
    .prepare('SELECT id, product_id, name, price, quantity FROM order_items WHERE order_id = ?')
    .all(order.id);
  const total = items.reduce((s, i) => s + i.price * i.quantity, 0);
  return {
    id: order.id,
    customerName: order.customer_name,
    eventDate: order.event_date,
    done: !!order.done,
    paid: !!order.paid,
    createdAt: order.created_at,
    items,
    total,
    // Código Pix "copia e cola" já com o valor do pedido (preço autoritativo).
    pix: pixCode(total, order.id),
  };
}

/// Monta o código Pix se houver chave configurada e valor > 0.
function pixCode(amount, orderId) {
  const cfg = pixConfig();
  if (!cfg.key || amount <= 0) return null;
  return buildPixPayload({ ...cfg, amount, txid: String(orderId) });
}

function getOrder(id) {
  const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(id);
  return order ? withItems(order) : null;
}
