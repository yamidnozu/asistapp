# Correcciones: QR Scanner y SnackBar

## Fecha: 2024

## Problemas Identificados y Solucionados

### 1. QR Scanner - Múltiples Peticiones al Backend

**Problema:**
Cuando el usuario ponía la cámara sobre un código QR y lo mantenía enfocado, el scanner hacía múltiples peticiones HTTP al backend para registrar asistencia, causando errores 500 y registros duplicados.

**Causa:**
El callback `onDetect` del `MobileScannerController` se ejecuta continuamente (30-60 veces por segundo) mientras el código QR esté en el campo de visión de la cámara. Aunque existía un flag `_isProcessing`, no era suficiente para prevenir múltiples detecciones del mismo código.

**Solución Implementada:**
1. **Rastreo del último código escaneado:** Agregamos `String? _lastScannedCode` para recordar el código QR más reciente
2. **Validación temprana:** Verificamos si el código actual es igual al último escaneado y salimos inmediatamente
3. **Pausar el scanner:** Llamamos a `controller.stop()` después de detectar un código válido para detener completamente el scanner
4. **Proceso limpio:** Solo limpiamos `_isProcessing` al finalizar (éxito o error), no limpiamos `_lastScannedCode` para evitar re-escaneos

```dart
// Variables de estado
bool _isProcessing = false;
String? _lastScannedCode; // NUEVO

Future<void> _onDetect(BarcodeCapture capture) async {
  // Si ya está procesando, ignorar
  if (_isProcessing) return;

  final List<Barcode> barcodes = capture.barcodes;
  if (barcodes.isEmpty) return;

  final String? code = barcodes.first.rawValue;
  if (code == null || code.isEmpty) return;

  // Si es el mismo código que ya procesamos, ignorar
  if (_lastScannedCode == code) return; // NUEVO

  // Marcar como procesando y guardar el código
  setState(() {
    _isProcessing = true;
    _lastScannedCode = code; // NUEVO
  });

  // Pausar el escáner para evitar múltiples detecciones
  await controller.stop(); // NUEVO

  // ... resto del proceso ...
}
```

**Resultado:**
- ✅ Cada código QR se procesa exactamente una vez
- ✅ No hay múltiples peticiones HTTP al backend
- ✅ El scanner se detiene automáticamente después de detectar un código
- ✅ El usuario recibe feedback inmediato y limpio

---

### 2. SnackBar Bloqueando el Botón FAB

**Problema:**
Los mensajes de notificación (SnackBar) aparecían en la parte inferior de la pantalla, cubriendo el botón FAB "Escanear QR" y otros elementos importantes de la interfaz.

**Causa:**
El comportamiento por defecto de `SnackBar` en Flutter es posicionarse en la parte inferior del Scaffold, exactamente donde suelen estar los botones FAB y la navegación inferior.

**Solución Implementada:**

#### En `qr_scanner_screen.dart`:
Actualizamos todos los SnackBars para usar `SnackBarBehavior.floating` con márgenes personalizados que los posicionan en la parte superior:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Row(
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(width: 16),
        Expanded(child: Text('Registrando asistencia...')),
      ],
    ),
    duration: const Duration(seconds: 10),
    behavior: SnackBarBehavior.floating, // NUEVO
    margin: EdgeInsets.only(               // NUEVO
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).size.height - 150,
    ),
  ),
);
```

#### En `attendance_screen.dart`:
Creamos una función helper `_showTopSnackBar` para centralizar la lógica y mantener consistencia:

```dart
// Función helper para mostrar SnackBars en la parte superior
void _showTopSnackBar({
  required String message,
  Color? backgroundColor,
  Widget? leading,
  Duration duration = const Duration(seconds: 2),
}) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (leading != null) ...[
            leading,
            SizedBox(width: spacing.sm),
          ],
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).size.height - 150,
      ),
    ),
  );
}
```

Y reemplazamos todos los SnackBars para usar esta función:

```dart
// Antes
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Error: No estás autenticado'),
    backgroundColor: colors.error,
  ),
);

// Después
_showTopSnackBar(
  message: 'Error: No estás autenticado',
  backgroundColor: colors.error,
  leading: const Icon(Icons.error, color: Colors.white),
);
```

**Resultado:**
- ✅ Todos los mensajes aparecen en la parte superior de la pantalla
- ✅ El botón FAB permanece siempre visible y accesible
- ✅ Los mensajes incluyen íconos para mejor UX (check, error, loading)
- ✅ Código más limpio y mantenible con función helper reutilizable

---

## Archivos Modificados

### 1. `lib/screens/qr_scanner_screen.dart`
- ✅ Agregado `String? _lastScannedCode` para rastrear último código
- ✅ Agregada validación para evitar re-procesar el mismo código
- ✅ Agregado `controller.stop()` para pausar scanner después de detección
- ✅ Actualizados todos los SnackBars con posicionamiento superior

### 2. `lib/screens/attendance_screen.dart`
- ✅ Agregada función helper `_showTopSnackBar()` para mensajes consistentes
- ✅ Reemplazados todos los SnackBars para usar posicionamiento superior
- ✅ Agregados íconos a los mensajes (check, error) para mejor UX

---

## Testing Recomendado

### Prueba 1: QR Scanner - Sin Múltiples Peticiones
1. Iniciar sesión como profesor
2. Navegar a una clase activa
3. Presionar el botón FAB "Escanear QR"
4. Apuntar la cámara a un código QR de estudiante
5. **Mantener** el código QR enfocado por varios segundos
6. ✅ Verificar que solo se hace **UNA** petición al backend (revisar logs)
7. ✅ Verificar que el scanner se detiene después de la detección
8. ✅ Verificar mensaje de éxito en la parte superior

### Prueba 2: SnackBar - No Bloquea FAB
1. En la pantalla de asistencia (AttendanceScreen)
2. Realizar el doble-tap para marcar asistencia manual
3. ✅ Verificar que el mensaje aparece en la parte **superior**
4. ✅ Verificar que el botón FAB permanece **visible**
5. ✅ Verificar que se puede presionar el botón FAB mientras el mensaje está visible

### Prueba 3: Mensajes de Error
1. Intentar escanear un código QR inválido o de otra institución
2. ✅ Verificar que el mensaje de error aparece en la parte superior
3. ✅ Verificar que incluye ícono de error rojo
4. ✅ Verificar que el botón FAB permanece accesible

---

## Mejoras de UX Implementadas

1. **Íconos en Mensajes:**
   - ✅ Loading: CircularProgressIndicator
   - ✅ Éxito: check_circle verde
   - ✅ Error: error rojo

2. **Colores Consistentes:**
   - ✅ Verde para éxito
   - ✅ Rojo para errores
   - ✅ Azul para mensajes informativos

3. **Duraciones Apropiadas:**
   - ✅ Loading: 2-10 segundos
   - ✅ Éxito: 2 segundos
   - ✅ Error: 4 segundos (más tiempo para leer)

4. **Mensajes Descriptivos:**
   - ✅ "Registrando asistencia..." (con spinner)
   - ✅ "✓ [Nombre] marcado como presente"
   - ✅ "Error: [descripción detallada]"

---

## Próximos Pasos

1. ✅ Desplegar en dispositivo Android físico
2. ✅ Probar con múltiples códigos QR diferentes
3. ✅ Verificar comportamiento en diferentes tamaños de pantalla
4. ✅ Probar con conexión de red lenta (simular latencia)
5. ✅ Validar que el double-tap también funciona correctamente en Android

---

## Notas Técnicas

### Por qué `controller.stop()` funciona
- El `MobileScannerController` tiene estados internos
- `stop()` detiene la captura de cámara y el procesamiento
- El scanner no se reinicia automáticamente
- Perfecto para casos de "escanear una vez"

### Por qué no usar cooldown basado en tiempo
- Un cooldown de 3-5 segundos podría ser molesto si el usuario quiere escanear otro código
- Rastrear el código específico es más inteligente: permite escanear códigos diferentes inmediatamente
- El `stop()` del controller es más determinista que un timer

### Por qué posicionar SnackBars arriba
- Material Design permite SnackBars flotantes en cualquier posición
- La parte superior está libre de interacciones (no hay FAB, no hay bottom nav)
- Respeta el safe area del dispositivo (notch, status bar)
- Más visible en pantallas grandes (tablets)

---

## Comandos Útiles

```bash
# Reconstruir backend si hay cambios
cd backend
npm run build
docker compose up -d --build app

# Ver logs del backend
docker compose logs -f app

# Ver logs de Flutter en tiempo real
flutter run --verbose
```

---

## Referencias

- [Material Design - Snackbars](https://m3.material.io/components/snackbar/overview)
- [Flutter SnackBar Documentation](https://api.flutter.dev/flutter/material/SnackBar-class.html)
- [mobile_scanner Package](https://pub.dev/packages/mobile_scanner)
