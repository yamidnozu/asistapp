# Setup inicial en VPS
# Ejecutar estos comandos en tu VPS (con Docker instalado)

# 1. Instalar Docker si no está (en Ubuntu/Debian):
# sudo apt update && sudo apt install docker.io docker-compose

# 2. Clonar el repositorio
git clone https://github.com/TU_USUARIO/TU_REPO.git /path/to/project

# 3. Ir al directorio
cd /path/to/project

# 4. Login a GitHub Container Registry (recomendado si la imagen es privada)
#  - Genera un 'Personal Access Token' (PAT) en GitHub con scope: 'write:packages' y 'read:packages'.
#  - En la VPS: echo "<GHCR_PAT>" | docker login ghcr.io -u "<GHCR_USER>" --password-stdin

# 5. Copiar .env (crea uno con las variables de producción)
cp backend/.env.example backend/.env
# Edita backend/.env con tus valores de producción

# 6. Ejecutar docker-compose de producción (usando la imagen GHCR):
#     docker-compose -f docker-compose.prod.yml up -d

# Si prefieres realizar el pull manualmente, ejecuta:
#  echo "<GHCR_PAT>" | docker login ghcr.io -u "<GHCR_USER>" --password-stdin
#  docker pull ghcr.io/<GHCR_OWNER>/<GHCR_REPO>/asistapp_backend:latest
#  docker-compose -f docker-compose.prod.yml up -d

# Para logs
docker-compose logs -f app

## Secrets / Variables que debes configurar en GitHub
1. `VPS_HOST` - IP o dominio de tu VPS
2. `VPS_USER` - Usuario SSH que usará Actions (ej. 'ubuntu' o 'root')
3. `SSH_PRIVATE_KEY` - Clave privada SSH que tenga su pareja pública en `~/.ssh/authorized_keys` del VPS
4. `GHCR_USER` - Usuario de GitHub (owner) que publicará la imagen
5. `GHCR_PAT` - Personal Access Token (PAT) con permisos `packages:write` y `packages:read`
6. Variables DB/JWT para automatización del `.env` (si quieres que el workflow cree el env en la VPS):
	- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`, `JWT_SECRET`
	- Opcionales: `JWT_EXPIRES_IN`, `PORT`, `HOST`, `LOG_LEVEL`, `FIREBASE_PROJECT_ID`

## Notas de seguridad
- No subas tu `.env` al repo. Manténlo en el VPS o usa un secreto de configuración en el servicio de despliegue.
- Asegúrate de que la clave privada SSH es segura y está en GitHub Secrets.

## En la VPS una vez configurado
1. Coloca tu `backend/.env` con las variables `DB_*`, `JWT_SECRET`, etc. en el directorio del repositorio clonado.
	 - O, en la VPS, exporta las variables de entorno (DB_HOST, DB_USER, DB_PASS, DB_NAME, JWT_SECRET) y ejecuta `./scripts/generate_env.sh` para crear `backend/.env` automáticamente.
	 - Ejemplo en la VPS:
		 ```bash
		 export DB_HOST=db
		 export DB_PORT=5432
		 export DB_USER=myuser
		 export DB_PASS=mypass
		 export DB_NAME=asistapp
		 export JWT_SECRET=$(openssl rand -hex 32)
		 cd /opt/asistapp
		 ./scripts/generate_env.sh
		 ```
2. Si la imagen GHCR es privada, realiza docker login:
	- echo "<GHCR_PAT>" | docker login ghcr.io -u "<GHCR_USER>" --password-stdin
3. Levanta el stack producción:
	- docker-compose -f docker-compose.prod.yml up -d

## Firewall / Reverse Proxy
- Si quieres exponer el servidor por HTTP/HTTPS, usa un reverse proxy (nginx) y certificados TLS.
- Abre los puertos necesarios en tu VPS (80, 443 o el puerto 3002) según tu arquitectura.