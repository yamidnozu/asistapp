#!/bin/bash
#
# Script de despliegue inicial en un VPS nuevo
# Este script configura TODO lo necesario desde cero
#
# Uso: 
#   1. Sube este script al servidor: scp deploy-fresh-vps.sh root@IP:/root/
#   2. SSH al servidor: ssh root@IP
#   3. Ejecuta: bash deploy-fresh-vps.sh
#

set -e

echo "🚀 Script de Despliegue Inicial - AsistApp"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables configurables
REPO_URL="https://github.com/yamidnozu/asistapp.git"
INSTALL_DIR="/opt/asistapp"
DOMAIN="${DOMAIN:-srv974201.hstgr.cloud}"
EMAIL="${EMAIL:-admin@example.com}"

echo -e "${BLUE}📋 Configuración:${NC}"
echo "   - Repositorio: $REPO_URL"
echo "   - Directorio: $INSTALL_DIR"
echo "   - Dominio: $DOMAIN"
echo ""

# Verificar que estamos como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Este script debe ejecutarse como root${NC}"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo -e "${GREEN}✅ Ejecutando como root${NC}"
echo ""

# ========================================
# 1. ACTUALIZAR SISTEMA
# ========================================
echo -e "${YELLOW}📦 Paso 1: Actualizando sistema...${NC}"
apt update
apt upgrade -y

# ========================================
# 2. INSTALAR DOCKER
# ========================================
echo ""
echo -e "${YELLOW}🐳 Paso 2: Instalando Docker...${NC}"

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo -e "${GREEN}✅ Docker instalado${NC}"
else
    echo -e "${GREEN}✅ Docker ya está instalado${NC}"
fi

# Iniciar Docker
systemctl start docker
systemctl enable docker

# ========================================
# 3. INSTALAR NGINX Y CERTBOT
# ========================================
echo ""
echo -e "${YELLOW}🌐 Paso 3: Instalando Nginx y Certbot...${NC}"

if ! command -v nginx &> /dev/null; then
    apt install -y nginx certbot python3-certbot-nginx
    echo -e "${GREEN}✅ Nginx y Certbot instalados${NC}"
else
    echo -e "${GREEN}✅ Nginx ya está instalado${NC}"
fi

# ========================================
# 4. CONFIGURAR FIREWALL
# ========================================
echo ""
echo -e "${YELLOW}🔒 Paso 4: Configurando firewall...${NC}"

if ! command -v ufw &> /dev/null; then
    apt install -y ufw
fi

ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
echo -e "${GREEN}✅ Firewall configurado${NC}"

# ========================================
# 5. CLONAR REPOSITORIO
# ========================================
echo ""
echo -e "${YELLOW}📥 Paso 5: Clonando repositorio...${NC}"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  El directorio $INSTALL_DIR ya existe${NC}"
    read -p "¿Quieres eliminarlo y clonar de nuevo? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        rm -rf "$INSTALL_DIR"
    else
        echo -e "${RED}Abortado${NC}"
        exit 1
    fi
fi

mkdir -p $(dirname "$INSTALL_DIR")
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${GREEN}✅ Repositorio clonado${NC}"

# ========================================
# 6. CONFIGURAR VARIABLES DE ENTORNO
# ========================================
echo ""
echo -e "${YELLOW}⚙️  Paso 6: Configurando variables de entorno...${NC}"

if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Ya existe un archivo .env${NC}"
    read -p "¿Quieres sobrescribirlo? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Usando .env existente${NC}"
    else
        rm .env
    fi
fi

if [ ! -f ".env" ]; then
    # Generar credenciales seguras
    DB_PASS_GENERATED=$(openssl rand -hex 16)
    JWT_SECRET_GENERATED=$(openssl rand -hex 32)
    
    cat > .env <<EOF
# Generado automáticamente por deploy-fresh-vps.sh
# Fecha: $(date)

# BASE DE DATOS
DB_USER=asistapp_user
DB_PASS=${DB_PASS_GENERATED}
DB_NAME=asistapp_prod
DB_PORT=5432

# SEGURIDAD
JWT_SECRET=${JWT_SECRET_GENERATED}
JWT_EXPIRES_IN=24h

# SERVIDOR
HOST=0.0.0.0
PORT=3000

# DOMINIO
API_BASE_URL=https://${DOMAIN}

# ENTORNO
NODE_ENV=production
LOG_LEVEL=info
EOF

    chmod 600 .env
    
    echo -e "${GREEN}✅ Archivo .env creado con credenciales generadas automáticamente${NC}"
    echo ""
    echo -e "${BLUE}📝 Credenciales generadas:${NC}"
    echo "   DB_USER: asistapp_user"
    echo "   DB_PASS: ${DB_PASS_GENERATED}"
    echo "   JWT_SECRET: ${JWT_SECRET_GENERATED}"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Guarda estas credenciales en un lugar seguro${NC}"
    echo ""
    read -p "Presiona ENTER para continuar..."
fi

# ========================================
# 7. CONFIGURAR NGINX
# ========================================
echo ""
echo -e "${YELLOW}🌐 Paso 7: Configurando Nginx...${NC}"

# Crear configuración de nginx
cat > /etc/nginx/sites-available/asistapp <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Habilitar sitio
ln -sf /etc/nginx/sites-available/asistapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Probar configuración
nginx -t

# Reiniciar nginx
systemctl restart nginx

echo -e "${GREEN}✅ Nginx configurado${NC}"

# ========================================
# 8. OBTENER CERTIFICADO SSL
# ========================================
echo ""
echo -e "${YELLOW}🔒 Paso 8: Obteniendo certificado SSL...${NC}"

# Verificar que el dominio resuelve
echo "   Verificando que $DOMAIN resuelve a esta IP..."
CURRENT_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

if [ "$CURRENT_IP" != "$DOMAIN_IP" ]; then
    echo -e "${YELLOW}⚠️  ADVERTENCIA: El dominio $DOMAIN no apunta a esta IP ($CURRENT_IP)${NC}"
    echo "   - IP del servidor: $CURRENT_IP"
    echo "   - IP del dominio: $DOMAIN_IP"
    echo ""
    read -p "¿Quieres continuar sin SSL? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${RED}Abortado${NC}"
        exit 1
    fi
else
    # Obtener certificado
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect || {
        echo -e "${YELLOW}⚠️  No se pudo obtener el certificado SSL automáticamente${NC}"
        echo "   La aplicación funcionará con HTTP por ahora"
        echo "   Puedes intentar obtener el certificado manualmente con:"
        echo "   certbot --nginx -d $DOMAIN"
    }
fi

# ========================================
# 9. LEVANTAR SERVICIOS
# ========================================
echo ""
echo -e "${YELLOW}🚀 Paso 9: Levantando servicios con Docker...${NC}"

# Cargar variables
export $(cat .env | grep -v '^#' | xargs)

# Levantar servicios
docker compose -f docker-compose.prod.yml up -d --build

echo -e "${GREEN}✅ Servicios iniciados${NC}"

# ========================================
# 10. ESPERAR Y VERIFICAR
# ========================================
echo ""
echo -e "${YELLOW}⏳ Paso 10: Esperando a que los servicios estén listos...${NC}"
sleep 30

echo ""
echo "🔍 Estado de los contenedores:"
docker compose -f docker-compose.prod.yml ps

echo ""
echo "📋 Logs recientes del backend:"
docker compose -f docker-compose.prod.yml logs --tail 20 app

# ========================================
# RESUMEN FINAL
# ========================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ ¡Despliegue completado exitosamente!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 Información del despliegue:${NC}"
echo "   - URL: https://${DOMAIN}"
echo "   - Directorio: ${INSTALL_DIR}"
echo "   - Backend: http://localhost:3002"
echo ""
echo -e "${BLUE}🔧 Comandos útiles:${NC}"
echo "   - Ver logs: cd ${INSTALL_DIR} && docker compose -f docker-compose.prod.yml logs -f"
echo "   - Reiniciar: cd ${INSTALL_DIR} && docker compose -f docker-compose.prod.yml restart"
echo "   - Detener: cd ${INSTALL_DIR} && docker compose -f docker-compose.prod.yml down"
echo "   - Actualizar: cd ${INSTALL_DIR} && git pull && docker compose -f docker-compose.prod.yml up -d --build"
echo ""
echo -e "${BLUE}🔍 Verificar:${NC}"
echo "   curl http://localhost:3002/health"
echo "   curl https://${DOMAIN}/health"
echo ""
echo -e "${YELLOW}⚠️  No olvides guardar las credenciales que se mostraron anteriormente${NC}"
echo ""
