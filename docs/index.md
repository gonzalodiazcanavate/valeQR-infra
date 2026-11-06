# Índice de funcionalidades — `valeQR-infra`

| Funcionalidad | Resumen | Requisitos | Documento de contexto |
|---|---|---|---|
| Stack de producción y dev | Compose (Postgres, API, Caddy), roles de BD, redes, límites | RNF-DISP-01, RNF-COST-01, RNF-SEC-03 | [stack.md](stack.md) |
| Despliegue y rollback | Deploy de API (migrar → arrancar → comprobar), web atómica, rollback, workflow | RNF-DISP-02 | [deploy.md](deploy.md) |
| Backups y restauración | Copias cifradas con age, prueba de restauración con invariantes | RNF-DUR-01..03 | [backups.md](backups.md) |
| Secretos | sops + age, qué va dónde, rotación | RNF-SEC-03 | [secrets.md](secrets.md) |
| Preparación del VPS | Runbook de bootstrap y endurecimiento | RNF-SEC-01 | [vps-bootstrap.md](vps-bootstrap.md) |

## Pendiente (aún sin documento de contexto)

Staging, worker (pg-boss), WAL continuo con pgBackRest (RPO ≤ 15 min), monitorización (Uptime Kuma, Sentry), despliegue automático de la web, firewall como código, rotación de claves de firma de QR.

## Reglas del índice

- Todo documento de `docs/` debe estar listado aquí (lo verifica `scripts/docs-check.mjs`).
- Al añadir una funcionalidad nueva, añade su fila en el mismo PR.
