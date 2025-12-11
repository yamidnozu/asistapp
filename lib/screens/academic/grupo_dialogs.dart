import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_extensions.dart';
import '../../providers/grupo_provider.dart';
import '../../providers/periodo_academico_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/grupo.dart';
import '../../services/academic/grupo_service.dart';

class CreateGrupoDialog extends StatefulWidget {
  const CreateGrupoDialog({super.key});

  @override
  State<CreateGrupoDialog> createState() => _CreateGrupoDialogState();
}

class _CreateGrupoDialogState extends State<CreateGrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _gradoController = TextEditingController();
  final _seccionController = TextEditingController();

  String? _selectedPeriodoId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar períodos académicos si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final periodoProvider =
          Provider.of<PeriodoAcademicoProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (periodoProvider.periodosAcademicos.isEmpty) {
        final token = authProvider.accessToken;
        if (token != null) {
          periodoProvider.loadPeriodosAcademicos(token);
        }
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _gradoController.dispose();
    _seccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Consumer2<GrupoProvider, PeriodoAcademicoProvider>(
      builder: (context, grupoProvider, periodoProvider, child) {
        final periodosActivos = periodoProvider.periodosActivos;

        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Crear Grupo',
            style: textStyles.headlineMedium,
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Grupo',
                      hintText: 'Ej: Grupo A, 1er Grado A',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.borderRadius),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),

                  // Grado
                  TextFormField(
                    controller: _gradoController,
                    decoration: InputDecoration(
                      labelText: 'Grado',
                      hintText: 'Ej: 1er Grado, 2do Grado, Preescolar',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.borderRadius),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El grado es obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),

                  // Sección (opcional)
                  TextFormField(
                    controller: _seccionController,
                    decoration: InputDecoration(
                      labelText: 'Sección (Opcional)',
                      hintText: 'Ej: A, B, C',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.borderRadius),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),

                  // Periodo Académico
                  DropdownButtonFormField<String>(
                    value: _selectedPeriodoId,
                    decoration: InputDecoration(
                      labelText: 'Periodo Académico',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.borderRadius),
                      ),
                    ),
                    items: periodosActivos.map((periodo) {
                      return DropdownMenuItem<String>(
                        value: periodo.id,
                        child: Text(
                            '${periodo.nombre} ${periodo.activo ? '(Activo)' : ''}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriodoId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Debes seleccionar un periodo académico';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style:
                    textStyles.labelLarge.copyWith(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _createGrupo,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.white,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.white),
                      ),
                    )
                  : const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateGrupoRequest(
        nombre: _nombreController.text.trim(),
        grado: _gradoController.text.trim(),
        seccion: _seccionController.text.trim().isEmpty
            ? null
            : _seccionController.text.trim(),
        periodoId: _selectedPeriodoId!,
      );

      final success = await grupoProvider.createGrupo(token, request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Grupo creado correctamente'),
              backgroundColor: context.colors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(grupoProvider.errorMessage ?? 'Error al crear grupo'),
              backgroundColor: context.colors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class EditGrupoDialog extends StatefulWidget {
  final Grupo grupo;

  const EditGrupoDialog({super.key, required this.grupo});

  @override
  State<EditGrupoDialog> createState() => _EditGrupoDialogState();
}

class _EditGrupoDialogState extends State<EditGrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _gradoController = TextEditingController();
  final _seccionController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.grupo.nombre;
    _gradoController.text = widget.grupo.grado;
    _seccionController.text = widget.grupo.seccion ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _gradoController.dispose();
    _seccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Editar Grupo',
        style: textStyles.headlineMedium,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Grupo',
                  hintText: 'Ej: Grupo A, 1er Grado A',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.md),

              // Grado
              TextFormField(
                controller: _gradoController,
                decoration: InputDecoration(
                  labelText: 'Grado',
                  hintText: 'Ej: 1er Grado, 2do Grado, Preescolar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El grado es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.md),

              // Sección (opcional)
              TextFormField(
                controller: _seccionController,
                decoration: InputDecoration(
                  labelText: 'Sección (Opcional)',
                  hintText: 'Ej: A, B, C',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                ),
              ),
              SizedBox(height: spacing.md),

              // Información del periodo (solo lectura)
              Container(
                padding: EdgeInsets.all(spacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periodo Académico',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.grupo.periodoAcademico.nombre,
                      style: textStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: textStyles.labelLarge.copyWith(color: colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateGrupo,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.white,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.white),
                  ),
                )
              : const Text('Actualizar'),
        ),
      ],
    );
  }

  Future<void> _updateGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = UpdateGrupoRequest(
        nombre: _nombreController.text.trim(),
        grado: _gradoController.text.trim(),
        seccion: _seccionController.text.trim().isEmpty
            ? null
            : _seccionController.text.trim(),
      );

      final success =
          await grupoProvider.updateGrupo(token, widget.grupo.id, request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Grupo actualizado correctamente'),
              backgroundColor: context.colors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  grupoProvider.errorMessage ?? 'Error al actualizar grupo'),
              backgroundColor: context.colors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
