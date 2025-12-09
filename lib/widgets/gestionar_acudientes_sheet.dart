import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/acudiente_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../theme/theme_extensions.dart';
import 'dart:math';

/// Bottom Sheet para gestionar acudientes de un estudiante
/// Permite:
/// - Ver acudientes vinculados
/// - Buscar acudiente existente por email
/// - Crear nuevo acudiente con credenciales temporales
/// - Vincular/Desvincular acudientes
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
  final AcudienteService _acudienteService = AcudienteService();
  final UserService _userService = UserService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();

  List<AcudienteVinculadoResponse> _acudientesVinculados = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _showCreateForm = false;
  bool _isSearching = false;
  String? _searchResult;
  String? _foundAcudienteId;
  String _selectedParentesco = 'padre';
  String? _errorMessage;
  // La contraseña temporal se muestra en el dialog inmediatamente después de crear

  final List<String> _parentescoOptions = [
    'padre',
    'madre',
    'tutor',
    'abuelo',
    'abuela',
    'tío',
    'tía',
    'hermano',
    'hermana',
    'otro',
  ];

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token != null) {
      try {
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
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error al cargar acudientes: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _buscarPorEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _searchResult = 'Ingrese un email válido';
        _foundAcudienteId = null;
        _showCreateForm = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _foundAcudienteId = null;
      _showCreateForm = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token != null) {
      try {
        // Buscar por email usando el servicio de usuarios
        final response = await _userService.getAllUsers(
          token,
          search: email,
          roles: ['acudiente'],
          limit: 1,
        );

        if (mounted) {
          if (response != null && response.users.isNotEmpty) {
            final user = response.users.first;
            // Verificar que el email coincida exactamente
            if (user.email?.toLowerCase() == email) {
              // Verificar si ya está vinculado
              final yaVinculado =
                  _acudientesVinculados.any((a) => a.id == user.id);
              if (yaVinculado) {
                setState(() {
                  _searchResult =
                      '⚠️ ${user.nombreCompleto} ya está vinculado a este estudiante';
                  _foundAcudienteId = null;
                  _isSearching = false;
                });
              } else {
                setState(() {
                  _searchResult = '✅ Encontrado: ${user.nombreCompleto}';
                  _foundAcudienteId = user.id;
                  _isSearching = false;
                });
              }
              return;
            }
          }

          // No encontrado - mostrar formulario de creación
          setState(() {
            _searchResult =
                'No se encontró acudiente con ese email. Puede crear uno nuevo:';
            _showCreateForm = true;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResult = 'Error al buscar: $e';
            _isSearching = false;
          });
        }
      }
    }
  }

  Future<void> _vincularAcudienteExistente() async {
    if (_foundAcudienteId == null) return;

    setState(() => _isCreating = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token != null) {
      try {
        await _acudienteService.vincularEstudiante(
          token,
          _foundAcudienteId!,
          widget.estudianteId,
          _selectedParentesco,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Acudiente vinculado exitosamente'),
              backgroundColor: context.colors.success,
            ),
          );
          _resetForm();
          await _loadAcudientes();
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

    setState(() => _isCreating = false);
  }

  String _generateRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    const specials = '!@#%^&*';
    final random = Random.secure();

    final password = StringBuffer();
    // 8 caracteres alfanuméricos
    for (var i = 0; i < 8; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }
    // 1 caracter especial
    password.write(specials[random.nextInt(specials.length)]);
    // 1 número más
    password.write(random.nextInt(10));

    return password.toString();
  }

  Future<void> _crearYVincularAcudiente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    final institucionId = authProvider.selectedInstitutionId;

    if (token != null) {
      try {
        // Generar contraseña temporal
        final tempPassword = _generateRandomPassword();

        // Crear el acudiente
        final createRequest = CreateUserRequest(
          email: _emailController.text.trim(),
          password: tempPassword,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          rol: 'acudiente',
          telefono: _telefonoController.text.trim().isNotEmpty
              ? _telefonoController.text.trim()
              : null,
          institucionId: institucionId,
        );

        final newUser = await _userService.createUser(token, createRequest);

        if (newUser != null) {
          // Vincular al estudiante
          await _acudienteService.vincularEstudiante(
            token,
            newUser.id,
            widget.estudianteId,
            _selectedParentesco,
          );

          if (mounted) {
            setState(() {
              _isCreating = false;
            });

            // Mostrar diálogo con credenciales
            await _showCredentialsDialog(
              _emailController.text.trim(),
              tempPassword,
              '${_nombresController.text} ${_apellidosController.text}',
            );

            _resetForm();
            await _loadAcudientes();
          }
        } else {
          throw Exception('No se pudo crear el acudiente');
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = e.toString();
          if (errorMsg.contains('409') || errorMsg.contains('email')) {
            errorMsg = 'El email ya está en uso';
          }
          setState(() {
            _errorMessage = 'Error: $errorMsg';
            _isCreating = false;
          });
        }
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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: spacing.md),
            decoration: BoxDecoration(
              color: colors.grey400,
              borderRadius: BorderRadius.circular(2),
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

                                // Buscar por email - responsive
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmall = constraints.maxWidth < 400;
                                    if (isSmall) {
                                      // Layout vertical para pantallas pequeñas
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          TextFormField(
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
                                          SizedBox(height: spacing.sm),
                                          SizedBox(
                                            height: 48,
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: _isSearching
                                                  ? null
                                                  : _buscarPorEmail,
                                              icon: _isSearching
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : const Icon(Icons.search),
                                              label: const Text('Buscar'),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    // Layout horizontal para pantallas grandes
                                    return Row(
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
                                        SizedBox(width: spacing.sm),
                                        SizedBox(
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: _isSearching
                                                ? null
                                                : _buscarPorEmail,
                                            child: _isSearching
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  )
                                                : const Text('Buscar'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                // Resultado de búsqueda
                                if (_searchResult != null) ...[
                                  SizedBox(height: spacing.md),
                                  Text(
                                    _searchResult!,
                                    style: textStyles.bodyMedium.copyWith(
                                      color: _foundAcudienteId != null
                                          ? colors.success
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],

                                // Vincular acudiente existente - responsive
                                if (_foundAcudienteId != null) ...[
                                  SizedBox(height: spacing.md),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmall =
                                          constraints.maxWidth < 400;
                                      if (isSmall) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            DropdownButtonFormField<String>(
                                              value: _selectedParentesco,
                                              decoration: const InputDecoration(
                                                labelText: 'Parentesco',
                                                border: OutlineInputBorder(),
                                              ),
                                              items: _parentescoOptions
                                                  .map((p) => DropdownMenuItem(
                                                        value: p,
                                                        child: Text(
                                                            p[0].toUpperCase() +
                                                                p.substring(1)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() =>
                                                      _selectedParentesco =
                                                          value);
                                                }
                                              },
                                            ),
                                            SizedBox(height: spacing.sm),
                                            SizedBox(
                                              height: 48,
                                              child: ElevatedButton.icon(
                                                onPressed: _isCreating
                                                    ? null
                                                    : _vincularAcudienteExistente,
                                                icon: _isCreating
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2),
                                                      )
                                                    : const Icon(Icons.link),
                                                label: const Text(
                                                    'Vincular Acudiente'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colors.success,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: _selectedParentesco,
                                              decoration: const InputDecoration(
                                                labelText: 'Parentesco',
                                                border: OutlineInputBorder(),
                                              ),
                                              items: _parentescoOptions
                                                  .map((p) => DropdownMenuItem(
                                                        value: p,
                                                        child: Text(
                                                            p[0].toUpperCase() +
                                                                p.substring(1)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() =>
                                                      _selectedParentesco =
                                                          value);
                                                }
                                              },
                                            ),
                                          ),
                                          SizedBox(width: spacing.md),
                                          ElevatedButton.icon(
                                            onPressed: _isCreating
                                                ? null
                                                : _vincularAcudienteExistente,
                                            icon: _isCreating
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.link),
                                            label: const Text('Vincular'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: colors.success,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],

                                // Formulario de creación
                                if (_showCreateForm) ...[
                                  SizedBox(height: spacing.lg),
                                  Divider(color: colors.border),
                                  SizedBox(height: spacing.md),
                                  Text(
                                    'Crear Nuevo Acudiente',
                                    style: textStyles.titleSmall,
                                  ),
                                  SizedBox(height: spacing.md),
                                  // Nombres y Apellidos - responsive
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmall =
                                          constraints.maxWidth < 400;
                                      if (isSmall) {
                                        return Column(
                                          children: [
                                            TextFormField(
                                              controller: _nombresController,
                                              decoration: const InputDecoration(
                                                labelText: 'Nombres *',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Requerido';
                                                }
                                                return null;
                                              },
                                            ),
                                            SizedBox(height: spacing.md),
                                            TextFormField(
                                              controller: _apellidosController,
                                              decoration: const InputDecoration(
                                                labelText: 'Apellidos *',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Requerido';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _nombresController,
                                              decoration: const InputDecoration(
                                                labelText: 'Nombres *',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Requerido';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          SizedBox(width: spacing.md),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _apellidosController,
                                              decoration: const InputDecoration(
                                                labelText: 'Apellidos *',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Requerido';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: spacing.md),
                                  // Teléfono y Parentesco - responsive
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmall =
                                          constraints.maxWidth < 400;
                                      if (isSmall) {
                                        return Column(
                                          children: [
                                            TextFormField(
                                              controller: _telefonoController,
                                              decoration: const InputDecoration(
                                                labelText: 'Teléfono',
                                                hintText: '+57 300 123 4567',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.phone,
                                            ),
                                            SizedBox(height: spacing.md),
                                            DropdownButtonFormField<String>(
                                              value: _selectedParentesco,
                                              decoration: const InputDecoration(
                                                labelText: 'Parentesco',
                                                border: OutlineInputBorder(),
                                              ),
                                              items: _parentescoOptions
                                                  .map((p) => DropdownMenuItem(
                                                        value: p,
                                                        child: Text(
                                                            p[0].toUpperCase() +
                                                                p.substring(1)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() =>
                                                      _selectedParentesco =
                                                          value);
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _telefonoController,
                                              decoration: const InputDecoration(
                                                labelText: 'Teléfono',
                                                hintText: '+57 300 123 4567',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.phone,
                                            ),
                                          ),
                                          SizedBox(width: spacing.md),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: _selectedParentesco,
                                              decoration: const InputDecoration(
                                                labelText: 'Parentesco',
                                                border: OutlineInputBorder(),
                                              ),
                                              items: _parentescoOptions
                                                  .map((p) => DropdownMenuItem(
                                                        value: p,
                                                        child: Text(
                                                            p[0].toUpperCase() +
                                                                p.substring(1)),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() =>
                                                      _selectedParentesco =
                                                          value);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: spacing.md),
                                  Container(
                                    padding: EdgeInsets.all(spacing.sm),
                                    decoration: BoxDecoration(
                                      color: colors.info.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: colors.info, size: 18),
                                        SizedBox(width: spacing.sm),
                                        Expanded(
                                          child: Text(
                                            'Se generará una contraseña temporal que deberá compartir con el acudiente.',
                                            style: textStyles.bodySmall
                                                .copyWith(color: colors.info),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: spacing.lg),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isCreating
                                          ? null
                                          : _crearYVincularAcudiente,
                                      icon: _isCreating
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(Icons.person_add),
                                      label: const Text(
                                          'Crear y Vincular Acudiente'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            vertical: spacing.md),
                                      ),
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
    );
  }
}
