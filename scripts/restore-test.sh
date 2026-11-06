#!/usr/bin/env bash
# Prueba de restauración: restaura una copia en un PostgreSQL temporal y comprueba invariantes.
# Uso: AGE_IDENTITY=/ruta/clave-privada.txt scripts/restore-test.sh <copia.dump.age>
# Ejecutar en una máquina de confianza (no tiene por qué ser el VPS). Nunca deja datos en disco.
set -euo pipefail

BACKUP="${1:?Uso: restore-test.sh <copia.dump.age>}"
IDENTITY="${AGE_IDENTITY:?Define AGE_IDENTITY con la clave privada age}"
NAME="autoqr-restore-test-$$"
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT

docker run -d --name "$NAME" -e POSTGRES_PASSWORD=restore-test postgres:17-alpine >/dev/null
for _ in $(seq 1 30); do
  docker exec "$NAME" pg_isready -U postgres >/dev/null 2>&1 && break
  sleep 1
done

# Rol que la copia referencia en sus GRANT. El restore se hace como superusuario (RLS forzada).
docker exec "$NAME" psql -U postgres -v ON_ERROR_STOP=1 \
  -c "CREATE ROLE autoqr_app NOLOGIN" -c "CREATE DATABASE autoqr" >/dev/null

age -d -i "$IDENTITY" "$BACKUP" | docker exec -i "$NAME" pg_restore -U postgres -d autoqr --no-owner --exit-on-error

q() { docker exec "$NAME" psql -U postgres -d autoqr -Atc "$1"; }
fail() { echo "!! Comprobación fallida: $1" >&2; exit 1; }

echo ">> Invariantes"
[ "$(q "SELECT count(*) FROM schema_migrations")" -ge 1 ] || fail "sin migraciones registradas"
[ "$(q "SELECT count(*) FROM pg_trigger WHERE tgname LIKE '%_append_only'")" -eq 4 ] || fail "faltan triggers append-only"
[ "$(q "SELECT count(*) FROM pg_class WHERE relrowsecurity AND relforcerowsecurity AND relkind='r' AND relnamespace='public'::regnamespace")" -ge 15 ] || fail "RLS no forzada en todas las tablas"
[ "$(q "SELECT count(*) FROM redemptions WHERE employee_id = client_id")" -eq 0 ] || fail "hay auto-canjes"
[ "$(q "SELECT count(*) FROM tickets t WHERE t.status='redeemed' AND NOT EXISTS (SELECT 1 FROM redemptions r WHERE r.ticket_id=t.id)")" -eq 0 ] || fail "tickets canjeados sin registro de canje"

echo ">> Recuento"
q "SELECT 'users', count(*) FROM users UNION ALL SELECT 'organizations', count(*) FROM organizations UNION ALL SELECT 'tickets', count(*) FROM tickets UNION ALL SELECT 'redemptions', count(*) FROM redemptions"
echo ">> Restauración verificada"
