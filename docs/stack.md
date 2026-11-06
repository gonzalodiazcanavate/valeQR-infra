# Stack de producción y desarrollo

- **Repo**: valeQR-infra · **Estado**: validado en local (sin VPS aún) · **Requisitos**: RNF-DISP-01, RNF-COST-01, RNF-SEC-03

## Piezas
| Archivo | Para qué |
|---|---|
| `compose/dev.yml` | PostgreSQL 17 local con los roles reales: `docker compose -f compose/dev.yml up -d --wait` |
| `compose/docker-compose.yml` | Producción: `postgres`, `migrate` (perfil `tools`), `api`, `caddy` |
| `compose/initdb/01-roles.sh` | Crea roles y base `autoqr` en la primera inicialización del volumen |
| `compose/prod.env.example` | Variables necesarias (`compose/.env` real, no versionado) |
| `caddy/Caddyfile` | TLS automático, CSP/HSTS, SPA, proxy a la API |

## Roles de base de datos
| Rol | Uso |
|---|---|
| `postgres` (superusuario) | Solo administración y `pg_dump` desde el contenedor |
| `autoqr_owner` | Dueño de la BD; ejecuta migraciones (`MIGRATION_DATABASE_URL`) |
| `autoqr_app` (NOLOGIN) | Permisos mínimos + RLS; lo crea `01-roles.sh` |
| `autoqr_app_login` | Login de la API, `NOINHERIT`: no ve tablas hasta `SET ROLE autoqr_app` (lo hace `withTenant`). Probado: `SELECT` directo → *permission denied*; tras `SET ROLE` → ok |

Las contraseñas solo se aplican al crear el volumen; cambiarlas después requiere `ALTER ROLE`.

## Redes y límites
- `db` (`internal: true`): PostgreSQL, API y migraciones. Sin salida a internet.
- `edge`: Caddy y API (la API necesita salida para email y push).
- Solo Caddy publica puertos (80, 443 TCP/UDP). Límites de memoria: postgres 1 GB, api 512 MB, caddy 256 MB (VPS de 4 GB).
- API: `read_only`, `tmpfs /tmp`, `cap_drop: ALL`, `no-new-privileges`.

## Caddy
- Dominios por `APP_DOMAIN` y `API_DOMAIN`. La SPA se sirve desde `${WEB_ROOT}/current` (symlink atómico, ver `deploy.md`).
- CSP estricta (`default-src 'self'`, `connect-src` solo la API), HSTS, `Permissions-Policy` con cámara solo propia. `index.html` sin caché; `/assets/*` inmutables.
- `/.well-known/apple-app-site-association` con `Content-Type: application/json`. `assetlinks.json` y el AASA los aporta la SPA (`public/.well-known/`, pendiente en `valeQR-app`).
- CORS lo gestiona la API (pendiente de implementar).

## Validación
`docker compose config -q`, `caddy validate` y `shellcheck` en CI.

## Decisiones y deuda
- Staging compartiendo VPS aún no está definido (conflicto de puertos 80/443); se resolverá al elegir proveedor.
- Sin worker todavía (llegará con pg-boss).
