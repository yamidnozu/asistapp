#!/bin/bash
#
# Script para arreglar el problema de credenciales en producción
# y dejarlo configurado correctamente para futuros despliegues
#
# Uso: ./scripts/fix-production-db.sh
#

set -e

echo "🔧 Script de corrección de credenciales de base de datos"
echo "========================================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.prod.yml" ]; then
    echo -e "${RED}❌ Error: No se encuentra docker-compose.prod.yml${NC}"
    echo "   Asegúrate de estar en el directorio raíz del proyecto"
    exit 1
fi

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  No se encuentra el archivo .env${NC}"
    echo ""
    read -p "¿Quieres crear uno desde .env.prod.example? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        if [ -f ".env.prod.example" ]; then
            cp .env.prod.example .env
            echo -e "${GREEN}✅ Archivo .env creado desde .env.prod.example${NC}"
            echo -e "${YELLOW}⚠️  IMPORTANTE: Edita el archivo .env y configura los valores correctos${NC}"
            echo ""
            read -p "Presiona ENTER cuando hayas editado el archivo .env..." 
        else
            echo -e "${RED}❌ No se encuentra .env.prod.example${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Abortado. Crea el archivo .env antes de continuar.${NC}"
        exit 1
    fi
fi

# Cargar variables del .env
echo "📋 Cargando variables de entorno desde .env..."
export $(cat .env | grep -v '^#' | xargs)

# Validar que las variables críticas estén definidas
if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
    echo -e "${RED}❌ Error: Faltan variables críticas en .env${NC}"
    echo "   Asegúrate de definir: DB_USER, DB_PASS, DB_NAME"
    exit 1
fi

echo -e "${GREEN}✅ Variables cargadas correctamente${NC}"
echo ""
echo "📊 Configuración detectada:"
echo "   - DB_USER: $DB_USER"
echo "   - DB_NAME: $DB_NAME"
echo "   - DB_PORT: $DB_PORT"
echo ""

# Advertencia
echo -e "${YELLOW}⚠️  ADVERTENCIA: Este script va a:${NC}"
echo "   1. Detener los contenedores actuales"
echo "   2. ELIMINAR el volumen de datos (se perderán los datos actuales)"
echo "   3. Recrear la base de datos con las credenciales del archivo .env"
echo "   4. Reiniciar los servicios"
echo ""
echo -e "${RED}   Esto BORRARÁ TODOS LOS DATOS de la base de datos actual${NC}"
echo ""

read -p "¿Estás seguro de continuar? (escribe 'SI' para confirmar): " -r
echo
if [[ ! $REPLY == "SI" ]]; then
    echo -e "${YELLOW}Abortado. No se realizaron cambios.${NC}"
    exit 0
fi

echo ""
echo "🛑 Paso 1: Deteniendo contenedores..."
docker compose -f docker-compose.prod.yml down

echo ""
echo "🗑️  Paso 2: Eliminando volumen de datos..."
docker volume rm asistapp_postgres_data 2>/dev/null || echo "   (El volumen no existía o ya fue eliminado)"

echo ""
echo "🚀 Paso 3: Levantando servicios con las nuevas credenciales..."
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "⏳ Paso 4: Esperando a que los servicios estén listos (30 segundos)..."
sleep 30

echo ""
echo "🔍 Paso 5: Verificando estado de los servicios..."
docker compose -f docker-compose.prod.yml ps

echo ""
echo "📋 Paso 6: Verificando logs del backend..."
docker compose -f docker-compose.prod.yml logs --tail 50 app | grep -i "error\|Authentication\|connected\|ready" || true

echo ""
echo "✅ Proceso completado!"
echo ""
echo "🔍 Para verificar que todo funciona:"
echo "   docker compose -f docker-compose.prod.yml logs -f app"
echo ""
echo "🌐 Prueba la API:"
echo "   curl http://localhost:3002/health"
echo ""
