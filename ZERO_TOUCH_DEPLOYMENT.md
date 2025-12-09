# 🎯 Deployment 100% Automatizado - Guía Definitiva

## ✨ **Estado: COMPLETAMENTE AUTOMATIZADO**

El deployment está 100% automatizado. Solo necesitas:
1. ✅ Configurar secrets en GitHub (UNA VEZ)
2. ✅ `git push origin main`
3. ✅ Esperar 5-10 minutos
4. ✅ ¡Listo!

---

## 🚀 **Setup Inicial (Solo UNA vez)**

### **Paso 1: Configurar GitHub Secrets**

Ve a: https://github.com/yamidnozu/asistapp/settings/secrets/actions

**Secrets OBLIGATORIOS** (ya los tienes ✅):
- `VPS_HOST`
- `VPS_USER` 
- `SSH_PRIVATE_KEY`
- `DOMAIN`
- `EMAIL`
- `DB_USER`
- `DB_PASS`
- `DB_NAME`
- `DB_PORT`
- `JWT_SECRET`

**Secrets OPCIONALES** (configúralos para habilitar todas las funciones):

| Secret | Valor | Para qué sirve |
|--------|-------|----------------|
| `WHATSAPP_API_TOKEN` | Tu token de WhatsApp | Notificaciones por WhatsApp |
| `WHATSAPP_PHONE_NUMBER_ID` | ID de tu número | Notificaciones por WhatsApp |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | ID de cuenta business | Notificaciones por WhatsApp |
| `FIREBASE_PROJECT_ID` | `asistapp-1c728` | Push Notifications |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | JSON completo de Firebase | Push Notifications |

---

### **Paso 2: Deploy Inicial**

```bash
git push origin main
```

**El workflow automáticamente:**
1. ✅ Detecta si eres root o usuario normal
2. ✅ Configura passwordless sudo si es necesario
3. ✅ Instala Docker, nginx, certbot
4. ✅ Configura firewall (UFW)
5. ✅ Obtiene certificados SSL
6. ✅ Genera archivo `.env` completo
7. ✅ Configura Firebase Service Account
8. ✅ Configura WhatsApp API
9. ✅ Genera `docker-compose.prod.yml`
10. ✅ Construye y despliega el backend
11. ✅ Ejecuta migraciones de BD
12. ✅ Configura nginx con HTTPS

**TODO sin tocar el servidor.**

---

## 🔄 **Re-Deploy (Cada cambio de código)**

Simplemente:
```bash
git add .
git commit -m "tu mensaje"
git push origin main
```

El workflow se ejecuta automáticamente en cada push que modifique:
- `backend/**`
- `docker-compose.yml`
- `scripts/**`
- `prisma/**`
- `.github/workflows/deploy.yml`

---

## 🆕 **Migrar a VPS Nueva (10 minutos)**

### **Escenario: Nueva VPS Ubuntu 24.04 vacía**

1. **Configura DNS:**
   - Apunta tu dominio a la nueva IP

2. **Genera nueva SSH key:**
   ```bash
   ssh-keygen -t ed25519 -C "asistapp-deploy-new" -f ~/.ssh/asistapp_new
   ssh-copy-id -i ~/.ssh/asistapp_new.pub root@NUEVA_IP
   ```

3. **Actualiza 3 secrets en GitHub:**
   - `VPS_HOST`: `NUEVA_IP`
   - `DOMAIN`: `nuevo-dominio.com` (si cambió)
   - `SSH_PRIVATE_KEY`: Contenido de `~/.ssh/asistapp_new`

4. **Deploy:**
   ```bash
   git push origin main
   ```

5. **¡Listo!** En 10 minutos tu app está en la nueva VPS con:
   - ✅ Docker instalado
   - ✅ SSL configurado
   - ✅ Backend corriendo
   - ✅ BD migrada
   - ✅ Todo funcionando

**CERO intervención manual en el servidor.**

---

## 🛠️ **Características del Deployment Automatizado**

### **Auto-Configuración:**
- ✅ Detecta sistema operativo
- ✅ Instala dependencias faltantes
- ✅ Configura passwordless sudo automáticamente
- ✅ Crea directorios necesarios
- ✅ Protege archivos sensibles (permisos 600)

### **Auto-Reparación:**
- ✅ Si Docker no existe → Lo instala
- ✅ Si nginx no existe → Lo instala
- ✅ Si SSL no existe → Lo obtiene con Let's Encrypt
- ✅ Si contenedores conflictúan → Los remueve y recrea
- ✅ Si la BD está vacía → Ejecuta seed

### **Zero-Downtime:**
- ✅ Espera a que BD esté healthy antes de levantar backend
- ✅ Usa healthchecks para verificar servicios
- ✅ Backup automático de docker-compose.yml antes de actualizar
- ✅ Si el deploy falla, los contenedores viejos siguen corriendo

### **Seguridad:**
- ✅ Credenciales solo en GitHub Secrets
- ✅ Firebase Service Account con permisos 600
- ✅ Firewall configurado automáticamente
- ✅ HTTPS forzado (redirect de HTTP)
- ✅ Certificados SSL renovados automáticamente

---

## 📊 **Monitoreo del Deployment**

### **En GitHub:**
https://github.com/yamidnozu/asistapp/actions

Verás:
- ✅ Build and push (2-3 min)
- ✅ Deploy (5-7 min)

### **En tu navegador:**
https://srv974201.hstgr.cloud/health

Deberías ver:
```json
{"success":true,"status":"healthy","timestamp":"..."}
```

### **Variables de ambiente:**
El workflow mostrará en los logs:
```
📋 Optional secrets status:
✅ WHATSAPP_API_TOKEN set
✅ WHATSAPP_PHONE_NUMBER_ID set
✅ FIREBASE_SERVICE_ACCOUNT_JSON set
```

---

## 🐛 **Solución de Problemas**

### **"Passwordless sudo not configured"**

Si eres **root**: 
- ⚠️ No debería pasar, el workflow lo detecta
- Verifica que `VPS_USER` sea `root`

Si eres **usuario normal**:
- El workflow intentará configurarlo automáticamente
- Si falla, ejecuta UNA VEZ:
  ```bash
  ssh tu-usuario@tu-vps 'echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami) && sudo chmod 0440 /etc/sudoers.d/$(whoami)'
  ```

### **"Variables de WhatsApp vacías"**

Configura los secrets en GitHub:
- `WHATSAPP_API_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_BUSINESS_ACCOUNT_ID`

### **"Firebase credentials NO montado"**

Configura el secret en GitHub:
- `FIREBASE_SERVICE_ACCOUNT_JSON`

### **"502 Bad Gateway"**

El backend está arrancando, espera 30-60 segundos.

### **"Backend unhealthy"**

Si HTTPS funciona (`/health` responde), ignora el estado "unhealthy".
Es un problema cosmético del healthcheck de Docker.

---

## 📝 **Comandos Útiles (Opcionales)**

Solo si quieres debugging manual:

```bash
# Conectarse al VPS
ssh root@srv974201.hstgr.cloud

# Ver contenedores
docker ps

# Ver logs
docker logs -f backend-app-v3

# Ver variables en contenedor
docker exec backend-app-v3 env | grep -E "FIREBASE|WHATSAPP"

# Reiniciar backend
cd /opt/asistapp
docker compose -f docker-compose.prod.yml restart app

# Ver archivo .env
cat /opt/asistapp/.env

# Verificar Firebase
ls -la /opt/asistapp/firebase-service-account.json
```

---

## 🎯 **Casos de Uso**

### **Desarrollo diario:**
```bash
# Haces cambios en el código
vim backend/src/...

# Commit y push
git add .
git commit -m "fix: algún bug"
git push origin main

# Esperas 5 min → ✅ Desplegado
```

### **Nueva feature:**
```bash
git checkout -b feature/nueva-feature
# ... desarrollo ...
git push origin feature/nueva-feature
# Creas PR, revisas, merges a main
# → Deployment automático
```

### **Rollback:**
```bash
git revert HEAD
git push origin main
# → Deploy de la versión anterior
```

### **Cambiar VPS:**
```bash
# Actualizas 3 secrets en GitHub
# git push origin main
# → Nueva VPS configurada en 10 min
```

---

## ✅ **Checklist Final**

Antes de considerar el setup completo:

- [ ] Todos los secrets obligatorios configurados
- [ ] Secrets opcionales configurados (WhatsApp + Firebase)
- [ ] Primer deployment exitoso (workflow verde ✅)
- [ ] `/health` responde en HTTPS
- [ ] Backend logs sin errores
- [ ] Notificaciones WhatsApp funcionan (si configuraste)
- [ ] Push notifications funcionan (si configuraste)
- [ ] Dominio apunta correctamente
- [ ] SSL configurado y válido

---

## 🎉 **¡Listo!**

Ahora tienes:
- ✅ Deployment 100% automatizado
- ✅ Zero-touch deployment
- ✅ Migración de VPS en minutos
- ✅ Configuración centralizada en GitHub Secrets
- ✅ Monitoreo en GitHub Actions
- ✅ Auto-reparación y auto-configuración

**Solo haz `git push` y relájate.** ☕

---

## 📞 **Soporte**

Si algo falla:
1. Revisa logs en GitHub Actions
2. Verifica que los secrets estén configurados
3. Prueba `/health` endpoint
4. Revisa logs del backend: `docker logs backend-app-v3`
5. Si todo lo demás falla, abre un issue con los logs

**Documentación adicional:**
- `DEPLOYMENT_AUTOMATIZADO.md` - Guía completa
- `GITHUB_SECRETS_SETUP.md` - Setup de secrets
- `scripts/validate_production.sh` - Script de validación
