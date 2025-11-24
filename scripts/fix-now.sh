#!/bin/bash
#
# SCRIPT DE EMERGENCIA - Ejecutar en el servidor VPS actual (srv974201)
# Este script arregla el problema de autenticación AHORA
#
# Uso: bash fix-now.sh
#

set -e

echo "🚨 Script de Emergencia - Arreglo Rápido de DB"
echo "=============================================="
echo ""
echo "⚠️  Este script va a:"
echo "   1. Crear archivo .env con las credenciales actuales del servidor"
echo "   2. Detener contenedores"
echo "   3. BORRAR el volumen de datos (se pierden datos actuales)"
echo "   4. Recrear la base de datos con credenciales correctas"
echo ""

read -p "¿Continuar? (escribe SI en mayúsculas): " confirm
if [ "$confirm" != "SI" ]; then
    echo "Abortado"
    exit 1
fi

# Buscar el docker-compose.prod.yml
if [ -f "docker-compose.prod.yml" ]; then
    COMPOSE_FILE="docker-compose.prod.yml"
elif [ -f "/opt/asistapp/docker-compose.prod.yml" ]; then
    cd /opt/asistapp
    COMPOSE_FILE="docker-compose.prod.yml"
else
    echo "❌ No se encuentra docker-compose.prod.yml"
    echo "   Directorio actual: $(pwd)"
    exit 1
fi

echo "✅ Usando: $(pwd)/$COMPOSE_FILE"
echo ""

# Crear .env con las credenciales que están en el servidor actual
cat > .env <<'EOF'
# Credenciales que están actualmente en el servidor
# Generado automáticamente para solucionar problema de autenticación
DB_USER=asistapp_user
DB_PASS=65d2fa10c17a9781ba97954a3165c723
DB_NAME=asistapp_prod
DB_PORT=5432

# JWT - genera uno nuevo si no tienes
JWT_SECRET=change_this_to_a_random_secret_in_production
JWT_EXPIRES_IN=24h

# Servidor
HOST=0.0.0.0
PORT=3000

# Dominio
API_BASE_URL=https://srv974201.hstgr.cloud

# Entorno
NODE_ENV=production
LOG_LEVEL=info
EOF

echo "✅ Archivo .env creado"
echo ""

echo "🛑 Deteniendo contenedores..."
docker compose -f $COMPOSE_FILE down

echo ""
echo "🗑️  Eliminando volumen de datos..."
docker volume rm asistapp_postgres_data 2>/dev/null || echo "   (volumen no existía)"

echo ""
echo "🚀 Levantando servicios con configuración correcta..."
docker compose -f $COMPOSE_FILE up -d

echo ""
echo "⏳ Esperando 30 segundos a que los servicios inicien..."
sleep 30

echo ""
echo "📊 Estado de contenedores:"
docker compose -f $COMPOSE_FILE ps

echo ""
echo "📋 Últimos logs del backend:"
docker compose -f $COMPOSE_FILE logs --tail 30 app

echo ""
echo "✅ Proceso completado"
echo ""
echo "🔍 Verifica que no hay errores de autenticación en los logs de arriba"
echo ""
echo "Para ver logs en tiempo real:"
echo "   docker compose -f $COMPOSE_FILE logs -f app"
echo ""
