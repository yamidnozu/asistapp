# 🔐 Guía de Configuración: Firebase Auth con Google Sign-In

## 📋 Problema Actual
**Los errores que ves son porque cambiaron las credenciales de Firebase hace unos días.** El proyecto funcionaba antes porque tenía configuración correcta, pero al cambiar las API keys, se perdió la configuración de Google Sign-In.

## ⚙️ Configuración Rápida (3 pasos)

### 1. **Habilitar Google Sign-In en Firebase Console**
1. Ve a [Firebase Console](https://console.firebase.google.com/project/alacartes/authentication/providers)
2. Haz clic en **Google** en la lista de proveedores
3. **Habilita** el interruptor
4. **Guarda** los cambios

### 2. **Configurar SHA-1 en Google Cloud Console**
1. Ve a [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Selecciona el proyecto **alacartes**
3. Busca el **OAuth 2.0 Client ID** para Android
4. Haz clic en **Editar** (lápiz)
5. En **SHA-1 certificate fingerprints**, agrega:
   ```
   F9:2F:BE:A2:A9:81:98:93:38:29:A8:27:EB:EB:A9:AE:CF:E0:9D:61
   ```
6. **Guarda** los cambios

### 3. **Configurar OAuth Consent Screen**
1. Ve a [OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent)
2. Si no está configurado, selecciona **External** user type
3. Completa la información básica
4. Agrega tu email como **Test user**
5. **Guarda** y continúa

## ✅ Verificación

Después de configurar, ejecuta:
```bash
flutter run
```

Si ves estos logs, ¡funciona!:
```
🚀 Iniciando login con Google desde UI...
✅ Usuario de Google seleccionado: tuemail@gmail.com
✅ Autenticación exitosa con Firebase
```

## 🔍 Información del Proyecto

- **Project ID**: `alacartes`
- **Package Name**: `com.edevcore.asistapp`
- **SHA-1**: `F9:2F:BE:A2:A9:81:98:93:38:29:A8:27:EB:EB:A9:AE:CF:E0:9D:61`

## 🚀 Solución Alternativa

Si no quieres configurar Google Cloud Console, puedes usar **Autenticación Anónima** que funciona inmediatamente:

```dart
// En AuthService
Future<UserCredential?> signInAnonymously() async {
  return await _auth.signInAnonymously();
}
```

La app ya tiene el botón **"Continuar como Invitado"** que funciona sin configuración adicional.

---

**Nota**: El problema ocurrió porque se cambiaron las credenciales de Firebase, perdiendo la configuración previa de Google Sign-In.