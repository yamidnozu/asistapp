# Guía de Uso - Componentes UI y Utilidades

## 🎨 Componentes UI

### 1. AppButton (Botón Primario)

```dart
import 'package:taskmonitoring/ui/widgets/app_button.dart';
import 'package:taskmonitoring/theme/app_theme.dart';

AppButton(
  label: 'Guardar Tarea',
  onPressed: () {
    // Acción al presionar
  },
  isLoading: false,        // Muestra spinner si es true
  isEnabled: true,         // Deshabilitado si es false
  width: 200,              // Ancho opcional
)
```

### 2. AppSecondaryButton (Botón Secundario)

```dart
AppSecondaryButton(
  label: 'Cancelar',
  onPressed: () {
    Navigator.pop(context);
  },
  isEnabled: true,
  width: double.infinity,
)
```

### 3. AppTextInput (Input de Texto)

```dart
AppTextInput(
  label: 'Email',
  hint: 'ejemplo@correo.com',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.email),      // Opcional
  suffixIcon: Icon(Icons.check),      // Opcional
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'El email es requerido';
    }
    return null;
  },
  onChanged: (value) {
    print('Email: $value');
  },
)
```

### 4. AppCheckbox (Checkbox)

```dart
AppCheckbox(
  value: acceptedTerms,
  onChanged: (value) {
    setState(() {
      acceptedTerms = value;
    });
  },
  label: 'Aceptar términos y condiciones',
)
```

### 5. AppScaffold (Layout Base)

```dart
AppScaffold(
  title: 'Mis Tareas',
  showBackButton: true,
  onBackPressed: () {
    Navigator.pop(context);
  },
  actions: [
    GestureDetector(
      onTap: () {},
      child: Text('⋮'),
    )
  ],
  body: Column(
    children: [
      Text('Contenido aquí'),
    ],
  ),
  floatingActionButton: AppButton(
    label: 'Agregar',
    onPressed: () {},
  ),
)
```

### 6. AppCard (Tarjeta)

```dart
AppCard(
  padding: EdgeInsets.all(AppSpacing.md),
  backgroundColor: AppColors.white,
  onTap: () {
    print('Tarjeta presionada');
  },
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Título', style: AppTextStyles.titleMedium),
      SizedBox(height: AppSpacing.sm),
      Text('Descripción', style: AppTextStyles.bodySmall),
    ],
  ),
)
```

### 7. AppDialog (Diálogo)

```dart
showDialog(
  context: context,
  builder: (_) => AppDialog(
    title: '¿Eliminar tarea?',
    message: 'Esta acción no se puede deshacer.',
    actionLabel: 'Eliminar',
    onAction: () {
      Navigator.pop(context);
      // Ejecutar eliminación
    },
    cancelLabel: 'Cancelar',
    onCancel: () => Navigator.pop(context),
  ),
)
```

---

## 🎨 Sistema de Tema

### Colores

```dart
import 'package:taskmonitoring/theme/app_theme.dart';

// Primarios
AppColors.primary        // #000000 (Negro)
AppColors.primaryDark    // #000000
AppColors.primaryLight   // #1A1A1A

// Secundarios
AppColors.secondary      // #757575
AppColors.secondaryLight // #9E9E9E

// Estados
AppColors.success        // #4CAF50
AppColors.warning        // #FFC107
AppColors.error          // #F44336
AppColors.info           // #2196F3

// Neutros
AppColors.white
AppColors.black
AppColors.grey
AppColors.greyDark

// Superficie
AppColors.surface
AppColors.background
```

### Tipografía

```dart
// Display
AppTextStyles.displayLarge
AppTextStyles.displayMedium

// Headline
AppTextStyles.headlineLarge
AppTextStyles.headlineMedium

// Title
AppTextStyles.titleLarge
AppTextStyles.titleMedium

// Body
AppTextStyles.bodyLarge
AppTextStyles.bodyMedium
AppTextStyles.bodySmall

// Label
AppTextStyles.labelLarge
AppTextStyles.labelMedium
AppTextStyles.labelSmall
```

**Ejemplo de uso:**

```dart
Text(
  'Mi Título',
  style: AppTextStyles.headlineMedium.copyWith(
    color: AppColors.primary,
  ),
)
```

### Espaciado

```dart
AppSpacing.xs    // 4
AppSpacing.sm    // 8
AppSpacing.md    // 16
AppSpacing.lg    // 24
AppSpacing.xl    // 32
AppSpacing.xxl   // 48

// Uso
SizedBox(height: AppSpacing.md)
Padding(
  padding: EdgeInsets.all(AppSpacing.lg),
  child: widget,
)
```

---

## 🔐 Route Guards (Protección de Rutas)

### 1. Proteger por autenticación

```dart
import 'package:taskmonitoring/utils/route_guards.dart';

Consumer<AuthProvider>(
  builder: (context, auth, _) {
    return ProtectedRoute(
      guard: (ctx) => RouteGuards.requireAuth(ctx),
      fallback: LoginScreen(),
      child: HomeScreen(),
    );
  },
)
```

### 2. Proteger por rol

```dart
Consumer<UserProvider>(
  builder: (context, user, _) {
    return ProtectedRoute(
      guard: (ctx) => RouteGuards.requireRole(ctx, 'admin'),
      fallback: Center(child: Text('Acceso denegado')),
      child: AdminPanel(),
    );
  },
)
```

### 3. Proteger solo admin

```dart
ProtectedRoute(
  guard: RouteGuards.requireAdmin,
  fallback: Center(child: Text('Solo admins')),
  child: AdminScreen(),
)
```

### 4. Usar guards en métodos

```dart
void navigateToProfile() {
  if (RouteGuards.requireAuth(context)) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
  } else {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }
}
```

---

## 👤 UserProvider (Sincronización de Roles)

```dart
import 'package:taskmonitoring/providers/user_provider.dart';

// En tu Provider
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Sincronizar datos del usuario después del login
    context.read<UserProvider>().syncUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Text('Usuario ID: ${userProvider.userId}'),
            Text('Rol: ${userProvider.userRole}'),
            if (userProvider.isAdmin())
              Text('Eres administrador'),
          ],
        );
      },
    );
  }
}
```

### Métodos disponibles

```dart
// Obtener datos
userProvider.userId          // String?
userProvider.userRole        // String?
userProvider.isLoading       // bool

// Sincronizar
await userProvider.syncUserData()

// Cambiar rol
await userProvider.setUserRole('admin')

// Verificadores
userProvider.hasRole('admin')
userProvider.isAdmin()
userProvider.isUser()
```

---

## 📦 Modelo Hive (Persistencia Local)

```dart
import 'package:taskmonitoring/models/task_hive.dart';

// Crear una tarea
TaskHive task = TaskHive(
  id: 'task-123',
  title: 'Hacer compras',
  description: 'Comprar comida en el mercado',
  isCompleted: false,
  createdAt: DateTime.now(),
  dueDate: DateTime.now().add(Duration(days: 1)),
);

// Convertir a JSON
Map<String, dynamic> json = task.toJson();

// Crear desde JSON
TaskHive taskFromJson = TaskHive.fromJson(json);
```

**Después de actualizar TaskHive, ejecuta:**
```bash
flutter pub run build_runner build
```

---

## 📋 Ejemplo Completo: Pantalla de Tareas

```dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:taskmonitoring/ui/widgets/index.dart';
import 'package:taskmonitoring/theme/app_theme.dart';
import 'package:taskmonitoring/utils/route_guards.dart';
import 'package:taskmonitoring/providers/task_provider.dart';

class TasksScreen extends StatefulWidget {
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mis Tareas',
      showBackButton: true,
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          return Column(
            children: [
              AppTextInput(
                label: 'Título',
                controller: titleController,
                hint: 'Ej: Hacer compras',
              ),
              SizedBox(height: AppSpacing.md),
              AppTextInput(
                label: 'Descripción',
                controller: descriptionController,
                hint: 'Detalles',
                maxLines: 3,
              ),
              SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Agregar Tarea',
                onPressed: () async {
                  // Agregar tarea
                },
              ),
              SizedBox(height: AppSpacing.lg),
              ...taskProvider.tasks.map((task) =>
                AppCard(
                  onTap: () {},
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: AppTextStyles.titleMedium),
                            Text(
                              task.description ?? '',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      AppCheckbox(
                        value: task.isCompleted,
                        onChanged: (value) {
                          taskProvider.toggleTaskCompletion(task.id);
                        },
                        label: '',
                      ),
                    ],
                  ),
                )
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
```

---

## 🚀 Checklist de Implementación

- [ ] Importar componentes en pantallas
- [ ] Reemplazar widgets nativos por AppComponents
- [ ] Aplicar AppScaffold a todas las pantallas
- [ ] Usar AppTextStyles y AppColors en todo el app
- [ ] Implementar route guards en navegación
- [ ] Sincronizar UserProvider después de login
- [ ] Generar adaptadores Hive con `build_runner`
- [ ] Probar en múltiples plataformas

---

**Última actualización**: 16 de octubre de 2025
