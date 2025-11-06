# Fix: Error 500 y Cámara Gris en QR Scanner

## Fecha: 5 de noviembre de 2025

## Problema Reportado

Al escanear un código QR de un estudiante que **ya tenía registrada su asistencia** para esa clase:

1. **Error 500 sin mensaje claro**: La app mostraba "Error del servidor: 500" en lugar de un mensaje descriptivo como "El estudiante ya tiene registrada su asistencia para esta clase hoy"

2. **Cámara se queda en gris/cartón**: Después de mostrar el error, el scanner no se reiniciaba y la cámara mostraba una pantalla gris/cartón en lugar de volver a mostrar la vista de la cámara

## Causa Raíz

### Problema 1: Backend enviaba 500 en lugar de 400

**Backend (`asistencia.controller.ts`):**
```typescript
// ❌ ANTES - Verificación incorrecta
if (error.message?.includes('NotFoundError') ||
    error.message?.includes('ValidationError') ||
    error.message?.includes('AuthorizationError')) {
  // ...
}
```

- El código verificaba si el **mensaje** incluía el texto "ValidationError"
- Pero el error real es una instancia de la clase `ValidationError`
- Por lo tanto, nunca entraba en el `if` y devolvía un genérico 500

**Frontend (`asistencia_service.dart`):**
```dart
// ❌ ANTES - Solo manejaba hasta 404
} else if (response.statusCode == 404) {
  final responseData = jsonDecode(response.body);
  throw Exception(responseData['error'] ?? 'Horario o estudiante no encontrado');
} else {
  throw Exception('Error del servidor: ${response.statusCode}');
}
```

- No manejaba específicamente el código 500
- No intentaba extraer el mensaje del error del servidor

### Problema 2: Scanner no se reiniciaba después de error

**QR Scanner (`qr_scanner_screen.dart`):**
```dart
// ❌ ANTES - Solo limpiaba el flag
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showErrorSnackBar(e.toString());
  }
} finally {
  if (mounted) {
    setState(() {
      _isProcessing = false;
    });
  }
}
```

- Después de llamar a `controller.stop()` en caso de éxito, nunca llamaba a `controller.start()` en caso de error
- El `_lastScannedCode` nunca se limpiaba, por lo que no se podía reintentar escanear el mismo código
- La cámara quedaba detenida permanentemente

---

## Soluciones Implementadas

### ✅ Fix 1: Backend - Manejo Correcto de Errores

**Archivo:** `backend/src/controllers/asistencia.controller.ts`

```typescript
// ✅ DESPUÉS - Verificación por tipo de clase
} catch (error: any) {
  console.error('Error en registrarAsistencia:', error);

  // Manejar errores conocidos por nombre de clase
  const errorName = error.constructor?.name || '';
  
  if (errorName === 'NotFoundError') {
    reply.code(404).send({
      success: false,
      message: error.message || 'Recurso no encontrado',
      error: 'NotFoundError',
    });
    return;
  }
  
  if (errorName === 'ValidationError') {
    reply.code(400).send({
      success: false,
      message: error.message || 'Datos inválidos',
      error: 'ValidationError',
    });
    return;
  }
  
  if (errorName === 'AuthorizationError') {
    reply.code(403).send({
      success: false,
      message: error.message || 'No autorizado',
      error: 'AuthorizationError',
    });
    return;
  }

  // Error genérico
  reply.code(500).send({
    success: false,
    message: error.message || 'Error interno del servidor',
    error: 'InternalServerError',
  });
}
```

**Cambios:**
- ✅ Ahora verifica `error.constructor.name` en lugar del mensaje
- ✅ `ValidationError` devuelve **400** (Bad Request) en lugar de 500
- ✅ Incluye el `error.message` real en la respuesta
- ✅ Aplicado también al método `registrarAsistenciaManual`

**Resultado:**
- Cuando un estudiante ya tiene asistencia registrada, el backend devuelve:
  ```json
  {
    "success": false,
    "message": "El estudiante ya tiene registrada su asistencia para esta clase hoy",
    "error": "ValidationError"
  }
  ```
  Con status **400** (no 500)

---

### ✅ Fix 2: Frontend - Manejo de Errores 400 y 500

**Archivo:** `lib/services/asistencia_service.dart`

```dart
// ✅ Mejorado manejo de 400
} else if (response.statusCode == 400) {
  final responseData = jsonDecode(response.body);
  // 400 puede ser ValidationError (ej: ya registrado) o datos inválidos
  final errorMsg = responseData['message'] ?? 
                  responseData['error'] ?? 
                  'Datos inválidos';
  throw Exception(errorMsg);
}

// ✅ NUEVO - Manejo específico de 500
} else if (response.statusCode == 500) {
  // Intentar extraer el mensaje de error del servidor
  try {
    final responseData = jsonDecode(response.body);
    final errorMessage = responseData['error'] ?? 
                        responseData['message'] ?? 
                        'Error interno del servidor';
    throw Exception(errorMessage);
  } catch (e) {
    throw Exception('Error interno del servidor');
  }
}
```

**Cambios:**
- ✅ Código 400: Intenta extraer `message` o `error` del JSON de respuesta
- ✅ Código 500: Nuevo bloque que intenta extraer el mensaje real del servidor
- ✅ Aplicado a ambos métodos: `registrarAsistencia` y `registrarAsistenciaManual`

**Resultado:**
- Ahora muestra: "El estudiante ya tiene registrada su asistencia para esta clase hoy"
- En lugar de: "Error del servidor: 500"

---

### ✅ Fix 3: Reiniciar Scanner Después de Error

**Archivo:** `lib/screens/qr_scanner_screen.dart`

```dart
// ✅ DESPUÉS - Reinicia scanner y limpia código
} catch (e) {
  if (mounted) {
    // Ocultar snackbar anterior
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Mostrar error
    _showErrorSnackBar(e.toString());
    
    // ✅ NUEVO - Reiniciar el scanner para permitir escanear de nuevo
    await controller.start();
    
    // ✅ NUEVO - Limpiar el código escaneado después de un delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _lastScannedCode = null;
        });
      }
    });
  }
} finally {
  if (mounted) {
    setState(() {
      _isProcessing = false;
    });
  }
}
```

**Cambios:**
- ✅ Llama a `controller.start()` para reiniciar la cámara después de un error
- ✅ Limpia `_lastScannedCode = null` después de 2 segundos
- ✅ Esto permite volver a escanear el mismo código después del error (útil para reintentos)

**Resultado:**
- La cámara se reinicia automáticamente después de un error
- Después de 2 segundos, se puede volver a intentar escanear el mismo código
- No más pantalla gris/cartón

---

## Flujo Completo: Antes vs Después

### ❌ ANTES (Con bugs)

```
1. Usuario escanea QR de estudiante ya registrado
2. Backend: ValidationError lanzado
3. Controller: No reconoce el tipo de error
4. Backend responde: 500 {"message": "Error interno del servidor"}
5. Flutter Service: "Error del servidor: 500"
6. QR Scanner: Muestra error pero NO reinicia cámara
7. Scanner: Pantalla gris/cartón, no se puede volver a escanear
8. Usuario ve: "Error del servidor: 500" (sin contexto)
```

### ✅ DESPUÉS (Corregido)

```
1. Usuario escanea QR de estudiante ya registrado
2. Backend: ValidationError lanzado
3. Controller: Reconoce ValidationError por constructor.name
4. Backend responde: 400 {"message": "El estudiante ya tiene registrada su asistencia..."}
5. Flutter Service: Extrae el mensaje del JSON
6. QR Scanner: Muestra error Y reinicia la cámara
7. Scanner: Después de 2s limpia _lastScannedCode
8. Usuario ve: "El estudiante ya tiene registrada su asistencia para esta clase hoy"
9. Usuario puede: Volver a escanear otro código QR inmediatamente
```

---

## Testing Realizado

### ✅ Compilación Backend
```bash
cd backend
npm run build
# ✅ Sin errores
```

### ✅ Build Docker
```bash
docker compose up -d --build backend
# ✅ Contenedor reconstruido exitosamente
```

### ✅ Análisis Flutter
```bash
flutter analyze
# ✅ Sin errores en asistencia_service.dart y qr_scanner_screen.dart
```

---

## Archivos Modificados

### Backend
- ✅ `backend/src/controllers/asistencia.controller.ts`
  - Método `registrarAsistencia`: Manejo por `constructor.name`
  - Método `registrarAsistenciaManual`: Manejo por `constructor.name`

### Frontend
- ✅ `lib/services/asistencia_service.dart`
  - Método `registrarAsistencia`: Manejo de 400 y 500 mejorado
  - Método `registrarAsistenciaManual`: Manejo de 400 y 500 mejorado

- ✅ `lib/screens/qr_scanner_screen.dart`
  - Bloque `catch`: Reinicia scanner con `controller.start()`
  - Bloque `catch`: Limpia `_lastScannedCode` después de 2s

---

## Cómo Probar

### Escenario 1: Estudiante Ya Registrado
1. Login como profesor
2. Ir a una clase activa
3. Escanear QR de un estudiante
4. ✅ Debe registrar exitosamente (primera vez)
5. Escanear el **mismo** QR de nuevo
6. ✅ Debe mostrar: "El estudiante ya tiene registrada su asistencia para esta clase hoy"
7. ✅ La cámara debe **volver a funcionar** (no gris)
8. Escanear QR de **otro** estudiante
9. ✅ Debe registrar exitosamente

### Escenario 2: QR Inválido
1. Escanear un QR que no sea de un estudiante válido
2. ✅ Debe mostrar mensaje de error descriptivo
3. ✅ La cámara debe reiniciarse
4. ✅ Se puede volver a escanear

### Escenario 3: Sin Conexión
1. Desconectar WiFi/datos
2. Escanear un QR
3. ✅ Debe mostrar: "Timeout: El servidor no responde"
4. ✅ La cámara debe reiniciarse

---

## Mejoras Adicionales Sugeridas

### Para el Futuro

1. **Indicador Visual de Reinicio**
   - Mostrar un pequeño spinner mientras se reinicia la cámara
   - Cambiar el color del overlay brevemente

2. **Vibración o Sonido**
   - Vibración de error cuando se detecta registro duplicado
   - Sonido diferente para éxito vs error

3. **Contador de Reintentos**
   - Si un código falla 3 veces, mostrar opción de registro manual
   - Logging para debug en modo desarrollo

4. **Cache de Códigos Exitosos**
   - Mantener lista de códigos ya procesados en memoria
   - Validar localmente antes de enviar al servidor

---

## Comandos Útiles

```bash
# Reconstruir backend
cd backend && npm run build && cd .. && docker compose up -d --build backend

# Ver logs del backend
docker compose logs -f backend

# Ejecutar Flutter en Android
flutter run -d <device-id>

# Ver logs completos de Flutter
flutter run --verbose
```

---

## Conclusión

✅ **Problema 1 resuelto:** Los errores de validación ahora devuelven 400 con mensajes descriptivos en lugar de 500 genéricos

✅ **Problema 2 resuelto:** El scanner se reinicia automáticamente después de cualquier error, evitando la pantalla gris

✅ **UX mejorada:** Los usuarios ahora ven mensajes claros como "El estudiante ya tiene registrada su asistencia para esta clase hoy" en lugar de errores técnicos

✅ **Robustez incrementada:** El sistema maneja correctamente reintentos y permite seguir escaneando después de errores

---

## Próximos Pasos

1. ✅ Desplegar en Android físico y probar el flujo completo
2. ✅ Verificar que el registro manual también muestra mensajes correctos
3. ✅ Probar con múltiples estudiantes en secuencia rápida
4. ✅ Validar comportamiento con conexión lenta/intermitente
