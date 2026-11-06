# Preparación del VPS (runbook)

- **Repo**: valeQR-infra · **Requisitos**: RNF-SEC-01 · **Estado**: guía sin ejecutar; revisar cada paso antes de aplicarlo.

Proveedor: UE (preferible España), ~2 vCPU / 4 GB / 40+ GB (ver `valeQR-docs/docs/11`). Ubuntu LTS.

## 1. Acceso y usuarios
```bash
adduser deploy && usermod -aG sudo deploy
# copiar la clave pública SSH del operador a /home/deploy/.ssh/authorized_keys
# /etc/ssh/sshd_config: PermitRootLogin no, PasswordAuthentication no
systemctl reload ssh
```

## 2. Firewall y protección
```bash
ufw default deny incoming && ufw default allow outgoing
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw allow 443/udp
ufw enable
apt install -y fail2ban unattended-upgrades
```
Restringe el 22 por IP si es posible. Ojo: Docker publica puertos saltándose `ufw`; por eso Compose solo publica 80/443 y PostgreSQL no tiene `ports`.

## 3. Docker y repo
```bash
curl -fsSL https://get.docker.com | sh && usermod -aG docker deploy
git clone git@github.com:gonzalodiazcanavate/valeQR-infra.git /opt/valeQR-infra   # con deploy key de solo lectura
mkdir -p /srv/autoqr/web/releases /srv/autoqr/backups
```
Descifrar `compose/.env` (ver `secrets.md`) y `docker login ghcr.io` con un token `read:packages`.

## 4. Primer arranque
`scripts/deploy.sh <tag>`; después `scripts/web-deploy.sh` con el build de la web. Comprobar `https://api.<dominio>/readyz`.

## 5. Tareas periódicas
Cron de `scripts/backup.sh` (`backups.md`), prueba de restauración trimestral, `docker image prune` mensual, revisión de actualizaciones del sistema.

## 6. DNS
A/AAAA de `app`, `api` (y `status`), CAA, y SPF/DKIM/DMARC del dominio de correo.
