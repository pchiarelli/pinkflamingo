import express from 'express';
import cors from 'cors';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { initSchema } from './db.js';
import { router } from './routes.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3333;

initSchema();

// Behind a reverse proxy (nginx/PaaS) so req.protocol reflects HTTPS — this
// makes the generated image URLs use https in production.
app.set('trust proxy', true);

app.use(cors());
app.use(express.json());
app.use((req, _res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});
app.use('/uploads', express.static(join(__dirname, '..', 'uploads')));
app.use('/admin', express.static(join(__dirname, '..', 'public')));

app.get('/', (_req, res) => res.redirect('/admin'));
app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/api', router);

// Multer / generic error handler
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Erro interno.' });
});

app.listen(PORT, () => {
  console.log(`🦩 Pink Flamingo API rodando em http://localhost:${PORT}`);
});
