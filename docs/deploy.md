# Despliegue y rollback

- **Repo**: valeQR-infra · **Requisitos**: RNF-DISP-02

## API (`scripts/deploy.sh <tag>`)
Se ejecuta en el VPS, en la raíz del repo, con `compose/.env` presente.

1. Guarda el tag actual en `.deploy/previous_tag` y escribe el nuevo `API_TAG`.
2. `pull` de `api`, `migrate` y `caddy`.
3. Arranca `postgres` y ejecuta **migraciones** (`migrate`, una sola vez).
4. `up -d api caddy`.
5. Espera `healthy` de la API (hasta 60 s). Si falla: muestra logs y avisa para hacer rollback.

**Rollback**: `scripts/rollback.sh` (vuelve al tag de `.deploy/previous_tag`). Las migraciones no se revierten: deben ser expand/contract.

Tags: `sha-<commit>` (CI del API) o `vX.Y.Z`. **No usar `latest` en producción.**

## Web (`scripts/web-deploy.sh <dist.tar.gz>`)
Descomprime en `${WEB_ROOT}/releases/<timestamp>`, comprueba `index.html`, cambia el symlink `current` de forma atómica y conserva las últimas 5 versiones. Procedimiento manual por ahora:
```bash
tar -czf dist.tar.gz -C dist .          # en valeQR-app tras pnpm build
scp dist.tar.gz <vps>:/tmp/ && ssh <vps> 'cd /opt/valeQR-infra && scripts/web-deploy.sh /tmp/dist.tar.gz'
```

## Workflow de GitHub (`.github/workflows/deploy.yml`)
`workflow_dispatch` con el tag como entrada, sobre el *environment* `production`. **Configurar en GitHub**: reviewers obligatorios en ese environment y los secretos `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`. Ejecuta por SSH `git pull` + `scripts/deploy.sh <tag>`.

## Pendiente
Despliegue automático de la web, smoke test externo tras el deploy, blue/green si el reinicio visible molesta.
