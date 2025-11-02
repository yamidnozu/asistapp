# 🚀 Comandos Útiles para Pruebas E2E

## Comandos Básicos

### Ejecutar prueba principal
```bash
flutter test integration_test/app_test.dart
```

### Ejecutar todas las pruebas de integración
```bash
flutter test integration_test/
```

### Ejecutar prueba específica con salida verbose
```bash
flutter test integration_test/app_test.dart -v
```

### Ejecutar en un dispositivo específico
```bash
# En emulador Android
flutter test integration_test/app_test.dart -d android

# En dispositivo físico específico
flutter test integration_test/app_test.dart -d emulator-5554

# En Windows
flutter test integration_test/app_test.dart -d windows
```

---

## Comandos Avanzados

### Con timeout extendido (para redes lentas)
```bash
flutter test integration_test/app_test.dart --timeout=300s
```

### Con debug output
```bash
flutter test integration_test/app_test.dart -v --dart-define=DEBUG=true
```

### Ejecutar solo un test específico
```bash
flutter test integration_test/app_test.dart -p "Flujo completo"
```

### Con random seed (para reproducibilidad)
```bash
flutter test integration_test/app_test.dart --test-randomize-ordering-seed=12345
```

### Generar reporte de cobertura
```bash
flutter test integration_test/app_test.dart --coverage
```

---

## Preparación del Entorno

### Instalar dependencias
```bash
flutter pub get
```

### Limpiar todo y reinstalar
```bash
flutter clean
flutter pub get
```

### Verificar dispositivos disponibles
```bash
flutter devices
```

### Iniciar emulador desde línea de comandos
```bash
# Listar emuladores disponibles
emulator -list-avds

# Iniciar emulador
emulator -avd Pixel_4_API_30

# Iniciar emulador sin interfaz gráfica
emulator -avd Pixel_4_API_30 -no-window
```

### Verificar conexión con backend
```bash
# Verificar si el backend responde
curl http://192.168.20.22:3000/health

# O en Windows PowerShell
Invoke-WebRequest -Uri "http://192.168.20.22:3000/health"
```

---

## Verificación y Análisis

### Analizar el código
```bash
flutter analyze lib/
flutter analyze integration_test/
```

### Ver todos los archivos modificados
```bash
git status
```

### Listar pruebas disponibles (sin ejecutar)
```bash
flutter test --list integration_test/
```

### Ver versión de Flutter
```bash
flutter --version
```

---

## Debugging y Troubleshooting

### Ver logs del dispositivo en tiempo real
```bash
flutter logs
```

### Ejecutar con máxima verbosidad
```bash
flutter test integration_test/app_test.dart -vv
```

### Pausar la ejecución en un punto
```bash
# Agregar en el código de prueba
await tester.pumpAndSettle(const Duration(minutes: 5));
```

### Capturar screenshot
```dart
// En el código de prueba
await tester.binding.window.physicalSize = const Size(1080, 1920);
```

### Ver errores específicos
```bash
flutter test integration_test/app_test.dart 2>&1 | grep -A 5 "FAILED"
```

---

## Gestión del Backend

### Iniciar backend en desarrollo
```bash
cd backend
npm install
npm start
```

### Seed de base de datos
```bash
cd backend
npm run seed
```

### Ver logs del backend
```bash
cd backend
npm run dev  # Para desarrollo con logs detallados
```

### Detener todo
```bash
# En bash
pkill -f "npm" && pkill -f "flutter"

# En PowerShell (Windows)
Stop-Process -Name "node" -Force
Stop-Process -Name "dart" -Force
```

---

## Scripts Rápidos

### Script bash para ejecutar todo
```bash
#!/bin/bash

# Limpiar
flutter clean
flutter pub get

# Verificar backend
if ! curl -s http://192.168.20.22:3000/health > /dev/null; then
    echo "Backend no está corriendo"
    exit 1
fi

# Ejecutar pruebas
flutter test integration_test/app_test.dart -v
```

### Script PowerShell (Windows)
```powershell
# Limpiar
flutter clean
flutter pub get

# Verificar backend
try {
    Invoke-WebRequest -Uri "http://192.168.20.22:3000/health" -TimeoutSec 5
} catch {
    Write-Host "Backend no está corriendo"
    exit 1
}

# Ejecutar pruebas
flutter test integration_test/app_test.dart -v
```

---

## Ciclo de Desarrollo

### 1. Preparación inicial
```bash
cd proyecto
flutter pub get
```

### 2. Iniciar emulador
```bash
emulator -avd Pixel_4_API_30
```

### 3. Iniciar backend
```bash
cd backend && npm start
```

### 4. En otra terminal, ejecutar pruebas
```bash
flutter test integration_test/app_test.dart -v
```

### 5. Ver resultados
```
✓ Login como Super Admin exitoso.
✓ Navegación a Instituciones completada.
✓ Institución creada exitosamente.
✓ Institución actualizada exitosamente.
✓ Institución eliminada exitosamente.
✓ CRUD de Instituciones completado.
```

---

## Comandos Específicos por SO

### Windows (PowerShell)
```powershell
# Ejecutar pruebas
flutter test integration_test\app_test.dart

# Limpiar
Remove-Item -Recurse -Force build
```

### macOS/Linux (Bash)
```bash
# Ejecutar pruebas
flutter test integration_test/app_test.dart

# Limpiar
rm -rf build
```

---

## Integración Continua (CI/CD)

### GitHub Actions
```bash
# Ejecutar pruebas en CI
flutter test integration_test/app_test.dart --verbose --timeout=300s
```

### Variables de Entorno
```bash
# Pasar variables de entorno a las pruebas
flutter test integration_test/app_test.dart \
  --dart-define=BACKEND_URL=http://backend.test:3000 \
  --dart-define=TEST_MODE=true
```

---

## Monitoreo y Reportes

### Generar reporte de pruebas
```bash
flutter test integration_test/app_test.dart --verbose > test_results.log 2>&1
```

### Monitorear recursos durante pruebas
```bash
# En otra terminal
watch -n 1 'flutter devices && adb shell dumpsys meminfo'
```

### Ver estadísticas de ejecución
```bash
time flutter test integration_test/app_test.dart
```

---

## Guía Rápida de Referencia

| Tarea | Comando |
|-------|---------|
| Ejecutar pruebas | `flutter test integration_test/app_test.dart` |
| Limpiar y ejecutar | `flutter clean && flutter pub get && flutter test integration_test/` |
| Ver dispositivos | `flutter devices` |
| Ver logs | `flutter logs` |
| Verificar backend | `curl http://192.168.20.22:3000/health` |
| Con verbosidad | `flutter test integration_test/app_test.dart -v` |
| Timeout extendido | `flutter test ... --timeout=300s` |
| En dispositivo específico | `flutter test ... -d android` |

---

## 💡 Tips Útiles

1. **Mantener terminal de logs abierta**
   ```bash
   flutter logs  # En una terminal separada
   ```

2. **Usar aliases para comandos largos**
   ```bash
   alias ft='flutter test'
   alias fti='flutter test integration_test/app_test.dart -v'
   ```

3. **Ejecutar solo una prueba**
   ```bash
   flutter test integration_test/extended_tests.dart -p "Validaciones"
   ```

4. **Aumentar timeout para redes lentas**
   ```bash
   flutter test integration_test/ --timeout=300s
   ```

5. **Ver salida sin buffering**
   ```bash
   flutter test integration_test/app_test.dart -v --no-color
   ```

---

## 🚨 Errores Comunes y Soluciones

| Error | Solución |
|-------|----------|
| "Device not found" | Ejecuta `flutter devices` y verifica emulador |
| "Test timeout" | Aumenta timeout: `--timeout=300s` |
| "Connection refused" | Verifica que backend esté corriendo |
| "Key not found" | Verifica que la Key exista en el widget |
| "Emulator not running" | Inicia: `emulator -avd Pixel_4_API_30` |

---

**Última actualización**: 29 de Octubre de 2025
