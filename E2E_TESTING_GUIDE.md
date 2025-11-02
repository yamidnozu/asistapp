# Guía de Pruebas End-to-End (E2E) con Integration Test

## 📋 Descripción

Este proyecto utiliza `integration_test` de Flutter para realizar pruebas automatizadas end-to-end que simulan interacciones reales del usuario. El script de prueba `integration_test/app_test.dart` valida un flujo completo:

1. **Login** como Super Administrador
2. **CRUD de Instituciones** (Crear, Leer, Actualizar, Eliminar)
3. **CRUD de Usuarios** (Crear Profesor y Eliminar)
4. **Logout**

## ⚙️ Requisitos Previos

### 1. **Backend en Ejecución**
```bash
cd backend
npm install
npm start
```

El backend debe estar corriendo en la IP configurada (ej: 192.168.20.22:3000) y accesible desde el emulador/dispositivo.

### 2. **Base de Datos Preparada**
La base de datos debe tener seeded el usuario Super Admin:
- **Email**: `superadmin@asistapp.com`
- **Contraseña**: `Admin123!`

Si no existe, ejecuta el seed:
```bash
cd backend
npm run seed
```

### 3. **Emulador o Dispositivo Conectado**
```bash
# Verificar dispositivos disponibles
flutter devices

# Si usas emulador de Android, asegúrate de iniciarlo
emulator -avd <nombre_del_emulador>
```

### 4. **Dependencias de Flutter Instaladas**
```bash
flutter pub get
```

## 🎯 Keys Agregadas a los Widgets

Para que las pruebas sean robustas, se han agregado `Key` únicos a los widgets principales:

### Login Screen
```dart
TextFormField(key: const Key('emailField'), ...)
TextFormField(key: const Key('passwordField'), ...)
ElevatedButton(key: const Key('loginButton'), ...)
```

### Institutions Management
```dart
FloatingActionButton(key: const Key('addInstitutionButton'), ...)
TextFormField(key: const Key('nombreInstitucionField'), ...)
TextFormField(key: const Key('codigoInstitucionField'), ...)
TextFormField(key: const Key('emailInstitucionField'), ...)
ElevatedButton(key: const Key('formSaveButton'), ...)
OutlinedButton(key: const Key('cancelButton'), ...)
```

### User Management
```dart
TextField(key: const Key('user_form_nombres'), ...)
TextField(key: const Key('user_form_apellidos'), ...)
TextField(key: const Key('emailUsuarioField'), ...)
TextField(key: const Key('user_form_identificacion'), ...)
TextField(key: const Key('user_form_telefono'), ...)
```

## 🚀 Cómo Ejecutar las Pruebas

### Opción 1: Ejecutar prueba específica
```bash
flutter test integration_test/app_test.dart
```

### Opción 2: Ejecutar pruebas en un dispositivo específico
```bash
# En emulador Android
flutter test integration_test/app_test.dart -d android

# En dispositivo conectado
flutter test integration_test/app_test.dart -d emulator-5554

# En Windows
flutter test integration_test/app_test.dart -d windows
```

### Opción 3: Ejecutar todas las pruebas de integración
```bash
flutter test integration_test/
```

## 📊 Estructura del Script de Prueba

### Funciones Auxiliares

El script `app_test.dart` incluye funciones reutilizables para mantener el código limpio:

#### `loginAsAdmin(WidgetTester tester)`
Realiza el login como Super Admin.

```dart
await loginAsAdmin(tester);
```

#### `navigateToInstitutions(WidgetTester tester)`
Navega a la pantalla de gestión de instituciones.

```dart
await navigateToInstitutions(tester);
```

#### `createInstitution(WidgetTester tester, String name, String code, String email)`
Crea una nueva institución.

```dart
await createInstitution(tester, 'Mi Institución', 'MI-001', 'info@miinst.edu');
```

#### `updateInstitution(WidgetTester tester, String currentName, String newName)`
Actualiza el nombre de una institución existente.

```dart
await updateInstitution(tester, 'Mi Institución', 'Mi Institución Actualizada');
```

#### `deleteInstitution(WidgetTester tester, String institutionName)`
Elimina una institución.

```dart
await deleteInstitution(tester, 'Mi Institución');
```

#### `navigateToUsers(WidgetTester tester)`
Navega a la pantalla de gestión de usuarios.

```dart
await navigateToUsers(tester);
```

#### `createUser(WidgetTester tester, String nombres, String apellidos, String email, String identificacion)`
Crea un nuevo usuario (profesor).

```dart
await createUser(tester, 'Juan', 'Pérez', 'juan@test.edu', 'DNI-12345');
```

#### `deleteUser(WidgetTester tester, String fullName)`
Elimina un usuario.

```dart
await deleteUser(tester, 'Juan Pérez');
```

## 🧪 Entender la Salida de las Pruebas

Cuando ejecutas las pruebas, verás una salida como:

```
--- PASO 1: Iniciando Sesión como Super Admin ---
✓ Login como Super Admin exitoso.

--- PASO 2: Realizando CRUD de Instituciones ---
Navegando a Instituciones...
✓ Navegación a Instituciones completada.
Creando institución: Institución E2E Test...
✓ Institución creada exitosamente.
Actualizando institución: Institución E2E Test -> Institución E2E Test (Actualizada)...
✓ Institución actualizada exitosamente.
Eliminando institución: Institución E2E Test (Actualizada)...
✓ Institución eliminada exitosamente.
✓ CRUD de Instituciones completado.

--- PASO 3: Realizando CRUD de Usuarios (Profesor) ---
Navegando a Usuarios Globales...
✓ Navegación a Usuarios completada.
Creando usuario: Profesor E2E Test...
✓ Usuario creado exitosamente.
Eliminando usuario: Profesor E2E Test...
✓ Usuario eliminado exitosamente.
✓ CRUD de Usuarios completado.

🎉🎉🎉 ¡Flujo completo verificado con éxito! 🎉🎉🎉
```

## ⚠️ Solución de Problemas

### "Target of URI doesn't exist" o "URI_DOES_NOT_EXIST"
```bash
# Limpia el proyecto
flutter clean
flutter pub get
```

### "Could not find a matching widget with text: 'Instituciones'"
- Verifica que el texto exacto coincida con lo que aparece en la UI
- Considera usar `find.byKey()` en lugar de `find.byText()`

### "Emulator not found"
```bash
# Lista emuladores disponibles
emulator -list-avds

# Inicia un emulador
emulator -avd Pixel_4_API_30
```

### "Backend connection refused"
- Verifica que el backend esté corriendo
- Confirma la IP en el archivo de configuración (lib/utils/api_config.dart)
- Revisa que el firewall permita las conexiones

### "Test timeout"
Aumenta el timeout en el comando:
```bash
flutter test integration_test/app_test.dart --test-randomize-ordering-seed=random --timeout=300s
```

## 📱 Mejores Prácticas

1. **Usa Keys**: Siempre prefiere `find.byKey()` sobre `find.byText()` para mayor robustez
2. **pumpAndSettle()**: Usa este método después de acciones que causan animaciones
3. **Datos Únicos**: El script usa `DateTime.now().millisecondsSinceEpoch` para generar datos únicos
4. **Funciones Auxiliares**: Reutiliza las funciones proporcionadas para mantener el código limpio
5. **Tiempos Generosos**: Los timeouts son amplios para permitir operaciones de red

## 🔄 Extensión de las Pruebas

Para agregar nuevas pruebas, crea funciones auxiliares siguiendo el patrón:

```dart
Future<void> miNuevaPrueba(WidgetTester tester, String parametro) async {
  print('Realizando mi nueva prueba...');
  
  // Lógica de prueba
  final widget = find.byKey(const Key('miWidget'));
  expect(widget, findsOneWidget);
  await tester.tap(widget);
  await tester.pumpAndSettle();
  
  print('✓ Mi nueva prueba completada.');
}
```

Luego, llámala desde el `testWidgets`:

```dart
await miNuevaPrueba(tester, 'valor');
```

## 📚 Referencias

- [Flutter Integration Test Documentation](https://flutter.dev/docs/testing/integration-tests)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [Finder API](https://api.flutter.dev/flutter/flutter_test/Finder-class.html)

## 🤝 Contribuir

Si encuentras problemas o tienes sugerencias de mejora:

1. Documenta el problema
2. Proporciona pasos para reproducirlo
3. Sugiere una solución

---

**¡Felicidades!** Ya tienes un suite de pruebas E2E robusto y mantenible. 🎉
