#!/usr/bin/env bash
# Despliega una versión del API: pull -> migraciones -> arranque -> comprobación. Uso: scripts/deploy.sh <tag>
# Se ejecuta en el VPS, en la raíz del repositorio valeQR-infra, con compose/.env ya presente.
set -euo pipefail

TAG="${1:?Uso: deploy.sh <tag> (p. ej. sha-1a2b3c4 o v0.1.0)}"
cd "$(dirname "$0")/.."
COMPOSE=(docker compose --project-directory compose -f compose/docker-compose.yml)
STATE_DIR=".deploy"
mkdir -p "$STATE_DIR"

set_tag() { # actualiza API_TAG en compose/.env
  if grep -q '^API_TAG=' compose/.env; then
    sed -i "s|^API_TAG=.*|API_TAG=$1|" compose/.env
  else
    echo "API_TAG=$1" >>compose/.env
  fi
}

current="$(grep '^API_TAG=' compose/.env | cut -d= -f2- || true)"
[ -n "$current" ] && echo "$current" >"$STATE_DIR/previous_tag"

set_tag "$TAG"
echo ">> Descargando imágenes ($TAG)"
"${COMPOSE[@]}" pull api migrate caddy

echo ">> Arrancando PostgreSQL"
"${COMPOSE[@]}" up -d postgres

echo ">> Migraciones"
"${COMPOSE[@]}" --profile tools run --rm migrate

echo ">> Arrancando API y Caddy"
"${COMPOSE[@]}" up -d --remove-orphans api caddy

echo ">> Comprobando salud"
for _ in $(seq 1 30); do
  status="$("${COMPOSE[@]}" ps --format '{{.Health}}' api 2>/dev/null || true)"
  if [ "$status" = "healthy" ]; then
    echo ">> OK: $TAG desplegado"
    echo "$TAG" >"$STATE_DIR/deployed_tag"
    exit 0
  fi
  sleep 2
done

echo "!! La API no está sana tras el despliegue de $TAG" >&2
"${COMPOSE[@]}" logs --tail 50 api >&2
echo "!! Rollback: scripts/rollback.sh" >&2
exit 1
