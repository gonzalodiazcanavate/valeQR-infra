# AGENTS.md — `valeQR-infra`

## Qué es este repositorio

Infraestructura como código de AutoQR: Docker Compose (dev y producción), Caddy, scripts de despliegue/rollback/backup/restauración, workflows de despliegue y runbooks. Ver `valeQR-docs/docs/11-despliegue-e-infraestructura.md`.

Documentación de producto completa: repositorio `valeQR-docs` (ver su `index.md`).

## Protocolo obligatorio antes de tocar nada

1. Lee [docs/index.md](docs/index.md): lista las funcionalidades de este repo y su documento de contexto.
2. Comprueba si lo que te piden encaja con alguna funcionalidad del índice.
   - **Sí** → lee su documento de contexto y los que enlace.
   - **No** → es una funcionalidad nueva: crea un documento con [docs/_template.md](docs/_template.md) y añádelo al índice **como parte del cambio**.
3. Implementa.
4. Actualiza el documento de contexto afectado y el índice (`node scripts/docs-check.mjs` debe pasar).
5. Si el cambio afecta a otro repo o a producto, indícalo en el PR y actualiza `valeQR-docs`.

## Prácticas

- **No ejecutes nada contra producción.** Prepara el cambio y el runbook; lo aplica el operador.
- Todo reproducible y versionado; nada manual sin runbook en `docs/`.
- Imágenes con tag explícito (nunca `latest` en producción); contenedores sin root, `cap_drop: ALL`, `read_only` cuando sea posible; solo Caddy publica puertos; PostgreSQL solo en la red interna `db`.
- Secretos: nunca en claro en el repo, logs o CI. En el repo solo cifrados con sops/age (`docs/secrets.md`). Los `.env` reales no se versionan.
- Migraciones antes del despliegue (`migrate`); rollback = redeploy del tag anterior (las migraciones son expand/contract).
- Toda mejora de backups se valida con `scripts/restore-test.sh`.
- `pg_dump` requiere superusuario: la RLS forzada impide volcar con el propietario.
- Valida los cambios: `docker compose config`, `caddy validate`, `shellcheck` (lo hace CI; localmente con contenedores).
- Commits convencionales; ramas cortas; PR obligatorio.

## Definición de hecho

Cambio validado + runbook/documentación actualizados + índice al día + PR con la plantilla completada. Si toca red, secretos o backups: revisión del agente de seguridad.
