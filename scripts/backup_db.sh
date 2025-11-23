#!/usr/bin/env bash
set -euo pipefail

# backup_db.sh
# Realiza dump de la base de datos PostgreSQL a un archivo local con fecha.
# Requiere que 'pg_dump' esté instalado y que se puedan usar variables de entorno
#+ DB_HOST, DB_PORT, DB_USER, DB_PASS, DB_NAME

if [ -z "${DB_HOST:-}" ] || [ -z "${DB_USER:-}" ] || [ -z "${DB_NAME:-}" ]; then
  echo "ERROR: No están definidas las variables DB_HOST, DB_USER o DB_NAME" >&2
  exit 1
fi

OUTDIR="/var/backups/asistapp"
mkdir -p "$OUTDIR"
TIMESTAMP=$(date --utc +"%Y%m%dT%H%M%SZ")
FILE="$OUTDIR/${DB_NAME}_backup_${TIMESTAMP}.sql.gz"

echo "Haciendo backup de BD: $DB_HOST:$DB_PORT/$DB_NAME -> $FILE"
PGPASSWORD="${DB_PASS:-}" pg_dump -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" "$DB_NAME" | gzip > "$FILE"

echo "Backup completado: $FILE"
