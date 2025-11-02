# Guía: Cómo Agregar Más Tests E2E

## 🎯 Objetivo
Ampliar la suite de tests E2E con nuevas pruebas sin romper las existentes.

## 📋 Pasos Básicos

### 1. Usar la Estructura Correcta

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mi Grupo de Tests', () {
    
    // IMPORTANTE: Limpiar estado antes de cada test
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('user');
      await prefs.remove('selectedInstitutionId');
    });

    testWidgets('Mi primer test', (WidgetTester tester) async {
      // Aquí va el test
    });
  });
}
```

### 2. Iniciar la App

```dart
testWidgets('Ejemplo', (WidgetTester tester) async {
  // ✅ CORRECTO
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Continuar con el test...
});
```

### 3. Buscar Widgets Correctamente

```dart
// ❌ EVITA - Depende de Keys (no siempre funcionan en desktop)
find.byKey(const Key('emailField'))

// ✅ USA - Búsqueda por tipo
find.byType(TextFormField)

// ✅ USA - Búsqueda por texto
find.text('Instituciones')

// ✅ USA - Búsqueda por icono
find.byIcon(Icons.add)
```

### 4. Acceso Seguro a Widgets

```dart
// ✅ CORRECTO - Validar primero
final fields = find.byType(TextFormField);
if (fields.evaluate().isEmpty) {
  throw Exception('No se encontraron campos');
}

if (fields.evaluate().length < 2) {
  throw Exception('No hay suficientes campos');
}

await tester.enterText(fields.at(0), 'email');

// ❌ EVITA - Asumir que existe
await tester.enterText(find.byType(TextFormField).at(5), 'text');
```

### 5. Manejar Múltiples Resultados

```dart
// ❌ Falla si hay más de 1
expect(find.text('Instituciones'), findsOneWidget);

// ✅ Funciona con múltiples
expect(find.text('Instituciones'), findsWidgets);

// ✅ Usa el primero
await tester.tap(find.text('Instituciones').first);
```

## 🧪 Ejemplos de Tests

### Test Simple: Validar Campo Requerido

```dart
testWidgets('Campo email es requerido', (WidgetTester tester) async {
  print('\n=== Test: Campo Requerido ===');
  
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Buscar botón de submit sin llenar email
  final buttons = find.byType(ElevatedButton);
  await tester.tap(buttons.first);
  await tester.pumpAndSettle();

  // Verificar que hay mensaje de error
  final errorText = find.text('Campo requerido');
  expect(errorText, findsWidgets);
  
  print('✓ Validación funcionando');
});
```

### Test Complejo: CRUD de Institución

```dart
testWidgets('CRUD completo de institución', (WidgetTester tester) async {
  print('\n=== Test: CRUD Institución ===');
  
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // LOGIN
  print('1. Realizando login...');
  final textFields = find.byType(TextFormField);
  await tester.enterText(textFields.at(0), 'superadmin@asistapp.com');
  await tester.enterText(textFields.at(1), 'Admin123!');
  final buttons = find.byType(ElevatedButton);
  await tester.tap(buttons.first);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Navegar a Instituciones
  print('2. Navegando a Instituciones...');
  await tester.tap(find.text('Instituciones').first);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // CREATE - Agregar institución
  print('3. Creando institución...');
  final fabButton = find.byType(FloatingActionButton);
  if (fabButton.evaluate().isNotEmpty) {
    await tester.tap(fabButton.first);
    await tester.pumpAndSettle();
    
    // Llenar formulario
    final formFields = find.byType(TextFormField);
    await tester.enterText(formFields.at(0), 'Test Institution');
    await tester.enterText(formFields.at(1), 'TEST-001');
    await tester.enterText(formFields.at(2), 'test@institution.edu');
    
    // Guardar
    final saveButtons = find.byType(ElevatedButton);
    await tester.tap(saveButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // READ - Verificar que fue creada
  print('4. Verificando creación...');
  expect(find.text('Test Institution'), findsWidgets);

  // UPDATE - Actualizar
  print('5. Actualizando institución...');
  // ... código para encontrar y editar

  // DELETE - Eliminar
  print('6. Eliminando institución...');
  // ... código para eliminar

  print('✓ CRUD completo verificado');
});
```

### Test de Performance

```dart
testWidgets('Tiempo de carga del dashboard', (WidgetTester tester) async {
  print('\n=== Test: Performance ===');
  
  app.main();
  
  final stopwatch = Stopwatch()..start();
  await tester.pumpAndSettle(const Duration(seconds: 5));
  stopwatch.stop();
  
  print('Dashboard cargado en: ${stopwatch.elapsedMilliseconds}ms');
  
  // Verificar que es rápido (< 5 segundos)
  expect(stopwatch.elapsedMilliseconds, lessThan(5000));
  
  print('✓ Performance test pasado');
});
```

### Test de Validación

```dart
testWidgets('Validar formato de email', (WidgetTester tester) async {
  print('\n=== Test: Validación Email ===');
  
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Llenar email inválido
  final textFields = find.byType(TextFormField);
  await tester.enterText(textFields.at(0), 'email-invalido');
  await tester.pumpAndSettle();

  // Presionar submit
  final buttons = find.byType(ElevatedButton);
  await tester.tap(buttons.first);
  await tester.pumpAndSettle();

  // Verificar error
  final errorMessage = find.text('Email inválido');
  expect(errorMessage, findsWidgets);
  
  print('✓ Validación de email funciona');
});
```

## 🎨 Patrones Reutilizables

### Patrón: Helper Function

```dart
// Crear función auxiliar
Future<void> loginAndNavigate(WidgetTester tester, String path) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Login
  final textFields = find.byType(TextFormField);
  await tester.enterText(textFields.at(0), 'superadmin@asistapp.com');
  await tester.enterText(textFields.at(1), 'Admin123!');
  
  final buttons = find.byType(ElevatedButton);
  await tester.tap(buttons.first);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Navegar
  await tester.tap(find.text(path).first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

// Usar la función
testWidgets('Mi test', (WidgetTester tester) async {
  await loginAndNavigate(tester, 'Instituciones');
  // ... resto del test
});
```

### Patrón: Datos Dinámicos

```dart
testWidgets('Crear multiple', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Usar timestamp para datos únicos
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  
  final email = 'test_$timestamp@example.com';
  final code = 'CODE_$timestamp';
  
  // Usar estos valores en el test
  await tester.enterText(find.byType(TextFormField).at(0), email);
  
  // Verificar
  expect(find.text(email), findsWidgets);
});
```

## ✅ Checklist Antes de Enviar

- [ ] El test está dentro de un `group()`
- [ ] Hay `setUp()` que limpia `SharedPreferences`
- [ ] Usa `find.byType()` en lugar de `find.byKey()`
- [ ] Validar widgets con `evaluate().isNotEmpty` antes de usar
- [ ] Usar `findsWidgets` cuando hay múltiples resultados
- [ ] Esperar con `pumpAndSettle()` después de acciones
- [ ] Test es independiente (no depende de otro)
- [ ] Mensaje de print descriptivo
- [ ] Print de resultado final (✓ o ✗)

## 📊 Estructura de Múltiples Tests

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Tests', () {
    setUp(() async { /* limpiar estado */ });
    testWidgets('Test 1', (WidgetTester tester) async { /* ... */ });
    testWidgets('Test 2', (WidgetTester tester) async { /* ... */ });
  });

  group('Institution Tests', () {
    setUp(() async { /* limpiar estado */ });
    testWidgets('Test 3', (WidgetTester tester) async { /* ... */ });
    testWidgets('Test 4', (WidgetTester tester) async { /* ... */ });
  });

  group('User Tests', () {
    setUp(() async { /* limpiar estado */ });
    testWidgets('Test 5', (WidgetTester tester) async { /* ... */ });
    testWidgets('Test 6', (WidgetTester tester) async { /* ... */ });
  });
}
```

## 🚀 Ejecutar Nuevos Tests

```bash
# Ejecutar archivo específico
flutter test integration_test/nuevo_test.dart -d windows

# Ejecutar solo un grupo
flutter test integration_test/nuevo_test.dart -d windows --name "Login Tests"

# Ejecutar solo un test
flutter test integration_test/nuevo_test.dart -d windows --name "Test 1"

# Ejecutar con salida verbose
flutter test integration_test/nuevo_test.dart -d windows --verbose
```

## 📝 Template para Copiar

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mi Grupo de Tests', () {
    
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('user');
      await prefs.remove('selectedInstitutionId');
    });

    testWidgets('Mi test descriptivo', (WidgetTester tester) async {
      print('\n=== Mi Test ===');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test aquí
      
      print('✓ Test completado');
    });
  });
}
```

---

**Guía:** Agregar Más Tests E2E
**Versión:** 1.0
**Última actualización:** 2024
