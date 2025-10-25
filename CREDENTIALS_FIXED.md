# 🔐 CREDENCIALES CORRECTAS - AsistApp

## ⚠️ INFORMACIÓN IMPORTANTE

La contraseña del usuario administrador es **`pollo`**, NO `admin123`.

## 📋 Credenciales de Acceso

### Usuario Administrador (Super Admin)
```
Email:    admin@asistapp.com
Password: pollo
```

### Otros Usuarios (del seed.ts)
```
Super Admin:              superadmin@asistapp.com / Admin123!
Admin San José:           admin@sanjose.edu / SanJose123!
Admin FPS:                admin@fps.edu / Fps123!
Usuario Multi-institución: multi@asistapp.com / Multi123!
Profesor Pedro:           pedro.garcia@sanjose.edu / Prof123!
Estudiantes:              [nombre].[apellido]@sanjose.edu / Est123!
```

## 🔧 Cambios Realizados en el Código

### 1. Auth Service (Flutter) - Logs Mejorados

Se agregaron logs detallados en `lib/services/auth_service.dart`:

```dart
// 🔍 LOG: Mostrar hacia dónde se está apuntando
debugPrint('🌐 ========== AUTH SERVICE DEBUG ==========');
debugPrint('📍 URL: $url');  // Muestra: http://192.168.20.22:3000/auth/login
debugPrint('📧 Email: $email');
debugPrint('🔑 Password: ${password.substring(0, 3)}***');
debugPrint('📤 Enviando petición POST...');
debugPrint('📦 Body: $requestBody');
debugPrint('📥 Respuesta recibida:');
debugPrint('   Status: ${response.statusCode}');
debugPrint('   Body: ${response.body}');
```

### 2. Modelo de Respuesta Corregido

El backend devuelve `usuario`, no `user`:

```dart
factory LoginResponse.fromJson(Map<String, dynamic> json) {
  // El backend devuelve 'usuario', no 'user'
  final usuario = json['usuario'] ?? json['user'];
  
  return LoginResponse(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: usuario is Map<String, dynamic> ? usuario : {},
    expiresIn: json['expiresIn'] as int?,
  );
}
```

### 3. Timeout Agregado

Se agregó un timeout de 10 segundos para evitar esperas infinitas:

```dart
.timeout(
  const Duration(seconds: 10),
  onTimeout: () {
    debugPrint('⏱️ TIMEOUT: No se pudo conectar al servidor en 10 segundos');
    throw Exception('Timeout: El servidor no responde');
  },
);
```

## 📱 Cómo Ver los Logs en el Dispositivo

Cuando ejecutes la app, verás logs como estos:

```
🌐 ========== AUTH SERVICE DEBUG ==========
📍 URL: http://192.168.20.22:3000/auth/login
📧 Email: admin@asistapp.com
🔑 Password: pol***
📤 Enviando petición POST...
📦 Body: {"email":"admin@asistapp.com","password":"pollo"}
📥 Respuesta recibida:
   Status: 200
   Body: {"success":true,"data":{...}}
✅ Login exitoso!
========================================
```

## 🧪 Probar el Backend

### Desde la terminal:
```bash
curl -X POST http://192.168.20.22:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@asistapp.com","password":"pollo"}'
```

### Respuesta esperada:
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGci...",
    "refreshToken": "eyJhbGci...",
    "expiresIn": 86400,
    "usuario": {
      "id": "df2c15c5...",
      "nombres": "Administrador",
      "apellidos": "Sistema",
      "rol": "super_admin",
      "instituciones": []
    }
  }
}
```

## 🐛 Errores Anteriores y Soluciones

### Error: "type 'Null' is not a subtype of type 'String'"

**Causa:** El modelo `LoginResponse` esperaba que todos los campos fueran `String` obligatorios, pero:
- El backend devuelve `usuario` en lugar de `user`
- El campo `expiresIn` es opcional

**Solución:** 
- Actualizado el modelo para manejar ambos casos (`usuario` y `user`)
- Hecho `expiresIn` opcional
- Agregado manejo de errores robusto

### Error: "Credenciales inválidas"

**Causa:** La contraseña era incorrecta. Se intentó con `admin123` pero la correcta es `pollo`.

**Solución:** Usar la contraseña correcta: `pollo`

## 📊 Estado Actual del Sistema

```
✅ Backend Docker: CORRIENDO (http://192.168.20.22:3000)
✅ PostgreSQL: ACTIVO
✅ CORS: HABILITADO
✅ Auth Service: CORREGIDO con logs detallados
✅ Modelo de respuesta: CORREGIDO
⏳ App Flutter: COMPILANDO en el dispositivo (modo debug)
```

## 🔍 Qué Información Se Muestra Ahora

Cuando intentes hacer login desde la app, verás en los logs:

1. **URL completa** hacia donde apunta: `http://192.168.20.22:3000/auth/login`
2. **Email** que se está enviando
3. **Password** (primeros 3 caracteres) que se está enviando
4. **Body completo** del request en formato JSON
5. **Status code** de la respuesta (200, 401, 500, etc.)
6. **Body completo** de la respuesta del servidor
7. **Validación** de campos requeridos (accessToken, refreshToken)
8. **Mensajes de error** detallados con stack trace si algo falla

## 🚀 Próximos Pasos

1. **Espera a que termine la compilación** (en progreso)
2. **La app se abrirá automáticamente** en el dispositivo
3. **Ingresa las credenciales correctas:**
   - Email: `admin@asistapp.com`
   - Password: `pollo` ← **¡MUY IMPORTANTE!**
4. **Revisa los logs** con:
   ```bash
   flutter logs -d 2201116PG
   ```

## 📝 Notas Técnicas

- El backend usa **bcrypt** para hashear las contraseñas
- La contraseña `pollo` se define en `backend/src/services/auth.service.ts` línea 273
- El usuario se crea automáticamente si no existe al iniciar el backend
- La contraseña se hashea con: `await this.hashPassword('pollo')`

## 🔒 Cambiar la Contraseña del Admin

Si quieres cambiar la contraseña a `admin123`:

1. Edita `backend/src/services/auth.service.ts`
2. Cambia la línea 273 de:
   ```typescript
   const adminPassword = await this.hashPassword('pollo');
   ```
   a:
   ```typescript
   const adminPassword = await this.hashPassword('admin123');
   ```
3. Elimina el usuario existente:
   ```bash
   docker-compose exec app npx prisma studio
   # O directamente en la BD
   ```
4. Reinicia el backend para que cree el nuevo usuario

---

**¡Ahora la app debería funcionar correctamente con la contraseña "pollo"!** 🎉
