# TaskMonitoring: Gestión Inteligente de Tareas

Aplicación de monitoreo y gestión de tareas con autenticación Firebase, sincronización en tiempo real y sugerencias impulsadas por Gemini AI.

## 📋 Descripción

**TaskMonitoring** es una aplicación Flutter multiplataforma que permite:

- 🔐 **Autenticación segura** con Google Sign-In
- 📊 **Gestión de tareas** con sincronización en Firestore
- 💾 **Persistencia local** con Hive
- 🤖 **Sugerencias AI** con Gemini
- 📱 **Multiplataforma** (Android, iOS, Web, Windows, macOS)
- 👥 **Control de roles** (Admin, User)
- 🎨 **UI consistente** sin Material Design

## ✨ Características Principales

### 1. Autenticación
- [x] Google Sign-In integrado
- [x] Firebase Authentication
- [x] UserProvider con sincronización de roles

### 2. Gestión de Tareas
- [x] CRUD completo en Firestore
- [x] Persistencia local con Hive
- [x] Sincronización bidireccional
- [x] Soporte offline

### 3. UI/UX
- [x] 10 componentes reutilizables
- [x] Sistema de tema consistente
- [x] Sin Material Design (WidgetsApp)
- [x] Responsive en todas las plataformas

### 4. Seguridad
- [x] Route Guards por rol
- [x] Validación de datos
- [x] Firebase Rules configurables

### 5. IA (Próximo)
- [ ] Sugerencias de tareas con Gemini
- [ ] Generación automática de descripciones

## 🚀 Quick Start

```bash
# Instalar dependencias
flutter pub get

# Generar adaptadores Hive
flutter pub run build_runner build

# Ejecutar
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── theme/              # Sistema de tema (colores, estilos, espacios)
├── ui/widgets/         # Componentes reutilizables
├── utils/              # Utilidades (guards, helpers)
├── providers/          # State management (Auth, User, Tasks)
├── models/             # Modelos de datos (Hive, Firestore)
├── services/           # Servicios (Auth, Firestore, Storage, Gemini)
├── screens/            # Pantallas principales
└── main.dart           # Entrada de la app
```

## 🎨 Componentes UI Disponibles

### Botones
```dart
AppButton(label: 'Guardar', onPressed: () {})
AppSecondaryButton(label: 'Cancelar', onPressed: () {})
```

### Inputs
```dart
AppTextInput(label: 'Email', controller: controller)
AppCheckbox(label: 'Aceptar', value: true, onChanged: (v) {})
```

### Layouts
```dart
AppScaffold(title: 'Inicio', body: widget, showBackButton: true)
AppCard(child: Text('Contenido'), onTap: () {})
AppDialog(title: 'Confirmar', message: 'Mensaje', actionLabel: 'OK')
```

## 🔐 Route Guards

```dart
// Proteger por autenticación
ProtectedRoute(
  guard: RouteGuards.requireAuth,
  fallback: LoginScreen(),
  child: HomeScreen(),
)

// Proteger por rol
ProtectedRoute(
  guard: (ctx) => RouteGuards.requireRole(ctx, 'admin'),
  fallback: ErrorScreen(),
  child: AdminPanel(),
)
```

## 👤 User Management

```dart
// Sincronizar usuario
await context.read<UserProvider>().syncUserData();

// Obtener información
var userId = userProvider.userId;
var role = userProvider.userRole;
bool isAdmin = userProvider.isAdmin();
```

## 📦 Dependencias Principales

```yaml
firebase_core: ^3.0.0
firebase_auth: ^5.0.0
google_sign_in: ^6.2.1
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.10
hive: ^2.2.3
hive_flutter: ^1.1.0
google_generative_ai: ^0.4.6
provider: ^6.1.2
```

## ⚙️ Configuración

### Firebase
1. Crea proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilita Authentication (Google Sign-In)
3. Habilita Firestore Database
4. Habilita Storage
5. Descarga y configura `google-services.json` (Android)
6. Configura `GoogleService-Info.plist` (iOS)

### Variables de Entorno
```bash
# Para Gemini AI
export GEMINI_API_KEY="tu_api_key_aqui"
```

## 📚 Documentación

| Archivo | Descripción |
|---------|------------|
| [CAMBIOS_REALIZADOS.md](CAMBIOS_REALIZADOS.md) | Resumen detallado de cambios |
| [GUIA_COMPONENTES.md](GUIA_COMPONENTES.md) | Guía de uso de componentes |
| [CHECKLIST_TAREAS.md](CHECKLIST_TAREAS.md) | Tareas pendientes |
| [REFERENCIA_RAPIDA.md](REFERENCIA_RAPIDA.md) | Referencia rápida de imports |
| [RESUMEN_VISUAL.md](RESUMEN_VISUAL.md) | Visualización del proyecto |

## 🧪 Testing

```bash
# Analizar código
flutter analyze

# Ejecutar pruebas
flutter test

# Build APK
flutter build apk --release

# Build Web
flutter build web
```

## 🔄 Arquitectura

### State Management
- **AuthProvider**: Gestiona autenticación
- **UserProvider**: Sincroniza usuario y roles
- **TaskProvider**: Gestiona tareas locales

### Services
- **AuthService**: Firebase Authentication
- **FirestoreService**: Base de datos Firestore
- **StorageService**: Almacenamiento de archivos
- **GeminiService**: Integración IA

### Guards
- **RouteGuards**: Protección de rutas por rol

## 🎯 Próximos Pasos

1. Refactorizar pantallas existentes con componentes
2. Integrar Gemini AI para sugerencias
3. Implementar sincronización offline
4. Crear AdminPanel protegida
5. Agregar tests unitarios
6. Desplegar a App Store y Play Store

## 📊 Estado del Proyecto

- ✅ Autenticación
- ✅ Componentes UI
- ✅ Sistema de tema
- ✅ Route Guards
- ✅ UserProvider
- ✅ Hive configurado
- ✅ Firebase Storage listo
- ⏳ Integración IA
- ⏳ Testing completo
- ⏳ Despliegue

## 📞 Soporte

Para reportar bugs o sugerir mejoras, consulta:
- [GUIA_COMPONENTES.md](GUIA_COMPONENTES.md) para ejemplos
- [CHECKLIST_TAREAS.md](CHECKLIST_TAREAS.md) para tareas pendientes

## 📝 Licencia

Este proyecto está bajo licencia MIT.

---

**Última actualización**: 16 de octubre de 2025  
**Versión**: 2.0  
**Estado**: En desarrollo activo