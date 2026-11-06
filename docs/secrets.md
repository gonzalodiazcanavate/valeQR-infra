# Secretos

- **Repo**: valeQR-infra · **Requisitos**: RNF-SEC-03

## Principios
Nada secreto en claro en git, CI ni logs. Cifrado con **sops + age**; cada secreto se descifra solo donde se usa.

## Dónde vive cada cosa
| Secreto | Dónde |
|---|---|
| `compose/.env` de producción | Cifrado en `secrets/prod.env.enc` (sops); se descifra en el VPS al desplegar |
| Clave privada age del VPS (descifrar `.enc`) | Solo en el VPS (`~/.config/sops/age/keys.txt`) + copia del operador |
| Clave privada age de **backups** | **Nunca** en el VPS; custodia del operador |
| Claves de firma del QR (`kid`) | En `prod.env` cuando se implemente (rotables con solape) |
| `CONTRACT_DEPLOY_KEY` (lectura del contrato) | Secreto de Actions en `valeQR-api` y `valeQR-app`; deploy key de solo lectura en `valeQR-contract` |
| `DEPLOY_*` | Secretos del environment `production` de este repo |

## Uso
```bash
cp .sops.yaml.example .sops.yaml                # sustituir por la clave pública age real
sops --encrypt compose/.env > secrets/prod.env.enc
sops --decrypt secrets/prod.env.enc > compose/.env && chmod 600 compose/.env
```
`.gitignore` excluye `compose/.env` y `*.key`.

## Rotación
Contraseñas de BD: `ALTER ROLE` + actualizar `.env` + redeploy. Claves age: generar nueva, re-cifrar (`sops updatekeys`), retirar la antigua. Deploy keys: crear nueva, actualizar el secreto, borrar la antigua.
