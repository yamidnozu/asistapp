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
- Instala todo lo necesario
- Configura nginx
- Obtiene certificados SSL
- Levanta el backend

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
