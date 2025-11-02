# 🎯 Guía: Pruebas de Aceptación E2E (Flujos de Usuario)

## 📋 Descripción

Este archivo contiene **pruebas de aceptación End-to-End (E2E)** que simulan los flujos reales de usuario para cada rol definido en la aplicación.

**Archivo:** `integration_test/acceptance_flows_test.dart`

## 👥 Flujos de Usuario Implementados

### 1. 🔐 Super Administrador
**Email:** `superadmin@asistapp.com`  
**Contraseña:** `Admin123!`

**Flujo:**
1. ✅ Login
2. ✅ CRUD Completo de Instituciones (Crear → Actualizar → Eliminar)
3. ✅ CRUD Completo de Usuarios (Crear Profesor → Eliminar)
4. ✅ Logout

**Tiempo estimado:** 2-3 minutos

---

### 2. 🏫 Administrador de Institución (Multi-Institución)
**Email:** `multi@asistapp.com`  
**Contraseña:** `Multi123!`

**Flujo:**
1. ✅ Login
2. ✅ Selección de Institución (si aplica)
3. ✅ CRUD de Usuarios (Crear Estudiante → Eliminar)
4. ✅ Logout

**Tiempo estimado:** 1-2 minutos

---

### 3. 👨‍🏫 Profesor
**Email:** `pedro.garcia@sanjose.edu`  
**Contraseña:** `Prof123!`

**Flujo:**
1. ✅ Login
2. ✅ Verificar Dashboard
3. ✅ Logout

**Tiempo estimado:** 30-45 segundos

---

### 4. 👨‍🎓 Estudiante
**Email:** `juan.perez@sanjose.edu`  
**Contraseña:** `Est123!`

**Flujo:**
1. ✅ Login
2. ✅ Verificar Dashboard
3. ✅ Logout

**Tiempo estimado:** 30-45 segundos

---

### 5. 👨‍💼 Admin de Institución Específica (San José)
**Email:** `admin@sanjose.edu`  
**Contraseña:** `SanJose123!`

**Flujo:**
1. ✅ Login
2. ✅ Verificar Dashboard
3. ✅ Logout

**Tiempo estimado:** 30-45 segundos

---

## 🚀 Cómo Ejecutar

### Opción 1: Ejecutar Todos los Flujos
```bash
flutter test integration_test/acceptance_flows_test.dart -d windows
```

### Opción 2: Ejecutar un Flujo Específico
```bash
# Solo Super Administrador
flutter test integration_test/acceptance_flows_test.dart -d windows --name "Super Administrador"

# Solo Profesor
flutter test integration_test/acceptance_flows_test.dart -d windows --name "Profesor"

# Solo Estudiante
flutter test integration_test/acceptance_flows_test.dart -d windows --name "Estudiante"
```

### Opción 3: Ejecutar en Otras Plataformas
```bash
# Chrome Web
flutter test integration_test/acceptance_flows_test.dart -d chrome

# Android (si tienes emulador)
flutter test integration_test/acceptance_flows_test.dart -d android

# iOS (si tienes simulador)
flutter test integration_test/acceptance_flows_test.dart -d ios
```

### Opción 4: Ejecutar con Salida Verbose
```bash
flutter test integration_test/acceptance_flows_test.dart -d windows --verbose
```

## 📋 Pre-requisitos

- ✅ Backend corriendo en `192.168.20.22:3000`
- ✅ Base de datos con datos del seed.ts ejecutados
- ✅ Todos los usuarios del seed.ts creados y activos
- ✅ Flutter SDK actualizado: `flutter upgrade`
- ✅ Dependencias: `flutter pub get`

## 🔍 Qué Buscan Estas Pruebas

### Validaciones de Seguridad
- ✅ Cada rol solo ve su contenido
- ✅ Tokens se generan correctamente
- ✅ Logout limpia la sesión

### Validaciones Funcionales - Super Admin
- ✅ Puede crear instituciones
- ✅ Puede actualizar instituciones
- ✅ Puede eliminar instituciones
- ✅ Puede crear usuarios
- ✅ Puede eliminar usuarios

### Validaciones Funcionales - Admin de Institución
- ✅ Puede seleccionar institución
- ✅ Solo ve usuarios de su institución
- ✅ Puede crear y eliminar usuarios

### Validaciones de Acceso
- ✅ Profesor ve su dashboard
- ✅ Estudiante ve su dashboard
- ✅ Acceso correcto según rol

## 📊 Resultado Esperado

```
═══════════════════════════════════════════════════════════════════════
🔐 Flujo 1: Super Administrador
✅ Login PASSED
✅ CRUD Instituciones PASSED
✅ CRUD Usuarios PASSED
✅ Logout PASSED

🏫 Flujo 2: Administrador de Institución
✅ Login PASSED
✅ Selección de Institución PASSED
✅ CRUD Usuarios PASSED
✅ Logout PASSED

👨‍🏫 Flujo 3: Profesor
✅ Login PASSED
✅ Dashboard PASSED
✅ Logout PASSED

👨‍🎓 Flujo 4: Estudiante
✅ Login PASSED
✅ Dashboard PASSED
✅ Logout PASSED

👨‍💼 Flujo 5: Admin San José
✅ Login PASSED
✅ Dashboard PASSED
✅ Logout PASSED

═══════════════════════════════════════════════════════════════════════
Total Tests: 5
Passed: 5 ✅
Failed: 0
Skipped: 0

All tests passed! ✅
═══════════════════════════════════════════════════════════════════════
```

## 🛠️ Troubleshooting

### Error: "No se encontraron campos de texto en la pantalla de login"
**Solución:** 
- Verifica que la pantalla de login tiene TextFormFields
- Asegúrate que el backend está corriendo

### Error: "Dashboard cargado correctamente" pero no aparece
**Solución:**
- Aumenta el timeout: `pumpAndSettle(const Duration(seconds: 7))`
- Verifica que el login fue exitoso

### Error: "Institución no aparece en lista"
**Solución:**
- Verifica que el formulario tiene todos los campos requeridos
- Aumenta el timeout después de guardar

### Error: "No se encontró botón de logout"
**Solución:**
- Es normal, el logout es opcional
- Algunas roles pueden no tener botón de logout visible

## 🔧 Funciones Auxiliares Disponibles

### `loginAs(tester, email, password)`
Realiza login con las credenciales proporcionadas.

### `performLogout(tester)`
Cierra la sesión del usuario actual.

### `navigateTo(tester, sectionName)`
Navega a una sección específica.

### `createInstitution(tester, nombre, codigo, email)`
Crea una nueva institución con CRUD completo.

### `updateInstitution(tester, originalName, newName)`
Actualiza el nombre de una institución.

### `deleteInstitution(tester, institutionName)`
Elimina una institución.

### `createUser(tester, nombres, apellidos, email, ...)`
Crea un nuevo usuario.

### `deleteUser(tester, email)`
Elimina un usuario.

## 📈 Interpretando los Logs

### Durante la Ejecución
```
╔═══════════════════════════════════════════╗
║  INICIANDO FLUJO: SUPER ADMINISTRADOR  ║
╚═══════════════════════════════════════════╝

━━━ PASO 1: LOGIN ━━━
[LOGIN] Iniciando sesión con: superadmin@asistapp.com
✅ Login completado

━━━ PASO 2: CRUD DE INSTITUCIONES ━━━
[CREATE] Creando institución: Instituto E2E 1698751234567
✅ Institución creada exitosamente

[UPDATE] Actualizando institución: Instituto E2E 1698751234567 -> Instituto E2E 1698751234567 (Actualizado)
✅ Institución actualizada exitosamente

[DELETE] Eliminando institución: Instituto E2E 1698751234567 (Actualizado)
✅ Institución eliminada exitosamente
```

### Símbolos Comunes
- ✅ = Acción completada exitosamente
- ⚠️ = Advertencia (continúa)
- ❌ = Error (falla el test)
- ℹ️ = Información

## 📝 Notas Importantes

1. **Datos Únicos:** Cada test usa un timestamp para evitar conflictos
2. **Limpieza Automática:** `clearAuthState()` limpia tokens antes de cada test
3. **Robustez:** Las funciones buscan por tipo de widget en lugar de texto
4. **Tolerancia:** Los tests omiten acciones opcionales (como logout)

## 🎓 Próximos Pasos

1. **Agregar más validaciones:**
   - Campos requeridos
   - Formatos de email
   - Contraseñas débiles

2. **Agregar más casos de uso:**
   - Intentos de login fallido
   - Cambio de contraseña
   - Recuperación de contraseña

3. **Mejorar CRUD:**
   - Búsqueda y filtrado
   - Paginación
   - Ordenamiento

## 📚 Referencias

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)

---

**Archivo:** `integration_test/acceptance_flows_test.dart`  
**Estado:** ✅ Listo para ejecutar  
**Última actualización:** 2024  
**Plataforma:** Windows Desktop, Chrome Web, Android, iOS
