#!/usr/bin/env bash
# Copia de seguridad lógica cifrada de PostgreSQL. Uso (cron diario): scripts/backup.sh
# Requiere en el servidor: docker, age y (opcional) rclone. La clave privada age NO debe estar aquí.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a
# shellcheck source=/dev/null
. compose/.env
set +a

: "${BACKUP_DIR:?}" "${BACKUP_AGE_RECIPIENT:?Define BACKUP_AGE_RECIPIENT (clave pública age)}"
RETENTION="${BACKUP_RETENTION_DAYS:-30}"
mkdir -p "$BACKUP_DIR"
umask 077

file="$BACKUP_DIR/autoqr-$(date -u +%Y%m%dT%H%M%SZ).dump.age"
tmp="$file.partial"

# pg_dump como superusuario del contenedor (socket local): RLS forzada impide volcar con el propietario.
docker compose --project-directory compose -f compose/docker-compose.yml exec -T postgres \
  pg_dump -U postgres -d autoqr -Fc --no-owner \
  | age -r "$BACKUP_AGE_RECIPIENT" >"$tmp"
[ -s "$tmp" ] || { echo "Copia vacía" >&2; rm -f "$tmp"; exit 1; }
mv "$tmp" "$file"
echo ">> Copia creada: $file ($(du -h "$file" | cut -f1))"

if [ -n "${BACKUP_RCLONE_REMOTE:-}" ]; then
  rclone copy "$file" "$BACKUP_RCLONE_REMOTE"
  echo ">> Subida a $BACKUP_RCLONE_REMOTE"
fi

find "$BACKUP_DIR" -name 'autoqr-*.dump.age' -mtime +"$RETENTION" -delete

# Señal para monitorización (healthchecks.io u otro), si está configurada.
[ -z "${BACKUP_PING_URL:-}" ] || curl -fsS -m 10 --retry 3 "$BACKUP_PING_URL" >/dev/null || true
