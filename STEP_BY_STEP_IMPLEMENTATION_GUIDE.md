# 🚀 Guía Paso a Paso: Implementar Pruebas de Aceptación E2E

## 📌 Descripción General

Esta guía te mostrará exactamente qué hacer para implementar y ejecutar las **Pruebas de Aceptación End-to-End (E2E)** que cubren todos los flujos de usuario de tu aplicación.

## 📋 Tabla de Contenidos

1. [Paso 0: Preparación](#paso-0-preparación)
2. [Paso 1: Agregar Keys (Opcional)](#paso-1-agregar-keys-opcional)
3. [Paso 2: Verificar Archivo de Tests](#paso-2-verificar-archivo-de-tests)
4. [Paso 3: Preparar Backend](#paso-3-preparar-backend)
5. [Paso 4: Ejecutar Tests](#paso-4-ejecutar-tests)
6. [Paso 5: Interpretar Resultados](#paso-5-interpretar-resultados)

---

## Paso 0: Preparación

### 0.1 Verificar Flutter
```bash
# Actualizar Flutter a la versión más reciente
flutter upgrade

# Verificar que todo está bien
flutter doctor

# Limpiar caché (si hay problemas)
flutter clean
```

### 0.2 Instalar Dependencias
```bash
# En la raíz de tu proyecto Flutter
flutter pub get

# Actualizar pubspec.yaml si es necesario
# Asegúrate de tener:
# dev_dependencies:
#   flutter_test:
#     sdk: flutter
#   integration_test:
#     sdk: flutter
```

### 0.3 Verificar Proyecto
```bash
# Verificar que no hay errores de análisis
flutter analyze

# Compilar (opcional)
flutter build windows  # o tu plataforma
```

---

## Paso 1: Agregar Keys (Opcional)

> ℹ️ **NOTA:** Si no tienes Keys en tus widgets, los tests funcionarán pero serán menos robustos. Se recomienda agregar las Keys críticas.

### 1.1 Revisar Checklist
Lee el archivo: `KEYS_IMPLEMENTATION_CHECKLIST.md`

### 1.2 Agregar Keys Críticas (15 minutos)

Abre estos archivos y agrega Keys:

#### 1.2.1 `lib/screens/login_screen.dart`
```dart
// Busca el TextFormField de email y cambia a:
TextFormField(
  key: const Key('login_email_field'),  // ← Agrega esta línea
  // ... resto del código
)

// Lo mismo para password
TextFormField(
  key: const Key('login_password_field'),  // ← Agrega esta línea
  // ... resto del código
)

// Y para el botón de login
ElevatedButton(
  key: const Key('login_button'),  // ← Agrega esta línea
  // ... resto del código
)
```

#### 1.2.2 Dashboard/Navegación
```dart
// Instituciones
Tab(
  key: const Key('nav_institutions'),  // ← Agrega
  child: Text('Instituciones'),
)

// Usuarios
Tab(
  key: const Key('nav_users'),  // ← Agrega
  child: Text('Usuarios'),
)
```

#### 1.2.3 Formularios
```dart
// Nombre/Código/Email fields
TextFormField(
  key: const Key('form_name_field'),  // ← Agrega
  decoration: InputDecoration(labelText: 'Nombre'),
)

// Botón guardar
ElevatedButton(
  key: const Key('form_save_button'),  // ← Agrega
  child: Text('Guardar'),
)
```

#### 1.2.4 Alertas
```dart
// En AlertDialog - Botón confirmar
TextButton(
  key: const Key('alert_confirm_button'),  // ← Agrega
  onPressed: () => _delete(),
  child: Text('Eliminar'),
)
```

### 1.3 Compilar y Verificar
```bash
# Verificar que no hay errores
flutter analyze

# Si hay errores, corregir los Keys (no deben estar en strings si no son const)
```

---

## Paso 2: Verificar Archivo de Tests

### 2.1 Localizar Archivo
```
Tu proyecto debe tener:
c:\Proyectos\DemoLife\integration_test\acceptance_flows_test.dart
```

### 2.2 Abrir y Revisar
- Abre el archivo en VS Code
- Verifica que compile sin errores
- Nota los 5 grupos de tests (Super Admin, Admin Multi, Profesor, Estudiante, Admin San José)

### 2.3 Entender Estructura
El archivo contiene:
- ✅ Funciones auxiliares (login, logout, CRUD)
- ✅ 5 grupos de pruebas (uno por rol)
- ✅ Limpieza automática de estado
- ✅ Logging detallado

---

## Paso 3: Preparar Backend

### 3.1 Iniciar Backend
```bash
cd backend

# Opción A: npm
npm install  # si es necesario
npm start

# Opción B: Docker (si lo tienes)
docker-compose up

# Opción C: Prisma (si es necesario)
npx prisma migrate dev
```

### 3.2 Ejecutar Seed (si es necesario)
```bash
# Crear usuarios y datos de prueba
npx prisma db seed

# O manualmente
npm run seed
```

### 3.3 Verificar Backend
```bash
# En otra terminal, verifica que está funcionando
curl http://192.168.20.22:3000/health

# Debe responder algo como:
# {"status":"ok"}
```

### 3.4 Verificar Usuarios Existen
Abre tu cliente de BD y verifica que existen estos usuarios:
- ✅ `superadmin@asistapp.com` (contraseña: `Admin123!`)
- ✅ `multi@asistapp.com` (contraseña: `Multi123!`)
- ✅ `pedro.garcia@sanjose.edu` (contraseña: `Prof123!`)
- ✅ `juan.perez@sanjose.edu` (contraseña: `Est123!`)
- ✅ `admin@sanjose.edu` (contraseña: `SanJose123!`)

---

## Paso 4: Ejecutar Tests

### 4.1 Abrir Terminal en VS Code

```bash
cd c:\Proyectos\DemoLife
```

### 4.2 Ejecutar Todos los Tests
```bash
# Opción A: Todos los flujos (recomendado para validación completa)
flutter test integration_test/acceptance_flows_test.dart -d windows

# Opción B: Con salida verbose (para debugging)
flutter test integration_test/acceptance_flows_test.dart -d windows --verbose

# Opción C: Un flujo específico
flutter test integration_test/acceptance_flows_test.dart -d windows --name "Super Administrador"
```

### 4.3 Esperar Compilación y Ejecución

**Primera vez (~2-3 minutos):**
```
Building Windows application...
✓ Built build\windows\x64\runner\Debug\asistapp.exe

00:00 +0: 🔐 Flujo 1: Super Administrador
```

**Después (~1-2 minutos):**
```
00:18 +1: 🏫 Flujo 2: Administrador de Institución
00:34 +2: 👨‍🏫 Flujo 3: Profesor
00:51 +3: 👨‍🎓 Flujo 4: Estudiante
01:08 +4: 👨‍💼 Flujo 5: Admin Institución
```

### 4.4 Observe la Ejecución

La aplicación se abrirá y ejecutará automáticamente:

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

[UPDATE] Actualizando institución
✅ Institución actualizada exitosamente

[DELETE] Eliminando institución
✅ Institución eliminada exitosamente
```

---

## Paso 5: Interpretar Resultados

### 5.1 Éxito Total (Lo que Esperas)

```
═══════════════════════════════════════════════════════════════════════
✅ 🔐 Flujo 1: Super Administrador ... PASSED
✅ 🏫 Flujo 2: Administrador de Institución ... PASSED
✅ 👨‍🏫 Flujo 3: Profesor ... PASSED
✅ 👨‍🎓 Flujo 4: Estudiante ... PASSED
✅ 👨‍💼 Flujo 5: Admin Institución ... PASSED

01:20 +5: (tearDownAll)
01:20 +5: All tests passed! ✅

═══════════════════════════════════════════════════════════════════════
```

### 5.2 Error: Login Falla

**Síntoma:**
```
[LOGIN] Iniciando sesión con: superadmin@asistapp.com
❌ TestFailure: Expected exactly one widget but found 0
```

**Solución:**
1. ✅ Verifica que backend está corriendo: `curl http://192.168.20.22:3000/health`
2. ✅ Verifica que el usuario existe en BD
3. ✅ Aumenta timeout en `loginAs()`: cambia `Duration(seconds: 5)` a `Duration(seconds: 10)`

### 5.3 Error: Widget No Encontrado

**Síntoma:**
```
❌ TestFailure: No se encontraron campos de texto en la pantalla de login
```

**Solución:**
1. ✅ Verifica que los TextFormFields existen en login_screen.dart
2. ✅ Verifica que no hay problemas en la pantalla
3. ✅ Aumenta timeout: `pumpAndSettle(const Duration(seconds: 7))`

### 5.4 Error: CRUD Incompleto

**Síntoma:**
```
❌ TestFailure: Institución no aparece en lista
```

**Solución:**
1. ✅ Verifica que el formulario tiene TODOS los campos requeridos
2. ✅ Comprueba que el backend retorna el item creado
3. ✅ Aumenta timeout después de guardar: `Duration(seconds: 5)` o más

### 5.5 Error: Connection Refused

**Síntoma:**
```
Connection refused
E/flutter: [ERROR] Connection to 192.168.20.22:3000 refused
```

**Solución:**
1. ✅ Inicia backend: `cd backend && npm start`
2. ✅ Verifica que está en puerto correcto: `192.168.20.22:3000`
3. ✅ Espera 10 segundos a que inicie completamente

---

## 📊 Resumen de Pasos

| Paso | Acción | Tiempo |
|------|--------|--------|
| 0 | Preparar Flutter | 2 min |
| 1 | Agregar Keys (opcional) | 15 min |
| 2 | Verificar tests | 2 min |
| 3 | Preparar backend | 3 min |
| 4 | Ejecutar tests | 5-10 min |
| 5 | Interpretar | 2 min |
| **Total** | | **~30 min** |

---

## 🎯 Checklist Final

Antes de ejecutar, verifica:

- [ ] Flutter actualizado: `flutter upgrade`
- [ ] Dependencias instaladas: `flutter pub get`
- [ ] Backend corriendo: `npm start`
- [ ] Usuarios en BD desde seed
- [ ] Archivo `acceptance_flows_test.dart` existe
- [ ] Terminal en `c:\Proyectos\DemoLife`
- [ ] Conectividad a `192.168.20.22:3000`

---

## 📚 Documentación Relacionada

Si necesitas más información:

1. **Guía Completa:** `ACCEPTANCE_E2E_TESTING_GUIDE.md`
2. **Resumen Técnico:** `ACCEPTANCE_E2E_COMPLETE_SUMMARY.md`
3. **Checklist Keys:** `KEYS_IMPLEMENTATION_CHECKLIST.md`
4. **Referencia Rápida:** `E2E_TESTING_GUIDE_UPDATED.md`

---

## 🆘 Soporte Rápido

### Problema más común

**"Tests fallan en login"**

```bash
# 1. Verifica backend
curl http://192.168.20.22:3000/health

# 2. Si no responde, inicia backend
cd backend
npm start

# 3. En otra terminal, espera 10 segundos y corre tests
flutter test integration_test/acceptance_flows_test.dart -d windows
```

### Segunda solución

```bash
# Limpiar todo y empezar de nuevo
flutter clean
flutter pub get
flutter test integration_test/acceptance_flows_test.dart -d windows
```

---

## ✅ Conclusión

Una vez completes estos pasos, tendrás:

✅ Suite de 5 flujos E2E funcionando  
✅ Validación de todos los roles  
✅ CRUD completo probado  
✅ Confianza en el sistema  

**Tiempo total:** ~30 minutos  
**Resultado:** Tests ejecutándose exitosamente ✅

---

**Guía:** Paso a Paso Implementación E2E  
**Versión:** 1.0  
**Estado:** Listo para usar  
**Última actualización:** 2024
