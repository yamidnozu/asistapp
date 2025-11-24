#!/bin/sh
#
# Script de inicialización para el contenedor
# Se ejecuta antes de iniciar el servidor
#

echo "🚀 Iniciando AsistApp Backend..."

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando conexión a la base de datos..."
timeout=60
while ! npx prisma db push --preview-feature --accept-data-loss > /dev/null 2>&1; do
  if [ $timeout -le 0 ]; then
    echo "❌ Error: No se pudo conectar a la base de datos después de 60 segundos"
    exit 1
  fi
  echo "   Base de datos no disponible, esperando... ($timeout segundos restantes)"
  sleep 5
  timeout=$((timeout - 5))
done

echo "✅ Base de datos conectada"

# Verificar si la base de datos tiene datos (usando un script Node simple)
echo "🔍 Verificando si la base de datos tiene datos..."
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.usuarios.count().then(count => {
  if (count === 0) {
    console.log('📦 Base de datos vacía, ejecutando seed...');
    process.exit(0);
  } else {
    console.log('✅ Base de datos ya tiene datos (' + count + ' usuarios), saltando seed');
    process.exit(1);
  }
}).catch(err => {
  console.log('📦 Error al verificar datos o tabla no existe, ejecutando seed...');
  process.exit(0);
}).finally(() => prisma.\$disconnect());
" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "📦 Ejecutando seed..."
  node dist/seed.js
  echo "✅ Seed ejecutado exitosamente"
fi

echo "🎯 Iniciando servidor..."
# Ejecutar el comando original
exec "$@"