# 🔐 GUÍA DE GESTIÓN DE ARCHIVOS SENSIBLES Y SECRETOS

## ⚠️ PROBLEMA ACTUAL

**ENCONTRADO EN EL REPO (❌ INSEGURO):**
```
keystore.b64          ← ❌ Keystore en base64 (ELIMINAR)
keystore-new.jks      ← ⚠️ Puede estar (si .gitignore funciona)
```

## ✅ SOLUCIÓN: Dónde Debe Estar Cada Cosa

### 📦 **1. KEYSTORE DE ANDROID**

#### **¿Qué es?**
El archivo que firma tu aplicación Android para publicación en Play Store.

#### **Ubicación CORRECTA:**

##### **Opción A: GitHub Secrets (RECOMENDADO ✅)**
```
Ubicación: GitHub Repository → Settings → Secrets and variables → Actions

Secrets requeridos:
┌─────────────────────────────────┬───────────────────────────────────┐
│ Secret Name                      │ Valor                             │
├─────────────────────────────────┼───────────────────────────────────┤
│ KEYSTORE_BASE64                  │ [contenido del archivo en base64] │
│ KEYSTORE_PASSWORD                │ [tu password del keystore]        │
│ KEY_PASSWORD                     │ [password de la key]              │
│ KEY_ALIAS                        │ [alias de la key, ej: asistapp]   │
└─────────────────────────────────┴───────────────────────────────────┘
```

**Cómo conseguir el KEYSTORE_BASE64:**
```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("keystore-new.jks")) | Set-Clipboard
# Ahora está en tu portapapeles, pégalo en GitHub Secrets
```

##### **Opción B: Archivo Local (BACKUP PERSONAL ✅)**
```
Ubicación física segura:
- USB externa encriptada
- Servicio de password manager (1Password, Bitwarden)
- Google Drive personal (carpeta privada, NO compartida)
- Keepass database

⚠️ NUNCA en:
- Repositorio Git (público o privado)
- Email
- Slack/Discord
- Carpeta compartida no encriptada
```

---

### 🌐 **2. VARIABLES DE ENTORNO (.env)**

#### **¿Qué es?**
Configuración de URLs, API keys, credenciales de servicios.

#### **Ubicación CORRECTA:**

##### **Para DESARROLLO local:**
```
c:\Proyectos\DemoLife\.env (ignorado por Git ✅)
```

##### **Para PRODUCCIÓN (GitHub Actions):**
```
GitHub Secrets:
┌─────────────────────────────────┬───────────────────────────────────┐
│ API_BASE_URL                     │ https://api.asistapp.com          │
│ WHATSAPP_API_BASE_URL           │ https://graph.facebook.com        │
│ WHATSAPP_API_TOKEN              │ [tu token de Meta]                │
│ WHATSAPP_PHONE_NUMBER_ID        │ [tu phone number ID]              │
│ DATABASE_URL                     │ postgresql://...                  │
│ JWT_SECRET                       │ [tu secret para JWT]              │
└─────────────────────────────────┴───────────────────────────────────┘
```

##### **Para PRODUCCIÓN (VPS):**
```
Ubicación: /var/www/asistapp/.env (en el VPS)

Cómo configurar:
ssh usuario@tu-vps.com
cd /var/www/asistapp
nano .env
# Pegar las variables
# Guardar con Ctrl+X, Y, Enter
```

---

### 📱 **3. SERVICE ACCOUNT DE GOOGLE PLAY**

#### **¿Qué es?**
JSON con credenciales para subir automáticamente a Play Store.

#### **Ubicación CORRECTA:**
```
GitHub Secret:
┌─────────────────────────────────┬───────────────────────────────────┐
│ PLAY_STORE_SERVICE_ACCOUNT       │ {                                 │
│                                  │   "type": "service_account",      │
│                                  │   "project_id": "...",            │
│                                  │   "private_key_id": "...",        │
│                                  │   ...                             │
│                                  │ }                                 │
└─────────────────────────────────┴───────────────────────────────────┘

Nota: Pegar TODO el contenido del JSON (sin escapar)
```

**Cómo obtenerlo:**
1. Google Cloud Console → Services Accounts
2. Crear nueva cuenta de servicio
3. Descargar JSON
4. Copiar TODO el contenido y pegarlo en el secret

---

### 🔑 **4. CLAVES SSH PARA DEPLOY**

#### **¿Qué es?**
Par de claves para acceder al VPS sin password.

#### **Ubicación CORRECTA:**

##### **Clave PRIVADA:**
```
GitHub Secret:
┌─────────────────────────────────┬───────────────────────────────────┐
│ SSH_PRIVATE_KEY                  │ -----BEGIN OPENSSH PRIVATE KEY----|
│                                  │ [contenido completo de la clave]  │
│                                  │ -----END OPENSSH PRIVATE KEY------|
└─────────────────────────────────┴───────────────────────────────────┘

⚠️ Incluir TODO desde "-----BEGIN" hasta "-----END"
```

##### **Clave PÚBLICA:**
```
VPS: ~/.ssh/authorized_keys
```

---

### 🔥 **5. FIREBASE CREDENTIALS**

#### **¿Qué es?**
Credenciales para Firebase Admin SDK (notificaciones push).

#### **Ubicación CORRECTA:**

##### **Service Account JSON:**
```
VPS: /var/www/asistapp/firebase-service-account.json
Permisos: chmod 600 (solo el owner puede leer/escribir)

GitHub Secret (para deploy automático):
┌─────────────────────────────────┬───────────────────────────────────┐
│ FIREBASE_SERVICE_ACCOUNT         │ {                                 │
│                                  │   "type": "service_account",      │
│                                  │   "project_id": "asistapp-...",   │
│                                  │   ...                             │
│                                  │ }                                 │
└─────────────────────────────────┴───────────────────────────────────┘
```

---

## 📋 **CHECKLIST DE ARCHIVOS SENSIBLES**

### ❌ **NUNCA en Git:**
- [ ] `keystore.b64` 
- [ ] `keystore-new.jks` (verificar .gitignore)
- [ ] `.env` (excepto `.env.example`)
- [ ] `key.properties`
- [ ] `service_account.json`
- [ ] `firebase-service-account.json`
- [ ] Archivos con claves SSH privadas

### ✅ **SIEMPRE en GitHub Secrets:**
- [ ] `KEYSTORE_BASE64`
- [ ] `KEYSTORE_PASSWORD`
- [ ] `KEY_PASSWORD`
- [ ] `KEY_ALIAS`
- [ ] `PLAY_STORE_SERVICE_ACCOUNT`
- [ ] `SSH_PRIVATE_KEY`
- [ ] `SSH_HOST`
- [ ] `SSH_USER`
- [ ] `API_BASE_URL`
- [ ] `FIREBASE_SERVICE_ACCOUNT` (si usas deploy automático)

### ✅ **SIEMPRE en .gitignore:**
- [x] `*.jks` ✅ (ya está)
- [x] `*.keystore` ✅ (ya está)
- [x] `key.properties` ✅ (ya está)
- [ ] `*.b64` ❌ (AGREGAR)
- [ ] `service_account*.json` ❌ (AGREGAR)
- [ ] `firebase-service-account.json` ❌ (AGREGAR)

---

## 🔧 **ACCIONES INMEDIATAS REQUERIDAS**

### 1. Eliminar `keystore.b64` del repositorio
```bash
git rm --cached keystore.b64
git commit -m "security: Remove sensitive keystore file from repository"
git push
```

### 2. Actualizar .gitignore
```bash
# Agregar al final de .gitignore
echo "*.b64" >> .gitignore
echo "service_account*.json" >> .gitignore
echo "firebase-service-account.json" >> .gitignore
git add .gitignore
git commit -m "chore: Update gitignore to prevent sensitive files"
git push
```

### 3. Verificar que el keystore esté en GitHub Secrets
```powershell
# Convertir a base64 (Windows PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("keystore-new.jks")) | Set-Clipboard
```
Luego ir a: `GitHub Repo → Settings → Secrets and variables → Actions → New secret`
- Name: `KEYSTORE_BASE64`
- Value: Pegar del portapapeles

### 4. Hacer backup seguro del keystore
**Guardar `keystore-new.jks` en:**
- Password manager (recomendado)
- USB encriptada
- Google Drive personal (carpeta privada)

**NUNCA perder este archivo** - sin él no podrás actualizar la app en Play Store.

---

## 📝 **RESUMEN: ¿Dónde Va Cada Cosa?**

| Archivo/Secret | Git Repo | GitHub Secrets | VPS | Local Backup |
|----------------|----------|----------------|-----|--------------|
| keystore-new.jks | ❌ NO | ✅ (base64) | ❌ NO | ✅ SÍ |
| keystore.b64 | ❌ NO | ❌ NO | ❌ NO | ❌ ELIMINAR |
| .env | ❌ NO | ❌ NO | ✅ SÍ | ✅ SÍ |
| .env.example | ✅ SÍ | ❌ NO | ❌ NO | - |
| key.properties | ❌ NO | ❌ NO | ❌ NO | - |
| service_account.json (Play) | ❌ NO | ✅ SÍ | ❌ NO | ✅ SÍ |
| firebase-service-account.json | ❌ NO | ✅ SÍ | ✅ SÍ | ✅ SÍ |
| SSH private key | ❌ NO | ✅ SÍ | ✅ SÍ | ✅ SÍ |
| Passwords/Tokens | ❌ NO | ✅ SÍ | ✅ (.env) | ✅ Password Manager |

---

## 🆘 **FAQ**

### ¿Qué pasa si pierdo el keystore?
⚠️ **NO PODRÁS ACTUALIZAR LA APP EN PLAY STORE**. Tendrás que:
1. Crear nuevo keystore
2. Subir una app completamente nueva (nuevo package name)
3. Perder todos los usuarios/reviews

### ¿Puedo compartir el repositorio con el keystore en GitHub Secrets?
✅ **SÍ**, los Secrets NO son accesibles para otros colaboradores del repo. Solo los workflows de GitHub Actions pueden usarlos.

### ¿Cómo verifico que algo NO está en Git?
```bash
git log --all --full-history -- keystore.b64
# Si muestra commits, el archivo estuvo/está en el historial
```

### ¿Cómo elimino algo del historial de Git completamente?
```bash
# ⚠️ PELIGROSO - Solo si es crítico
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch keystore.b64" \
  --prune-empty --tag-name-filter cat -- --all
git push origin --force --all
```

---

## 📚 **Documentos Relacionados**

- `GITHUB_SECRETS_SETUP.md` - Guía detallada de configuración de secrets
- `SECRETS_SETUP_GUIDE.md` - Otra guía de secrets
- `RELEASE_ANDROID.md` - Proceso de release a Play Store
- `DEPLOY_VPS.md` - Configuración del VPS

---

**🔒 Regla de Oro**: Si tiene passwords, keys, tokens o credenciales → **NUNCA en Git, SIEMPRE en Secrets o archivos locales seguros**
