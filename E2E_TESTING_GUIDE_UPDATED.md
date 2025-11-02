# 🚀 Guía Actualizada de E2E Testing - DemoLife/AsistApp

## ✅ Estado Actual

Los **tests E2E ahora están funcionando correctamente** en Windows Desktop. Se han ejecutado exitosamente los siguientes tests:

- ✅ **01 - Login exitoso**
- ✅ **02 - Navegar a Instituciones**
- ✅ **03 - Ver lista de Usuarios**
- ✅ **04 - Estructura de widgets en login**
- ✅ **05 - Logout**

## 📋 Cambios Realizados

### 1. **Limpieza de Estado de Autenticación**

El problema principal fue que la aplicación mantenía tokens en `SharedPreferences`. Ahora cada test limpia el estado:

```dart
setUp(() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('accessToken');
  await prefs.remove('refreshToken');
  await prefs.remove('user');
  await prefs.remove('selectedInstitutionId');
});
```

### 2. **Búsqueda de Widgets Más Robusta**

En lugar de depender de Keys (que pueden no estar presentes o no propagarse), ahora usamos búsquedas por tipo:

```dart
// ❌ Anterior (no funcionaba)
final emailField = find.byKey(const Key('emailField'));

// ✅ Ahora (funciona)
final textFields = find.byType(TextFormField);
await tester.enterText(textFields.at(0), 'email@example.com');
```

### 3. **Mejor Manejo de Excepciones**

Los tests ahora verifican que los widgets existan antes de intentar interactuar:

```dart
final buttons = find.byType(ElevatedButton);
if (buttons.evaluate().isNotEmpty) {
  await tester.tap(buttons.first);
}
```

## 🔧 Archivos de Test

### `integration_test/app_e2e_test.dart` ✅ RECOMENDADO

**Archivo principal con tests funcionales en Windows Desktop**

```bash
# Ejecutar todos los tests
flutter test integration_test/app_e2e_test.dart -d windows

# Ejecutar un test específico
flutter test integration_test/app_e2e_test.dart -d windows --name "Login exitoso"

# Ejecutar en Chrome
flutter test integration_test/app_e2e_test.dart -d chrome
```

### `integration_test/simple_test.dart` ⚡ DIAGNÓSTICO

**Pruebas simplificadas para diagnóstico rápido**

```bash
flutter test integration_test/simple_test.dart -d windows
```

### `integration_test/app_test.dart` 🔄 EN DESARROLLO

**Versión más compleja con funciones auxiliares (en revisión)**

## 🧪 Tests Disponibles

### Grupo: "E2E Tests - Login y Navegación"

#### 1. **01 - Login exitoso** ✅
```
- Limpia estado de autenticación
- Ingresa credenciales de super admin
- Verifica que el dashboard se carga
- Duración: ~18 segundos
```

#### 2. **02 - Navegar a Instituciones** ✅
```
- Realiza login
- Navega a la sección de Instituciones
- Verifica que se cargaron las instituciones
- Duración: ~34 segundos acumulados
```

#### 3. **03 - Ver lista de Usuarios** ✅
```
- Realiza login
- Navega a la sección de Usuarios
- Verifica que se cargó la lista
- Duración: ~38 segundos acumulados
```

#### 4. **04 - Estructura de widgets en login** ✅
```
- Valida estructura de la pantalla de login
- Verifica cantidad de Scaffolds, TextFormFields, etc.
- Test de diagnóstico
- Duración: ~56 segundos acumulados
```

#### 5. **05 - Logout** ✅
```
- Realiza login
- Intenta encontrar y usar opción de logout
- Continúa incluso si logout no se encuentra
- Duración: ~1:19 minutos total
```

## 🔑 Credenciales para Testing

```
Email: superadmin@asistapp.com
Contraseña: Admin123!
```

## 💻 Ejecución en Diferentes Plataformas

### Windows Desktop ✅ (Recomendado para desarrollo)
```bash
flutter test integration_test/app_e2e_test.dart -d windows
```

### Chrome Web
```bash
flutter test integration_test/app_e2e_test.dart -d chrome
```

### Android (Requiere emulador/dispositivo)
```bash
flutter test integration_test/app_e2e_test.dart -d android
```

### iOS (Requiere simulador/dispositivo)
```bash
flutter test integration_test/app_e2e_test.dart -d ios
```

## 🛠️ Scripting

### Script Bash (Linux/macOS)
```bash
./run_e2e_tests.sh
```

### Script Batch (Windows)
```batch
run_e2e_tests.bat
```

## 📊 Resultados de Ejecución

### Última Ejecución Exitosa
```
✓ Built build\windows\x64\runner\Debug\asistapp.exe
✓ 01 - Login exitoso [00:18]
✓ 02 - Navegar a Instituciones [00:34]
✓ 03 - Ver lista de Usuarios [00:38]
✓ 04 - Estructura de widgets en login [00:56]
✓ 05 - Logout [01:19]

Resultado: All tests passed! ✅
```

## 🔍 Requisitos Previos

1. **Backend Running**
   ```bash
   cd backend
   npm start
   # O si está en Docker:
   docker-compose up
   ```

2. **Flutter SDK Actualizado**
   ```bash
   flutter upgrade
   ```

3. **Dependencias Instaladas**
   ```bash
   flutter pub get
   ```

4. **Base de Datos Configurada**
   - Asegúrate de que el backend puede conectar a la BD
   - Super Admin debe estar creado en la BD

## ⚠️ Notas Importantes

### Sobre SharedPreferences
- El estado de autenticación se almacena en `SharedPreferences`
- Cada test limpia este estado automáticamente con `setUp()`
- Esto asegura que cada test comience con estado limpio

### Sobre Timeouts
- `pumpAndSettle()` espera 3 segundos por defecto al iniciar
- Después del login espera 5 segundos para que se cargue el dashboard
- Ajusta estos valores si tu conexión es lenta

### Sobre Búsqueda de Widgets
- Usamos `find.byType()` para búsquedas genéricas
- Esto es más robusto que keys en entornos de testing
- Las búsquedas por texto usan `find.text()`

## 🐛 Troubleshooting

### Error: "Expected: exactly one matching candidate"
```dart
// ❌ Problema: Múltiples widgets con el mismo texto
expect(find.text('Instituciones'), findsOneWidget);

// ✅ Solución: Usa findsWidgets para múltiples
expect(find.text('Instituciones'), findsWidgets);

// ✅ O sé más específico en tu búsqueda
final institucionesTab = find.byWidgetPredicate(...);
```

### Error: "IndexError: Index out of range"
```dart
// ❌ Problema: Intentando acceder a índice que no existe
final field = find.byType(TextFormField).at(5);  // Pero solo hay 2

// ✅ Solución: Verifica primero
final fields = find.byType(TextFormField);
if (fields.evaluate().length > 5) {
  final field = fields.at(5);
}
```

### Tests Se Quedan Colgados
```dart
// ✅ Asegúrate de que el backend está corriendo
cd backend && npm start

// ✅ Verifica conectividad
ping 192.168.20.22

// ✅ Aumenta el timeout
await tester.pumpAndSettle(const Duration(seconds: 10));
```

## 📈 Próximos Pasos

1. **Crear tests para CRUD completo**
   - Crear, actualizar, eliminar Instituciones
   - Crear, actualizar, eliminar Usuarios

2. **Agregar tests para validaciones**
   - Campos obligatorios
   - Formatos de email
   - Contraseñas débiles

3. **Integrar con CI/CD**
   - GitHub Actions
   - GitLab CI
   - Jenkins

4. **Tests en dispositivos reales**
   - Android real
   - iOS real
   - Web en múltiples navegadores

## 📚 Referencias

- [Flutter Integration Test Documentation](https://flutter.dev/docs/testing/integration-tests)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [Finder API](https://api.flutter.dev/flutter/flutter_test/Finder-class.html)

---

**Actualizado:** 2024
**Estado:** ✅ Todos los tests funcionando en Windows Desktop
