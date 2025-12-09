import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/acudiente_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';

class GestionarAcudientesSheet extends StatefulWidget {
  final String estudianteId;
  final String estudianteNombre;

  const GestionarAcudientesSheet({
    super.key,
    required this.estudianteId,
    required this.estudianteNombre,
  });

  /// Muestra el bottom sheet
  static Future<void> show(
      BuildContext context, String estudianteId, String estudianteNombre) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestionarAcudientesSheet(
        estudianteId: estudianteId,
        estudianteNombre: estudianteNombre,
      ),
    );
  }

  @override
  State<GestionarAcudientesSheet> createState() =>
      _GestionarAcudientesSheetState();
}

class _GestionarAcudientesSheetState extends State<GestionarAcudientesSheet> {
  final _acudienteService = AcudienteService();
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _emailController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();

  // Estado
  bool _isLoading = true;
  String? _errorMessage;
  List<AcudienteVinculadoResponse> _acudientesVinculados = [];

  // Estado de búsqueda/creación
  bool _isSearching = false;
  bool _isCreating = false;
  User? _searchResult;
  bool _showCreateForm = false;
  String? _foundAcudienteId;
  String _selectedParentesco = 'padre';

  @override
  void initState() {
    super.initState();
    _loadAcudientes();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _loadAcudientes() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token != null) {
        final acudientes = await _acudienteService.getAcudientesDeEstudiante(
          token,
          widget.estudianteId,
        );
        if (mounted) {
          setState(() {
            _acudientesVinculados = acudientes;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _buscarAcudiente() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    // Verificar si ya está vinculado
    final yaVinculado = _acudientesVinculados
        .any((a) => a.email?.toLowerCase() == email.toLowerCase());
    if (yaVinculado) {
      setState(() {
        _errorMessage = 'Este usuario ya es acudiente del estudiante';
        _searchResult = null;
        _foundAcudienteId = null;
        _showCreateForm = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResult = null;
      _foundAcudienteId = null;
      _showCreateForm = false;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token != null) {
        final usuarios = await _userService.getAllUsers(
          token,
          page: 1,
          limit: 1,
          search: email,
          roles: ['acudiente'],
        );

        if (mounted) {
          setState(() {
            _isSearching = false;
            if (usuarios != null && usuarios.users.isNotEmpty) {
              _searchResult = usuarios.users.first;
              _foundAcudienteId = _searchResult!.id;
              _showCreateForm = false;
            } else {
              _searchResult = null;
              _foundAcudienteId = null;
              _showCreateForm = true; // No encontrado, mostrar form de creación
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Error buscando usuario: $e';
        });
      }
    }
  }

  Future<void> _vincularAcudienteExistente() async {
    if (_foundAcudienteId == null) return;

    setState(() => _isCreating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token != null) {
        await _acudienteService.vincularEstudiante(
          token,
          _foundAcudienteId!,
          widget.estudianteId,
          _selectedParentesco,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acudiente vinculado exitosamente')),
          );
          _resetForm();
          _loadAcudientes();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al vincular: $e';
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _crearYVincularAcudiente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token != null) {
        // 1. Crear el usuario
        // Generar una contraseña segura temporal
        final tempPassword = _userService.generateSecurePassword();

        final newUser = CreateUserRequest(
          email: _emailController.text.trim(),
          password: tempPassword,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          rol: 'acudiente',
          telefono: _telefonoController.text.trim(),
        );

        final createdUser = await _userService.createUser(token, newUser);

        if (createdUser != null) {
          // 2. Vincular como acudiente
          await _acudienteService.vincularEstudiante(
            token,
            createdUser.id,
            widget.estudianteId,
            _selectedParentesco,
          );

          if (mounted) {
            // Mostrar credenciales
            await _showCredentialsDialog(
              newUser.email,
              tempPassword,
              '${newUser.nombres} ${newUser.apellidos}',
            );

            _resetForm();
            _loadAcudientes();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        // Si el email ya existe, sugerir vincularlo en lugar de crearlo
        if (errorMsg.contains('409') ||
            errorMsg.contains('email') ||
            errorMsg.contains('ya existe')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('El usuario ya existe. Buscándolo para vincular...'),
              duration: Duration(seconds: 2),
            ),
          );
          // Cambiar a modo búsqueda automáticamente
          setState(() {
            _isCreating = false;
            _errorMessage = null;
          });
          _buscarAcudiente();
          return;
        }

        // Mostrar error real del servidor para debug
        setState(() {
          _errorMessage = 'Error al vincular: $errorMsg';
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _showCredentialsDialog(
      String email, String password, String nombre) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: context.colors.success),
            const SizedBox(width: 8),
            const Text('Acudiente Creado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$nombre puede acceder al sistema con:',
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCredentialRow('Email:', email, context),
                  const SizedBox(height: 8),
                  _buildCredentialRow('Contraseña:', password, context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: context.colors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: context.colors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Comparta estas credenciales con el acudiente. La contraseña no se volverá a mostrar.',
                      style: context.textStyles.bodySmall.copyWith(
                        color: context.colors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                text: 'Email: $email\nContraseña: $password',
              ));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Credenciales copiadas al portapapeles')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: context.textStyles.labelMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: context.textStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _desvincularAcudiente(String acudienteId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular Acudiente'),
        content:
            Text('¿Está seguro de desvincular a $nombre de este estudiante?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token != null) {
        try {
          await _acudienteService.desvincularEstudiante(
            token,
            acudienteId,
            widget.estudianteId,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Acudiente desvinculado')),
            );
            await _loadAcudientes();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al desvincular: $e'),
                backgroundColor: context.colors.error,
              ),
            );
          }
        }
      }
    }
  }

  void _resetForm() {
    _emailController.clear();
    _nombresController.clear();
    _apellidosController.clear();
    _telefonoController.clear();
    setState(() {
      _showCreateForm = false;
      _searchResult = null;
      _foundAcudienteId = null;
      _errorMessage = null;
      _selectedParentesco = 'padre';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Integración de Scaffold para manejo automático de teclado
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: spacing.md),
                decoration: BoxDecoration(
                  color: colors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              child: Row(
                children: [
                  Icon(Icons.family_restroom, color: colors.primary, size: 28),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestionar Acudientes',
                          style: textStyles.headlineSmall,
                        ),
                        Text(
                          widget.estudianteNombre,
                          style: textStyles.bodySmall
                              .copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Divider(color: colors.borderLight),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              padding: EdgeInsets.all(spacing.md),
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: colors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error,
                                      color: colors.error, size: 20),
                                  SizedBox(width: spacing.sm),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: textStyles.bodySmall
                                          .copyWith(color: colors.error),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        setState(() => _errorMessage = null),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacing.md),
                          ],

                          // Acudientes vinculados
                          Text(
                            'Acudientes Vinculados (${_acudientesVinculados.length})',
                            style: textStyles.titleMedium,
                          ),
                          SizedBox(height: spacing.sm),

                          if (_acudientesVinculados.isEmpty)
                            Container(
                              padding: EdgeInsets.all(spacing.lg),
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: colors.textSecondary),
                                  SizedBox(width: spacing.sm),
                                  Expanded(
                                    child: Text(
                                      'No hay acudientes vinculados a este estudiante',
                                      style: textStyles.bodyMedium.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...(_acudientesVinculados.map((acudiente) => Card(
                                  margin: EdgeInsets.only(bottom: spacing.sm),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          colors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        acudiente.nombres.isNotEmpty
                                            ? acudiente.nombres[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(color: colors.primary),
                                      ),
                                    ),
                                    title: Text(
                                        '${acudiente.nombres} ${acudiente.apellidos}'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(acudiente.email ?? 'Sin email'),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: spacing.xs,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colors.info
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                acudiente.parentesco
                                                    .toUpperCase(),
                                                style: textStyles.labelSmall
                                                    .copyWith(
                                                  color: colors.info,
                                                ),
                                              ),
                                            ),
                                            if (acudiente.esPrincipal) ...[
                                              SizedBox(width: spacing.xs),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: spacing.xs,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colors.success
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'PRINCIPAL',
                                                  style: textStyles.labelSmall
                                                      .copyWith(
                                                    color: colors.success,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.link_off,
                                          color: colors.error),
                                      tooltip: 'Desvincular',
                                      onPressed: () => _desvincularAcudiente(
                                        acudiente.id,
                                        '${acudiente.nombres} ${acudiente.apellidos}',
                                      ),
                                    ),
                                    isThreeLine: true,
                                  ),
                                ))),

                          SizedBox(height: spacing.xl),

                          // Sección de agregar acudiente
                          Container(
                            padding: EdgeInsets.all(spacing.lg),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person_add,
                                          color: colors.primary),
                                      SizedBox(width: spacing.sm),
                                      Text(
                                        'Agregar Acudiente',
                                        style: textStyles.titleMedium.copyWith(
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing.lg),

                                  // Buscar por email
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _emailController,
                                          decoration: const InputDecoration(
                                            labelText: 'Email del acudiente',
                                            hintText: 'ejemplo@correo.com',
                                            prefixIcon: Icon(Icons.email),
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (_showCreateForm) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'El email es requerido';
                                              }
                                              if (!value.contains('@')) {
                                                return 'Email inválido';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(width: spacing.md),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: ElevatedButton.icon(
                                          onPressed: _isSearching
                                              ? null
                                              : _buscarAcudiente,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: spacing.md,
                                              vertical: spacing.lg,
                                            ),
                                          ),
                                          icon: _isSearching
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: colors.onPrimary,
                                                  ),
                                                )
                                              : const Icon(Icons.search),
                                          label: Text(
                                              _isSearching ? '...' : 'Buscar'),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Resto del contenido visible solo cuando se busca/crea
                                  if (_searchResult != null) ...[
                                    SizedBox(height: spacing.lg),
                                    Container(
                                      padding: EdgeInsets.all(spacing.md),
                                      decoration: BoxDecoration(
                                        color: colors.success
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: colors.success
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: colors.success),
                                              SizedBox(width: spacing.sm),
                                              Expanded(
                                                child: Text(
                                                  'Usuario encontrado',
                                                  style: textStyles.titleSmall
                                                      .copyWith(
                                                          color:
                                                              colors.success),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: spacing.sm),
                                          Text(
                                              '${_searchResult!.nombres} ${_searchResult!.apellidos}'),
                                          Text(_searchResult!.email ?? '',
                                              style: textStyles.bodySmall),
                                          SizedBox(height: spacing.md),

                                          // Selector de parentesco
                                          DropdownButtonFormField<String>(
                                            value: _selectedParentesco,
                                            decoration: const InputDecoration(
                                              labelText: 'Parentesco',
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'padre',
                                                  child: Text('Padre')),
                                              DropdownMenuItem(
                                                  value: 'madre',
                                                  child: Text('Madre')),
                                              DropdownMenuItem(
                                                  value: 'acudiente',
                                                  child:
                                                      Text('Acudiente/Tutor')),
                                              DropdownMenuItem(
                                                  value: 'familiar',
                                                  child: Text('Familiar')),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() =>
                                                    _selectedParentesco =
                                                        value);
                                              }
                                            },
                                          ),

                                          SizedBox(height: spacing.md),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _isCreating
                                                  ? null
                                                  : _vincularAcudienteExistente,
                                              child: _isCreating
                                                  ? const CircularProgressIndicator()
                                                  : const Text(
                                                      'Vincular Usuario'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (_showCreateForm) ...[
                                    SizedBox(height: spacing.lg),
                                    Container(
                                      padding: EdgeInsets.all(spacing.md),
                                      decoration: BoxDecoration(
                                        color: colors.warning
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: colors.warning
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info,
                                              color: colors.warning),
                                          SizedBox(width: spacing.sm),
                                          Expanded(
                                            child: Text(
                                              'Usuario no encontrado. Complete los datos para crearlo.',
                                              style: textStyles.bodySmall
                                                  .copyWith(
                                                      color: colors.warning),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: spacing.lg),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _nombresController,
                                            decoration: const InputDecoration(
                                              labelText: 'Nombres',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (value) =>
                                                value?.isEmpty ?? true
                                                    ? 'Requerido'
                                                    : null,
                                          ),
                                        ),
                                        SizedBox(width: spacing.md),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _apellidosController,
                                            decoration: const InputDecoration(
                                              labelText: 'Apellidos',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (value) =>
                                                value?.isEmpty ?? true
                                                    ? 'Requerido'
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing.md),
                                    TextFormField(
                                      controller: _telefonoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Teléfono',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),

                                    SizedBox(height: spacing.md),
                                    // Selector de parentesco para nuevo usuario
                                    DropdownButtonFormField<String>(
                                      value: _selectedParentesco,
                                      decoration: const InputDecoration(
                                        labelText: 'Parentesco',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'padre',
                                            child: Text('Padre')),
                                        DropdownMenuItem(
                                            value: 'madre',
                                            child: Text('Madre')),
                                        DropdownMenuItem(
                                            value: 'acudiente',
                                            child: Text('Acudiente/Tutor')),
                                        DropdownMenuItem(
                                            value: 'familiar',
                                            child: Text('Familiar')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() =>
                                              _selectedParentesco = value);
                                        }
                                      },
                                    ),

                                    SizedBox(height: spacing.lg),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isCreating
                                            ? null
                                            : _crearYVincularAcudiente,
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: spacing.md),
                                        ),
                                        child: _isCreating
                                            ? const CircularProgressIndicator()
                                            : const Text(
                                                'Crear y Vincular Acudiente'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
