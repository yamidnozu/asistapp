import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clase_del_dia.dart';
import '../models/asistencia_estudiante.dart';
import '../providers/asistencia_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../screens/qr_scanner_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final ClaseDelDia clase;

  const AttendanceScreen({
    super.key,
    required this.clase,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AppColors colors = AppColors.instance;
  final AppSpacing spacing = AppSpacing.instance;
  
  // Estado para tracking del estudiante seleccionado (primer toque)
  String? _estudianteSeleccionadoId;
  DateTime _selectedDate = DateTime.now();

  // Función helper para mostrar SnackBars en la parte superior
  void _showTopSnackBar({
    required String message,
    Color? backgroundColor,
    Widget? leading,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (leading != null) ...[
              leading,
              SizedBox(width: spacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height - 150,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Cargar asistencias al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAsistencias();
    });
  }

  void _limpiarSeleccion() {
    if (_estudianteSeleccionadoId != null) {
      setState(() {
        _estudianteSeleccionadoId = null;
      });
    }
  }

  Future<void> _loadAsistencias() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      await asistenciaProvider.fetchAsistencias(token, widget.clase.id, date: _selectedDate);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.primary,
              onPrimary: colors.white,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAsistencias();
    }
  }

  Future<void> _onScanQR() async {
    // Navegar al escáner QR
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          horarioId: widget.clase.id,
        ),
      ),
    );

    // Si el escaneo fue exitoso, refrescar la lista
    if (result == true && mounted) {
      await _loadAsistencias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _limpiarSeleccion, // Limpiar selección al tocar fuera
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tomar Asistencia'),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              backgroundColor: colors.primary,
              foregroundColor: colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                  tooltip: 'Cambiar fecha',
                ),
              ],
            ),
            body: Consumer<AsistenciaProvider>(
              builder: (context, asistenciaProvider, child) {
                if (asistenciaProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (asistenciaProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colors.error,
                        ),
                        SizedBox(height: spacing.md),
                        Text(
                          'Error al cargar asistencias',
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.sm),
                        Text(
                          asistenciaProvider.errorMessage ?? 'Error desconocido',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.lg),
                        ElevatedButton.icon(
                          onPressed: _loadAsistencias,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Información de la clase
                    _buildClassInfo(constraints),

                    // Estadísticas de asistencia
                    _buildAttendanceStats(asistenciaProvider, constraints),

                    // Lista de estudiantes
                    Expanded(
                      child: _buildStudentsList(asistenciaProvider.asistencias),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _onScanQR,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear QR'),
              backgroundColor: colors.primary,
              foregroundColor: colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassInfo(BoxConstraints constraints) {
    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Materia y grupo
          Text(
            widget.clase.materia.nombre,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.xs),
          Text(
            '${widget.clase.grupo.nombreCompleto} - ${widget.clase.diaSemanaNombre}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.sm),
          // Horario
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: colors.textMuted,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  widget.clase.horarioFormato,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats(AsistenciaProvider provider, BoxConstraints constraints) {
    final stats = provider.getEstadisticas();
    final porcentaje = (provider.getPorcentajeAsistencia() * 100).round();

    // Si el ancho es pequeño, usar layout vertical
    final isSmallScreen = constraints.maxWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: colors.borderLight, width: 1),
        ),
      ),
      child: isSmallScreen
          ? Column(
              children: [
                // Estadísticas en columna
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Presentes', stats['presentes']!, colors.success),
                    _buildStatItem('Ausentes', stats['ausentes']!, colors.error),
                  ],
                ),
                SizedBox(height: spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Sin registrar', stats['sinRegistrar']!, colors.textMuted),
                    // Porcentaje
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(spacing.borderRadius),
                      ),
                      child: Text(
                        '$porcentaje%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // Estadísticas principales
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Presentes', stats['presentes']!, colors.success),
                      _buildStatItem('Ausentes', stats['ausentes']!, colors.error),
                      _buildStatItem('Sin registrar', stats['sinRegistrar']!, colors.textMuted),
                    ],
                  ),
                ),
                // Porcentaje
                Container(
                  padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                  child: Text(
                    '$porcentaje%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(List<AsistenciaEstudiante> asistencias) {
    if (asistencias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: colors.textMuted,
            ),
            SizedBox(height: spacing.md),
            Text(
              'No hay estudiantes en este grupo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(spacing.md),
      itemCount: asistencias.length,
      itemBuilder: (context, index) {
        final estudiante = asistencias[index];
        final puedeMarcarManualmente = estudiante.sinRegistrar || estudiante.estaAusente;
        final estaSeleccionado = _estudianteSeleccionadoId == estudiante.estudianteId;
        
        return Card(
          margin: EdgeInsets.only(bottom: spacing.sm),
          color: estaSeleccionado 
              ? colors.warning.withValues(alpha: 0.15)  // Color amarillo suave para primer toque
              : null,
          elevation: estaSeleccionado ? 4 : 1,
          child: ListTile(
            onTap: puedeMarcarManualmente 
                ? () => _onEstudianteTap(estudiante)
                : null,
            leading: CircleAvatar(
              backgroundColor: estaSeleccionado
                  ? colors.warning.withValues(alpha: 0.3)
                  : colors.primary.withValues(alpha: 0.1),
              child: Text(
                estudiante.inicial,
                style: TextStyle(
                  color: estaSeleccionado ? colors.warning : colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              estudiante.nombreCompleto,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Text(
                  'ID: ${estudiante.identificacion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (estaSeleccionado) ...[
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      'Toca de nuevo para confirmar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(estudiante),
                if (puedeMarcarManualmente && !estaSeleccionado) ...[
                  SizedBox(width: spacing.xs),
                  Icon(
                    Icons.touch_app,
                    color: colors.primary.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
                if (estaSeleccionado) ...[
                  SizedBox(width: spacing.xs),
                  Icon(
                    Icons.check_circle_outline,
                    color: colors.warning,
                    size: 24,
                  ),
                ],
                // Botón de edición
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: colors.primary,
                  onPressed: () => _showEditDialog(estudiante),
                  tooltip: 'Editar asistencia',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onEstudianteTap(AsistenciaEstudiante estudiante) {
    if (_estudianteSeleccionadoId == estudiante.estudianteId) {
      // Segundo toque - confirmar registro
      _registrarAsistenciaManual(estudiante);
    } else {
      // Primer toque - marcar como seleccionado
      setState(() {
        _estudianteSeleccionadoId = estudiante.estudianteId;
      });
    }
  }

  Future<void> _registrarAsistenciaManual(AsistenciaEstudiante estudiante) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      _showTopSnackBar(
        message: 'Error: No estás autenticado',
        backgroundColor: colors.error,
        leading: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    // Limpiar selección
    setState(() {
      _estudianteSeleccionadoId = null;
    });

    // Mostrar indicador de carga
    _showTopSnackBar(
      message: 'Registrando asistencia...',
      duration: const Duration(seconds: 2),
      leading: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.white),
        ),
      ),
    );

    try {
      final success = await asistenciaProvider.registrarAsistenciaManual(
        token,
        widget.clase.id,
        estudiante.estudianteId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (success) {
          _showTopSnackBar(
            message: '✓ ${estudiante.nombreCompleto} marcado como presente',
            backgroundColor: colors.success,
            leading: const Icon(Icons.check_circle, color: Colors.white),
          );
        } else {
          _showTopSnackBar(
            message: 'Error al registrar asistencia',
            backgroundColor: colors.error,
            leading: const Icon(Icons.error, color: Colors.white),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showTopSnackBar(
          message: 'Error: ${e.toString()}',
          backgroundColor: colors.error,
          leading: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<void> _showEditDialog(AsistenciaEstudiante estudiante) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    String estado = estudiante.estado ?? 'PRESENTE';
    // Si el estado es vacío, por defecto PRESENTE
    if (estado.isEmpty) estado = 'PRESENTE';
    
    final String observacion = estudiante.observacion ?? '';
    bool justificada = estudiante.estaJustificado;
    
    // Controlador para el campo de texto
    final observacionController = TextEditingController(text: observacion);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Editar Asistencia: ${estudiante.nombreCompleto}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: estado,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: ['PRESENTE', 'AUSENTE', 'TARDANZA', 'JUSTIFICADO']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            estado = value;
                            if (estado == 'JUSTIFICADO') {
                              justificada = true;
                            } else {
                              justificada = false;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: observacionController,
                      decoration: const InputDecoration(labelText: 'Observación'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Justificada'),
                      value: justificada,
                      onChanged: (value) {
                        setStateDialog(() {
                          justificada = value ?? false;
                          if (justificada && estado != 'JUSTIFICADO') {
                            // Opcional: cambiar estado a justificado si se marca el check
                            // estado = 'JUSTIFICADO';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Cerrar diálogo
                    
                    // Mostrar loading
                    _showTopSnackBar(
                      message: 'Actualizando asistencia...',
                      leading: const CircularProgressIndicator(color: Colors.white),
                    );

                    try {
                      // Si la asistencia no tiene ID (sin registrar), primero hay que registrarla?
                      // No, el backend updateAsistencia requiere ID.
                      // Si está "sin registrar", AsistenciaEstudiante tiene id?
                      // Revisar modelo. Si es null, no se puede actualizar.
                      // Pero si está en la lista, viene del backend.
                      // Si es "sin registrar" (mock o placeholder), tal vez no tenga ID de asistencia real.
                      // Pero fetchAsistencias devuelve registros de asistencia.
                      // Si no existe, no se puede hacer PUT.
                      // Se debe hacer POST si no existe.
                      // Pero el endpoint GET devuelve solo las existentes?
                      // Si es así, la lista solo muestra los que tienen asistencia.
                      // Si queremos mostrar todos los estudiantes, el backend debe hacer un left join con estudiantes.
                      // Asumo que el backend ya hace eso y devuelve objetos con o sin ID de asistencia.
                      
                      // Si estudiante.id (de asistencia) es null o vacío, usar registrarAsistenciaManual primero o usar endpoint update que maneje upsert?
                      // El endpoint PUT /asistencias/:id requiere ID.
                      
                      if (estudiante.id == null || estudiante.id!.isEmpty) {
                         _showTopSnackBar(
                          message: 'Error: Primero registre la asistencia (toque el estudiante)',
                          backgroundColor: colors.error,
                        );
                        return;
                      }

                      final success = await asistenciaProvider.updateAsistencia(
                        accessToken: token,
                        asistenciaId: estudiante.id!,
                        estado: estado,
                        observacion: observacionController.text,
                        justificada: justificada,
                      );

                      if (success) {
                        _showTopSnackBar(
                          message: 'Asistencia actualizada',
                          backgroundColor: colors.success,
                        );
                        // Recargar
                        _loadAsistencias();
                      } else {
                        _showTopSnackBar(
                          message: 'Error al actualizar',
                          backgroundColor: colors.error,
                        );
                      }
                    } catch (e) {
                      _showTopSnackBar(
                        message: 'Error: $e',
                        backgroundColor: colors.error,
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(AsistenciaEstudiante estudiante) {
    final Color chipColor;
    final String statusText;

    if (estudiante.estaPresente) {
      chipColor = colors.success;
      statusText = 'Presente';
    } else if (estudiante.estaAusente) {
      chipColor = colors.error;
      statusText = 'Ausente';
    } else if (estudiante.tieneTardanza) {
      chipColor = colors.warning;
      statusText = 'Tardanza';
    } else if (estudiante.estaJustificado) {
      chipColor = colors.info;
      statusText = 'Justificado';
    } else {
      chipColor = colors.textMuted;
      statusText = 'Sin registrar';
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.symmetric(horizontal: spacing.xs),
    );
  }
}