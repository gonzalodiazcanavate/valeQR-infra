#!/usr/bin/env bash
# Despliega el build de la SPA de forma atómica. Uso: scripts/web-deploy.sh <ruta/al/dist.tar.gz>
# Deja releases/<timestamp> y apunta el symlink `current` (lo que sirve Caddy).
set -euo pipefail

ARCHIVE="${1:?Uso: web-deploy.sh <dist.tar.gz>}"
WEB_ROOT="${WEB_ROOT:-/srv/autoqr/web}"
KEEP="${KEEP_RELEASES:-5}"

release="$WEB_ROOT/releases/$(date -u +%Y%m%d%H%M%S)"
mkdir -p "$release"
tar -xzf "$ARCHIVE" -C "$release"
[ -f "$release/index.html" ] || { echo "El paquete no contiene index.html" >&2; rm -rf "$release"; exit 1; }

ln -sfn "$release" "$WEB_ROOT/current.tmp"
mv -Tf "$WEB_ROOT/current.tmp" "$WEB_ROOT/current"
echo ">> Web desplegada: $release"

# Conserva solo las últimas KEEP versiones.
# shellcheck disable=SC2012
ls -1dt "$WEB_ROOT"/releases/* | tail -n +"$((KEEP + 1))" | xargs -r rm -rf
