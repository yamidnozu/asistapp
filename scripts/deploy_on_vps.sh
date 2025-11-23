#!/usr/bin/env bash
set -euo pipefail

# deploy_on_vps.sh
# Script que corre en la VPS para desplegar la aplicación.
# - Si existe la imagen remota (GHCR o Docker Hub), se hace pull y up.
# - Si no existe o es preferible, se construye localmente en la VPS.

WORKDIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE="docker-compose -f ${WORKDIR}/docker-compose.prod.yml"

print() { echo "[deploy] $*"; }

check_commands() {
  for cmd in docker docker-compose; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "ERROR: '$cmd' no está instalado. Instálalo y vuelve a correr este script." >&2
      exit 1
    fi
  done
}

usage() {
  cat <<EOF
Uso: deploy_on_vps.sh [--pull | --build]
  --pull  : intentar 'docker pull' desde la imagen remota (GHCR) y subir con compose
  --build : forzar build local con docker-compose build en la VPS
EOF
}

MODE="pull"
if [ "${1:-}" = "--build" ]; then
  MODE="build"
elif [ "${1:-}" = "--pull" ]; then
  MODE="pull"
fi

check_commands
print "Directorio de trabajo: $WORKDIR"

# Ensure .env exists
if [ ! -f "$WORKDIR/backend/.env" ]; then
  echo "ERROR: falta backend/.env. Copia backend/.env.example y rellénalo con valores de producción." >&2
  exit 1
fi

cd "$WORKDIR"

if [ "$MODE" = "pull" ]; then
  print "Intentando 'docker pull' de la imagen remota"
  # Intenta pull, si falla, cae a build
  if ! ${COMPOSE} pull app; then
    print "docker pull falló, construyendo localmente..."
    MODE=build
  else
    print "docker pull OK"
  fi
fi

if [ "$MODE" = "build" ]; then
  print "Construyendo la imagen localmente en la VPS"
  ${COMPOSE} build --no-cache --progress=plain
fi

# If backend/.env does not exist, try to generate it from environment variables using the helper script
if [ ! -f "$WORKDIR/backend/.env" ]; then
  print "No encontré backend/.env. Intentando generarlo desde variables de entorno..."
  if [ -n "${DB_HOST:-}" ] && [ -n "${DB_USER:-}" ] && [ -n "${DB_PASS:-}" ] && [ -n "${DB_NAME:-}" ] && [ -n "${JWT_SECRET:-}" ]; then
    print "Variables detectadas, generando backend/.env desde scripts/generate_env.sh"
    /bin/bash "$WORKDIR/scripts/generate_env.sh"
  else
    print "No se detectaron variables necesarias; asegúrate de crear backend/.env (puede copiar backend/.env.example)"
    exit 1
  fi
fi

print "Deteniendo contenedores actuales si existen"
${COMPOSE} down --remove-orphans

print "Iniciando servicios en background"
${COMPOSE} up -d --remove-orphans

# Esperar y chequear el estado del servicio
sleep 2
print "Contenedores activos:"
docker ps --filter "name=backend-app-v3" --format "{{.Names}} - {{.Status}}"

print "Se recomienda revisar los logs: docker-compose -f docker-compose.prod.yml logs -f app"
print "Si utilizas Prisma, ejecuta migraciones manuales si es necesario: docker compose -f docker-compose.prod.yml run --rm app npx prisma migrate deploy"

print "Despliegue finalizado"
