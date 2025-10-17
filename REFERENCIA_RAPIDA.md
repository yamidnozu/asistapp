# ⚡ Referencia Rápida

## 🎯 Import Rápido de Componentes

```dart
// Todos los widgets
import 'package:taskmonitoring/ui/widgets/index.dart';

// Tema
import 'package:taskmonitoring/theme/app_theme.dart';

// Guards
import 'package:taskmonitoring/utils/route_guards.dart';

// Providers
import 'package:taskmonitoring/providers/user_provider.dart';
```

---

## 🎨 Componentes - Uso Rápido

### Botones
```dart
// Primario
AppButton(label: 'Guardar', onPressed: () {})

// Secundario
AppSecondaryButton(label: 'Cancelar', onPressed: () {})
```

### Inputs
```dart
// Texto
AppTextInput(label: 'Email', controller: controller)

// Checkbox
AppCheckbox(label: 'Aceptar', value: true, onChanged: (v) {})
```

### Layouts
```dart
// Página
AppScaffold(title: 'Inicio', body: widget, showBackButton: true)

// Tarjeta
AppCard(child: Text('Contenido'), onTap: () {})

// Diálogo
AppDialog(title: 'Confirmar', message: 'Mensaje', actionLabel: 'OK')
```

---

## 🎨 Colores - Referencia Rápida

```dart
AppColors.primary           // #000000 Negro
AppColors.success           // #4CAF50 Verde
AppColors.error             // #F44336 Rojo
AppColors.warning           // #FFC107 Amarillo
AppColors.white             // #FFFFFF Blanco
AppColors.background        // #FAFAFA Fondo
```

---

## 📝 Tipografía - Referencia Rápida

```dart
AppTextStyles.displayLarge    // 32px Bold
AppTextStyles.headlineMedium  // 20px 600
AppTextStyles.titleMedium     // 16px 500
AppTextStyles.bodyMedium      // 14px Normal
AppTextStyles.labelSmall      // 11px 500
```

---

## 📏 Espacios - Referencia Rápida

```dart
AppSpacing.xs   // 4
AppSpacing.sm   // 8
AppSpacing.md   // 16
AppSpacing.lg   // 24
AppSpacing.xl   // 32
```

---

## 🔐 Route Guards - Uso Rápido

```dart
// Proteger por autenticación
if (RouteGuards.requireAuth(context)) {
  Navigator.push(...); // Ir a pantalla protegida
}

// Proteger por rol
ProtectedRoute(
  guard: (ctx) => RouteGuards.requireRole(ctx, 'admin'),
  fallback: ErrorScreen(),
  child: AdminScreen(),
)

// Solo admin
ProtectedRoute(
  guard: RouteGuards.requireAdmin,
  fallback: Text('No permitido'),
  child: AdminPanel(),
)
```

---

## 👤 UserProvider - Uso Rápido

```dart
// Sincronizar usuario
await context.read<UserProvider>().syncUserData();

// Obtener rol
var role = context.read<UserProvider>().userRole;

// Verificar rol
bool isAdmin = context.read<UserProvider>().isAdmin();

// En Consumer
Consumer<UserProvider>(
  builder: (context, user, _) {
    return Text('Rol: ${user.userRole}');
  },
)
```

---

## 💾 Hive/Local - Uso Rápido

```dart
import 'package:taskmonitoring/models/task_hive.dart';

// Crear
TaskHive task = TaskHive(
  id: 'task-1',
  title: 'Mi tarea',
  createdAt: DateTime.now(),
);

// Convertir
Map json = task.toJson();
TaskHive taskFromJson = TaskHive.fromJson(json);
```

---

## 🎯 Patrones Comunes

### Pantalla Completa
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mi Pantalla',
      showBackButton: true,
      body: Column(
        children: [
          AppTextInput(label: 'Nombre', controller: controller),
          SizedBox(height: AppSpacing.md),
          AppButton(label: 'Guardar', onPressed: () {}),
        ],
      ),
    );
  }
}
```

### Lista de Items
```dart
Consumer<TaskProvider>(
  builder: (context, tasks, _) {
    return Column(
      children: tasks.tasks.map((task) =>
        AppCard(
          child: Text(task.title, style: AppTextStyles.titleMedium),
          onTap: () {},
        )
      ).toList(),
    );
  },
)
```

### Diálogo de Confirmación
```dart
showDialog(
  context: context,
  builder: (_) => AppDialog(
    title: 'Eliminar',
    message: '¿Estás seguro?',
    actionLabel: 'Eliminar',
    onAction: () {
      Navigator.pop(context);
      // Acción
    },
    cancelLabel: 'Cancelar',
  ),
)
```

### Proteger Ruta
```dart
Consumer2<AuthProvider, UserProvider>(
  builder: (context, auth, user, _) {
    if (!auth.isAuthenticated) {
      return LoginScreen();
    }
    if (!user.isAdmin()) {
      return ErrorScreen();
    }
    return AdminScreen();
  },
)
```

---

## 📋 Checklist antes de usar

- [ ] `flutter pub get` ejecutado
- [ ] `flutter analyze` sin errores
- [ ] Imports correctos en archivos
- [ ] Providers en MultiProvider (main.dart)
- [ ] UserProvider sincronizado en AuthProvider
- [ ] TaskHive adapters generados (si aplica)

---

## 🔗 Links de Referencia

- **CAMBIOS_REALIZADOS.md** - Resumen detallado
- **GUIA_COMPONENTES.md** - Ejemplos extensos
- **CHECKLIST_TAREAS.md** - Próximas tareas
- **RESUMEN_VISUAL.md** - Visualización del proyecto

---

## 🆘 Troubleshooting Rápido

### Error: "Target of URI doesn't exist"
```bash
flutter pub get
flutter analyze
```

### Error: "Undefined name 'AppColors'"
```dart
// Verifica import
import 'package:taskmonitoring/theme/app_theme.dart';
```

### Error: Hive adapters
```bash
flutter pub run build_runner build
```

### Error: MultiProvider no encuentra UserProvider
```dart
// main.dart debe tener:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
  ],
  child: app,
)
```

---

## ⚡ Tips y Trucos

1. **Reutilizar AppButton en muchos lados**
   ```dart
   final primaryButton = AppButton(label: 'OK', onPressed: () {});
   ```

2. **Tema personalizado**
   ```dart
   Text('Texto', style: AppTextStyles.bodyMedium.copyWith(
     color: AppColors.primary,
     fontSize: 16,
   ))
   ```

3. **Validación en input**
   ```dart
   AppTextInput(
     label: 'Email',
     validator: (value) => value?.contains('@') ?? false ? null : 'Email inválido',
   )
   ```

4. **Consumer anidados**
   ```dart
   Consumer2<AuthProvider, UserProvider>(
     builder: (context, auth, user, _) => ...,
   )
   ```

5. **Navigator fácil**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(builder: (_) => NextScreen()),
   )
   ```

---

## 📱 Resumen de Archivos Clave

```
lib/theme/app_theme.dart           ← Colores, estilos, espacios
lib/ui/widgets/                    ← Componentes reutilizables
lib/utils/route_guards.dart        ← Protección de rutas
lib/providers/user_provider.dart   ← Sincronización de roles
lib/models/task_hive.dart          ← Persistencia local
```

---

## 🎓 Flujo de Autenticación

```
1. Usuario abre app
   ↓
2. main.dart inicializa Firebase + Hive
   ↓
3. AuthProvider verifica si está autenticado
   ↓
4. Si NO: Muestra LoginScreen
   ↓
5. Si SÍ: UserProvider.syncUserData()
   ↓
6. Muestra HomeScreen o AdminScreen según rol
   ↓
7. ProtectedRoute verifica permisos
```

---

## 🚀 Lista Rápida de Compilación

```bash
# Limpiar
flutter clean

# Instalar deps
flutter pub get

# Generar código
flutter pub run build_runner build

# Analizar
flutter analyze

# Ejecutar
flutter run

# Build APK
flutter build apk --release

# Build Web
flutter build web
```

---

**Última actualización**: 16 de octubre de 2025  
**Versión**: 1.0  
**Tipo**: Referencia Rápida
