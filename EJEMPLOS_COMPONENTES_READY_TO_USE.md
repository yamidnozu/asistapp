# 🎨 Ejemplos de Componentes - Refactorización UI/UX

Este archivo contiene **snippets de código listos para copiar-pegar** que implementan los patrones recomendados en la estrategia de rediseño.

---

## 1️⃣ ClarityManagementHeader (Nuevo Componente)

```dart
/// Agregar a: lib/widgets/components/clarity_components.dart

/// Header funcional para pantallas de gestión
/// Incluye: título, búsqueda, filtros y botón de acción primaria
class ClarityManagementHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final IconData primaryActionIcon;
  final List<Widget>? filters;

  const ClarityManagementHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint = 'Buscar...',
    this.searchController,
    this.onSearchChanged,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Crear',
    this.primaryActionIcon = Icons.add,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;
    final spacing = AppSpacing.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila: Título + Botón de Acción
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
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
            ),
            if (onPrimaryAction != null) ...[
              SizedBox(width: spacing.lg),
              ElevatedButton.icon(
                onPressed: onPrimaryAction,
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel ?? 'Crear'),
              ),
            ],
          ],
        ),
        
        SizedBox(height: spacing.lg),
        
        // Campo de Búsqueda
        if (onSearchChanged != null)
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController?.text.isNotEmpty == true
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController?.clear();
                      onSearchChanged?.call('');
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                borderSide: BorderSide(color: colors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                borderSide: BorderSide(color: colors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
              filled: true,
              fillColor: colors.surface,
            ),
          ),
        
        // Filtros
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

---

## 2️⃣ Patrón: ClarityCard con PopupMenuButton

```dart
/// Uso en: UsersListScreen, InstitutionsListScreen
/// Reemplaza múltiples ClarityActionButton con un menú limpio

Widget _buildUserCard(User user, UserProvider provider, BuildContext context) {
  final colors = context.colors;
  final spacing = context.spacing;
  final textStyles = context.textStyles;

  return ClarityCard(
    onTap: () {
      // 🔑 Acción Principal: Ver Detalles
      _navigateToUserDetail(user);
    },
    title: Text(
      user.nombreCompleto,
      style: textStyles.titleMedium.bold,
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.email, size: 14, color: colors.textSecondary),
            SizedBox(width: spacing.xs),
            Expanded(
              child: Text(
                user.email,
                style: textStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.xs),
        ClarityStatusBadge(
          text: _getRoleDisplayName(user.rol),
          backgroundColor: _getRoleColor(user.rol, context),
          textColor: colors.surface,
        ),
      ],
    ),
    trailing: PopupMenuButton<String>(
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // 📝 Acción: Editar
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        
        // 🔄 Acción: Cambiar Estado
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                user.activo ? Icons.toggle_on : Icons.toggle_off,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(user.activo ? 'Desactivar' : 'Activar'),
            ],
          ),
        ),
        
        // ─────────────────
        const PopupMenuDivider(),
        
        // 🗑️ Acción: Eliminar (en rojo)
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Eliminar',
                style: TextStyle(color: colors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'edit':
            _navigateToUserEdit(user);
            break;
          case 'toggle':
            _toggleUserStatus(user, provider);
            break;
          case 'delete':
            _deleteUser(user, provider);
            break;
        }
      },
    ),
  );
}
```

---

## 3️⃣ Patrón: Dashboard Responsivo con Max-Width

```dart
/// Uso en: AdminDashboard, SuperAdminDashboard, etc.
/// Garantiza que contenido no se estire en monitors grandes

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text('Panel de Administración'),
      ),
      // 🔑 CLAVE: ConstrainedBox + Center para limitar ancho
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Saludo
                Text('¡Hola, Admin!', style: context.textStyles.displayMedium),
                SizedBox(height: spacing.xl),
                
                // 2. Estadísticas (adaptable)
                _buildStatsBar(context),
                SizedBox(height: spacing.xl),
                
                // 3. Grilla de Acciones (responsiva)
                _buildActionGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      // 🔑 SingleChildScrollView permite scroll horizontal si es necesario
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ClarityCompactStat(
              value: '250',
              title: 'Usuarios',
              icon: Icons.people,
              color: colors.primary,
            ),
            SizedBox(width: spacing.lg),
            ClarityCompactStat(
              value: '15',
              title: 'Instituciones',
              icon: Icons.business,
              color: colors.info,
            ),
            SizedBox(width: spacing.lg),
            ClarityCompactStat(
              value: '98%',
              title: 'Asistencia',
              icon: Icons.check_circle,
              color: colors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 🔑 Adaptativo: 2 cols en móvil, 4 en desktop
        final colCount = constraints.maxWidth > 1200 ? 4 : 2;

        return GridView.count(
          crossAxisCount: colCount,
          childAspectRatio: 1.5,
          crossAxisSpacing: spacing.md,
          mainAxisSpacing: spacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context,
              icon: Icons.people_outline,
              label: 'Usuarios',
              onTap: () {},
            ),
            _buildActionCard(
              context,
              icon: Icons.business_outlined,
              label: 'Instituciones',
              onTap: () {},
            ),
            _buildActionCard(
              context,
              icon: Icons.bar_chart_outlined,
              label: 'Reportes',
              onTap: () {},
            ),
            _buildActionCard(
              context,
              icon: Icons.settings_outlined,
              label: 'Ajustes',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.borderRadius),
      child: Container(
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(spacing.borderRadius),
          border: Border.all(color: colors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: colors.primary),
            const Spacer(),
            Text(label, style: textStyles.titleMedium.bold),
          ],
        ),
      ),
    );
  }
}
```

---

## 4️⃣ Patrón: GridView Responsivo (Transición de Columnas)

```dart
/// Uso en: Dashboards, Grillas de Contenido
/// Cambia de 2 → 4 columnas según ancho

Widget _buildResponsiveGrid(BuildContext context, List<Widget> items) {
  final spacing = context.spacing;

  return LayoutBuilder(
    builder: (context, constraints) {
      int cols;
      
      if (constraints.maxWidth > 1400) {
        cols = 4;      // Desktop grande: 4 columnas
      } else if (constraints.maxWidth > 1024) {
        cols = 3;      // Desktop: 3 columnas
      } else if (constraints.maxWidth > 600) {
        cols = 2;      // Tablet: 2 columnas
      } else {
        cols = 1;      // Móvil: 1 columna
      }

      return GridView.count(
        crossAxisCount: cols,
        childAspectRatio: 1.4,
        crossAxisSpacing: spacing.md,
        mainAxisSpacing: spacing.md,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: items,
      );
    },
  );
}
```

---

## 5️⃣ Patrón: Formulario Responsivo (Row → GridView)

```dart
/// Uso en: Formularios multi-campo
/// Móvil: 1 columna | Tablet: 2 columnas | Desktop: 3 columnas

Widget _buildResponsiveForm(BuildContext context) {
  final spacing = context.spacing;

  return LayoutBuilder(
    builder: (context, constraints) {
      int cols;
      
      if (constraints.maxWidth > 1024) {
        cols = 3;  // Desktop
      } else if (constraints.maxWidth > 600) {
        cols = 2;  // Tablet
      } else {
        cols = 1;  // Móvil
      }

      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: spacing.md,
        mainAxisSpacing: spacing.md,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 4,
        children: [
          // Campo 1
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          // Campo 2
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          // Campo 3
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
    },
  );
}
```

---

## 6️⃣ Actualizar responsive_utils.dart

```dart
/// Agregar a: lib/utils/responsive_utils.dart

class ResponsiveUtils {
  static const int mobileBreakpoint = 600;
  static const int tabletBreakpoint = 1024;
  static const int desktopBreakpoint = 1400;
  
  // 🆕 Constantes de max-width
  static const double maxContentWidth = 1400.0;
  static const double maxDialogWidth = 600.0;
  static const double maxFormWidth = 800.0;
  static const double maxCardWidth = 320.0;
  
  static Map<String, dynamic> getResponsiveValues(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final isMobile = width < mobileBreakpoint;
    final isTablet = width >= mobileBreakpoint && width < desktopBreakpoint;
    final isDesktop = width >= desktopBreakpoint;

    return {
      'isMobile': isMobile,
      'isTablet': isTablet,
      'isDesktop': isDesktop,
      
      // 🆕 Helpers de columnas
      'gridCols': isDesktop 
        ? 4 
        : isTablet 
          ? 3 
          : 2,
      
      'formCols': isDesktop 
        ? 3 
        : isTablet 
          ? 2 
          : 1,
      
      // 🆕 Helper de max-width
      'constraintMaxWidth': isDesktop 
        ? maxContentWidth 
        : width,
        
      // 🆕 Escala tipográfica adaptativa (opcional)
      'fontSize': isMobile 
        ? 1.0 
        : isTablet 
          ? 1.1 
          : 1.2,
    };
  }
}
```

---

## ✅ Checklist de Uso

Cuando implementes estos componentes:

- [ ] ¿Importaste los colores/textStyles/spacing correctamente?
- [ ] ¿Probaste en móvil (375px), tablet (768px) y desktop (1400px)?
- [ ] ¿Hay max-width en contenedores principales?
- [ ] ¿Las acciones secundarias están en PopupMenuButton?
- [ ] ¿El header tiene título, búsqueda y botón primario?
- [ ] ¿Usaste LayoutBuilder para responsividad?
- [ ] ¿No hay overflow en ninguna resolución?

---

## 🔗 Referencias

- Material 3 PopupMenuButton: https://flutter.dev/docs/cookbook/design/menus
- LayoutBuilder: https://flutter.dev/docs/development/ui/widgets/layout
- GridView.count: https://flutter.dev/docs/development/ui/layout/responsive

---

**Último Actualizado**: 2 de noviembre de 2025
