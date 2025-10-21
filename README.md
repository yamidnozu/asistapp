# AsistApp - Sistema de Registro de Asistencia Escolar

Aplicación Flutter para el registro y gestión de asistencia estudiantil en instituciones educativas mediante códigos QR.

## 📋 Descripción

**AsistApp** es una aplicación móvil desarrollada con Flutter que permite a profesores y administradores registrar la asistencia de estudiantes mediante escaneo de códigos QR, consultar reportes históricos y gestionar bases de datos de estudiantes y profesores.

La aplicación utiliza Firebase para autenticación y base de datos, con una interfaz intuitiva y responsive.

## ✨ Características

- 🔐 **Autenticación Google**: Login seguro con Google Sign-In
- 📷 **Escaneo QR**: Registro de asistencia en tiempo real con cámara
- 📊 **Reportes**: Consulta de asistencia por mes, grupo y estudiante
- 👨‍🏫 **Gestión de Profesores**: CRUD completo para administradores
- 👨‍🎓 **Gestión de Estudiantes**: CRUD completo para administradores
- 📱 **Interfaz Responsive**: Optimizada para móvil y tablet
- ☁️ **Firebase Integrado**: Auth, Firestore y Storage
- 🎨 **UI Personalizada**: Sin Material Design, diseño custom

## 🚀 Inicio Rápido

### 1. Configuración Firebase

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Crear proyecto
firebase projects:create asistapp-prod
firebase use asistapp-prod

# Inicializar servicios
firebase init
# Seleccionar: Authentication, Firestore
```

### 2. Configurar Flutter

```bash
# Instalar dependencias
flutter pub get

# Configurar Firebase
flutterfire configure
```

### 3. Ejecutar App

```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── models/
│   ├── user.dart              # Modelo de usuario
│   ├── task.dart              # Modelo de tarea
│   └── assignment.dart        # Modelo de asignación
├── services/
│   ├── auth_service.dart      # Servicio de autenticación
│   └── firestore_service.dart # Servicio de Firestore
├── providers/
│   ├── auth_provider.dart     # Provider de autenticación
│   ├── user_provider.dart     # Provider de usuarios
│   └── task_provider.dart     # Provider de tareas
├── screens/
│   ├── login_screen.dart      # Pantalla de login
│   ├── home_screen.dart       # Dashboard principal
│   └── welcome_screen.dart    # Pantalla de bienvenida
├── ui/widgets/                # Componentes UI
│   ├── app_button.dart
│   ├── app_layout.dart
│   └── index.dart
├── theme/
│   └── app_theme.dart         # Tema de la app
└── main.dart                  # Punto de entrada
```

## 🔐 Autenticación

### Google Sign-In

```dart
final authService = AuthService();
final result = await authService.signInWithGoogle();
```

### Estado de Usuario

```dart
final userProvider = Provider.of<UserProvider>(context);
if (userProvider.isLoggedIn) {
  // Usuario autenticado
}
```

## 📦 Dependencias

```yaml
firebase_core: ^3.15.2
firebase_auth: ^5.7.0
firebase_storage: ^12.4.10
google_sign_in: ^6.3.0
provider: ^6.1.2
go_router: ^14.8.1
cloud_firestore: ^5.6.12
```

## 🧪 Testing

```bash
# Análisis estático
flutter analyze

# Ejecutar app
flutter run
```

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Web

## 📝 Licencia

MIT License

---

**AsistApp** - Sistema de asistencia escolar  
**Última actualización**: 20 de octubre de 2025  
**Versión**: 1.0.0  
**Estado**: ✅ Funcional