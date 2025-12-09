# 🔐 Configuración de Secrets en GitHub

Este documento explica cómo configurar los secrets necesarios para el deployment automatizado.

## 📋 Secrets Requeridos (OBLIGATORIOS)

Ve a tu repositorio → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Descripción | Valor Actual |
|--------|-------------|--------------|
| `VPS_HOST` | IP o dominio de tu VPS | `srv974201.hstgr.cloud` |
| `VPS_USER` | Usuario SSH | `root` |
| `SSH_PRIVATE_KEY` | Clave privada SSH completa | *Contenido de tu clave SSH privada* |
| `DOMAIN` | Tu dominio | `srv974201.hstgr.cloud` |
| `EMAIL` | Email para Let's Encrypt | Tu email |
| `DB_USER` | Usuario de PostgreSQL | `asistapp_user` |
| `DB_PASS` | Contraseña de PostgreSQL | `65d2fa10c17a9781ba97954a3165c723` |
| `DB_NAME` | Nombre de la BD | `asistapp_prod` |
| `DB_PORT` | Puerto de PostgreSQL | `5432` |
| `JWT_SECRET` | Secret para JWT | `ccfcae26adca30d801c33382fd12c68f8652055c84cd5f31a7b73f81917f6d61` |

## 📱 Secrets Opcionales - WhatsApp

| Secret | Descripción | Valor Actual |
|--------|-------------|--------------|
| `WHATSAPP_API_TOKEN` | Token de WhatsApp Cloud API | `EAATWH2LvOj8BQPqDVeIjbdtAMXZBmtXtCZBZB3ICnnMxoPCWqIhCE5IbGZCYA7iq2wAoqKZBuxNtjUcIadhTkfVEL8tGHywK5dbPPlcYFBbJrllsFoopzw3rUm03Aflv5TuPbb00UaODsW3BeiBjUYqpqwZC7YrCVfuHh0yxYPaSMGoDD5iBnsb1818Axp4RCmHOfKv84ZCtBmk` |
| `WHATSAPP_PHONE_NUMBER_ID` | ID del número de WhatsApp | `947476001773627` |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | ID de cuenta de WhatsApp Business | `840929655333048` |

### ⚠️ Importante sobre el Token de WhatsApp
El token actual **expira en 24 horas**. Para producción necesitas generar un **token permanente**:

1. Ve a https://developers.facebook.com/apps/
2. Selecciona tu app de WhatsApp
3. Ve a **System Users** (Usuarios del sistema)
4. Crea un System User o usa uno existente
5. Genera un token permanente con permisos de `whatsapp_business_messaging`
6. Actualiza el secret `WHATSAPP_API_TOKEN` con el nuevo token

## 🔥 Secrets Opcionales - Firebase (Push Notifications)

| Secret | Descripción | Cómo obtenerlo |
|--------|-------------|----------------|
| `FIREBASE_PROJECT_ID` | ID del proyecto Firebase | Por defecto: `asistapp-1c728` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Credenciales de Service Account (JSON completo) | Ver instrucciones abajo |

### Cómo obtener Firebase Service Account JSON:

1. Ve a https://console.firebase.google.com/project/asistapp-1c728/settings/serviceaccounts/adminsdk
2. Click en **"Generar nueva clave privada"**
3. Se descargará un archivo JSON
4. Copia **TODO el contenido del archivo JSON** (incluyendo las llaves `{}`)
5. Pégalo como valor del secret `FIREBASE_SERVICE_ACCOUNT_JSON`

**Ejemplo del formato** (NO uses este, genera el tuyo):
```json
{
  "type": "service_account",
  "project_id": "asistapp-1c728",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@asistapp-1c728.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

## ✅ Verificar Secrets Configurados

Una vez configurados los secrets, el workflow mostrará su estado:

```
✅ All required secrets validated successfully

📋 Optional secrets status:
✅ WHATSAPP_API_TOKEN set
✅ WHATSAPP_PHONE_NUMBER_ID set
✅ WHATSAPP_BUSINESS_ACCOUNT_ID set
✅ FIREBASE_SERVICE_ACCOUNT_JSON set
```

## 🚀 Deploy Automático

Después de configurar los secrets:

```bash
git add .
git commit -m "feat: automated deployment with WhatsApp and Firebase"
git push origin main
```

El workflow se ejecutará automáticamente y:
- ✅ Generará el archivo `.env` completo en el servidor
- ✅ Configurará Firebase Service Account
- ✅ Configurará WhatsApp API
- ✅ Montará el archivo de credenciales en el contenedor
- ✅ Desplegará el backend con todas las variables configuradas

## 🔍 Monitorear el Deployment

1. Ve a tu repositorio en GitHub
2. Click en **Actions**
3. Selecciona el workflow **"Deploy to VPS"**
4. Verás el progreso en tiempo real

## 📝 Notas de Seguridad

- ❌ **NUNCA** subas estos valores al repositorio
- ✅ Solo configúralos como GitHub Secrets
- 🔄 Rota las credenciales periódicamente
- 🔒 El archivo `firebase-service-account.json` se crea con permisos `600` (solo lectura para root)
