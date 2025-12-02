import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';

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
        _notificacionesActivas = widget.institution!.configuraciones!.notificacionesActivas;
        _canalNotificacion = widget.institution!.configuraciones!.canalNotificacion;
        _modoNotificacionAsistencia = widget.institution!.configuraciones!.modoNotificacionAsistencia;
        _horaDisparoNotificacion = widget.institution!.configuraciones!.horaDisparoNotificacion;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Institución' : 'Nueva Institución'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SwitchListTile(
                title: const Text('Activa'),
                value: _activa,
                onChanged: (value) => setState(() => _activa = value),
              ),
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
    final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    final institutionData = {
      'nombre': _nombreController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'email': _emailController.text.trim(),
      'activa': _activa,
      'notificacionesActivas': _notificacionesActivas,
      'canalNotificacion': _canalNotificacion,
      'modoNotificacionAsistencia': _modoNotificacionAsistencia,
      'horaDisparoNotificacion': _horaDisparoNotificacion,
    };

    try {
      if (isEditing) {
        await institutionProvider.updateInstitution(
          token,
          widget.institution!.id,
          nombre: institutionData['nombre'] as String?,
          direccion: institutionData['direccion'] as String?,
          telefono: institutionData['telefono'] as String?,
          email: institutionData['email'] as String?,
          activa: institutionData['activa'] as bool?,
        );
      } else {
        await institutionProvider.createInstitution(token, institutionData);
      }

      if (mounted) {
        context.go('/institutions');
      }
    } catch (e) {
      // Error handling is done in the provider
    }
  }
}