# valeQR-infra

Infraestructura de **AutoQR**: Docker Compose, Caddy, scripts de despliegue/backup y runbooks. Guía para agentes y humanos: [AGENTS.md](AGENTS.md). Funcionalidades y contexto: [docs/index.md](docs/index.md). Documentación de producto: repo `valeQR-docs`.

```bash
docker compose -f compose/dev.yml up -d --wait   # PostgreSQL local con los roles reales
```
