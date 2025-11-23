# Handoff / Delivery Guide

Esta guía describe los pasos para entregar el proyecto al cliente de forma limpia, sin vendor-lock-in, y con instrucciones para desplegar y mantener el servicio.

## Entregables mínimos
- Código fuente (repositorio git) con historial en `main` (o `master`).
- `backend/Dockerfile` y `docker-compose.prod.yml`.
- `backend/.env.example` y guía para crear `.env` con variables de producción.
- Scripts de despliegue: `scripts/deploy_on_vps.sh` (despliegue en VPS), `scripts/backup_db.sh`, `scripts/restore_db.sh`.
- `DEPLOY_VPS.md` y `docs/DELIVERY.md` (esta guía).

## Objetivo: no quedar vinculado
1. Evitar usar servicios propietarios que impidan transferir el proyecto (salvo el VPS del cliente).
2. Mantener código y la infra en formato portable (Docker, Compose) para que el cliente o un tercero pueda migrar.
3. Proveer scripts e instrucciones para instalar/actualizar/backup/restore.

## Opciones de despliegue (y recomendaciones)
Opción A - Despliegue en VPS (Recomendado para entrega limpia)
- Ventajas: Todo queda en el VPS, no necesita registries ni cuentas externas.
- Pasos básicos:
  1. Clonar el repo en el VPS.
  2. Crear `backend/.env` con valores de producción y secretos.
  3. Ejecutar en la VPS `/path/to/repo/scripts/deploy_on_vps.sh --pull` (si quieres usar imagen publicada) o `--build` para construir en VPS.
  4. Revisar logs y entrar a la app.

Opción B - Automatización mediante Registry (GHCR o Docker Hub)
- Ventajas: despliegues más rápidos y rollback mediante tags.
- Recomendado si el cliente quiere CI.
- Solo uso si confirmamos que el cliente está de acuerdo en usar un registry.

Opción C - Transferencia de imagen por scp
- Si el cliente no quiere subir imagen a un registry, Actions puede `docker save` y scp la imagen para `docker load` en la VPS.

## Checklist de seguridad y handoff
1. Cambiar claves (SSH) y rotarlas cuando termines la entrega.
2. Asegurarte que el cliente tiene su cuenta de GitHub / owner y se te transfiera la repo o se configuren permisos.
3. Documentar y rotar cualquier `GHCR_PAT`, `SSH_PRIVATE_KEY`, `DB_PASSWORD` antes de finalizar.
4. Proveer un listado de comandos de mantenimiento (logs, backups, restore, migraciones).

## Backup y restauración
Scripts incluidos:
- `scripts/backup_db.sh`: dump y gzip a `/var/backups/asistapp`
- `scripts/restore_db.sh`: restaura un dump gz out

Recomiendo una tarea cron en la VPS para backups diarios y copiar a un bucket S3 o al almacenamiento remoto del cliente.

## TLS y reverse proxy
- Configura nginx como reverse proxy + Let’s Encrypt certbot para HTTPS.
- Mantén puertos de DB cerrados salvo para localhost o red interna.

## Migraciones y seed
- Si usas Prisma y migraciones, el cliente debe ejecutar migraciones tras el deploy:
  - `docker compose -f docker-compose.prod.yml run --rm app npx prisma migrate deploy`
  - Para seeds: `docker compose -f docker-compose.prod.yml run --rm app npm run prisma:seed` (si está disponible)

## Repositorio y acceso
- Entrega del repo: si quieres que el cliente lo reciba, transfierelo o entrégalos un tag/release con documentación.
- Quitar 'secrets' privados o crear una versión final para el cliente con certificados nuevos.

## Automatización CI (opcional)
- Si el cliente desea CI, documenta las variables en GitHub Secrets:
  - `VPS_HOST`, `VPS_USER`, `SSH_PRIVATE_KEY`
  - `GHCR_USER`, `GHCR_PAT` (si se usa GHCR)
  - `DOCKER_USERNAME`, `DOCKER_PASSWORD` (si se usa Docker Hub)

## Recomendaciones finales
1. Prefiere construir en VPS a menos que el cliente quiera CI y automatización.
2. Si usas un registry, asegúrate que el cliente tenga control sobre la cuenta/owners.
3. Entrega al cliente scripts de mantenimiento y una sesión de handoff donde demuestres: despliegue, backup, restore, y rotación de secretos.

---
Si quieres, aplico estos cambios al repo ahora (crear systemd, integración de nginx o script para automatizar tasks), o creo un PR con las instrucciones listadas. ¿Cuál prefieres seguir? 
