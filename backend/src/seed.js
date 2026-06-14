import bcrypt from 'bcryptjs';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { db, initSchema, tx } from './db.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

const CATEGORIES = [
  ['Bandejas', 'Bandejas retangulares, sextavadas e orgânicas.'],
  ['Boleiras', 'Boleiras pequenas e grandes.'],
  ['Bolos fakes', 'Bolos fakes de 2 a 4 andares.'],
  ['Bonecos', 'Bonecos de vinil, de pelúcia e de feltro.'],
  ['Displays', 'Displays em mdf.'],
  ['Flores artificiais', 'Folhagem e flores em geral.'],
  ['Itens decorativos', 'Bonecos, displays, quadros, velas, luminárias e muito mais!'],
  ['Leds', 'Letras e números de led.'],
  ['Mesas', 'Mesas retangulares, cones, cilindros e de ferro.'],
  ['Painéis', 'Capas de painel redondo, quadrado e retangular.'],
  ['Tapetes', 'Tapetes e mantas.'],
  ['Vasos', 'Vasos pequenos, médios e de cerâmica.'],
];

const KITS = [
  'Barbie', 'Bolofofos', 'Call of Duty', 'Casa Mágica da Gabby',
  'Champions League', 'Cinderela', 'Descendentes', 'Dragon Ball', 'Frozen',
  'Galinha Pintadinha', 'Harry Potter', 'Minnie', 'Patrulha Canina',
  'Princesas', 'Stitch', 'Unicórnio',
];

function run() {
  initSchema();

  const products = JSON.parse(
    readFileSync(join(__dirname, 'seed-products.json'), 'utf8'),
  );

  tx(() => {
    // Categories
    const insCat = db.prepare(
      'INSERT OR IGNORE INTO categories (name, description) VALUES (?, ?)',
    );
    for (const [name, desc] of CATEGORIES) insCat.run(name, desc);

    // Products — only seed once (skip if already populated)
    const count = db.prepare('SELECT COUNT(*) AS n FROM products').get().n;
    if (count === 0) {
      const insProd = db.prepare(
        'INSERT INTO products (name, price, category) VALUES (?, ?, ?)',
      );
      for (const p of products) insProd.run(p.name, p.price, p.category);
    }

    // Kits
    const insKit = db.prepare('INSERT OR IGNORE INTO kits (name) VALUES (?)');
    for (const k of KITS) insKit.run(k);

    // Default admin
    const admin = db.prepare('SELECT id FROM admins WHERE username = ?').get('admin');
    if (!admin) {
      const hash = bcrypt.hashSync(process.env.ADMIN_PASSWORD || 'pinkflamingo', 10);
      db.prepare('INSERT INTO admins (username, password_hash) VALUES (?, ?)')
        .run('admin', hash);
    }
  });

  const n = db.prepare('SELECT COUNT(*) AS n FROM products').get().n;
  const c = db.prepare('SELECT COUNT(*) AS n FROM categories').get().n;
  const k = db.prepare('SELECT COUNT(*) AS n FROM kits').get().n;
  console.log(`Seed OK → ${n} produtos, ${c} categorias, ${k} kits.`);
  console.log('Admin: usuário "admin" / senha "' + (process.env.ADMIN_PASSWORD || 'pinkflamingo') + '"');
}

run();
