---
description: Guía de estilos UI para pantallas de AsistApp
---

# Guía de Estilos UI - AsistApp

## Estándar de Diseño para Pantallas

### 1. Scaffold
Todas las pantallas deben usar:

```dart
final colors = context.colors;
return Scaffold(
  backgroundColor: colors.background,
  // ...
);
```

### 2. AppBar Estandarizado
```dart
appBar: AppBar(
  title: Text('Título', style: textStyles.titleLarge),
  backgroundColor: colors.surface,
  foregroundColor: colors.textPrimary,
  elevation: 0,
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
    onPressed: () => context.pop(),
  ),
),
```

### 3. Importaciones Necesarias
```dart
import '../theme/theme_extensions.dart';
```

### 4. Variables de Estilo
Al inicio del método build:
```dart
final colors = context.colors;
final textStyles = context.textStyles;
final spacing = context.spacing;
```

### 5. Espaciado en Formularios
Para separación entre inputs:
```dart
SizedBox(height: spacing.inputSpacing), // 20px
```
Para separación entre secciones:
```dart
SizedBox(height: spacing.sectionSpacing), // 32px
```

### 6. Widgets Centralizados (lib/theme/app_styles.dart)

#### DashboardResumenCard
Card de resumen para dashboards con gradiente:
```dart
DashboardResumenCard(
  icon: Icons.person,
  greeting: 'Hola, Usuario',
  subtitle: 'Rol del usuario',
  onMenuPressed: () => Scaffold.of(context).openDrawer(),
  onRefreshPressed: _loadData,
  stats: [
    DashboardStatItem(value: '5', label: 'Clases'),
    DashboardStatItem(value: '50', label: 'Estudiantes'),
  ],
)
```

#### MenuActionCard
Card para acciones en listas:
```dart
MenuActionCard(
  icon: Icons.class_,
  title: 'Título de Acción',
  subtitle: 'Descripción',
  onTap: () => context.push('/ruta'),
)
```

### 7. Keys para Pruebas de Integración
**IMPORTANTE:** Mantener estos keys para las pruebas:

- `Key('emailField')` - Campo de email en login
- `Key('passwordField')` - Campo de contraseña en login
- `Key('loginButton')` - Botón de login
- `Key('createUser_professor')` - SpeedDial opción profesor
- `Key('createUser_student')` - SpeedDial opción estudiante
- `Key('createUser_acudiente')` - SpeedDial opción acudiente
- `Key('createUser_admin_institution')` - SpeedDial opción admin institución
- `Key('institucionField')` - Campo de selección de institución
- `Key('emailUsuarioField')` - Campo email en formulario usuario
- `Key('formSaveButton')` - Botón guardar en stepper
- `Key('user_form_nombres')` - Campo nombres (pantalla ancha)
- `Key('nombresUsuarioField')` - Campo nombres (pantalla angosta)

### 8. Iconos para Pruebas
Las pruebas buscan estos iconos:
- `Icons.logout` - Cerrar sesión (en Drawer)
- `Icons.arrow_back` - Botón de volver
- `Icons.notifications_outlined` - Notificaciones

## Verificación
// turbo
```powershell
flutter analyze lib/
```
