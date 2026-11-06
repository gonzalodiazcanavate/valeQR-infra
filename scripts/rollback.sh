#!/usr/bin/env bash
# Vuelve a la versión anterior del API. Las migraciones deben ser expand/contract (compatibles hacia atrás),
# por eso no se revierten. Uso: scripts/rollback.sh
set -euo pipefail
cd "$(dirname "$0")/.."

previous="$(cat .deploy/previous_tag 2>/dev/null || true)"
[ -n "$previous" ] || { echo "No hay versión anterior registrada" >&2; exit 1; }
echo ">> Rollback a $previous"
exec scripts/deploy.sh "$previous"
