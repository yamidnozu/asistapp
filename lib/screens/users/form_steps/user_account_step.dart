// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/form_widgets.dart';
import '../../../providers/institution_provider.dart';
import '../../../models/institution.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Step 1: Información de Cuenta (Email, Institución si aplica)
class UserAccountStep extends StatefulWidget {
  final TextEditingController emailController;
  final String userRole;
  final List<String> selectedInstitutionIds;
  final List<String> selectedInstitutionNames;
  final ValueChanged<List<String>> onInstitutionChanged;
  final bool isEditMode;
  final bool disableInstitution;
  final FocusNode? emailFocusNode;
  final FocusNode? institutionFocusNode;
  final GlobalKey<FormFieldState<String>>? emailFieldKey;
  final GlobalKey<FormFieldState<String>>? institutionFieldKey;
  final String? errorEmail;

  const UserAccountStep({
    super.key,
    required this.emailController,
    required this.userRole,
    required this.selectedInstitutionIds,
    required this.selectedInstitutionNames,
    required this.onInstitutionChanged,
    this.isEditMode = false,
    this.disableInstitution = false,
    this.emailFocusNode,
    this.institutionFocusNode,
    this.emailFieldKey,
    this.institutionFieldKey,
    this.errorEmail,
  });

  @override
  State<UserAccountStep> createState() => _UserAccountStepState();
}

class _UserAccountStepState extends State<UserAccountStep> {
  bool _isReloading = false;
  final TextEditingController _institutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateInstitutionController();
  }

  @override
  void didUpdateWidget(covariant UserAccountStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedInstitutionIds != widget.selectedInstitutionIds ||
        oldWidget.selectedInstitutionNames != widget.selectedInstitutionNames) {
      _updateInstitutionController();
    }
  }

  void _updateInstitutionController() {
    final institutionProvider =
        Provider.of<InstitutionProvider>(context, listen: false);
    // Mostrar las instituciones seleccionadas como una única cadena separada por comas
    if (widget.selectedInstitutionIds.isNotEmpty) {
      // Intentar mapear ids a nombres usando el provider; si no hay coincidencia, usar los nombres pasados
      final names = <String>[];
      for (final id in widget.selectedInstitutionIds) {
        final match = institutionProvider.institutions.firstWhere(
          (i) => i.id == id,
          orElse: () => Institution(
              id: id,
              nombre: '',
              direccion: null,
              telefono: null,
              email: null,
              activa: true),
        );
        if (match.nombre.isNotEmpty) names.add(match.nombre);
      }
      if (names.isEmpty && widget.selectedInstitutionNames.isNotEmpty) {
        _institutionController.text =
            widget.selectedInstitutionNames.join(', ');
      } else {
        _institutionController.text = names.join(', ');
      }
    } else {
      _institutionController.text = '';
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de la Cuenta',
          style: context.textStyles.headlineSmall,
        ),
        SizedBox(height: spacing.md),
        Text(
          'Configure las credenciales de acceso del usuario',
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.lg),

        // Correo electrónico
        CustomTextFormField(
          key: const Key('emailUsuarioField'),
          fieldKey: widget.emailFieldKey,
          focusNode: widget.emailFocusNode,
          controller: widget.emailController,
          labelText: 'Email',
          hintText: '${widget.userRole}@ejemplo.com',
          keyboardType: TextInputType.emailAddress,
          enabled: true, // Editable tanto en creación como edición
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El email es requerido';
            }
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Ingrese un email válido';
            }
            return null;
          },
          errorText: widget.errorEmail,
        ),
        SizedBox(height: spacing.md),

        // Dropdown de Institución (solo para admin_institucion creado por super_admin)
        if (widget.userRole == 'admin_institucion') ...[
          Consumer2<AuthProvider, InstitutionProvider>(
            builder: (context, authProvider, institutionProvider, child) {
              // Si es self-edit por admin_institucion y la institución está bloqueada,
              // mostrar un campo de solo lectura con las instituciones asignadas.
              if (widget.disableInstitution) {
                final names = widget.selectedInstitutionNames.isNotEmpty
                    ? widget.selectedInstitutionNames
                    : (authProvider.administrationName != null
                        ? [authProvider.administrationName!]
                        : ['—']);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instituciones', style: context.textStyles.labelLarge),
                    SizedBox(height: spacing.sm),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: spacing.md, vertical: spacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.borderLight),
                      ),
                      child: Text(names.join(', '),
                          style: context.textStyles.bodyMedium),
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      'No puedes cambiar las instituciones de tu propia cuenta',
                      style: context.textStyles.bodySmall
                          .copyWith(color: context.colors.textSecondary),
                    ),
                    SizedBox(height: spacing.md),
                  ],
                );
              }

              // Mostrar dropdown cuando se crea un admin_institucion.
              // Si la lista de instituciones está vacía, mostrar un mensaje y un botón para recargar.
              if (institutionProvider.institutions.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No se encontraron instituciones.',
                      style: context.textStyles.bodyMedium
                          .copyWith(color: context.colors.textSecondary),
                    ),
                    SizedBox(height: spacing.sm),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isReloading
                              ? null
                              : () async {
                                  final token = authProvider.accessToken;
                                  if (token != null) {
                                    setState(() => _isReloading = true);
                                    try {
                                      await institutionProvider
                                          .loadInstitutions(token,
                                              page: 1, limit: 100);
                                    } finally {
                                      if (mounted)
                                        setState(() => _isReloading = false);
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'No hay sesión activa para recargar instituciones')),
                                    );
                                  }
                                },
                          child: _isReloading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Recargar instituciones'),
                        ),
                        SizedBox(width: spacing.md),
                        TextButton(
                          onPressed: () {},
                          child: Text('Contactar soporte',
                              style: context.textStyles.bodySmall
                                  .withColor(context.colors.info)),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return TextFormField(
                key: const Key('institucionField'),
                controller: _institutionController,
                focusNode: widget.institutionFocusNode,
                decoration: InputDecoration(
                  labelText: 'Institución',
                  hintText: 'Seleccione una institución',
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                readOnly: true,
                onTap: widget.disableInstitution
                    ? null
                    : () => _showInstitutionSelectionModal(
                        context, institutionProvider, authProvider),
                validator: (value) {
                  if (widget.selectedInstitutionIds.isEmpty) {
                    return 'Debe seleccionar al menos una institución';
                  }
                  return null;
                },
              );
            },
          ),
          SizedBox(height: spacing.md),
        ],

        if (!widget.isEditMode) ...[
          Container(
            padding: EdgeInsets.all(spacing.md),
            decoration: BoxDecoration(
              color: context.colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: context.colors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: context.colors.info, size: 20),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Se generará una contraseña temporal. El usuario deberá cambiarla en su primer acceso.',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showInstitutionSelectionModal(BuildContext context,
      InstitutionProvider institutionProvider, AuthProvider authProvider) {
    final TextEditingController searchController = TextEditingController();
    List<Institution> filteredInstitutions = institutionProvider.institutions;
    bool isLoading = institutionProvider.isLoading;

    // Mantener selección local fuera del builder para que sobreviva a los
    // rebuilds que provoca `setModalState`. Antes estaba dentro del builder
    // y se reiniciaba en cada rebuild, por eso los checks no cambiaban.
    final selectedIds = widget.selectedInstitutionIds.toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFiltered() {
              final query = searchController.text.toLowerCase();
              setModalState(() {
                filteredInstitutions = institutionProvider.institutions
                    .where((inst) => inst.nombre.toLowerCase().contains(query))
                    .toList();
              });
            }

            Future<void> reloadInstitutions() async {
              final token = authProvider.accessToken;
              if (token != null) {
                setModalState(() => isLoading = true);
                try {
                  await institutionProvider.loadInstitutions(token,
                      page: 1, limit: 100);
                  setModalState(() {
                    filteredInstitutions = institutionProvider.institutions;
                    isLoading = false;
                  });
                } catch (e) {
                  setModalState(() => isLoading = false);
                }
              }
            }

            // `selectedIds` declarado fuera para persistir entre rebuilds

            Widget buildContent() {
              // Estado de carga
              if (isLoading) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando instituciones...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              }

              // Estado vacío
              if (filteredInstitutions.isEmpty) {
                final hasSearchQuery = searchController.text.isNotEmpty;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSearchQuery
                              ? Icons.search_off
                              : Icons.business_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasSearchQuery
                              ? 'No se encontraron instituciones'
                              : 'Sin instituciones disponibles',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasSearchQuery
                              ? 'Intenta con otros términos de búsqueda'
                              : 'No hay instituciones activas en el sistema',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (hasSearchQuery)
                          TextButton.icon(
                            onPressed: () {
                              searchController.clear();
                              updateFiltered();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar búsqueda'),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: reloadInstitutions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recargar'),
                          ),
                      ],
                    ),
                  ),
                );
              }

              // Lista de instituciones con selección múltiple
              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredInstitutions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final institution = filteredInstitutions[index];
                        final isSelected = selectedIds.contains(institution.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true)
                                selectedIds.add(institution.id);
                              else
                                selectedIds.remove(institution.id);
                            });
                          },
                          title: Text(institution.nombre,
                              style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          subtitle: Text(
                              institution.email ??
                                  institution.telefono ??
                                  'Sin contacto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          secondary: CircleAvatar(child: Icon(Icons.business)),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(modalContext).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Confirmar selección
                              widget.onInstitutionChanged(selectedIds.toList());
                              // Actualizar el controlador visible con los nombres seleccionados
                              final names = institutionProvider.institutions
                                  .where((i) => selectedIds.contains(i.id))
                                  .map((i) => i.nombre)
                                  .toList();
                              _institutionController.text = names.join(', ');
                              Navigator.of(modalContext).pop();
                            },
                            child: const Text('Confirmar selección'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Seleccionar Institución',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barra de búsqueda
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar institución...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  updateFiltered();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      onChanged: (value) => updateFiltered(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Contador de resultados
                  if (!isLoading && filteredInstitutions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filteredInstitutions.length} institución${filteredInstitutions.length == 1 ? '' : 'es'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  // Contenido principal
                  Expanded(child: buildContent()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
