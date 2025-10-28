# Guía de Paleta de Colores - AsistApp

## 📊 Sistema de Colores Centralizado

Todos los colores de la aplicación están centralizados en `lib/theme/app_colors.dart` para garantizar consistencia visual y facilitar mantenimiento.

## 🎨 Colores Base

### Colores Primarios y Secundarios
- **primary** (`#0F172A` - Slate 900): Color principal de marca, usado en AppBars, botones primarios
- **primaryDark** (`#0F172A` - Slate 900): Variante oscura del primario
- **primaryLight** (`#6366F1` - Indigo 500): Color para hover/focus
- **primaryContainer** (`#E2E8F0` - Slate 200): Fondo de contenedores primarios

- **secondary** (`#64748B` - Slate 500): Color secundario
- **secondaryLight** (`#94A3B8` - Slate 400): Variante clara del secundario
- **secondaryContainer** (`#F1F5F9` - Slate 100): Fondo de contenedores secundarios

### Superficies y Fondos
- **surface** (`#FFFFFF` - White): Color de tarjetas y superficies elevadas
- **surfaceLight** (`#F8FAFC` - Slate 50): Superficie con ligero tinte
- **surfaceContainer** (`#FFFFFF` - White): Contenedores sobre superficie
- **background** (`#F8FAFC` - Slate 50): Fondo general de la aplicación
- **backgroundLight** (`#FFFFFF` - White): Fondo claro

### Colores de Estado
- **success** (`#10B981` - Emerald 500): Operaciones exitosas, confirmaciones
- **warning** (`#F59E0B` - Amber 500): Advertencias, información importante
- **error** (`#F43F5E` - Rose 500): Errores, acciones destructivas
- **info** (`#6366F1` - Indigo 500): Información general, mensajes informativos

## 🎯 Colores Semánticos para Features

Cada tipo de funcionalidad tiene un color asignado para consistencia visual:

| Feature | Color | Código | Uso |
|---------|-------|--------|-----|
| **Usuarios** | Blue 500 | `#3B82F6` | `colors.featureUsers` - Gestión de usuarios |
| **Instituciones** | Emerald 500 | `#10B981` | `colors.featureInstitutions` - Gestión de instituciones |
| **Asistencia** | Amber 500 | `#F59E0B` | `colors.featureAttendance` - Registro de asistencia |
| **Reportes** | Violet 500 | `#8B5CF6` | `colors.featureReports` - Reportes y estadísticas |
| **Horarios** | Cyan 500 | `#06B6D4` | `colors.featureSchedule` - Horarios y calendario |
| **Configuración** | Slate 500 | `#64748B` | `colors.featureSettings` - Configuración del sistema |
| **Notificaciones** | Rose 500 | `#F43F5E` | `colors.featureNotifications` - Notificaciones |
| **Clases** | Red 500 | `#EF4444` | `colors.featureClasses` - Gestión de clases |
| **Calificaciones** | Teal 500 | `#14B8A6` | `colors.featureGrades` - Calificaciones |
| **Estudiantes** | Indigo 500 | `#6366F1` | `colors.featureStudents` - Gestión de estudiantes |

## 📝 Colores de Texto

### Texto en Fondos Claros
- **textPrimary** (`#1E293B` - Slate 800): Texto principal, títulos
- **textSecondary** (`#64748B` - Slate 500): Texto secundario, subtítulos
- **textMuted** (`#94A3B8` - Slate 400): Texto atenuado, hints
- **textDisabled** (`#CBD5E1` - Slate 300): Texto deshabilitado

### Texto en Fondos Oscuros
- **textOnDark** (`#F1F5F9` - Slate 100): Texto principal sobre fondos oscuros
- **textOnDarkSecondary** (`#CBD5E1` - Slate 300): Texto secundario sobre fondos oscuros
- **textOnDarkMuted** (`#94A3B8` - Slate 400): Texto atenuado sobre fondos oscuros

## 🔲 Bordes y Divisores
- **border** (`#E2E8F0` - Slate 200): Bordes estándar
- **borderLight** (`#F1F5F9` - Slate 100): Bordes sutiles
- **divider** (`#E2E8F0` - Slate 200): Líneas divisoras

## 🌈 Estados Informativos

Colores para estados específicos de la UI:

- **stateNoData** (`#F59E0B` - Amber 500): Sin datos disponibles
- **stateInDevelopment** (`#3B82F6` - Blue 500): Funcionalidad en desarrollo
- **stateSuccess** (`#10B981` - Emerald 500): Estado exitoso/activo
- **stateInactive** (`#94A3B8` - Slate 400): Estado inactivo

## 🎨 Helpers de Opacidad

### Colores con Opacidad Predefinida
```dart
colors.primaryWithOpacity        // primary con alpha: 0.8
colors.surfaceWithOpacity        // surface con alpha: 0.9
colors.textSecondaryWithOpacity  // textSecondary con alpha: 0.7
```

### Fondos de Estado con Opacidad
```dart
colors.warningBackground   // warning con alpha: 0.1
colors.warningBorder       // warning con alpha: 0.3
colors.infoBackground      // info con alpha: 0.1
colors.infoBorder          // info con alpha: 0.3
colors.errorBackground     // error con alpha: 0.1
colors.errorBorder         // error con alpha: 0.3
colors.successBackground   // success con alpha: 0.1
colors.successBorder       // success con alpha: 0.3
```

### Badges de Rol (AppBar)
```dart
colors.roleBadgeBackground  // white con alpha: 0.2
colors.roleBadgeText        // white
colors.roleBadgeIcon        // white
```

## 🛠️ Métodos Helper para Contraste

### Determinación Automática de Color de Texto

El sistema incluye métodos helper para determinar automáticamente el color de texto apropiado según el fondo:

```dart
// Texto principal según fondo
colors.getTextColorForBackground(backgroundColor)

// Texto secundario según fondo
colors.getSecondaryTextColorForBackground(backgroundColor)

// Texto atenuado según fondo
colors.getMutedTextColorForBackground(backgroundColor)
```

## 📋 Guía de Uso por Componente

### AppBar
```dart
AppBar(
  backgroundColor: colors.primary,
  // Los iconos y texto serán blancos automáticamente
)
```

### Tarjetas de Features (Dashboard)
```dart
DashboardFeatureCard(
  icon: Icons.people,
  title: 'Usuarios',
  description: 'Gestionar usuarios',
  color: colors.featureUsers,  // ✅ Correcto: usar color semántico
  responsive: responsive,
)
```

### Mensajes de Estado
```dart
// Sin datos
Container(
  color: colors.warningBackground,
  child: Icon(Icons.info, color: colors.warning),
)

// En desarrollo
Container(
  color: colors.infoBackground,
  child: Icon(Icons.construction, color: colors.info),
)

// Error
Container(
  color: colors.errorBackground,
  child: Icon(Icons.error, color: colors.error),
)
```

### Textos
```dart
// Sobre fondo claro
Text('Título', style: TextStyle(color: colors.textPrimary))
Text('Subtítulo', style: TextStyle(color: colors.textSecondary))

// Sobre fondo oscuro (primary)
Text('Título', style: TextStyle(color: colors.textOnDark))
Text('Subtítulo', style: TextStyle(color: colors.textOnDarkSecondary))

// Automático según fondo
Text(
  'Texto',
  style: TextStyle(
    color: colors.getTextColorForBackground(backgroundColor)
  )
)
```

## ❌ Evitar

### NO usar colores hardcoded:
```dart
// ❌ MAL
color: Colors.blue
color: Colors.red
color: Color(0xFF123456)
color: Colors.grey[800]

// ✅ BIEN
color: colors.featureUsers
color: colors.error
color: colors.primary
color: colors.textPrimary
```

### NO usar opacidades arbitrarias:
```dart
// ❌ MAL
color: Colors.blue.withValues(alpha: 0.1)

// ✅ BIEN
color: colors.infoBackground
```

## 🔄 Cómo Acceder a los Colores

En cualquier widget con BuildContext:

```dart
@override
Widget build(BuildContext context) {
  final colors = context.colors;  // Extension method
  
  return Container(
    color: colors.primary,
    child: Text(
      'Hola',
      style: TextStyle(color: colors.textOnDark),
    ),
  );
}
```

## 📦 Archivos Relacionados

- **Definición de colores**: `lib/theme/app_colors.dart`
- **Extension para acceso**: `lib/theme/theme_extensions.dart`
- **Tema de la app**: `lib/theme/app_theme.dart`

## 🎯 Beneficios del Sistema Centralizado

1. **Consistencia Visual**: Todos los componentes usan los mismos colores
2. **Fácil Mantenimiento**: Cambiar un color actualiza toda la app
3. **Accesibilidad**: Contraste apropiado automáticamente
4. **Branding**: Fácil adaptar a diferentes marcas
5. **Semántica Clara**: Nombres descriptivos de colores
6. **Type Safety**: IntelliSense muestra todos los colores disponibles

## 📊 Mapa Visual de Uso

### Super Admin Dashboard
- Instituciones → `colors.featureInstitutions` 
- Usuarios Globales → `colors.featureUsers`
- Permisos → `colors.featureSettings`
- Reportes Globales → `colors.featureReports`
- Configuración → `colors.featureSettings`
- Backup & Restore → `colors.error`

### Admin Dashboard
- Usuarios → `colors.featureUsers`
- Grupos → `colors.featureClasses`
- Horarios → `colors.featureSchedule`
- Asistencia → `colors.featureAttendance`
- Reportes → `colors.featureReports`
- Configuración → `colors.featureSettings`

### Teacher Dashboard
- Tomar Asistencia → `colors.featureAttendance`
- Mis Clases → `colors.featureClasses`
- Estudiantes → `colors.featureStudents`
- Reportes → `colors.featureReports`
- Notificaciones → `colors.featureNotifications`
- Horario → `colors.featureSchedule`

### Student Dashboard
- Mi Código QR → `colors.featureAttendance`
- Mi Horario → `colors.featureSchedule`
- Asistencia → `colors.featureClasses`
- Estadísticas → `colors.featureReports`
- Notificaciones → `colors.featureNotifications`
- Contacto → `colors.info`

---

**Última actualización**: 27 de octubre de 2025  
**Versión**: 1.0.0
