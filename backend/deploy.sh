#!/usr/bin/env bash
#
# Deploy do backend Pink Flamingo (idempotente — use no 1º deploy e nos updates).
#
#   1º deploy (configura nginx + HTTPS também):   ./deploy.sh --nginx
#   updates (depois de `git pull`):                ./deploy.sh
#
# Não sobrescreve .env nem o banco existente. Roda o app como o usuário atual
# (pm2); só os passos de nginx/certbot usam sudo (quando passar --nginx).

set -euo pipefail

# ===== Config =====
APP_NAME="pinkflamingo-api"
HOSTNAME="pinkflamingo.dyndns.ws"
PORT="3333"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # = pasta backend/
DATA_DIR="$APP_DIR/data"
ENV_FILE="$APP_DIR/.env"

cd "$APP_DIR"
echo "==> Pink Flamingo — deploy em $APP_DIR"

# ===== 1. Node >= 22.5 (necessário p/ node:sqlite) =====
echo "==> Node: $(node -v 2>/dev/null || echo 'NÃO ENCONTRADO')"
node -e 'const [a,b]=process.versions.node.split(".").map(Number); if(a<22||(a===22&&b<5)){console.error("ERRO: precisa de Node >= 22.5 (node:sqlite). Rode: nvm install 22 && nvm use 22"); process.exit(1);}'

# ===== 2. Dependências =====
echo "==> npm ci"
npm ci --omit=dev

# ===== 3. Pastas persistentes =====
mkdir -p "$DATA_DIR" "$APP_DIR/uploads"

# ===== 4. .env (cria se não existir; nunca sobrescreve) =====
if [ ! -f "$ENV_FILE" ]; then
  echo "==> Criando .env (com JWT_SECRET aleatório)"
  cat > "$ENV_FILE" <<EOF
PORT=$PORT
DB_PATH=$DATA_DIR/data.sqlite
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_PASSWORD=pinkflamingo
PIX_NAME=Pink Flamingo
PIX_CITY=Sao Paulo
PIX_KEY=
EOF
else
  echo "==> .env já existe — mantido"
fi

# ===== 5. Seed (só na 1ª vez) =====
DB_FILE="$(grep -E '^DB_PATH=' "$ENV_FILE" | cut -d= -f2-)"
if [ ! -f "$DB_FILE" ]; then
  echo "==> Seed inicial do banco"
  node --no-warnings --env-file="$ENV_FILE" src/seed.js
else
  echo "==> Banco já existe — pulando seed (não sobrescreve dados)"
fi

# ===== 6. pm2 (start na 1ª vez, restart nas próximas) =====
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  echo "==> pm2 restart $APP_NAME"
  pm2 restart "$APP_NAME" --update-env
else
  echo "==> pm2 start $APP_NAME"
  pm2 start "node --no-warnings --env-file=$ENV_FILE src/server.js" --name "$APP_NAME"
fi
pm2 save >/dev/null

# ===== 7. Healthcheck local =====
sleep 1
echo -n "==> Healthcheck local: "
if curl -fsS "http://localhost:$PORT/api/health" >/dev/null; then
  echo "OK"
else
  echo "FALHOU — veja os logs: pm2 logs $APP_NAME"
fi

# ===== 8. nginx + HTTPS (opcional, normalmente só na 1ª vez): --nginx =====
if [ "${1:-}" = "--nginx" ]; then
  echo "==> Configurando nginx + certbot (sudo)"
  SITE=/etc/nginx/sites-available/pinkflamingo
  sudo tee "$SITE" >/dev/null <<EOF
server {
    listen 80;
    server_name $HOSTNAME;
    client_max_body_size 12M;
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
  sudo ln -sf "$SITE" /etc/nginx/sites-enabled/pinkflamingo
  sudo nginx -t && sudo systemctl reload nginx
  sudo certbot --nginx -d "$HOSTNAME" || echo "(certbot: rode manualmente se precisar de interação)"
fi

echo ""
echo "==> Pronto!"
echo "    API:    https://$HOSTNAME/api/health"
echo "    Painel: https://$HOSTNAME/admin   (admin / pinkflamingo — troque a senha)"
