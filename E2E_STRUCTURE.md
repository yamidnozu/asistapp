# Estructura de E2E Testing - Proyecto DemoLife/AsistApp

## 📂 Árbol de Archivos

```
DemoLife/
├── integration_test/
│   ├── app_e2e_test.dart           ✅ Tests principales (RECOMENDADO)
│   ├── simple_test.dart             ✅ Tests de diagnóstico
│   └── app_test.dart                🔄 Tests avanzados (en revisión)
│
├── Documentation/
│   ├── README_E2E_TESTING.md        📖 Guía rápida (LEER PRIMERO)
│   ├── E2E_TESTING_GUIDE_UPDATED.md 📖 Documentación detallada
│   ├── E2E_TESTING_COMPLETE.md      📖 Resumen técnico
│   └── E2E_IMPLEMENTATION_SUMMARY.md 📖 Histórico de cambios
│
├── Scripts/
│   ├── run_e2e_tests_updated.bat    🎮 Menu interactivo (Windows)
│   ├── run_e2e_tests.bat            🎮 Script básico (Windows)
│   └── run_e2e_tests.sh             🎮 Script (Linux/Mac)
│
└── pubspec.yaml                     ⚙️ Dependencies (integration_test)
```

## 🎯 Cuál Archivo Usar Cuando

### Para Ejecutar Tests
```bash
# ✅ PRINCIPAL - Usa esto
flutter test integration_test/app_e2e_test.dart -d windows

# ✅ ALTERNATIVA - Diagnóstico rápido
flutter test integration_test/simple_test.dart -d windows
```

### Para Documentación
```
1️⃣ README_E2E_TESTING.md        ← LEER PRIMERO (Quick Start)
2️⃣ E2E_TESTING_GUIDE_UPDATED.md ← Detalles técnicos
3️⃣ E2E_TESTING_COMPLETE.md      ← Referencia completa
```

### Para Scripts
```bash
# 🎮 Windows - Menu interactivo
run_e2e_tests_updated.bat

# 🎮 Linux/Mac
./run_e2e_tests.sh
```

## 🔧 Configuración Mínima Requerida

### pubspec.yaml - REQUERIDO
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

### Backend - OBLIGATORIO
```bash
cd backend
npm start
# Disponible en: http://192.168.20.22:3000
```

### Credenciales - NECESARIAS
```
Email: superadmin@asistapp.com
Contraseña: Admin123!
```

## 📊 Matriz de Tests

| Test | Archivo | Plataforma | Duración | Estado |
|------|---------|-----------|----------|--------|
| Login exitoso | app_e2e_test.dart | Windows | 18s | ✅ |
| Navegar Instituciones | app_e2e_test.dart | Windows | 34s | ✅ |
| Ver Usuarios | app_e2e_test.dart | Windows | 38s | ✅ |
| Diagnóstico | app_e2e_test.dart | Windows | 56s | ✅ |
| Logout | app_e2e_test.dart | Windows | 1:19m | ✅ |
| **Total** | **5 tests** | **Windows** | **1:19m** | **✅** |

## 🚀 Guía Rápida

### 1. Preparar Ambiente
```bash
# Actualizar Flutter
flutter upgrade

# Instalar dependencias
flutter pub get

# Limpiar (si hay problemas)
flutter clean && flutter pub get
```

### 2. Iniciar Backend
```bash
cd backend
npm start
# Esperar: "Server listening on port 3000"
```

### 3. Ejecutar Tests
```bash
# En otra terminal
cd .. # Volver a DemoLife
flutter test integration_test/app_e2e_test.dart -d windows
```

### 4. Ver Resultados
```
✅ Test 1/5: Login exitoso ... PASSED
✅ Test 2/5: Navegar Instituciones ... PASSED
✅ Test 3/5: Ver Usuarios ... PASSED
✅ Test 4/5: Diagnóstico ... PASSED
✅ Test 5/5: Logout ... PASSED

All tests passed! ✅
```

## 🔑 Conceptos Clave

### SharedPreferences Cleanup
```dart
// Se ejecuta antes de cada test
setUp(() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('accessToken');
  // ... limpiar otros tokens
});
```

### Widget Finding
```dart
// Búsqueda robusta - RECOMENDADO
final fields = find.byType(TextFormField);
final buttons = find.byType(ElevatedButton);

// Acceso seguro
if (fields.evaluate().isNotEmpty) {
  await tester.enterText(fields.at(0), 'value');
}
```

### Timing
```dart
// Esperar a que se cargue
await tester.pumpAndSettle(const Duration(seconds: 3));

// Esperar después de interacción
await tester.pumpAndSettle(const Duration(seconds: 5));
```

## 📋 Checklist Pre-Testing

- [ ] Backend corriendo en `192.168.20.22:3000`
- [ ] Base de datos tiene Super Admin creado
- [ ] Credenciales correctas: `superadmin@asistapp.com` / `Admin123!`
- [ ] Flutter SDK actualizado: `flutter upgrade`
- [ ] Dependencias: `flutter pub get`
- [ ] Sin puertos en conflicto (3000, 5900 para VNC)
- [ ] Suficiente espacio en disco (500MB mínimo)
- [ ] RAM disponible (2GB recomendado)

## 🐛 Troubleshooting Rápido

| Error | Solución |
|-------|----------|
| Connection refused | Backend no está corriendo |
| Widget not found | Validar que el widget existe |
| Timeout | Aumentar tiempo en `pumpAndSettle()` |
| Index out of range | Verificar `evaluate().length` antes |
| Status 401 | Credenciales incorrectas o token expirado |

## 📱 Ejecutar en Otras Plataformas

### Chrome (Web)
```bash
flutter test integration_test/app_e2e_test.dart -d chrome
```

### Android Emulator
```bash
flutter test integration_test/app_e2e_test.dart -d android
```

### iOS Simulator
```bash
flutter test integration_test/app_e2e_test.dart -d ios
```

## 🎓 Aprendiendo

### Estructura de un Test
```dart
testWidgets('Descripción', (WidgetTester tester) async {
  // 1. Arrange - Preparar
  app.main();
  await tester.pumpAndSettle();
  
  // 2. Act - Ejecutar
  await tester.enterText(field, 'value');
  await tester.tap(button);
  
  // 3. Assert - Verificar
  expect(find.text('esperado'), findsWidgets);
});
```

### Finders Comunes
```dart
find.byType(Widget)          // Por tipo de widget
find.text('text')            // Por texto exacto
find.byIcon(Icons.add)       // Por icono
find.byKey(Key('key'))       // Por Key (menos recomendado)
find.byWidgetPredicate(...)  // Personalizado
```

### Acciones Comunes
```dart
tester.enterText(finder, 'text')      // Escribir
tester.tap(finder)                    // Tocar
tester.pumpAndSettle()                // Esperar
tester.pumpAndSettle(Duration(...))   // Esperar X tiempo
tester.scrollUntilVisible(finder)     // Hacer scroll
tester.showKeyboard(finder)           // Mostrar teclado
```

## 📞 Contacto y Soporte

Para problemas específicos:
1. Revisa `README_E2E_TESTING.md`
2. Consulta `E2E_TESTING_GUIDE_UPDATED.md`
3. Verifica `E2E_TESTING_COMPLETE.md`

## 📚 Enlaces Útiles

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)

## ✅ Próximas Versiones

- [ ] CRUD completo tests
- [ ] Performance benchmarking
- [ ] CI/CD integration
- [ ] Device farm testing

---

**Documento:** Estructura de E2E Testing
**Versión:** 1.0
**Estado:** ✅ Producción Lista
**Plataforma:** Windows Desktop
