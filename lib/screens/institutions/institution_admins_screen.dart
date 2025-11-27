import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/institution_admins_paginated_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/components/index.dart';
import '../../theme/theme_extensions.dart';
import '../../models/user.dart';
// import '../../services/user_service.dart'; // no longer used directly
// create_institution_admin_screen route is now opened via go_router, no direct import required


class InstitutionAdminsScreen extends StatefulWidget {
  final String institutionId;

  const InstitutionAdminsScreen({super.key, required this.institutionId});

  @override
  State<InstitutionAdminsScreen> createState() => _InstitutionAdminsScreenState();
}

class _InstitutionAdminsScreenState extends State<InstitutionAdminsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdmins();
    });
  }

  void _showAssignExistingUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AssignExistingUserDialog(institutionId: widget.institutionId, onAssigned: () async {
        await _loadAdmins();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
  final pag = Provider.of<InstitutionAdminsPaginatedProvider>(context);
    return ClarityManagementPage(
      title: 'Administradores de Institución',
  isLoading: pag.isLoading,
  hasError: pag.hasError,
  errorMessage: pag.errorMessage,
  itemCount: pag.items.length,
      itemBuilder: (context, index) {
        if (index >= pag.items.length) {
          return pag.isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }

  final user = pag.items[index];
        return _buildAdminCard(user, context);
      },
      onRefresh: _loadAdmins,
      scrollController: _scrollController,
  hasMoreData: pag.hasMoreData,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAdminSheet,
        backgroundColor: context.colors.primary,
        child: Icon(
          Icons.add,
          color: context.colors.getTextColorForBackground(context.colors.primary),
        ),
      ),
      emptyStateWidget: const ClarityEmptyState(
        icon: Icons.group_off,
        title: 'No hay administradores',
        subtitle: 'Agrega administradores a esta institución',
      ),
    );
  }

  Future<void> _loadAdmins() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final pag = Provider.of<InstitutionAdminsPaginatedProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
  await pag.loadItems(token, page: 1, limit: 10, filters: {'institutionId': widget.institutionId});
    }
  }

  Future<void> _removeAdmin(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final pag = Provider.of<InstitutionAdminsPaginatedProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Administrador'),
        content: Text('¿Deseas remover el rol de administrador a ${user.nombreCompleto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remover')),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = authProvider.accessToken;
    if (token != null) {
      final success = await userProvider.removeAdminFromInstitution(token, widget.institutionId, user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrador removido correctamente')));
  await pag.loadItems(token, page: 1, limit: 10, filters: {'institutionId': widget.institutionId});
      }
    }
  }

  void _openAddAdminSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.person_add, color: colors.primary),
                title: const Text('Crear Nuevo Administrador'),
                onTap: () {
                  Navigator.of(context).pop();
                  final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);
                  final institution = institutionProvider.institutions.firstWhere((i) => i.id == widget.institutionId);
                  // Use go_router named route so navigation is consistent across the app
                  context.pushNamed('institution-create-admin', extra: institution);
                  // Reload admins after possible changes once the pushed route completes
                  // go_router's context.pushNamed doesn't return a Future using .then directly,
                  // but we can listen for route pops via a post-frame callback or refresh on resume of the screen.
                  // For simplicity, trigger reload when this bottom sheet closes (above) or rely on provider updates.
                },
              ),
              ListTile(
                leading: Icon(Icons.person_search, color: colors.primary),
                title: const Text('Asignar Usuario Existente'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAssignExistingUserDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminCard(User user, BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return ClarityCard(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Text(
              user.inicial,
              style: textStyles.bodyMedium.withColor(colors.primary),
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              user.nombreCompleto,
              style: textStyles.titleMedium.bold,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 16, color: colors.textSecondary),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  user.email ?? '',
                  style: textStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (user.telefono != null)
            SizedBox(height: spacing.xs),
          if (user.telefono != null)
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: colors.textSecondary),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    user.telefono!,
                    style: textStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClarityActionButton(
            icon: Icons.key,
            tooltip: 'Cambiar contraseña',
            color: colors.primary,
            onPressed: () => _showChangePasswordDialog(context, user),
          ),
          SizedBox(width: spacing.sm),
          ClarityActionButton(
            icon: Icons.remove_circle,
            tooltip: 'Remover administrador',
            color: colors.error,
            onPressed: () => _removeAdmin(user),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, User user) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChangePasswordDialog(user: user, onSaved: () async {
        // Recargar lista después de cambio de contraseña
        await _loadAdmins();
      }),
    );
  }

}

class _ChangePasswordDialog extends StatefulWidget {
  final User user;
  final VoidCallback? onSaved;

  const _ChangePasswordDialog({required this.user, this.onSaved});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    // ClarityFormDialog validates before calling onSave, keep guard
    if (!_formKey.currentState!.validate()) return false;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final token = authProvider.accessToken;
      if (token == null) throw Exception('No hay sesión activa');

      final success = await userProvider.changeUserPassword(
        token,
        widget.user.id,
        _newPasswordController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contraseña de ${widget.user.nombreCompleto} cambiada correctamente')));
        widget.onSaved?.call();
        return true;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar la contraseña')));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return ClarityFormDialog(
      title: Text('Cambiar contraseña - ${widget.user.nombreCompleto}'),
      formKey: _formKey,
      onSave: _save,
      saveLabel: 'Guardar',
      cancelLabel: 'Cancelar',
      children: [
        TextFormField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'La contraseña es requerida';
            if (value.trim().length < 8) return 'La contraseña debe tener al menos 8 caracteres';
            return null;
          },
        ),
        SizedBox(height: spacing.md),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'La confirmación es requerida';
            if (value.trim() != _newPasswordController.text.trim()) return 'Las contraseñas no coinciden';
            return null;
          },
        ),
      ],
    );
  }
}


class AssignExistingUserDialog extends StatefulWidget {
  final String institutionId;
  final VoidCallback? onAssigned;

  const AssignExistingUserDialog({super.key, required this.institutionId, this.onAssigned});

  @override
  State<AssignExistingUserDialog> createState() => _AssignExistingUserDialogState();
}

class _AssignExistingUserDialogState extends State<AssignExistingUserDialog> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // selected users not used for now; dialog assigns directly
  static const int _pageSize = 20;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Evitar notificar listeners durante el build; cargar datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialUsers();
    });
  }

  @override
  void dispose() {
  _searchController.removeListener(_onSearchChanged);
  if (_debounce?.isActive ?? false) _debounce!.cancel();
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
      if (token == null) return;
      final pag = Provider.of<InstitutionAdminsPaginatedProvider>(context, listen: false);
      pag.resetPagination();
      // Usar modo assignment para buscar todos los admin_institucion (pueden estar en otras instituciones)
      await pag.loadItems(token, page: 1, limit: _pageSize, search: query.isEmpty ? null : query, filters: {'institutionId': widget.institutionId, 'assignment': 'true'});
    });
  }

  // Filtering/search handled by provider

  Future<void> _loadInitialUsers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;
    final pag = Provider.of<InstitutionAdminsPaginatedProvider>(context, listen: false);
    try {
      // Cargar en modo assignment para mostrar todos los admin_institucion
      await pag.loadItems(token, page: 1, limit: _pageSize, filters: {'institutionId': widget.institutionId, 'assignment': 'true'});
    } catch (e) {
      debugPrint('Error cargando usuarios iniciales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: ${e.toString()}')),
        );
      }
    } finally {
      // no local isLoading
    }
  }
      // handled above in the debounce body

  // loading and paging are handled by InstitutionAdminsPaginatedProvider;
  // no local implementation required here.

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;
    final pag = Provider.of<InstitutionAdminsPaginatedProvider>(context, listen: false);
    if (pag.isLoadingMore || !pag.hasMoreData) return;
    // Mantener assignment mode para cargar admins globales
    pag.setFilter('institutionId', widget.institutionId);
    pag.setFilter('assignment', 'true');
    await pag.loadNextPage(token);
  }

  Future<void> _assign(User user) async {
  setState(() => _isAssigning = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final success = await userProvider.assignAdminToInstitution(
        token,
        widget.institutionId,
        user.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.nombreCompleto} asignado como administrador')),
        );
        widget.onAssigned?.call();
        Navigator.of(context).pop();
      } else {
        throw Exception('No se pudo asignar el administrador');
      }
    } catch (e) {
      debugPrint('Error asignando administrador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar administrador: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Administrador de Institución'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar administradores...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de administradores de institución (paginados)
            Expanded(
              child: Consumer<InstitutionAdminsPaginatedProvider>(
                  builder: (context, pag, child) {
                    if (pag.isLoading && pag.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!pag.isLoading && pag.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.people_outline, size: 56, color: context.colors.textMuted),
                            const SizedBox(height: 12),
                              Text('No hay administradores disponibles', style: context.textStyles.bodyMedium.copyWith(color: context.colors.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }
                    final items = pag.items;
                    return ListView.builder(
                  controller: _scrollController,
                  // quitar padding horizontal global para que las filas se alineen exactamente
                  padding: EdgeInsets.zero,
                  itemCount: items.length + (pag.hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Item de carga al final
                    if (index == items.length) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      );
                    }

                    final user = items[index];
                    final alreadyAssigned = (user.instituciones ?? []).any((inst) => inst.id == widget.institutionId);

                    return Card(
                      // mantener sólo margen vertical; el padding lo controlamos en el contenido
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                              onTap: (pag.isLoading || alreadyAssigned || _isAssigning) ? null : () => _assign(user),
                        child: Padding(
                          // padding horizontal más reducido para evitar columna en blanco
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar eliminado intencionalmente para ajustar layout

                              // Información del usuario
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Nombre completo
                                      Text(
                                        user.nombreCompleto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Email
                                      Text(
                                        user.email ?? '',
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                      ),

                                      // Instituciones asignadas
                                      if ((user.instituciones ?? []).any((inst) => inst.activo)) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'En: ${(user.instituciones ?? []).where((inst) => inst.activo).map((inst) => inst.nombre).join(', ')}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ),

                              const SizedBox(width: 12),

                              // Botón de asignar (deshabilitado si ya está asignado)
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: (pag.isLoading || alreadyAssigned || _isAssigning) ? null : () => _assign(user),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    alreadyAssigned ? 'Ya asignado' : 'Asignar',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

            // footer handled in consumer list view branches
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
