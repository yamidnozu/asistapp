# 🛠️ Guía Técnica de Implementación - Rediseño UI/UX

**Versión**: 1.0  
**Fecha**: 2 de noviembre de 2025  
**Audiencia**: Equipo Técnico de Desarrollo

---

## 📌 Índice Rápido

1. [Fase 1: Unificación Visual](#fase-1-unificación-visual)
2. [Fase 3: Responsividad Fluida](#fase-3-responsividad-fluida)
3. [Fase 4: Menús Contextuales](#fase-4-menús-contextuales)
4. [Fase 5: Header Funcional](#fase-5-header-funcional)
5. [Componentes Nuevos](#componentes-nuevos-a-crear)

---

## Fase 1: Unificación Visual

### Objetivo
Asegurar que TODAS las pantallas usan componentes Clarity y siguen un patrón visual coherente.

### Checklist de Pantallas a Auditar

```dart
// ❓ ANTES: Dos estilos diferentes
lib/screens/admin_dashboard.dart          // ✅ Ya refactorizado con patrón Clarity
lib/screens/clarity_admin_dashboard.dart  // ❌ DEPRECAR (si existe)

lib/screens/super_admin_dashboard.dart    // ✅ Ya refactorizado
lib/screens/teacher_dashboard.dart        // ✅ Ya refactorizado
lib/screens/student_dashboard.dart        // ✅ Ya refactorizado

// ✅ Listas (verificar que usan ClarityCard)
lib/screens/users/users_list_screen.dart           // Usa ClarityCard ✓
lib/screens/institutions/institutions_list_screen.dart // Usa ClarityCard ✓
```

### Patrón Clarity Estándar para Dashboards

```dart
// ✅ PATRÓN CORRECTO - Todos los dashboards deben seguir esto

class SuperAdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Panel de Super Admin', style: textStyles.headlineSmall),
        actions: [...], // Solo acciones esenciales
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400), // 🔑 Max-width
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Saludo
                _buildGreeting(),
                
                // 2. Estadísticas (Wrap o horizontal scrollable)
                _buildStatsBar(),
                
                // 3. Contenido Principal
                _buildMainContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Fase 3: Responsividad Fluida

### Principio Clave: NO Escalar, Reorganizar

```dart
// ❌ MAL - Solo escala tamaños
GridView.count(
  crossAxisCount: _width > 1000 ? 4 : 2, // Cambia cols, pero item size escala
  children: [...],
)

// ✅ BIEN - Reorganiza y constrine
GridView.count(
  crossAxisCount: 2,
  childAspectRatio: 1.5,
  mainAxisSpacing: spacing.md,
  crossAxisSpacing: spacing.md,
  children: [...],
) 
// En escritorio: Envuelto en ConstrainedBox(maxWidth: 1200)
```

### Patrón: Columna Central para Desktop

```dart
// 🔑 Patrón Recomendado para Todas las Pantallas

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 1024;
      
      // En desktop, centra y limita ancho
      if (isDesktop) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1400),
            child: _buildContent(),
          ),
        );
      } else {
        // En móvil, contenido fluido
        return _buildContent();
      }
    },
  );
}
```

### Actualizar `responsive_utils.dart` con Max-Width

```dart
// 📝 lib/utils/responsive_utils.dart

class ResponsiveUtils {
  static const int mobileBreakpoint = 600;
  static const int tabletBreakpoint = 1024;
  static const int desktopBreakpoint = 1400;
  
  // 🆕 Agregue constantes de max-width
  static const double maxContentWidth = 1400.0;
  static const double maxDialogWidth = 600.0;
  static const double maxFormWidth = 800.0;
  
  static Map<String, dynamic> getResponsiveValues(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    
    return {
      'isMobile': width < mobileBreakpoint,
      'isTablet': width >= mobileBreakpoint && width < desktopBreakpoint,
      'isDesktop': width >= desktopBreakpoint,
      
      // 🆕 Helpers útiles
      'gridCols': width > desktopBreakpoint 
        ? 4 
        : width > tabletBreakpoint 
          ? 3 
          : 2,
      
      'constraintMaxWidth': width > desktopBreakpoint 
        ? maxContentWidth 
        : width,
    };
  }
}
```

### Ejemplo: GridView Responsivo en Dashboard

```dart
// ❌ ANTES: Rígido
GridView.count(
  crossAxisCount: 2,
  children: [
    _buildActionCard(...),
    _buildActionCard(...),
    _buildActionCard(...),
    _buildActionCard(...),
  ],
)

// ✅ DESPUÉS: Adaptativo
LayoutBuilder(
  builder: (context, constraints) {
    final colCount = constraints.maxWidth > 1200 ? 4 : 2;
    
    return GridView.count(
      crossAxisCount: colCount,
      childAspectRatio: 1.5,
      crossAxisSpacing: spacing.md,
      mainAxisSpacing: spacing.md,
      children: [
        _buildActionCard(...),
        _buildActionCard(...),
        _buildActionCard(...),
        _buildActionCard(...),
      ],
    );
  },
)
```

---

## Fase 4: Menús Contextuales

### Patrón: Reemplazar Múltiples Botones con PopupMenuButton

```dart
// ❌ ANTES: Demasiados botones visibles
Widget _buildUserCard(User user) {
  return ClarityCard(
    title: Text(user.name),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClarityActionButton(
          icon: Icons.edit,
          onPressed: () => _edit(user),
        ),
        ClarityActionButton(
          icon: Icons.toggle_on,
          onPressed: () => _toggle(user),
        ),
        ClarityActionButton(
          icon: Icons.delete,
          onPressed: () => _delete(user),
        ),
      ],
    ),
  );
}

// ✅ DESPUÉS: Acciones principales visible, secundarias en menú
Widget _buildUserCard(User user) {
  return ClarityCard(
    onTap: () => _viewDetails(user), // 🔑 Acción principal en tap
    title: Text(user.name),
    subtitle: Text(user.email),
    status: user.active ? 'Activo' : 'Inactivo',
    trailing: PopupMenuButton<String>(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(Icons.toggle_on, size: 18),
              SizedBox(width: 8),
              Text('Cambiar Estado'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _edit(user);
            break;
          case 'toggle':
            _toggle(user);
            break;
          case 'delete':
            _delete(user);
            break;
        }
      },
    ),
  );
}
```

---

## Fase 5: Header Funcional

### Crear Componente `ClarityManagementHeader`

```dart
// 📝 Agregar a lib/widgets/components/clarity_components.dart

class ClarityManagementHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final IconData primaryActionIcon;
  final List<Widget>? filters;

  const ClarityManagementHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint,
    this.onSearchChanged,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Crear',
    this.primaryActionIcon = Icons.add,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔑 Título + Botón de Acción Principal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textStyles.headlineSmall),
                if (subtitle != null) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    subtitle!,
                    style: textStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            if (onPrimaryAction != null)
              ElevatedButton.icon(
                onPressed: onPrimaryAction,
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel!),
              ),
          ],
        ),
        
        SizedBox(height: spacing.lg),
        
        // 🔑 Búsqueda
        if (onSearchChanged != null)
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint ?? 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
            ),
          ),
        
        // 🔑 Filtros
        if (filters != null && filters!.isNotEmpty) ...[
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.md,
            runSpacing: spacing.sm,
            children: filters!,
          ),
        ],
      ],
    );
  }
}
```

### Uso en UsersListScreen

```dart
// 📝 lib/screens/users/users_list_screen.dart

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // 🆕 Header Funcional
          Padding(
            padding: EdgeInsets.all(context.spacing.lg),
            child: ClarityManagementHeader(
              title: 'Gestión de Usuarios',
              subtitle: '${users.length} usuarios en total',
              searchHint: 'Buscar por nombre, email...',
              onSearchChanged: _onSearchChanged,
              onPrimaryAction: _navigateToCreateUser,
              primaryActionLabel: 'Crear Usuario',
              filters: [
                FilterChip(
                  label: const Text('Activos'),
                  onSelected: (selected) => _filterByStatus(true),
                ),
                FilterChip(
                  label: const Text('Todos'),
                  onSelected: (selected) => _filterByStatus(null),
                ),
              ],
            ),
          ),
          
          // 📋 Lista de usuarios con nuevo patrón
          ..._buildUsersList(),
        ],
      ),
    ),
  );
}
```

---

## Componentes Nuevos a Crear

### 1. `ClarityListItemWithContextMenu`

```dart
class ClarityListItemWithContextMenu<T> extends StatelessWidget {
  final T item;
  final Widget title;
  final Widget subtitle;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<String>> menuItems;
  final ValueChanged<String>? onMenuSelected;

  const ClarityListItemWithContextMenu({
    required this.item,
    required this.title,
    required this.subtitle,
    this.onTap,
    required this.menuItems,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClarityCard(
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) => menuItems,
        onSelected: onMenuSelected,
      ),
    );
  }
}
```

### 2. `ResponsiveLayout`

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget? tabletView;
  final Widget? desktopView;

  const ResponsiveLayout({
    required this.mobileView,
    this.tabletView,
    this.desktopView,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktopView ?? tabletView ?? mobileView;
        } else if (constraints.maxWidth >= 600) {
          return tabletView ?? mobileView;
        } else {
          return mobileView;
        }
      },
    );
  }
}
```

---

## Checklist de Implementación

### Antes de Mergear Código

- [ ] ¿El componente usa `context.colors`, `context.textStyles`, `context.spacing`?
- [ ] ¿El layout se adapta correctamente en móvil (375px) y desktop (1400px)?
- [ ] ¿Hay un max-width en dashboards/pantallas principales?
- [ ] ¿Las acciones secundarias están en menú contextual, no en botones visibles?
- [ ] ¿El header de gestión tiene título, búsqueda y botón de acción primaria?
- [ ] ¿No hay duplicidad de componentes (ej. AdminDashboard vs ClarityAdminDashboard)?
- [ ] ¿Contraste de colores ≥ 4.5:1 en textos críticos?
- [ ] ¿Se probó en al menos 3 resoluciones (móvil, tablet, desktop)?

---

## Comandos Útiles

```bash
# Analizar código
flutter analyze

# Ejecutar linter estricto
flutter analyze --no-pub

# Probar en device preview
# (Agregue: device_preview: ^1.1.0 a pubspec.yaml)
# Luego: wrap main() con DevicePreview

# Ejecutar tests
flutter test

# Build de prueba
flutter build web --web-renderer html
```

---

## Referencias Internas

- Componentes Clarity: `lib/widgets/components/clarity_components.dart`
- Colores: `lib/theme/app_colors.dart`
- Tipografía: `lib/theme/app_text_styles.dart`
- Espaciado: `lib/theme/app_spacing.dart`
- Responsive Utils: `lib/utils/responsive_utils.dart`

---

**Documento Preparado Por**: Equipo de UX/Desarrollo  
**Última Actualización**: 2 de noviembre de 2025
