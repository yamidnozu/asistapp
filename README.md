# ChronoLife - Sistema de Autenticación# TaskMonitoring 2.0: Sistema Completo de Gestión de Tareas



Aplicación Flutter minimalista con autenticación Google Sign-In.Aplicación Flutter completa para monitoreo y gestión de tareas con roles RBAC, Firebase integrado, y arquitectura enterprise-ready.



## 📋 Descripción## 📋 Descripción



**ChronoLife** es una aplicación Flutter que implementa un sistema básico de autenticación usando Firebase Authentication con Google Sign-In.**TaskMonitoring 2.0** es una aplicación Flutter multiplataforma que implementa un sistema completo de gestión de tareas con:



## ✨ Características- 🔐 **Autenticación Firebase** con Google Sign-In

- 👥 **RBAC (Role-Based Access Control)**: super_admin, site_admin, employee

- 🔐 **Autenticación Google**: Login seguro con Google Sign-In- 🏢 **Gestión jerárquica**: Sedes → Empleos → Responsabilidades → Tareas

- 👤 **Gestión de usuarios**: Perfiles de usuario con Firebase- 📅 **Recurrencias flexibles**: diaria, semanal, custom con múltiples horarios

- 📱 **UI personalizada**: Componentes sin Material Design- 📊 **Dashboard administrativo** con KPIs y filtros

- ☁️ **Firebase integrado**: Auth y Firestore básicos- 📱 **Vista empleado** con assignments y evidencia

- ☁️ **Firebase completo**: Auth, Firestore, Storage, Functions

## 🚀 Inicio Rápido- 💾 **Offline-first** con Hive para assignments

- 🎨 **UI personalizada** sin Material Design

### 1. Configuración Firebase- 🔒 **Seguridad enterprise** con Firebase Rules

```bash

# Instalar Firebase CLI## ✨ Características Principales

npm install -g firebase-tools

firebase login### 1. Arquitectura RBAC

- **super_admin**: Reset BD, seed demo, gestión global

# Crear proyecto- **site_admin**: Gestión de usuarios/tareas de sus sedes

firebase projects:create chronolife-prod- **employee**: Vista de assignments propios, subir evidencia

firebase use chronolife-prod

### 2. Modelo Jerárquico

# Inicializar servicios```

firebase initSedes (sites) → Empleos (jobs) → Responsabilidades (responsibilities) → Tareas (tasks)

# Seleccionar: Authentication, Firestore```

```

### 3. Recurrencias Avanzadas

### 2. Configurar Flutter- Tipos: `once`, `daily`, `weekly`, `custom`

```bash- Múltiples horarios por día: `["08:00", "14:00"]`

# Instalar dependencias- Días específicos: `[1, 2, 3, 4, 5]` (Lunes-Viernes)

flutter pub get- Rangos de fechas flexibles



# Configurar Firebase### 4. Estados de Assignment

flutterfire configure- `pending` → `in_progress` → `blocked` → `done`

```- Motivo de bloqueo opcional

- Evidencia requerida opcional (foto)

### 3. Ejecutar App

```bash### 5. Dashboard KPIs

flutter run- % cumplimiento por sede/usuario/responsabilidad

```- Tareas pendientes/hoy/atrasadas

- Filtros por fecha/estado/sede

## 📁 Estructura del Proyecto

## 🚀 Quick Start

```

lib/### 1. Configuración Firebase

├── models/```bash

│   └── user.dart              # Modelo de usuario# Instalar Firebase CLI

├── services/npm install -g firebase-tools

│   ├── auth_service.dart      # Servicio de autenticaciónfirebase login

│   └── user_service.dart      # Servicio de usuarios

├── providers/# Inicializar proyecto

│   ├── auth_provider.dart     # Provider de autenticaciónfirebase init

│   └── user_provider.dart     # Provider de usuarios# Seleccionar: Firestore, Storage, Functions, Hosting

├── screens/```

│   └── login_screen.dart      # Pantalla de login

├── ui/widgets/                # Componentes UI### 2. Configurar Flutter

│   ├── app_button.dart```bash

│   ├── app_input.dart# Instalar dependencias

│   ├── app_layout.dartflutter pub get

│   └── app_spinner.dart

├── theme/# Generar adaptadores Hive (si es necesario)

│   └── app_theme.dart         # Tema de la appflutter pub run build_runner build

├── utils/

│   └── route_guards.dart      # Guards de rutas# Configurar Firebase

└── main.dart                  # Punto de entradaflutterfire configure

``````



## 🔐 Autenticación### 3. Asignar Super Admin Inicial

```javascript

### Google Sign-In// En Firebase Console > Firestore, crear documento:

```dartdb.collection('taskmonitoring').doc('config').set({

final authService = AuthService();  superAdminUids: ['TU_UID_AQUI'],

final result = await authService.signInWithGoogle();  allowSeed: true,

```  version: '1.0.0',

  createdAt: Timestamp.now()

### Estado de Usuario});

```dart```

final userProvider = Provider.of<UserProvider>(context);

if (userProvider.isLoggedIn) {### 4. Ejecutar Seed Demo

  // Usuario autenticado```bash

}# Desplegar Functions

```cd functions

npm install

## 📦 Dependenciasnpm run deploy



```yaml# Ejecutar seed desde la app (como super_admin)

firebase_core: ^3.0.0# O desde Functions:

firebase_auth: ^5.0.0firebase functions:call seedDemo

cloud_firestore: ^5.6.0```

provider: ^6.1.2

google_sign_in: ^6.2.1### 5. Ejecutar App

``````bash

flutter run

## 🧪 Testing```



```bash## 📁 Estructura del Proyecto

# Análisis estático

flutter analyze```

lib/

# Ejecutar app├── models/             # POJOs con fromJson/toJson

flutter run│   ├── user.dart

```│   ├── site.dart

│   ├── job.dart

## 📱 Plataformas Soportadas│   ├── responsibility.dart

│   ├── task.dart

- ✅ Android│   ├── assignment.dart

- ✅ iOS│   ├── log.dart

- ✅ Web│   ├── config.dart

│   ├── date_range.dart

## 📝 Licencia│   └── task_hive.dart

├── services/           # Lógica de negocio

MIT License│   ├── auth_service.dart

│   ├── user_service.dart

---│   ├── admin_service.dart

│   ├── catalog_service.dart

**ChronoLife** - Base de autenticación Flutter  │   ├── assignment_service.dart

**Última actualización**: 20 de octubre de 2025  │   ├── evidence_service.dart

**Versión**: 1.0.0  │   └── seed_service.dart

**Estado**: ✅ Funcional├── providers/          # State management
│   ├── user_provider.dart
│   ├── admin_provider.dart
│   ├── assignment_provider.dart
│   └── catalog_provider.dart
├── screens/            # UI por rol
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── users_screen.dart
│   ├── catalog_screens.dart
│   ├── assignments_screen.dart
│   └── reset_seed_screen.dart
├── ui/widgets/         # Componentes sin Material
│   ├── app_button.dart
│   ├── app_input.dart
│   ├── app_layout.dart
│   ├── app_spinner.dart
│   └── app_select.dart
├── theme/              # Tema consistente
│   └── app_theme.dart
├── utils/              # Helpers
│   └── route_guards.dart
└── main.dart

functions/              # Cloud Functions TS
├── src/
│   └── index.ts
├── package.json
└── tsconfig.json

firestore.rules         # Security Rules
storage.rules           # Storage Rules
```

## 🎨 Componentes UI

### Layouts
```dart
AppScaffold(
  title: 'Dashboard',
  body: content,
  actions: [botones],
)
```

### Formularios
```dart
AppTextInput(label: 'Nombre', controller: ctrl)
AppSelect(
  items: [DropdownItem(label: 'Opción', value: 'val')],
  value: selected,
  onChanged: (v) => setState(() => selected = v),
)
```

### Feedback
```dart
AppSpinner()  // Loading
AppDialog(title: 'Error', message: 'Mensaje')  // Modales
```

## 🔐 Seguridad

### Firebase Rules
- **Firestore**: Acceso granular por rol y siteId
- **Storage**: Solo evidencia de assignments propios
- **Functions**: Callable functions protegidas

### Route Guards
```dart
// En main.dart con go_router
redirect: (context, state) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  if (!userProvider.isLoggedIn) return '/';
  return null;
}
```

## 📊 Dashboard KPIs

### Métricas Disponibles
- **Cumplimiento global**: % tareas completadas
- **Por sede**: distribución de cumplimiento
- **Por usuario**: rendimiento individual
- **Por responsabilidad**: eficiencia por rol
- **Tendencias**: evolución temporal

### Filtros
- Rango de fechas
- Estados: pending/in_progress/blocked/done
- Sedes específicas
- Usuarios específicos

## ☁️ Cloud Functions

### Disponibles
- `onUserCreate`: Crea doc usuario automáticamente
- `setCustomClaims`: Asigna roles/sites (solo super_admin)
- `seedDemo`: Inserta datos de ejemplo
- `clearSeed`: Borra datos de ejemplo
- `resetDatabase`: Reset completo preservando config

### Uso
```typescript
// Desde cliente
const result = await firebase.functions().httpsCallable('seedDemo')();
```

## 💾 Offline & Sync

### Hive Integration
- **Assignments**: Cache local para vista offline
- **Sync**: Reintento automático al reconectar
- **Evidencia**: Queue de uploads pendientes

### Estrategia
```dart
// En assignment_provider.dart
Stream<List<Assignment>> assignmentsStream(String userId) {
  return _service.assignmentsStream(userId);
}
```

## 📱 Vistas por Rol

### Employee
- Lista assignments: Hoy/Próximas/Atrasadas
- Acciones: Iniciar/Bloquear/Finalizar/Subir evidencia
- Sin acceso a admin panels

### Site Admin
- Dashboard con KPIs de sus sedes
- Gestión usuarios de sus sites
- CRUD catálogo limitado a sites

### Super Admin
- Dashboard global
- Gestión todos los usuarios
- Reset BD / Seed functions
- Acceso completo

## 🧪 Testing

```bash
# Análisis estático
flutter analyze

# Tests unitarios
flutter test

# Emuladores Firebase
firebase emulators:start

# Tests con emulador
flutter drive --target=test_driver/app.dart
```

## 📦 Dependencias

```yaml
# Firebase
firebase_core: ^3.0.0
firebase_auth: ^5.0.0
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.10

# State & Navigation
provider: ^6.1.2
go_router: ^14.2.0

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# UI & Utils
image_picker: ^1.1.2
intl: ^0.19.0
path_provider: ^2.1.3
```

## ⚙️ Configuración Detallada

### 1. Firebase Project
```bash
firebase projects:create taskmonitoring-prod
firebase use taskmonitoring-prod
```

### 2. Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 3. Storage Rules
```bash
firebase deploy --only storage
```

### 4. Functions
```bash
cd functions
npm run deploy
```

### 5. FlutterFire
```bash
flutterfire configure
# Seleccionar plataformas: android, ios, web
```

## 🎯 Scripts de Desarrollo

```bash
# Desarrollo local
firebase emulators:start

# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web

# Deploy completo
firebase deploy
```

## 📊 Datos de Seed

### Sedes (2)
- Oficina Central
- Sucursal Norte

### Empleos (3)
- Gerente
- Supervisor
- Empleado

### Responsabilidades (5)
- Gestión general
- Supervisión
- Limpieza
- Reportes
- Mantenimiento

### Tareas (6)
- Limpieza oficina (diaria, 09:00, L-V)
- Reporte diario (diaria, 17:00, L-V)
- Supervisión semanal (semanal, lunes 10:00)
- Mantenimiento mensual (custom, último día mes)

## 🔄 Próximos Pasos

1. **Export CSV**: Dashboard exportable
2. **Notificaciones**: Recordatorios locales
3. **Marca de agua**: En fotos de evidencia
4. **Tests E2E**: Con emuladores
5. **CI/CD**: GitHub Actions
6. **Despliegue**: App Store / Play Store

## 📞 Soporte

- **Issues**: GitHub Issues
- **Docs**: Ver archivos en `/docs/`
- **Firebase**: Console para logs

## 📝 Licencia

MIT License - ver LICENSE file.

---

**TaskMonitoring 2.0** - Sistema enterprise de gestión de tareas  
**Última actualización**: 16 de octubre de 2025  
**Versión**: 2.0.0  
**Estado**: ✅ Completo y listo para producción