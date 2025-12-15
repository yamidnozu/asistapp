import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import '../../theme/theme_extensions.dart';
import '../../services/acudiente_service.dart';

/// Pantalla para vincular acudientes a estudiantes
/// Permite seleccionar un estudiante y asociar acudientes
class VincularAcudienteScreen extends StatefulWidget {
  final String estudianteId;

  const VincularAcudienteScreen({super.key, required this.estudianteId});

  @override
  State<VincularAcudienteScreen> createState() =>
      _VincularAcudienteScreenState();
}

class _VincularAcudienteScreenState extends State<VincularAcudienteScreen> {
  final AcudienteService _acudienteService = AcudienteService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  User? _estudiante;
  List<User> _acudientesDisponibles = [];
  List<AcudienteVinculadoResponse> _acudientesVinculados = [];

  String _parentescoSeleccionado = 'padre';
  String? _acudienteSeleccionadoId;

  final List<String> _opcionesParentesco = [
    'padre',
    'madre',
    'tutor',
    'abuelo',
    'abuela',
    'tio',
    'tia',
    'hermano',
    'otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final token = authProvider.accessToken!;

      // Cargar datos del estudiante
      await userProvider.loadUserById(token, widget.estudianteId);
      _estudiante = userProvider.users.firstWhere(
        (u) => u.id == widget.estudianteId,
        orElse: () => throw Exception('Estudiante no encontrado'),
      );

      // Cargar acudientes disponibles (usuarios con rol acudiente)
      userProvider.setFilter('role', 'acudiente');
      await userProvider.loadUsers(token);
      _acudientesDisponibles =
          userProvider.users.where((u) => u.rol == 'acudiente').toList();
      userProvider.removeFilter('role');

      // Cargar acudientes ya vinculados
      _acudientesVinculados = await _acudienteService.getAcudientesDeEstudiante(
        token,
        widget.estudianteId,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _vincularAcudiente() async {
    if (_acudienteSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un acudiente')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken!;

      await _acudienteService.vincularEstudiante(
        token,
        _acudienteSeleccionadoId!,
        widget.estudianteId,
        _parentescoSeleccionado,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acudiente vinculado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadData();
      setState(() {
        _acudienteSeleccionadoId = null;
        _parentescoSeleccionado = 'padre';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al vincular: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _desvincularAcudiente(String acudienteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de desvincular este acudiente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken!;

      await _acudienteService.desvincularEstudiante(
        token,
        acudienteId,
        widget.estudianteId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acudiente desvinculado'),
          backgroundColor: Colors.orange,
        ),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desvincular: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_estudiante != null
            ? 'Acudientes de ${_estudiante!.nombres}'
            : 'Vincular Acudientes'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            SizedBox(height: context.spacing.md),
            Text('Error: $_error'),
            SizedBox(height: context.spacing.md),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del estudiante
          _buildEstudianteCard(),
          SizedBox(height: context.spacing.lg),

          // Formulario para vincular nuevo acudiente
          _buildVincularForm(),
          SizedBox(height: context.spacing.lg),

          // Lista de acudientes vinculados
          _buildAcudientesVinculados(),
        ],
      ),
    );
  }

  Widget _buildEstudianteCard() {
    if (_estudiante == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: context.colors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 36,
                color: context.colors.primary,
              ),
            ),
            SizedBox(width: context.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_estudiante!.nombres} ${_estudiante!.apellidos}',
                    style: context.textStyles.titleLarge,
                  ),
                  Text(
                    'Estudiante',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (_estudiante!.email != null)
                    Text(
                      _estudiante!.email!,
                      style: context.textStyles.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVincularForm() {
    // Filtrar acudientes que ya están vinculados
    final vinculadosIds = _acudientesVinculados.map((a) => a.id).toSet();
    final disponibles = _acudientesDisponibles
        .where((a) => !vinculadosIds.contains(a.id))
        .toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vincular Nuevo Acudiente',
              style: context.textStyles.titleMedium,
            ),
            SizedBox(height: context.spacing.md),

            // Dropdown de acudientes
            DropdownButtonFormField<String>(
              value: _acudienteSeleccionadoId,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Acudiente',
                prefixIcon: Icon(Icons.family_restroom),
              ),
              items: disponibles.isEmpty
                  ? [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('No hay acudientes disponibles'))
                    ]
                  : disponibles
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.nombres} ${a.apellidos}'),
                          ))
                      .toList(),
              onChanged: disponibles.isEmpty
                  ? null
                  : (value) {
                      setState(() => _acudienteSeleccionadoId = value);
                    },
            ),
            SizedBox(height: context.spacing.md),

            // Dropdown de parentesco
            DropdownButtonFormField<String>(
              value: _parentescoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Parentesco',
                prefixIcon: Icon(Icons.people),
              ),
              items: _opcionesParentesco
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                            p.substring(0, 1).toUpperCase() + p.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _parentescoSeleccionado = value);
                }
              },
            ),
            SizedBox(height: context.spacing.lg),

            // Botón vincular
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: disponibles.isEmpty || _isSaving
                    ? null
                    : _vincularAcudiente,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(_isSaving ? 'Vinculando...' : 'Vincular Acudiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcudientesVinculados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acudientes Vinculados (${_acudientesVinculados.length})',
          style: context.textStyles.titleMedium,
        ),
        SizedBox(height: context.spacing.md),
        if (_acudientesVinculados.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 48,
                      color:
                          context.colors.textSecondary.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: context.spacing.sm),
                    Text(
                      'No hay acudientes vinculados',
                      style: context.textStyles.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_acudientesVinculados.map(_buildAcudienteItem)),
      ],
    );
  }

  Widget _buildAcudienteItem(AcudienteVinculadoResponse acudiente) {
    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.colors.success.withValues(alpha: 0.1),
          child: Icon(
            Icons.family_restroom,
            color: context.colors.success,
          ),
        ),
        title: Text(acudiente.nombreCompleto),
        subtitle: Text(
          '${acudiente.parentesco.substring(0, 1).toUpperCase()}${acudiente.parentesco.substring(1)}',
        ),
        trailing: IconButton(
          icon: Icon(Icons.link_off, color: Colors.red.shade300),
          tooltip: 'Desvincular',
          onPressed:
              _isSaving ? null : () => _desvincularAcudiente(acudiente.id),
        ),
      ),
    );
  }
}
