import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';

class InstitutionFormScreen extends StatefulWidget {
  final Institution? institution;

  const InstitutionFormScreen({super.key, this.institution});

  @override
  State<InstitutionFormScreen> createState() => _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends State<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  bool _activa = true;
  bool _notificacionesActivas = false;
  bool _notificarAusenciaTotalDiaria = false;
  String _canalNotificacion = 'NONE';
  String _modoNotificacionAsistencia = 'MANUAL_ONLY';
  String? _horaDisparoNotificacion;

  bool get isEditing => widget.institution != null;

  @override
  void initState() {
    super.initState();
    if (widget.institution != null) {
      _loadInstitutionData();
    }
  }

  void _loadInstitutionData() {
    if (widget.institution != null) {
      _nombreController.text = widget.institution!.nombre;
      _direccionController.text = widget.institution!.direccion ?? '';
      _telefonoController.text = widget.institution!.telefono ?? '';
      _emailController.text = widget.institution!.email ?? '';
      _activa = widget.institution!.activa;

      if (widget.institution!.configuraciones != null) {
        _notificacionesActivas =
            widget.institution!.configuraciones!.notificacionesActivas;
        _notificarAusenciaTotalDiaria =
            widget.institution!.configuraciones!.notificarAusenciaTotalDiaria;
        _canalNotificacion =
            widget.institution!.configuraciones!.canalNotificacion;
        _modoNotificacionAsistencia =
            widget.institution!.configuraciones!.modoNotificacionAsistencia;
        _horaDisparoNotificacion =
            widget.institution!.configuraciones!.horaDisparoNotificacion;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Institución' : 'Nueva Institución'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Volver',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              SizedBox(height: spacing.inputSpacing),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              SizedBox(height: spacing.inputSpacing),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              SizedBox(height: spacing.inputSpacing),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: spacing.inputSpacing),
              SwitchListTile(
                title: const Text('Activa'),
                value: _activa,
                onChanged: (value) => setState(() => _activa = value),
              ),
              SizedBox(height: spacing.sectionSpacing),
              const Divider(),
              const Text(
                'Configuración de Notificaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Notificaciones Activas'),
                subtitle: const Text('Habilitar envío de notificaciones'),
                value: _notificacionesActivas,
                onChanged: (value) =>
                    setState(() => _notificacionesActivas = value),
              ),
              if (_notificacionesActivas) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Alerta de Ausencia Total'),
                  subtitle: const Text(
                      'Notificar si falta a TODAS las clases del día'),
                  value: _notificarAusenciaTotalDiaria,
                  onChanged: (value) =>
                      setState(() => _notificarAusenciaTotalDiaria = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _canalNotificacion,
                  decoration: const InputDecoration(
                    labelText: 'Canal de Notificación',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NONE', child: Text('Desactivado')),
                    DropdownMenuItem(
                        value: 'PUSH', child: Text('Solo App (Push)')),
                    DropdownMenuItem(
                        value: 'WHATSAPP', child: Text('WhatsApp + App')),
                  ],
                  onChanged: (value) =>
                      setState(() => _canalNotificacion = value ?? 'NONE'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _modoNotificacionAsistencia,
                  decoration: const InputDecoration(
                    labelText: 'Modo de Notificación',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'MANUAL_ONLY', child: Text('Solo Manual')),
                    DropdownMenuItem(
                        value: 'INSTANT', child: Text('Instantáneo')),
                    DropdownMenuItem(
                        value: 'END_OF_DAY', child: Text('Fin del Día')),
                  ],
                  onChanged: (value) => setState(() =>
                      _modoNotificacionAsistencia = value ?? 'MANUAL_ONLY'),
                ),
                if (_modoNotificacionAsistencia == 'END_OF_DAY') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _horaDisparoNotificacion ?? '18:00',
                    decoration: const InputDecoration(
                      labelText: 'Hora de Envío',
                      hintText: 'Ej: 18:00',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _horaDisparoNotificacion = value,
                  ),
                ],
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(isEditing ? 'Actualizar' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final institutionProvider =
        Provider.of<InstitutionProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    // Recopilar todos los datos, incluyendo configuración
    final institutionData = {
      'nombre': _nombreController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'email': _emailController.text.trim(),
      'activa': _activa,
      // Configuración de notificaciones
      'notificacionesActivas': _notificacionesActivas,
      'canalNotificacion': _canalNotificacion,
      'modoNotificacionAsistencia': _modoNotificacionAsistencia,
      'horaDisparoNotificacion': _horaDisparoNotificacion,
      'notificarAusenciaTotalDiaria': _notificarAusenciaTotalDiaria,
    };

    try {
      bool success = false;

      if (isEditing) {
        // Actualizar institucion existente con todos los datos
        success = await institutionProvider.updateInstitution(
          token,
          widget.institution!.id,
          nombre: institutionData['nombre'] as String?,
          direccion: institutionData['direccion'] as String?,
          telefono: institutionData['telefono'] as String?,
          email: institutionData['email'] as String?,
          activa: institutionData['activa'] as bool?,
          notificacionesActivas:
              institutionData['notificacionesActivas'] as bool?,
          canalNotificacion: institutionData['canalNotificacion'] as String?,
          modoNotificacionAsistencia:
              institutionData['modoNotificacionAsistencia'] as String?,
          horaDisparoNotificacion:
              institutionData['horaDisparoNotificacion'] as String?,
          notificarAusenciaTotalDiaria:
              institutionData['notificarAusenciaTotalDiaria'] as bool?,
        );
      } else {
        // Crear nueva institucion (createInstitution aún no soporta config inicial en provider, pero el backend lo soportaría si se actualiza)
        // Por ahora mantenemos create simple y luego update si es necesario, o asumimos defaults.
        // TODO: Actualizar createInstitution para soportar config inicial si es crítico.
        success =
            await institutionProvider.createInstitution(token, institutionData);
      }

      if (success && mounted) {
        context.go('/institutions');
      }
    } catch (e) {
      // Error handling is done in the provider
      debugPrint('Error in _submitForm: $e');
    }
  }
}
