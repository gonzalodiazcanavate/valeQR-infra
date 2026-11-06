# Backups y restauración

- **Repo**: valeQR-infra · **Requisitos**: RNF-DUR-01..03
- Objetivo del proyecto: RPO ≤ 15 min, RTO ≤ 4 h (`valeQR-docs/docs/04`).

## Estado actual (importante)
| Capa | Estado | RPO real |
|---|---|---|
| `pg_dump` lógico cifrado (age), diario | **Implementado y probado** (`scripts/backup.sh`, `restore-test.sh`) | ≤ 24 h |
| WAL continuo con pgBackRest | **Pendiente** | objetivo ≤ 15 min |

Hasta añadir WAL continuo no se cumple el RPO de 15 min: **antes de operar con datos reales, implementar pgBackRest o aceptar explícitamente RPO 24 h**.

## Copia diaria (`scripts/backup.sh`)
- `pg_dump -Fc` como superusuario del contenedor (RLS forzada impide volcar con el propietario) → cifrado con `age` para `BACKUP_AGE_RECIPIENT` → `${BACKUP_DIR}/autoqr-<UTC>.dump.age`.
- Si `BACKUP_RCLONE_REMOTE` está definido, sube la copia (almacenamiento UE, fuera del VPS). Retención local `BACKUP_RETENTION_DAYS`. Opcional `BACKUP_PING_URL` para monitorizar que se ejecuta.
- Cron del VPS: `15 3 * * * cd /opt/valeQR-infra && scripts/backup.sh >>/var/log/autoqr-backup.log 2>&1`.
- Solo existe la **clave pública** en el servidor. La privada se guarda aparte (gestor de contraseñas + copia impresa); sin ella las copias son irrecuperables.

## Prueba de restauración (`scripts/restore-test.sh`)
```bash
AGE_IDENTITY=/ruta/clave-privada.txt scripts/restore-test.sh autoqr-<fecha>.dump.age
```
Levanta un PostgreSQL temporal, restaura y verifica invariantes: migraciones presentes, 4 triggers append-only, RLS forzada en las 15 tablas, sin auto-canjes, sin tickets canjeados sin registro. **Hacer al menos trimestralmente** y tras cualquier cambio del esquema de backups. Probado con una base vacía; repetir con datos reales en el piloto.

## Restaurar en producción (resumen)
1. Parar `api`. 2. Crear BD vacía y restaurar: `age -d -i clave.txt copia.age | docker compose exec -T postgres pg_restore -U postgres -d autoqr --no-owner`. 3. Aplicar migraciones pendientes. 4. Arrancar `api` y comprobar `/readyz`. Runbook detallado pendiente de la primera prueba en VPS.
