#!/usr/bin/env bash
set -euo pipefail

# setup_vps_complete.sh
# Script completo para configurar VPS desde cero:
# - Instala Docker si no está
# - Instala nginx + certbot
# - Configura nginx con server block
# - Obtiene certificados SSL automáticamente
# - Genera .env desde variables de entorno
# - Construye y levanta backend con Docker Compose

echo "=== Setup completo de VPS ==="

# Variables requeridas (deben venir de GitHub Actions secrets/env)
DOMAIN="${DOMAIN:-}"
EMAIL="${EMAIL:-}"
PORT="${PORT:-3002}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-arroz}"
DB_PASS="${DB_PASS:-}"
DB_NAME="${DB_NAME:-asistapp}"
JWT_SECRET="${JWT_SECRET:-}"
REPO_PATH="${REPO_PATH:-/opt/asistapp}"

# Validar variables críticas
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ] || [ -z "$DB_PASS" ] || [ -z "$JWT_SECRET" ]; then
  echo "ERROR: Faltan variables requeridas (DOMAIN, EMAIL, DB_PASS, JWT_SECRET)" >&2
  exit 1
fi

echo "✓ Variables validadas"

# 1. Instalar Docker si no está
if ! command -v docker >/dev/null 2>&1; then
  echo "→ Instalando Docker..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  echo "✓ Docker instalado"
else
  echo "✓ Docker ya está instalado"
fi

# 2. Instalar nginx + certbot
if ! command -v nginx >/dev/null 2>&1; then
  echo "→ Instalando nginx + certbot..."
  apt-get update
  apt-get install -y nginx certbot python3-certbot-nginx
  systemctl enable --now nginx
  echo "✓ Nginx + certbot instalados"
else
  echo "✓ Nginx ya está instalado"
fi

# 3. Configurar firewall UFW
if ! command -v ufw >/dev/null 2>&1; then
  echo "→ Instalando UFW..."
  apt-get update
  apt-get install -y ufw
fi

echo "→ Configurando firewall UFW..."
sudo ufw --force allow OpenSSH
sudo ufw --force allow 'Nginx Full'
sudo ufw --force enable
echo "✓ Firewall configurado"

# 4. Crear webroot para Let's Encrypt
echo "→ Preparando webroot para certificados..."
mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
chown -R www-data:www-data /var/www/letsencrypt
chmod -R 755 /var/www/letsencrypt
echo "✓ Webroot listo"

# 5. Configurar nginx server block (HTTP primero, para obtener certificado)
echo "→ Configurando nginx..."
cat > /etc/nginx/sites-available/asistapp <<NGINX_HTTP
server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN} www.${DOMAIN};
  
  location /.well-known/acme-challenge/ {
    root /var/www/letsencrypt;
  }
  
  location / {
    proxy_pass http://127.0.0.1:${PORT};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
NGINX_HTTP

ln -sf /etc/nginx/sites-available/asistapp /etc/nginx/sites-enabled/asistapp
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
echo "✓ Nginx configurado (HTTP)"

# 6. Obtener certificados SSL
if [ ! -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
  echo "→ Obteniendo certificados SSL..."
  certbot certonly --webroot -w /var/www/letsencrypt \
    -d "${DOMAIN}" -d "www.${DOMAIN}" \
    -m "${EMAIL}" --agree-tos --non-interactive --no-eff-email
  echo "✓ Certificados obtenidos"
else
  echo "✓ Certificados ya existen"
fi

# 7. Actualizar nginx a HTTPS
echo "→ Configurando HTTPS..."
cat > /etc/nginx/sites-available/asistapp <<NGINX_HTTPS
server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN} www.${DOMAIN};
  
  location /.well-known/acme-challenge/ {
    root /var/www/letsencrypt;
  }
  
  return 301 https://\$server_name\$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name ${DOMAIN} www.${DOMAIN};
  
  ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;
  
  location / {
    proxy_pass http://127.0.0.1:${PORT};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
NGINX_HTTPS

nginx -t && systemctl reload nginx
echo "✓ HTTPS configurado"

# 8. Generar .env del backend
echo "→ Generando .env..."
DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?schema=public"

cat > "${REPO_PATH}/backend/.env" <<ENV
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=24h
PORT=${PORT}
HOST=0.0.0.0
NODE_ENV=production
LOG_LEVEL=info
API_BASE_URL=https://${DOMAIN}
ENV

cp "${REPO_PATH}/backend/.env" "${REPO_PATH}/.env"
chmod 600 "${REPO_PATH}/backend/.env" "${REPO_PATH}/.env"
echo "✓ .env generado"

# 9. Construir y levantar backend
echo "→ Construyendo y levantando backend..."
cd "${REPO_PATH}"
docker compose -f docker-compose.prod.yml down --remove-orphans || true
docker compose -f docker-compose.prod.yml up -d --build

echo "→ Esperando a que el backend inicie..."
sleep 10

# 10. Verificar que todo funciona
echo ""
echo "=== Verificación final ==="
echo "→ Contenedores Docker:"
docker ps --filter "name=backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "→ Test HTTP → HTTPS redirect:"
curl -sI http://${DOMAIN} | head -n 2

echo ""
echo "→ Test HTTPS:"
curl -sI https://${DOMAIN} | head -n 2

echo ""
echo "✅ Setup completado exitosamente"
echo ""
echo "📝 Resumen:"
echo "   - Backend: https://${DOMAIN}"
echo "   - Certificados: /etc/letsencrypt/live/${DOMAIN}/"
echo "   - Renovación automática: habilitada (certbot timer)"
echo "   - Logs backend: docker compose -f ${REPO_PATH}/docker-compose.prod.yml logs -f"
echo ""
