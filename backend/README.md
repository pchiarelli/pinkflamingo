# Pink Flamingo API 🦩

Backend leve em **Express + SQLite (`node:sqlite`, nativo do Node 22+) + multer**.
Sem dependências nativas para compilar — `npm install` e roda.

## Rodando

```bash
cd backend
npm install
npm run seed     # cria/popula data.sqlite (448 produtos, 12 categorias, 16 kits, admin)
npm start        # http://localhost:3333
```

Admin padrão: **admin / pinkflamingo** (mude com `ADMIN_PASSWORD=... npm run seed`,
ou pelo botão **"Trocar senha"** no painel web).
Variáveis: `PORT`, `DB_PATH`, `JWT_SECRET`, `ADMIN_PASSWORD`.

## Painel web de admin

Abra **http://localhost:3333/admin** no navegador (a raiz `/` redireciona pra lá).
Login com o admin → abas **Produtos / Kits / Pedidos**: cadastrar/editar/excluir
produto com **upload de foto**, gerenciar kits e pedidos, e **trocar a senha**.

## Endpoints

Público (cliente):
- `GET  /api/categories` — categorias + contagem de itens
- `GET  /api/products?category=&q=` — catálogo (filtro e busca)
- `GET  /api/products/:id`
- `GET  /api/kits`
- `POST /api/orders` — cliente envia um pedido `{ customerName, eventDate, items[] }`

Admin (header `Authorization: Bearer <token>`):
- `POST /api/auth/login` → `{ token }`
- `POST /api/auth/change-password` — `{ currentPassword, newPassword }`
- `POST/PUT/DELETE /api/products` — `multipart/form-data` com campo `image` para foto
- `POST/DELETE /api/kits`
- `GET/PATCH/DELETE /api/orders` — listar/gerenciar pedidos

## Imagens

`POST /api/products` (ou `PUT`) com `multipart/form-data` e o campo **`image`**.
O arquivo é salvo em `uploads/` e servido em `/uploads/<arquivo>`; o banco guarda
só a URL. O app carrega a imagem por essa URL (com cache no dispositivo).
