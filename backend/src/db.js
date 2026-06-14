import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const dbPath = process.env.DB_PATH || join(__dirname, '..', 'data.sqlite');

export const db = new DatabaseSync(dbPath);
db.exec('PRAGMA journal_mode = WAL;');
db.exec('PRAGMA foreign_keys = ON;');

/// Run `fn` inside a transaction (node:sqlite has no built-in helper).
export function tx(fn) {
  db.exec('BEGIN');
  try {
    const result = fn();
    db.exec('COMMIT');
    return result;
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}

// ---- Central catalog version ----------------------------------------------
// A single integer that increases on EVERY product add/edit/delete. The app
// keeps the last version it saw; if the server's is higher, it pulls only the
// items that changed since then (the delta). Cheap to check, cheap to sync.

export function currentVersion() {
  return db.prepare("SELECT value FROM meta WHERE key = 'version'").get().value;
}

/// Increment and return the new central version.
export function bumpVersion() {
  db.prepare("UPDATE meta SET value = value + 1 WHERE key = 'version'").run();
  return currentVersion();
}

// ---- Generic settings (key/value text) ------------------------------------
export function getSetting(key, fallback = null) {
  const row = db.prepare('SELECT value FROM settings WHERE key = ?').get(key);
  return row ? row.value : fallback;
}

export function setSetting(key, value) {
  db.prepare(
    `INSERT INTO settings (key, value) VALUES (?, ?)
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
  ).run(key, value == null ? null : String(value));
}

export function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS meta (
      key   TEXT PRIMARY KEY,
      value INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS settings (
      key   TEXT PRIMARY KEY,
      value TEXT
    );

    CREATE TABLE IF NOT EXISTS categories (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT NOT NULL UNIQUE,
      description TEXT NOT NULL DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS products (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      name      TEXT NOT NULL,
      price     REAL NOT NULL DEFAULT 0,
      category  TEXT NOT NULL,
      image_url TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      rev        INTEGER NOT NULL DEFAULT 0,
      deleted_at TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

    CREATE TABLE IF NOT EXISTS kits (
      id   INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      image_url TEXT
    );

    CREATE TABLE IF NOT EXISTS orders (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_name TEXT NOT NULL DEFAULT '',
      event_date    TEXT,
      done          INTEGER NOT NULL DEFAULT 0,
      paid          INTEGER NOT NULL DEFAULT 0,
      created_at    TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS order_items (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id   INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
      product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
      name       TEXT NOT NULL,
      price      REAL NOT NULL DEFAULT 0,
      quantity   INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS admins (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      username      TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS admin_sessions (
      id         TEXT PRIMARY KEY,
      admin_id   INTEGER NOT NULL,
      label      TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);

  migrate();

  // Index on rev — created after migration so the column always exists.
  db.exec('CREATE INDEX IF NOT EXISTS idx_products_rev ON products(rev);');
}

/// Add columns / rows that pre-existing databases may be missing.
function migrate() {
  const cols = db.prepare('PRAGMA table_info(products)').all().map((c) => c.name);
  if (!cols.includes('rev')) {
    db.exec('ALTER TABLE products ADD COLUMN rev INTEGER NOT NULL DEFAULT 0');
  }
  if (!cols.includes('deleted_at')) {
    db.exec('ALTER TABLE products ADD COLUMN deleted_at TEXT');
  }
  const orderCols = db.prepare('PRAGMA table_info(orders)').all().map((c) => c.name);
  if (!orderCols.includes('paid')) {
    db.exec('ALTER TABLE orders ADD COLUMN paid INTEGER NOT NULL DEFAULT 0');
  }
  // Seed the central version counter once.
  const hasVersion = db.prepare("SELECT 1 FROM meta WHERE key = 'version'").get();
  if (!hasVersion) {
    db.prepare("INSERT INTO meta (key, value) VALUES ('version', 0)").run();
  }
}
