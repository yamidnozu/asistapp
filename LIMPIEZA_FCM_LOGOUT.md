# Estrategia Login-Centric: Gestión Segura de Tokens FCM

## 📋 Problema Identificado

Antes de estos cambios, la gestión de tokens FCM tenía las siguientes deficiencias:

**Al cerrar sesión:**
- ✅ Se revocaba el refresh token en el backend
- ❌ **NO se desactivaban los tokens FCM** en el backend
- ❌ **NO se eliminaba el token FCM del dispositivo**

**Al iniciar sesión:**
- ❌ **NO se limpiaban los tokens FCM de sesiones anteriores**
- ❌ Se acumulaban tokens obsoletos de sesiones que no se cerraron correctamente

**Riesgo:** 
- Un usuario que cerró sesión podía seguir recibiendo notificaciones push
- Acumulación de tokens FCM obsoletos en la base de datos
- Múltiples dispositivos/sesiones recibiendo notificaciones cuando solo debería ser la actual

---

## ✅ Solución Implementada

### 1. Backend - Limpieza al Login (`auth.service.ts`)

**Cambio:** Modificación del método `login` para desactivar tokens FCM previos

```typescript
public static async login(credentials: LoginRequest): Promise<LoginResponse> {
  // ... autenticación ...

  try {
    // ESTRATEGIA LOGIN-CENTRIC: Desactivar todos los tokens FCM previos al hacer login
    // Esto asegura que solo la sesión actual tenga notificaciones activas
    try {
      await prisma.dispositivoFCM.updateMany({
        where: { usuarioId: usuario.id },
        data: { activo: false }
      });
      logger.info(`🔄 Tokens FCM previos desactivados para usuario ${usuario.id} en nuevo login`);
    } catch (fcmError) {
      logger.error('Error desactivando tokens FCM en login:', fcmError);
      // No bloquear el login si falla la desactivación de FCM
    }

    // ... crear refresh token ...
  }
}
```

**Impacto:**
- Al iniciar sesión, **se desactivan automáticamente todos los tokens FCM previos** del usuario
- Esto previene acumulación de tokens obsoletos de sesiones anteriores
- Si una sesión anterior no se cerró correctamente, sus tokens FCM quedan desactivados
- **Solo la sesión actual tendrá un token FCM activo**

---

### 2. Backend - Limpieza al Logout (`auth.service.ts`)

**Cambio:** Modificación del método `revokeRefreshTokens`

```typescript
public static async revokeRefreshTokens(usuarioId: string, refreshToken?: string): Promise<void> {
  // ... revocar refresh token ...

  // SEGURIDAD: Desactivar todos los dispositivos FCM al cerrar sesión
  try {
    await prisma.dispositivoFCM.updateMany({
      where: { usuarioId },
      data: { activo: false }
    });
    logger.info(`🔒 Dispositivos FCM desactivados para usuario ${usuarioId} en logout`);
  } catch (error) {
    logger.error('Error desactivando dispositivos FCM en logout:', error);
    // No lanzar error para no bloquear el logout
  }
}
```

**Impacto:**
- Ahora, cuando un usuario cierra sesión, **todos sus dispositivos FCM se desactivan automáticamente**.
- Esto garantiza que no se enviarán notificaciones a un dispositivo desde el cual el usuario cerró sesión.

---

### 3. Frontend - Limpieza al Logout (`push_notification_service.dart`)

**Cambio:** Método `dispose()` ahora realiza limpieza completa

```dart
Future<void> dispose() async {
  // 1. Eliminar el token FCM del backend
  if (_fcmToken != null && _accessToken != null) {
    await _acudienteService.eliminarDispositivo(_accessToken!, _fcmToken!);
  }

  // 2. Eliminar el token FCM del dispositivo
  final msg = messaging;
  if (msg != null) {
    await msg.deleteToken();
  }

  // 3. Limpiar estado local
  await _foregroundSubscription?.cancel();
  _fcmToken = null;
  _accessToken = null;
}
```

**Impacto:**
- Elimina el token FCM del backend (llamando al endpoint correspondiente)
- Solicita a Firebase que elimine el token del dispositivo
- Limpia el estado local del servicio

---

### 4. Frontend - Integración en Auth Provider (`auth_provider.dart`)

**Cambio:** Métodos `logout()` y `logoutAndClearAllData()` ahora llaman a `dispose()`

```dart
Future<void> logout() async {
  // 1. Limpiar notificaciones push del dispositivo y backend
  try {
    await PushNotificationService().dispose();
  } catch (e) {
    debugPrint('⚠️ Error limpiando push notifications en logout: $e');
  }

  // 2. Revocar refresh token en el backend
  if (_refreshToken != null) {
    await _authService.logout(_refreshToken!);
  }

  // 3. Limpiar tokens locales
  await _clearTokens();
}
```

**Impacto:**
- El logout ahora es un proceso de 3 pasos ordenado y robusto
- La limpieza de notificaciones ocurre **antes** de revocar el refresh token
- Si la limpieza de FCM falla, el logout continúa (no bloquea al usuario)

---

## 🔒 Beneficios de Seguridad

### Estrategia Login-Centric Completa

1. **Un solo dispositivo activo por sesión**: 
   - Al iniciar sesión, se desactivan **automáticamente** todos los tokens FCM previos
   - Solo el token de la sesión actual queda activo
   
2. **Sin notificaciones post-logout**: 
   - Al cerrar sesión, el token FCM se elimina del backend **y** del dispositivo
   - Usuario que cerró sesión no recibirá notificaciones

3. **Sin acumulación de tokens obsoletos**: 
   - No se acumulan tokens de sesiones que no se cerraron correctamente
   - La base de datos se mantiene limpia

4. **Protección de privacidad**: 
   - No quedan tokens activos que puedan ser utilizados después del logout
   - El dispositivo no conserva rastros de notificaciones después del cierre de sesión

5. **Robustez fail-safe**: 
   - Si algún paso falla (limpieza FCM), el login/logout continúa
   - Errores registrados en logs pero no bloquean al usuario

6. **Recuperación automática**: 
   - Si una sesión anterior no se cerró correctamente, el nuevo login la limpia
   - No se requiere intervención manual

---

## 🧪 Pruebas Recomendadas

### Flujo de Login (Estrategia Login-Centric)

1. **Prueba básica de login**:
   - Iniciar sesión como acudiente
   - Verificar en la consola del backend:
     - `🔄 Tokens FCM previos desactivados para usuario [ID] en nuevo login`
   - Verificar que el nuevo token FCM se registra correctamente

2. **Prueba de limpieza de sesión anterior**:
   - Iniciar sesión en el dispositivo A
   - **Sin cerrar sesión**, iniciar sesión en el dispositivo B
   - **Resultado esperado**: 
     - Dispositivo A debería dejar de recibir notificaciones
     - Solo dispositivo B debe recibir notificaciones
   - Verificar en backend que solo hay 1 token FCM activo

3. **Prueba de recuperación de sesión mal cerrada**:
   - Iniciar sesión
   - Forzar cierre de la app (kill app) sin hacer logout
   - Volver a iniciar sesión
   - **Resultado esperado**: 
     - El token FCM anterior se desactiva automáticamente
     - Se registra nuevo token sin acumulación

### Flujo de Logout

4. **Prueba básica de logout**:
   - Iniciar sesión como acudiente
   - Cerrar sesión
   - Verificar en la consola que se ejecutan los logs:
     - `🗑️ Eliminando token FCM del backend...`
     - `✅ Token FCM eliminado del backend`
     - `🗑️ Eliminando token FCM del dispositivo...`
     - `✅ Token FCM eliminado del dispositivo`
     - `🔒 Dispositivos FCM desactivados para usuario [ID] en logout`

5. **Prueba de notificaciones post-logout**:
   - Iniciar sesión y registrar el dispositivo
   - Cerrar sesión
   - Enviar una notificación al usuario desde el backend
   - **Resultado esperado**: El dispositivo NO debe recibir la notificación

6. **Prueba de re-login después de logout**:
   - Cerrar sesión
   - Volver a iniciar sesión
   - **Resultado esperado**: Nuevo token FCM debe registrarse correctamente

### Verificación en Base de Datos

7. **Verificar tabla dispositivoFCM**:
   ```sql
   -- Debería haber máximo 1 token activo por usuario
   SELECT usuarioId, COUNT(*) as tokens_activos 
   FROM dispositivoFCM 
   WHERE activo = true 
   GROUP BY usuarioId 
   HAVING COUNT(*) > 1;
   -- Resultado esperado: 0 filas (sin duplicados)
   ```

---

## 📝 Notas Técnicas

- El backend desactiva **todos** los dispositivos FCM del usuario (no solo el actual)
- Esto es por diseño: queremos desactivar todas las sesiones activas al hacer logout desde cualquier dispositivo
- Si en el futuro se requiere logout "por dispositivo", se puede modificar para enviar el token actual y desactivar solo ese

---

## 🚀 Archivos Modificados

### Backend
- `backend/src/services/auth.service.ts`: 
  - Agregada limpieza de tokens FCM en `login()` (estrategia login-centric)
  - Agregada limpieza de tokens FCM en `revokeRefreshTokens()` (logout seguro)

### Frontend
- `lib/services/push_notification_service.dart`: Método `dispose()` ahora elimina tokens del backend y dispositivo
- `lib/providers/auth_provider.dart`: Métodos `logout()` y `logoutAndClearAllData()` llaman a `dispose()` antes de limpiar tokens

---

**Fecha de implementación**: 2025-12-13
**Complejidad estimada**: 7/10
**Prioridad**: Alta (seguridad)
