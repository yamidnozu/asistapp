# 📝 Configuración de Secrets para GitHub Actions

## ⚠️ Secrets Requeridos

El workflow de deployment requiere los siguientes secrets configurados. Sigue las instrucciones a continuación para agregarlos.

## 🔑 Lista de Secrets

### 1. **Secrets del VPS**
- `VPS_HOST` - La IP o dominio de tu VPS (ejemplo: `31.220.104.130`)
- `VPS_USER` - Usuario para conectarse al VPS (ejemplo: `root`)
- `SSH_PRIVATE_KEY` - Tu llave privada SSH completa (ver instrucciones especiales abajo)

### 2. **Secrets del Dominio**
- `DOMAIN` - Tu dominio sin protocolo (ejemplo: `asistapp.com`)
- `EMAIL` - Email para notificaciones SSL (ejemplo: `admin@asistapp.com`)

### 3. **Secrets de Base de Datos**
- `DB_USER` - Usuario de PostgreSQL (ejemplo: `asistapp_user`)
- `DB_PASS` - Contraseña de PostgreSQL (genera una segura)
- `DB_NAME` - Nombre de la base de datos (ejemplo: `asistapp_db`)
- `DB_PORT` - Puerto de PostgreSQL (ejemplo: `5432`)

### 4. **Secrets de la Aplicación**
- `JWT_SECRET` - Token secreto para JWT (genera uno aleatorio seguro)

---

## 📋 Cómo Agregar los Secrets

### Opción 1: Secrets a Nivel de Repositorio (Recomendado)

1. Ve a tu repositorio en GitHub: https://github.com/yamidnozu/asistapp
2. Click en **Settings** (Configuración)
3. En el menú lateral izquierdo, click en **Secrets and variables** → **Actions**
4. Click en el botón verde **New repository secret**
5. Para cada secret:
   - **Name**: Ingresa el nombre exacto del secret (ejemplo: `VPS_HOST`)
   - **Secret**: Ingresa el valor
   - Click **Add secret**

### Opción 2: Secrets a Nivel de Environment

Si prefieres usar el environment `production` (más seguro para producción):

1. Ve a tu repositorio en GitHub
2. Click en **Settings** → **Environments**
3. Click en **production** (o créalo si no existe)
4. En la sección **Environment secrets**, click **Add secret**
5. Agrega cada secret como en la Opción 1

---

## 🔐 Instrucciones Especiales para SSH_PRIVATE_KEY

El secret `SSH_PRIVATE_KEY` requiere formato especial:

### 1. Obtener tu Llave Privada

Si ya tienes la llave en `~/.ssh/asistapp_deploy`:

```bash
cat ~/.ssh/asistapp_deploy
```

Si necesitas generar una nueva llave:

```bash
# Generar nueva llave SSH
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/asistapp_deploy

# Copiar la llave PÚBLICA al VPS
ssh-copy-id -i ~/.ssh/asistapp_deploy.pub root@31.220.104.130

# Mostrar la llave PRIVADA para copiarla
cat ~/.ssh/asistapp_deploy
```

### 2. Copiar la Llave Completa

La llave debe incluir:
- La línea de inicio: `-----BEGIN OPENSSH PRIVATE KEY-----`
- Todo el contenido (múltiples líneas)
- La línea de fin: `-----END OPENSSH PRIVATE KEY-----`

**Ejemplo de formato correcto:**

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBqxBX... (muchas líneas más)
... resto de la llave ...
-----END OPENSSH PRIVATE KEY-----
```

### 3. Pegar en GitHub

- **NO agregues comillas al inicio o al final**
- **NO agregues espacios antes o después**
- **SÍ incluye todas las líneas y saltos de línea**
- GitHub automáticamente protegerá los saltos de línea

---

## 🔒 Generar Secrets Seguros

### Para JWT_SECRET:

```bash
# Generar un JWT secret aleatorio seguro
openssl rand -base64 64
```

### Para DB_PASS:

```bash
# Generar una contraseña segura
openssl rand -base64 32
```

---

## ✅ Valores Ejemplo (NO USAR EN PRODUCCIÓN)

Para referencia de formato (genera tus propios valores):

```bash
VPS_HOST=31.220.104.130
VPS_USER=root
SSH_PRIVATE_KEY=<contenido de ~/.ssh/asistapp_deploy>
DOMAIN=asistapp.com
EMAIL=admin@asistapp.com
DB_USER=asistapp_user
DB_PASS=<generado con openssl>
DB_NAME=asistapp_db
DB_PORT=5432
JWT_SECRET=<generado con openssl>
```

---

## 🧪 Verificar la Configuración

Después de agregar todos los secrets:

1. Ve a la pestaña **Actions** en tu repositorio
2. Click en el workflow **Deploy to VPS** que falló
3. Click en **Re-run all jobs** (botón superior derecho)
4. El paso "Validate secrets" ahora debe mostrar: `✅ All secrets validated successfully`

---

## 🆘 Troubleshooting

### "Context access might be invalid"
- Estos son warnings del linter, no errores reales
- Se resuelven automáticamente cuando agregas los secrets

### El workflow sigue fallando en validación
- Verifica que los nombres de los secrets estén EXACTAMENTE como se listan arriba
- GitHub es sensible a mayúsculas/minúsculas
- Si usaste environment secrets, asegúrate de que el workflow use `environment: production`

### Error de SSH al conectar
- Verifica que copiaste la llave privada COMPLETA incluyendo las líneas `-----BEGIN` y `-----END`
- Asegúrate de que la llave pública esté en el VPS: `~/.ssh/authorized_keys`
- Verifica permisos en el VPS: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys`

---

## 📚 Referencias

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [SSH Key Authentication](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [appleboy/ssh-action Documentation](https://github.com/appleboy/ssh-action)
