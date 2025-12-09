#!/bin/bash
# Script de validación completa para producción
# Uso: bash validate_production.sh

echo "=========================================="
echo "🔍 VALIDACIÓN DE PRODUCCIÓN - AsistApp"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Verificar archivo .env
echo "1️⃣  Verificando archivo .env..."
if [ -f /opt/asistapp/.env ]; then
    success "Archivo .env existe"
    echo ""
    echo "Variables configuradas:"
    grep -E '^[A-Z_]+=.+' /opt/asistapp/.env | cut -d= -f1 | sort
    echo ""
    
    # Verificar variables críticas
    echo "Variables críticas:"
    for var in DB_USER DB_PASS DB_NAME JWT_SECRET WHATSAPP_API_TOKEN FIREBASE_PROJECT_ID; do
        if grep -q "^${var}=" /opt/asistapp/.env && [ -n "$(grep "^${var}=" /opt/asistapp/.env | cut -d= -f2)" ]; then
            success "$var configurado"
        else
            error "$var NO configurado o vacío"
        fi
    done
else
    error "Archivo .env NO existe"
fi

echo ""
echo "2️⃣  Verificando Firebase Service Account..."
if [ -f /opt/asistapp/firebase-service-account.json ]; then
    success "firebase-service-account.json existe"
    
    # Verificar permisos
    PERMS=$(stat -c %a /opt/asistapp/firebase-service-account.json 2>/dev/null || stat -f %A /opt/asistapp/firebase-service-account.json 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        success "Permisos correctos (600)"
    else
        warning "Permisos: $PERMS (debería ser 600)"
    fi
    
    # Verificar contenido JSON
    if jq empty /opt/asistapp/firebase-service-account.json 2>/dev/null; then
        success "JSON válido"
        PROJECT_ID=$(jq -r '.project_id' /opt/asistapp/firebase-service-account.json)
        success "Project ID: $PROJECT_ID"
    else
        error "JSON inválido o jq no instalado"
    fi
else
    error "firebase-service-account.json NO existe"
fi

echo ""
echo "3️⃣  Verificando contenedores Docker..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|asistapp|backend"

BACKEND_STATUS=$(docker inspect -f '{{.State.Health.Status}}' backend-app-v3 2>/dev/null)
DB_STATUS=$(docker inspect -f '{{.State.Health.Status}}' asistapp_db 2>/dev/null)

echo ""
if [ "$BACKEND_STATUS" = "healthy" ]; then
    success "Backend: healthy"
elif [ "$BACKEND_STATUS" = "unhealthy" ]; then
    warning "Backend: unhealthy (pero puede estar funcionando)"
else
    error "Backend: $BACKEND_STATUS"
fi

if [ "$DB_STATUS" = "healthy" ]; then
    success "Base de datos: healthy"
else
    warning "Base de datos: $DB_STATUS"
fi

echo ""
echo "4️⃣  Verificando endpoints del backend..."

# Health check
echo -n "Health endpoint... "
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    success "Respondiendo correctamente"
    echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
else
    error "No responde o error"
    echo "$HEALTH_RESPONSE"
fi

echo ""
echo -n "Health endpoint público (HTTPS)... "
HTTPS_RESPONSE=$(curl -s https://srv974201.hstgr.cloud/health)
if echo "$HTTPS_RESPONSE" | grep -q "healthy"; then
    success "HTTPS funcionando correctamente"
else
    error "HTTPS no responde correctamente"
fi

echo ""
echo "5️⃣  Verificando variables de ambiente en el contenedor..."
docker exec backend-app-v3 sh -c 'echo "NODE_ENV=$NODE_ENV" && echo "FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID" && echo "WHATSAPP_PHONE_NUMBER_ID=$WHATSAPP_PHONE_NUMBER_ID"'

echo ""
echo "6️⃣  Verificando archivo Firebase dentro del contenedor..."
if docker exec backend-app-v3 test -f /app/firebase-service-account.json; then
    success "Firebase credentials montado en el contenedor"
    docker exec backend-app-v3 ls -lh /app/firebase-service-account.json
else
    error "Firebase credentials NO montado en el contenedor"
fi

echo ""
echo "7️⃣  Verificando logs del backend (últimas 20 líneas)..."
docker logs --tail 20 backend-app-v3

echo ""
echo "8️⃣  Verificando nginx..."
if systemctl is-active --quiet nginx; then
    success "Nginx activo"
else
    error "Nginx no está activo"
fi

nginx -t 2>&1 | grep -q "successful" && success "Configuración nginx válida" || error "Configuración nginx inválida"

echo ""
echo "9️⃣  Verificando certificados SSL..."
certbot certificates 2>/dev/null | grep -A2 "Certificate Name" || warning "Certbot no instalado o sin certificados"

echo ""
echo "🔟  Verificando conectividad a la base de datos..."
if docker exec asistapp_db pg_isready -U asistapp_user -d asistapp_prod >/dev/null 2>&1; then
    success "Base de datos respondiendo"
else
    error "Base de datos no responde"
fi

echo ""
echo "=========================================="
echo "✅ VALIDACIÓN COMPLETA"
echo "=========================================="
echo ""
echo "📊 Resumen:"
echo "  - Backend URL interna: http://localhost:3000"
echo "  - Backend URL pública: https://srv974201.hstgr.cloud"
echo "  - Base de datos: PostgreSQL en puerto 5432"
echo "  - Firebase Project: asistapp-1c728"
echo ""
echo "🔍 Para ver logs en tiempo real:"
echo "  docker logs -f backend-app-v3"
echo ""
echo "🔄 Para reiniciar servicios:"
echo "  cd /opt/asistapp && docker compose -f docker-compose.prod.yml restart app"
echo ""
