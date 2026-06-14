# Deploy — Pink Flamingo

Três frentes: **(A)** publicar o backend, **(B)** apontar o app pra ele, **(C)** TestFlight.

---

## A. Backend em produção (Express + SQLite)

**Importante:** o backend guarda dados em **arquivo** (`data.sqlite`) e as fotos em
`uploads/`. Em produção isso precisa ficar num **disco persistente** (que sobrevive a
reinícios/deploys) e ser servido por **HTTPS** (o iOS exige).

### Setup de produção (VPS — nginx + pm2)

Hostname: **pinkflamingo.dyndns.ws** · porta interna: **3333** · pasta: **/home/pietro/pinkflamingo**

> Pré-requisitos: **Node ≥ 22.5** (usa `node:sqlite`; se for menor, instale via nvm) e
> porta 3333 livre (`ss -ltnp | grep :3333`).

```bash
# 1) do Mac: copiar o backend
rsync -av --exclude node_modules --exclude data.sqlite --exclude '.env' --exclude 'uploads/*' \
  ~/Projetos/pinkflamingo/backend/  pietro@pinkflamingo.dyndns.ws:/home/pietro/pinkflamingo/

# 2) no servidor
cd /home/pietro/pinkflamingo
mkdir -p data uploads
npm ci --omit=dev
cat > .env <<EOF
PORT=3333
DB_PATH=/home/pietro/pinkflamingo/data/data.sqlite
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_PASSWORD=pinkflamingo
PIX_NAME=Pink Flamingo
PIX_CITY=Sao Paulo
PIX_KEY=
EOF
node --env-file=.env src/seed.js          # só na 1ª vez (nunca com dados já no banco)

# 3) pm2
pm2 start "node --env-file=.env src/server.js" --name pinkflamingo-api
pm2 save
curl -s localhost:3333/api/health         # {"status":"ok"}
```

**nginx** (site novo, não mexe nos existentes):
```nginx
server {
  listen 80;
  server_name pinkflamingo.dyndns.ws;
  client_max_body_size 12M;
  location / {
    proxy_pass http://127.0.0.1:3333;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```
```bash
sudo ln -s /etc/nginx/sites-available/pinkflamingo /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d pinkflamingo.dyndns.ws    # TLS grátis
```

API: `https://pinkflamingo.dyndns.ws` · painel: `/admin`.

**Updates futuros:** novo rsync (mesmo comando) → `npm ci --omit=dev` → `pm2 restart pinkflamingo-api`. Nunca apague `data/` nem `uploads/`.

### Opção 2 — Plataforma gerenciada (Render / Railway / Fly.io)

Funciona, mas **exige um volume/disco persistente** para `data.sqlite` e `uploads/`
(no plano free da Render o disco é efêmero — os dados somem). Fly.io/Railway com
volume resolvem. Aponte `DB_PATH` para o volume.

### Variáveis de ambiente (ver `backend/.env.example`)
`PORT`, `DB_PATH` (disco persistente!), `JWT_SECRET` (troque!), `ADMIN_PASSWORD`, `PIX_*`.

---

## B. App apontando para a API de produção

Builde passando a URL pública (sem isso ele tenta `localhost`):

```bash
flutter build ipa --dart-define=API_BASE_URL=https://api.seudominio.com.br
```

(Para rodar em device de teste local: `flutter run --dart-define=API_BASE_URL=https://...`.)

---

## C. TestFlight (precisa da sua conta Apple)

Pré-requisitos (só você consegue fazer — exigem login Apple):
1. **Apple Developer Program** ativo ($99/ano) — https://developer.apple.com/account
2. No **App Store Connect**: criar o app com o bundle id **`com.pinkflamingo.app`**.

Passos:
```bash
open ios/Runner.xcworkspace      # Xcode: Signing & Capabilities → seu Team (automatic)
flutter build ipa --dart-define=API_BASE_URL=https://api.seudominio.com.br
```
- Abra **Xcode → Organizer** (ou o app **Transporter**) e **suba** o `.ipa`
  (`build/ios/ipa/*.ipa`) para o App Store Connect.
- Em **App Store Connect → TestFlight**: aguarde processar, adicione **testers internos**
  (instantâneo, até 100) ou **externos** (passa por uma revisão rápida da Apple).

Versão atual: **1.0.0 (build 1)** — em `pubspec.yaml` (`version: 1.0.0+1`).
A cada novo envio, suba o build: `1.0.0+2`, `1.0.0+3`, …
