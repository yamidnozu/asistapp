# 🔧 Solución Rápida - Problema de Credenciales de Base de Datos

## 📋 Resumen del Problema

El backend en producción está intentando conectarse con credenciales diferentes a las que espera la base de datos PostgreSQL:

- **Backend intenta usar**: `asistapp_user` / `65d2fa10c17a9781ba97954a3165c723`
- **Base de datos configurada previamente**: Posiblemente con otras credenciales

Esto ocurre porque Docker Postgres **solo crea usuarios en el primer inicio**. Si el volumen de datos ya existía, ignora las variables de entorno `POSTGRES_USER` y `POSTGRES_PASSWORD`.

## ✅ Solución Inmediata (Para tu VPS actual)

Estás conectado por SSH a `root@srv974201`, ejecuta estos comandos:

```bash
# 1. Ir al directorio del proyecto
cd /opt/asistapp  # o donde esté tu docker-compose.prod.yml

# 2. Crear el archivo .env si no existe
cat > .env <<'EOF'
DB_USER=asistapp_user
DB_PASS=65d2fa10c17a9781ba97954a3165c723
DB_NAME=asistapp_prod
DB_PORT=5432
JWT_SECRET=tu_jwt_secret_aqui
JWT_EXPIRES_IN=24h
HOST=0.0.0.0
PORT=3000
API_BASE_URL=https://srv974201.hstgr.cloud
NODE_ENV=production
LOG_LEVEL=info
EOF

# 3. Detener y eliminar volumen (ESTO BORRA LOS DATOS)
docker compose -f docker-compose.prod.yml down -v

# 4. Levantar de nuevo (recreará la DB con las credenciales correctas)
docker compose -f docker-compose.prod.yml up -d

# 5. Esperar 30 segundos
sleep 30

# 6. Verificar que funciona
docker compose -f docker-compose.prod.yml logs app | tail -50
```

Deberías ver en los logs algo como:
- ✅ `Servidor activo...`
- ✅ `Database connected successfully`
- ❌ **NO** debes ver: `Authentication failed`

## 🚀 Para Nuevos Despliegues (VPS Fresh)

He creado un script automatizado que configura TODO desde cero:

### Opción 1: Script Completo Automatizado

```bash
# En tu máquina local, sube el script
scp scripts/deploy-fresh-vps.sh root@TU_NUEVA_IP:/root/

# Conéctate al servidor
ssh root@TU_NUEVA_IP

# Ejecuta el script (hace TODO automáticamente)
bash deploy-fresh-vps.sh
```

Esto instalará:
- ✅ Docker
- ✅ Nginx
- ✅ Certbot (SSL automático)
- ✅ Firewall (UFW)
- ✅ Clonará el repo
- ✅ Generará credenciales seguras
- ✅ Configurará todo
- ✅ Obtendrá certificado SSL

### Opción 2: Paso a Paso Manual

Si prefieres hacerlo manual, sigue estos pasos:

#### 1. En tu máquina local

```bash
# Clonar el repo actualizado
git pull

# Ir al directorio
cd /ruta/a/asistapp

# Crear archivo .env desde el template
cp .env.prod.example .env

# Editar y configurar valores (IMPORTANTE)
nano .env  # o el editor que prefieras
```

Configurar estos valores en `.env`:
```bash
DB_USER=asistapp_user
DB_PASS=$(openssl rand -hex 16)  # Genera uno aleatorio
DB_NAME=asistapp_prod
JWT_SECRET=$(openssl rand -hex 32)  # Genera uno aleatorio
API_BASE_URL=https://tu-dominio.com
```

#### 2. En el servidor VPS

```bash
# Instalar Docker (si no está)
curl -fsSL https://get.docker.com | sh

# Crear directorio
mkdir -p /opt/asistapp
cd /opt/asistapp

# Clonar repo
git clone https://github.com/yamidnozu/asistapp.git .

# Subir tu archivo .env configurado
# (Desde tu máquina local)
scp .env root@TU_IP:/opt/asistapp/

# En el servidor, levantar servicios
docker compose -f docker-compose.prod.yml up -d

# Ver logs
docker compose -f docker-compose.prod.yml logs -f app
```

## 🔐 Mejores Prácticas

### Para evitar este problema en el futuro:

1. **Siempre usa el archivo `.env`** para configuración
2. **Nunca hardcodees credenciales** en el código o docker-compose
3. **Documenta las credenciales** en un gestor seguro (1Password, Bitwarden, etc.)
4. **En CI/CD**, usa GitHub Secrets para las credenciales
5. **Rota credenciales** después del primer despliegue exitoso

### Estructura recomendada:

```
/opt/asistapp/
├── .env                        # ⚠️ NO subir a git (secreto)
├── .env.prod.example           # ✅ Template para referencia
├── docker-compose.prod.yml     # ✅ Usa variables de .env
└── scripts/
    ├── deploy-fresh-vps.sh     # Script de despliegue completo
    └── fix-production-db.sh    # Script para arreglar credenciales
```

## 📝 Checklist de Despliegue

- [ ] Crear archivo `.env` con valores únicos y seguros
- [ ] Guardar credenciales en gestor de contraseñas
- [ ] Verificar que el dominio apunta al servidor
- [ ] Ejecutar script de despliegue
- [ ] Verificar logs: `docker compose logs -f app`
- [ ] Probar endpoint: `curl https://tu-dominio.com/health`
- [ ] Configurar renovación automática de SSL (certbot ya lo hace)
- [ ] Documentar credenciales y procedimientos

## 🆘 Troubleshooting

### Error: "Authentication failed"
**Causa**: Las credenciales en `.env` no coinciden con las de la base de datos existente.

**Solución**: Ejecutar el script `fix-production-db.sh` que recrea la base de datos.

### Error: "Connection refused"
**Causa**: El backend no está corriendo o no puede conectar a la DB.

**Solución**:
```bash
# Ver estado
docker ps

# Si no está el contenedor app, levantarlo
docker compose -f docker-compose.prod.yml up -d

# Ver logs
docker compose -f docker-compose.prod.yml logs app
```

### Error: "502 Bad Gateway"
**Causa**: Nginx no puede conectar al backend.

**Solución**:
```bash
# Verificar que el backend responde
curl http://localhost:3002/health

# Si no responde, reiniciar
docker compose -f docker-compose.prod.yml restart app
```

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs: `docker compose -f docker-compose.prod.yml logs app`
2. Verifica el archivo `.env` existe y tiene valores correctos
3. Confirma que el volumen de datos no es antiguo: `docker volume ls`
4. Si todo falla, borra volumen y recrea: `docker compose down -v && docker compose up -d`
