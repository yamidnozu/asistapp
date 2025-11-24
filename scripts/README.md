# Scripts de Despliegue y Mantenimiento

Este directorio contiene scripts útiles para desplegar y mantener la aplicación en servidores VPS.

## 📜 Scripts Disponibles

### 🚨 `fix-now.sh` - Arreglo de Emergencia
**Uso**: Cuando el backend no puede conectarse a la base de datos por credenciales incorrectas.

```bash
# En el servidor VPS (ya conectado por SSH)
cd /opt/asistapp
bash scripts/fix-now.sh
```

**Qué hace**:
- Crea archivo `.env` con credenciales actuales del servidor
- Detiene contenedores
- **BORRA** el volumen de datos (⚠️ se pierden datos)
- Recrea la base de datos con credenciales correctas
- Reinicia servicios

**Cuándo usar**: 
- Error: "Authentication failed against database server"
- El backend está "unhealthy"
- Después de cambiar credenciales de base de datos

---

### 🔧 `fix-production-db.sh` - Arreglo Interactivo
**Uso**: Versión interactiva del script de arreglo con más validaciones.

```bash
cd /opt/asistapp
bash scripts/fix-production-db.sh
```

**Qué hace**:
- Lee el archivo `.env` existente
- Valida configuración
- Solicita confirmación
- Recrea la base de datos
- Verifica el estado final

**Cuándo usar**:
- Cuando ya tienes un `.env` configurado
- Quieres más control sobre el proceso
- Prefieres ver validaciones paso a paso

---

### 🚀 `deploy-fresh-vps.sh` - Despliegue Completo desde Cero
**Uso**: Para configurar un VPS completamente nuevo.

```bash
# En tu máquina local
scp scripts/deploy-fresh-vps.sh root@TU_NUEVA_IP:/root/

# Conectarse al nuevo VPS
ssh root@TU_NUEVA_IP

# Ejecutar (con variables opcionales)
DOMAIN=tu-dominio.com EMAIL=tu@email.com bash /root/deploy-fresh-vps.sh
```

**Qué hace** (TODO automáticamente):
1. ✅ Actualiza el sistema
2. ✅ Instala Docker
3. ✅ Instala Nginx + Certbot
4. ✅ Configura firewall (UFW)
5. ✅ Clona el repositorio
6. ✅ Genera credenciales seguras aleatorias
7. ✅ Crea archivo `.env`
8. ✅ Configura Nginx como reverse proxy
9. ✅ Obtiene certificado SSL automáticamente
10. ✅ Levanta todos los servicios
11. ✅ Verifica que todo funciona

**Cuándo usar**:
- Servidor VPS completamente nuevo
- Primera instalación
- Quieres automatizar todo el proceso
- Migración a un nuevo servidor

**Variables de entorno opcionales**:
```bash
DOMAIN="api.miapp.com"     # Tu dominio
EMAIL="admin@miapp.com"    # Email para Let's Encrypt
INSTALL_DIR="/opt/asistapp" # Directorio de instalación
```

---

## 🎯 Casos de Uso Comunes

### Caso 1: Primera instalación en VPS nuevo
```bash
# Usa: deploy-fresh-vps.sh
scp scripts/deploy-fresh-vps.sh root@IP:/root/
ssh root@IP
bash /root/deploy-fresh-vps.sh
```

### Caso 2: El backend no conecta a la DB (error de auth)
```bash
# Usa: fix-now.sh
ssh root@srv974201.hstgr.cloud
cd /opt/asistapp
bash scripts/fix-now.sh
```

### Caso 3: Cambiar credenciales de base de datos
```bash
# 1. Edita el .env con las nuevas credenciales
nano .env

# 2. Usa: fix-production-db.sh
bash scripts/fix-production-db.sh
```

### Caso 4: Actualizar código en servidor existente
```bash
ssh root@TU_IP
cd /opt/asistapp
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

---

## ⚠️ Advertencias Importantes

### Pérdida de Datos
Los scripts `fix-now.sh` y `fix-production-db.sh` **BORRAN** el volumen de datos de PostgreSQL. Esto significa:
- ❌ Se pierden todos los usuarios
- ❌ Se pierden todos los registros
- ❌ Se pierde toda la información

**Antes de ejecutar**, considera:
1. ¿Hay datos importantes? → Haz backup primero
2. ¿Es un entorno de desarrollo/pruebas? → Ejecuta sin problemas
3. ¿Es producción con usuarios reales? → BACKUP OBLIGATORIO

### Backup Manual de la Base de Datos
```bash
# Crear backup
docker exec asistapp_db pg_dump -U asistapp_user asistapp_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup (después de recrear la DB)
cat backup_FECHA.sql | docker exec -i asistapp_db psql -U asistapp_user -d asistapp_prod
```

---

## 🔐 Seguridad

### Credenciales Generadas
El script `deploy-fresh-vps.sh` genera credenciales aleatorias seguras:
- `DB_PASS`: 32 caracteres hexadecimales
- `JWT_SECRET`: 64 caracteres hexadecimales

**Guarda estas credenciales** en un gestor de contraseñas (1Password, Bitwarden, etc.)

### Archivo .env
El archivo `.env` contiene información sensible:
- ✅ Está en `.gitignore` (no se sube a git)
- ✅ Tiene permisos `600` (solo root puede leer)
- ❌ Nunca lo compartas públicamente
- ❌ Nunca lo incluyas en issues/PRs

---

## 📚 Documentación Relacionada

- [SOLUCION_RAPIDA_DB.md](../SOLUCION_RAPIDA_DB.md) - Guía detallada del problema de credenciales
- [DEPLOY_VPS.md](../DEPLOY_VPS.md) - Guía completa de despliegue
- [.env.prod.example](../.env.prod.example) - Template de configuración

---

## 🆘 Problemas Comunes

### Error: "No such file or directory"
**Causa**: Estás en el directorio incorrecto.
**Solución**: 
```bash
cd /opt/asistapp  # o donde esté tu proyecto
```

### Error: "permission denied"
**Causa**: No tienes permisos de ejecución.
**Solución**:
```bash
chmod +x scripts/*.sh
```

### Error: "docker: command not found"
**Causa**: Docker no está instalado.
**Solución**: Usa `deploy-fresh-vps.sh` que lo instala automáticamente.

---

## 📞 Soporte

Si encuentras problemas:
1. Revisa los logs: `docker compose -f docker-compose.prod.yml logs app`
2. Verifica el estado: `docker compose -f docker-compose.prod.yml ps`
3. Confirma que `.env` existe y tiene valores correctos
4. Consulta [SOLUCION_RAPIDA_DB.md](../SOLUCION_RAPIDA_DB.md)
