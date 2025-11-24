# Despliegue Automatizado a VPS

Este proyecto incluye un workflow de GitHub Actions que **automatiza completamente** el despliegue a una VPS nueva desde cero.

## 🚀 Setup Automático (Recomendado)

El workflow hace TODO por ti al hacer push a `main`:
- ✅ Instala Docker (si no está)
- ✅ Instala nginx + certbot
- ✅ Configura firewall (UFW)
- ✅ Obtiene certificados SSL automáticamente
- ✅ Configura HTTPS con redirect de HTTP
- ✅ Genera archivos `.env` desde secrets
- ✅ Construye y levanta el backend con Docker Compose

### Requisitos previos

1. **VPS Ubuntu 24.04** con acceso root por SSH
2. **Dominio o subdominio** apuntando a la IP de tu VPS (registro A en DNS)
3. **GitHub Secrets** configurados (ver abajo)
4. **SSH Key** configurada en la VPS

### Paso 1: Generar y agregar SSH Key

En tu máquina local:

```bash
# Genera una nueva clave SSH (si no tienes una)
ssh-keygen -t ed25519 -C "deploy-asistapp" -f ~/.ssh/asistapp_deploy

# Copia la clave pública a tu VPS
ssh-copy-id -i ~/.ssh/asistapp_deploy.pub root@TU_VPS_IP

# Verifica que funciona
ssh -i ~/.ssh/asistapp_deploy root@TU_VPS_IP
```

### Paso 2: Configurar Secrets en GitHub

Ve a tu repo → Settings → Secrets and variables → Actions → New repository secret

**Secrets requeridos:**

| Secret | Descripción | Ejemplo |
|--------|-------------|---------|
| `VPS_HOST` | IP o dominio de tu VPS | `31.220.104.130` |
| `VPS_USER` | Usuario SSH (generalmente `root`) | `root` |
| `SSH_PRIVATE_KEY` | Contenido completo de `~/.ssh/asistapp_deploy` | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DB_PASS` | Contraseña de PostgreSQL | `tu_password_seguro_123` |
| `JWT_SECRET` | Secret para JWT | `openssl rand -hex 32` |
| `DOMAIN` | Tu dominio completo | `srv974201.hstgr.cloud` |
| `EMAIL` | Email para Let's Encrypt | `tu@email.com` |

**Secrets opcionales (tienen valores por defecto):**

- `API_BASE_URL` - Se genera automáticamente como `https://${DOMAIN}`
- Los demás tienen valores por defecto en el workflow

### Paso 3: Hacer Push

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

El workflow se ejecuta automáticamente y en ~5 minutos tu app estará en:
- **https://tu-dominio.com** ✅

**Nota**: Durante el deployment, el sistema ejecuta automáticamente el seed de la base de datos si está vacía, creando usuarios de prueba y datos iniciales. Los usuarios incluyen:
- Super Admin: `superadmin@asistapp.com` / `Admin123!`
- Admin: `admin@asistapp.com` / `Admin123!`
- Usuario regular: `user@asistapp.com` / `User123!`

### Ver logs del deployment

Ve a tu repo → Actions → último workflow ejecutado

### Verificar en la VPS

```bash
ssh -i ~/.ssh/asistapp_deploy root@TU_VPS_IP

# Ver contenedores
docker ps

# Ver logs del backend
cd /opt/asistapp
docker compose -f docker-compose.prod.yml logs -f app

# Verificar certificados
sudo certbot certificates

# Test local
curl -I http://localhost:3002
curl -I https://tu-dominio.com
```

---

## 📋 Setup Manual (Alternativa)

Si prefieres configurar todo manualmente sin el workflow automático:

### 1. Instalar dependencias base

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar nginx + certbot
sudo apt install -y nginx certbot python3-certbot-nginx

# Configurar firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 2. Clonar repositorio

```bash
sudo mkdir -p /opt
cd /opt
sudo git clone https://github.com/yamidnozu/asistapp.git asistapp
cd asistapp
```

### 3. Crear archivo .env

```bash
# Opción A: Copiar desde el template y editar manualmente
cp .env.prod.example .env
nano .env  # Edita los valores

# Opción B: Generar automáticamente con credenciales aleatorias
cat > .env <<EOF
DB_USER=asistapp_user
DB_PASS=$(openssl rand -hex 16)
DB_NAME=asistapp_prod
DB_PORT=5432
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRES_IN=24h
PORT=3000
HOST=0.0.0.0
NODE_ENV=production
LOG_LEVEL=info
API_BASE_URL=https://tu-dominio.com
EOF

# ⚠️ IMPORTANTE: Guarda estas credenciales en un lugar seguro
cat .env
```

### 4. Ejecutar script de setup

```bash
# Exportar variables requeridas
export DOMAIN="tu-dominio.com"
export EMAIL="tu@email.com"
export DB_PASS="tu_password"
export JWT_SECRET=$(openssl rand -hex 32)
export REPO_PATH="/opt/asistapp"

# Ejecutar setup completo
sudo bash scripts/setup_vps_complete.sh
```

Este script hace:
- Instala todo lo necesario (Docker, nginx, certbot)
- Configura nginx con SSL automático
- Obtiene certificados SSL con Let's Encrypt
- Levanta el backend con Docker Compose
- **Ejecuta automáticamente el seed de la base de datos** si está vacía (crea usuarios de prueba, instituciones, etc.)

**Nota**: El seed se ejecuta automáticamente durante el primer inicio del contenedor si la base de datos no tiene datos. Los usuarios de prueba incluyen:
- Super Admin: `superadmin@asistapp.com` / `Admin123!`
- Admin: `admin@asistapp.com` / `Admin123!`
- Usuario regular: `user@asistapp.com` / `User123!`

---

## 🔧 Troubleshooting

### El workflow falla con "secrets missing"

Verifica que todos los secrets requeridos están configurados:

```bash
# Desde tu máquina local
gh secret list

# Debe mostrar:
# VPS_HOST
# VPS_USER
# SSH_PRIVATE_KEY
# DB_PASS
# JWT_SECRET
# DOMAIN
# EMAIL
```

### Error "Could not resolve host" en IPv6

El dominio de Hostinger (`srv974201.hstgr.cloud`) no resuelve por IPv6 desde la VPS. Esto es normal y el script lo maneja. Si quieres usar tu propio dominio, asegúrate de tener un registro A apuntando a tu VPS.

### Backend devuelve 502

```bash
# Verifica que el backend está corriendo
docker ps

# Si no está, levántalo manualmente
cd /opt/asistapp
docker compose -f docker-compose.prod.yml up -d --build

# Ver logs
docker compose -f docker-compose.prod.yml logs -f app
```

### Si ves 502 Bad Gateway (nginx)

502 significa que nginx no pudo conectar al backend. Revisa:

- Estado de contenedores

```bash
# Contenedores y estado
docker ps -a
docker compose -f docker-compose.prod.yml ps
```

- Logs del backend (buscar errores al arrancar o Node stack traces)

```bash
docker compose -f docker-compose.prod.yml logs --tail 200 app
```

- Logs de nginx (en la VPS)

```bash
sudo journalctl -u nginx --no-pager -n 200
sudo tail -n 200 /var/log/nginx/error.log
```

- Verificar la ruta de salud interna (dentro de la VPS):

```bash
curl -I http://127.0.0.1:${PORT:-3002}/health
```

Si el backend devuelve 502, normalmente es porque:
- El contenedor del backend está caído por un error al arrancar (stack-trace en logs)
- El backend aún no terminó de arrancar (healthcheck fallando)
- Error en conexión a base de datos (mala variable de entorno / credenciales / DB caida)
- El seed o migración fallaron y detuvieron el arranque

Pasos rápidos para recuperarlo:

```bash
# Reiniciar contenedores
cd /opt/asistapp
docker compose -f docker-compose.prod.yml down --remove-orphans
docker compose -f docker-compose.prod.yml up -d --build

# Ver logs inmediatos
docker compose -f docker-compose.prod.yml logs --tail 200 -f app
```

Si el error proviene del seed, verás en los logs mensajes como "Falló la ejecución del seed" o errores de Prisma. Si esto ocurre, ejecuta manualmente para ver detalles:

```bash
docker compose -f docker-compose.prod.yml run --rm app node dist/seed.js
```

Observa los errores que salen y compártelos si quieres que los revise.


### Seed no se ejecutó automáticamente

Si la base de datos no tiene datos después del deployment:

```bash
# Verificar si el seed se ejecutó
cd /opt/asistapp
docker compose -f docker-compose.prod.yml exec app node dist/seed.js

# O verificar logs del contenedor durante el startup
docker compose -f docker-compose.prod.yml logs app | grep -i seed
```

El seed se ejecuta automáticamente solo si la base de datos está completamente vacía (sin usuarios).

### Renovación de certificados

Los certificados se renuevan automáticamente con un timer de systemd que certbot configura. Para verificar:

```bash
# Ver timer de renovación
sudo systemctl list-timers | grep certbot

# Renovar manualmente (test)
sudo certbot renew --dry-run
```

---

## 📚 Archivos importantes

- `.github/workflows/deploy.yml` - Workflow de CI/CD
- `scripts/setup_vps_complete.sh` - Script de setup automático
- `docker-compose.prod.yml` - Configuración Docker para producción
- `backend/.env.example` - Template de variables de entorno

---

## 🔐 Notas de Seguridad

1. **Nunca** subas el archivo `.env` al repositorio
2. Usa secrets de GitHub para información sensible
3. La clave SSH privada debe estar **solo** en GitHub Secrets
4. Rota `JWT_SECRET` periódicamente
5. Usa contraseñas fuertes para `DB_PASS`
6. Considera usar fail2ban para proteger SSH
7. Mantén el sistema actualizado: `apt update && apt upgrade`

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs del workflow en GitHub Actions
2. Revisa los logs en la VPS: `docker compose -f docker-compose.prod.yml logs`
3. Verifica que el dominio apunta correctamente: `dig +short tu-dominio.com`
4. Verifica que puertos 80/443 están abiertos: `sudo ufw status`
