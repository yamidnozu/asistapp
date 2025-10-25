# 📖 Guía Rápida - Estructura del Proyecto

## 🎯 Todo está organizado simple y claro

### Carpetas principales

```
lib/
├── main.dart                    ← Empieza aquí, inicializa todo
├── providers/                   ← Estado global (login, navegación, scroll)
├── screens/                     ← Las pantallas de la app
├── widgets/                     ← Componentes reutilizables
├── utils/                       ← Herramientas (router, rutas, roles)
├── services/                    ← Conexión con API
└── models/                      ← Estructuras de datos
```

## 📄 Archivos clave

### 1. `main.dart` - Punto de inicio
```dart
Lo que hace:
- Inicializa providers (AuthProvider, NavigationProvider, etc.)
- Configura el router
- Escucha cuando la app va al background y vuelve
```

### 2. `utils/app_router.dart` - Sistema de rutas
```dart
Secciones importantes:
- _getStartRoute()   → Decide dónde empezar (login o dashboard)
- _checkAuth()       → Verifica si puede entrar a cada ruta
- _allRoutes()       → Lista de todas las rutas
- _saveRoute()       → Guarda la ruta actual
```

### 3. `utils/app_routes.dart` - Lista de rutas
```dart
Todas las rutas en un lugar:
- AppRoutes.login
- AppRoutes.teacherDashboard
- AppRoutes.studentDashboard
etc.

Helper útil:
AppRoutes.getDashboardRouteForRole('profesor') // → '/teacher-dashboard'
```

### 4. `utils/role_enum.dart` - Tipos de usuario
```dart
enum UserRole {
  superAdmin,       // Administrador del sistema
  adminInstitucion, // Admin de colegio/universidad
  profesor,         // Profesor
  estudiante,       // Estudiante
}

Helpers:
- role.value         → Convertir a string para backend
- role.displayName   → Nombre bonito para UI
- role.isAdmin       → ¿Es administrador?
```

### 5. `widgets/role_guard.dart` - Mostrar/ocultar por rol
```dart
Uso simple:
RoleGuard(
  allowedRoles: [UserRole.profesor],  // Solo profes ven esto
  child: BotonEditar(),
  fallback: Text('Sin permiso'),      // Opcional
)
```

### 6. `widgets/scroll_state_keeper.dart` - Guardar scroll
```dart
Uso simple:
ScrollStateKeeper(
  routeKey: AppRoutes.teacherDashboard,
  builder: (context, controller) => SingleChildScrollView(
    controller: controller,  // ← Guarda y restaura automático
    child: MiContenido(),
  ),
)
```

## 🚀 Cómo agregar algo nuevo

### Agregar una nueva ruta

1. **En `app_routes.dart`** - Agregar la constante:
```dart
static const String miNuevaRuta = '/mi-nueva-ruta';
```

2. **En `app_router.dart`** - Agregar en `_allRoutes()`:
```dart
GoRoute(
  path: AppRoutes.miNuevaRuta,
  name: 'mi-ruta',
  pageBuilder: (context, state) {
    _saveRoute(state);
    return _fadePage(context, state, MiNuevaPantalla());
  },
),
```

3. **Listo!** Ahora puedes navegar con:
```dart
context.go(AppRoutes.miNuevaRuta);
```

### Agregar un nuevo rol

1. **En `role_enum.dart`** - Agregar al enum:
```dart
enum UserRole {
  superAdmin,
  adminInstitucion,
  profesor,
  estudiante,
  miNuevoRol,  // ← Nuevo
}
```

2. **Agregar en el extension** en los 3 switches:
```dart
case UserRole.miNuevoRol:
  return 'mi_nuevo_rol';  // Para backend
```

3. **Listo!** Ya puedes usar:
```dart
RoleGuard(
  allowedRoles: [UserRole.miNuevoRol],
  child: ...,
)
```

## 💡 Tips para entender el código

### Nomenclatura
- `_metodoPrivado()` - Los métodos con `_` son internos de la clase
- `metodoPublico()` - Sin `_` se pueden usar desde fuera
- `MAYUSCULAS` - Son constantes

### Comentarios
```dart
// Comentario de una línea

/// Comentario de documentación
/// Se ve cuando pasas el mouse sobre el método
```

### Secciones
```dart
// ==================== TÍTULO ====================
// Divide el código en secciones lógicas
```

## 🔄 Flujos importantes

### Login
```
Usuario escribe email/password
  → LoginScreen
  → AuthProvider.login()
  → AuthService (llama API)
  → Guarda tokens
  → AppRouter detecta cambio
  → Redirige a dashboard según rol
```

### Volver a la app
```
Usuario vuelve de otra app
  → didChangeAppLifecycleState(resumed)
  → AuthProvider.recoverFullState()
  → NavigationProvider verifica si el estado es válido (< 30 min)
  → Si es válido: restaura ruta + scroll
  → Si no: va al dashboard según rol
```

### Deep Link
```
Usuario abre: asistapp://app/teacher-dashboard
  → Android captura
  → AppRouter._checkAuth() verifica login
  → Si está logueado: abre TeacherDashboard
  → Si no: redirige a login
```

## 🆘 Qué hacer si...

### ¿Necesito agregar una pantalla nueva?
1. Crear archivo en `screens/mi_pantalla.dart`
2. Agregar ruta en `app_routes.dart`
3. Agregar en `app_router.dart`

### ¿Necesito controlar quién ve algo?
Usa `RoleGuard`:
```dart
RoleGuard(
  allowedRoles: [UserRole.profesor],
  child: MiWidget(),
)
```

### ¿Necesito guardar el scroll?
Usa `ScrollStateKeeper`:
```dart
ScrollStateKeeper(
  routeKey: AppRoutes.miRuta,
  builder: (context, controller) => SingleChildScrollView(
    controller: controller,
    child: ...,
  ),
)
```

### ¿Necesito saber el rol del usuario?
```dart
final authProvider = Provider.of<AuthProvider>(context);
final rolString = authProvider.user?['rol'];
final rol = UserRoleExtension.fromString(rolString);

if (rol.isAdmin) {
  // Es administrador
}
```

---

**Todo simple y directo. Sin complicaciones.** ✅
