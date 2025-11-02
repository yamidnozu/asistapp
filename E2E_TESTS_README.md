# 🧪 Pruebas de Integración End-to-End (E2E)

## Descripción Rápida

Este proyecto incluye un suite completo de pruebas E2E utilizando `integration_test` de Flutter. Las pruebas automatizan el flujo completo de la aplicación desde login hasta operaciones CRUD de instituciones y usuarios.

## 📁 Estructura de Archivos de Prueba

```
integration_test/
├── app_test.dart              # Script principal de pruebas E2E
├── extended_tests.dart        # Pruebas adicionales (validaciones, búsqueda, etc.)
```

Documentación:
```
/
├── E2E_TESTING_GUIDE.md       # Guía completa de pruebas
├── KEYS_GUIDE.md              # Instrucciones para agregar Keys
└── README.md (este archivo)
```

## 🚀 Quick Start

### 1. Preparar el Entorno

```bash
# Asegúrate de tener Flutter actualizado
flutter upgrade

# Instala dependencias
flutter pub get

# Verifica que tienes un emulador o dispositivo
flutter devices
```

### 2. Iniciar Backend

```bash
cd backend
npm install
npm start
```

### 3. Ejecutar Pruebas

```bash
# Prueba principal
flutter test integration_test/app_test.dart

# Todas las pruebas de integración
flutter test integration_test/

# Con más verbosidad
flutter test integration_test/app_test.dart -v
```

## 📊 Estructura de Pruebas

### `app_test.dart` - Script Principal

**Funciones Disponibles:**

1. `loginAsAdmin()` - Login como Super Admin
2. `navigateToInstitutions()` - Ir a gestión de instituciones
3. `createInstitution()` - Crear institución
4. `updateInstitution()` - Actualizar institución
5. `deleteInstitution()` - Eliminar institución
6. `navigateToUsers()` - Ir a gestión de usuarios
7. `createUser()` - Crear usuario
8. `deleteUser()` - Eliminar usuario

**Ejemplo de Uso:**

```dart
testWidgets('Mi prueba personalizada', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  await loginAsAdmin(tester);
  await navigateToInstitutions(tester);
  await createInstitution(tester, 'Mi Institución', 'MI-001', 'info@mi.edu');
  
  // Tu lógica de prueba aquí
});
```

### `extended_tests.dart` - Pruebas Avanzadas

Incluye:
- Validaciones de formularios
- Búsqueda y filtrado
- Manejo de errores
- Estados de carga

## 🔧 Configuración Necesaria

### Keys Requeridas

El script espera que estos widgets tengan Keys:

#### Login Screen
```dart
// lib/screens/login_screen.dart
TextFormField(key: const Key('emailField'), ...)
TextFormField(key: const Key('passwordField'), ...)
ElevatedButton(key: const Key('loginButton'), ...)
```

#### Institutions Management
```dart
// lib/screens/institutions/
FloatingActionButton(key: const Key('addInstitutionButton'), ...)
TextFormField(key: const Key('nombreInstitucionField'), ...)
TextFormField(key: const Key('codigoInstitucionField'), ...)
TextFormField(key: const Key('emailInstitucionField'), ...)
ElevatedButton(key: const Key('formSaveButton'), ...)
```

#### User Management
```dart
// lib/screens/users/
TextField(key: const Key('user_form_nombres'), ...)
TextField(key: const Key('user_form_apellidos'), ...)
TextField(key: const Key('emailUsuarioField'), ...)
TextField(key: const Key('user_form_identificacion'), ...)
TextField(key: const Key('user_form_telefono'), ...)
ElevatedButton(key: const Key('formSaveButton'), ...)
```

**Ver `KEYS_GUIDE.md` para instrucciones completas de agregar Keys.**

## 📋 Flujo de Prueba Principal

```
1. Login como Super Admin
   ├─ Ingresar email
   ├─ Ingresar contraseña
   └─ Verificar acceso al dashboard

2. CRUD de Instituciones
   ├─ Crear institución de prueba
   ├─ Verificar creación
   ├─ Actualizar nombre
   ├─ Verificar actualización
   ├─ Eliminar institución
   └─ Verificar eliminación

3. CRUD de Usuarios
   ├─ Crear profesor de prueba
   ├─ Verificar creación
   ├─ Eliminar usuario
   └─ Verificar eliminación

4. Logout (opcional)
```

## 🧨 Casos de Prueba Disponibles

### Prueba Principal: `app_test.dart`
- ✅ Login, CRUD Instituciones, CRUD Usuarios, Logout

### Pruebas Extendidas: `extended_tests.dart`
- ✅ Validaciones de formularios
- ✅ Búsqueda y filtrado
- ✅ Manejo de estados de carga
- ✅ Flujos de error

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS (con algunas limitaciones)
- ✅ Windows (desktop)
- ✅ Web (limitado)

## ⚠️ Solución de Problemas Comunes

### "Could not find widget with Key 'emailField'"

**Solución:**
1. Verifica que hayas agregado la Key al widget
2. Verifica que el nombre de la Key coincida exactamente
3. Ejecuta `flutter analyze` para buscar problemas

```bash
grep -r "key: const Key" lib/screens/login_screen.dart
```

### "Target of URI doesn't exist"

```bash
flutter clean
flutter pub get
```

### "Test timeout"

Aumenta el timeout:
```bash
flutter test integration_test/app_test.dart --timeout=300s
```

### "Backend connection refused"

1. Verifica que el backend esté corriendo
2. Verifica la IP en `lib/utils/api_config.dart`
3. Verifica que el firewall permita la conexión

### "Emulator not found"

```bash
# Lista emuladores disponibles
emulator -list-avds

# Inicia un emulador
emulator -avd Pixel_4_API_30
```

## 🔍 Debugging

### Ver todos los widgets disponibles

```dart
// Agregar en la prueba
find.byType(TextFormField).evaluate().forEach((element) {
  print(element.widget);
});
```

### Capturar screenshots durante las pruebas

Las pruebas pueden capturar screenshots agregando:

```dart
await tester.binding.window.physicalSize = const Size(1080, 1920);
addTearDown(tester.binding.window.clearPhysicalSize);
```

### Ver logs detallados

```bash
flutter test integration_test/app_test.dart -v 2>&1 | grep -E "(✓|✗|---)"
```

## 🔄 Extender las Pruebas

### Agregar una nueva función de prueba

```dart
// 1. Crear función auxiliar
Future<void> miNuevaPrueba(WidgetTester tester) async {
  print('Ejecutando mi nueva prueba...');
  
  final widget = find.byKey(const Key('miWidget'));
  expect(widget, findsOneWidget);
  await tester.tap(widget);
  await tester.pumpAndSettle();
  
  print('✓ Mi nueva prueba completada.');
}

// 2. Usarla en el test
testWidgets('Mi test', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  await loginAsAdmin(tester);
  await miNuevaPrueba(tester);
});
```

### Agregar una nueva suite de pruebas

```dart
group('Mi nueva suite de pruebas', () {
  testWidgets('Primer test', (WidgetTester tester) async {
    // ...
  });

  testWidgets('Segundo test', (WidgetTester tester) async {
    // ...
  });
});
```

## 🤖 Integración Continua (CI/CD)

Para ejecutar pruebas en GitHub Actions, añade a `.github/workflows/test.yml`:

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run integration tests
        run: |
          flutter config --enable-web
          flutter test integration_test/app_test.dart
```

## 📚 Documentación Relacionada

- **E2E_TESTING_GUIDE.md** - Guía completa y detallada
- **KEYS_GUIDE.md** - Cómo agregar Keys a los widgets
- [Flutter Integration Test Documentation](https://flutter.dev/docs/testing/integration-tests)

## 🎯 Mejores Prácticas

1. **Mantén las Keys consistentes**
   ```dart
   // ✅ Bueno
   key: const Key('emailField')
   
   // ❌ Malo
   key: const Key('Email_Field_123')
   ```

2. **Usa `pumpAndSettle()` después de acciones**
   ```dart
   await tester.tap(button);
   await tester.pumpAndSettle();  // Espera animaciones
   ```

3. **Genera datos únicos para pruebas**
   ```dart
   final timestamp = DateTime.now().millisecondsSinceEpoch;
   final email = 'test.$timestamp@example.com';
   ```

4. **Reutiliza funciones auxiliares**
   ```dart
   await loginAsAdmin(tester);  // En lugar de repetir el login
   ```

5. **Agrega mensajes descriptivos**
   ```dart
   expect(widget, findsOneWidget, reason: 'Widget no encontrado');
   ```

## 📞 Soporte

Si encuentras problemas:

1. Revisa la sección de "Solución de Problemas"
2. Consulta los archivos de documentación
3. Ejecuta con `-v` para más detalles:
   ```bash
   flutter test integration_test/app_test.dart -v
   ```

## ✅ Checklist Antes de Hacer Push

- [ ] Las pruebas pasan localmente
- [ ] El backend está corriendo
- [ ] No hay errores de análisis (`flutter analyze`)
- [ ] Las Keys están agregadas correctamente
- [ ] Los archivos de documentación están actualizados

---

**¡Felicidades! Ahora tienes un suite completo de pruebas E2E. 🎉**

Para más información, consulta `E2E_TESTING_GUIDE.md`.
