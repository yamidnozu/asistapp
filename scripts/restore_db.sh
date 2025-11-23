#!/usr/bin/env bash
set -euo pipefail

# restore_db.sh
# Restaura un backup gzip generado por backup_db.sh
# Uso: restore_db.sh /path/to/backup.sql.gz

if [ "$#" -ne 1 ]; then
  echo "Uso: $0 /path/to/backup.sql.gz" >&2
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: archivo no encontrado: $BACKUP_FILE" >&2
  exit 1
fi

echo "Restaura BD desde $BACKUP_FILE"
PGPASSWORD="${DB_PASS:-}" zcat "$BACKUP_FILE" | psql -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U "${DB_USER}" "${DB_NAME}"

echo "Restaura completada."
