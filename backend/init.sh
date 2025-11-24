#!/bin/sh
set -euo
# enable pipefail when supported
{ set -o pipefail; } 2>/dev/null || true
#
# Script de inicialización para el contenedor
# Se ejecuta antes de iniciar el servidor
#

echo "🚀 Iniciando AsistApp Backend..."

echo "📣 Variables de entorno (no se muestran secrets):"
echo "  NODE_ENV=${NODE_ENV:-}"
echo "  PORT=${PORT:-}"
echo "  HOST=${HOST:-}"
echo "  DB_HOST=${DB_HOST:-}"
echo "  DB_NAME=${DB_NAME:-}"
echo "  DB_USER=${DB_USER:-}"
echo "  API_BASE_URL=${API_BASE_URL:-<not set>}"

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando conexión a la base de datos..."
timeout=60
while ! npx prisma db push --accept-data-loss > /dev/null 2>&1; do
  if [ $timeout -le 0 ]; then
    echo "❌ Error: No se pudo conectar a la base de datos después de 60 segundos"
    exit 1
  fi
  echo "   Base de datos no disponible, esperando... ($timeout segundos restantes)"
  sleep 5
  timeout=$((timeout - 5))
done

echo "✅ Base de datos conectada"

# Crear tablas de la base de datos si no existen
echo "🔧 Creando tablas de la base de datos..."
npx prisma db push --accept-data-loss
echo "✅ Tablas creadas/verficadas"

# Verificar si la base de datos tiene datos (usando un script Node simple)
echo "🔍 Verificando si la base de datos tiene datos..."
if node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
(async () => {
  try {
    const count = await prisma.usuario.count();
    console.log('Usuarios en DB:', count);
    process.exit(count === 0 ? 0 : 1);
  } catch (err) {
    console.error('Error al verificar count:', err && err.message ? err.message : err);
    // Si no podemos verificar (tabla no existe), consideramos DB vacía para ejecutar seed
    process.exit(0);
  } finally {
    await prisma.\$disconnect();
  }
})();
"; then
  echo "📦 Ejecutando seed..."
  if node dist/seed.js; then
    echo "✅ Seed ejecutado exitosamente"
  else
    echo "❌ Falló la ejecución del seed. Revisa los logs para más detalles." >&2
    exit 1
  fi
else
  echo "⏭️  Saltando seed (base de datos ya poblada)"
fi

echo "🎯 Iniciando servidor..."
# Ejecutar el comando original
exec "$@"