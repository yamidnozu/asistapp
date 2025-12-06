import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clase_del_dia.dart';
import '../models/asistencia_estudiante.dart';
import '../providers/asistencia_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../screens/qr_scanner_screen.dart';

/// Estados de asistencia disponibles para acciones rápidas
enum QuickAttendanceAction {
  presente,
  ausente,
  tardanza,
  justificado,
}

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
  // Use context.colors and context.spacing inside build and other methods
  
  // Estado para tracking del estudiante seleccionado (primer toque)
  String? _estudianteSeleccionadoId;
  DateTime _selectedDate = DateTime.now();
  
  // Estado para modo de selección múltiple
  bool _multiSelectMode = false;
  final Set<String> _selectedStudentIds = {};

  // Función helper para mostrar SnackBars en la parte superior
  void _showTopSnackBar(BuildContext context, {
    required String message,
    Color? backgroundColor,
    Widget? leading,
    Duration duration = const Duration(seconds: 2),
  }) {
  if (!mounted) return;
  final spacing = context.spacing;
    
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

  Future<void> _loadAsistencias() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);

  final token = authProvider.accessToken;
    if (token != null) {
      await asistenciaProvider.fetchAsistencias(token, widget.clase.id, date: _selectedDate);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
            final colors = context.colors;
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
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navegar al escáner QR y esperar resultado
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen(horarioId: widget.clase.id)),
    );

    // Si se registró una asistencia con éxito, recargar la lista
    if (result == true) {
      final token = authProvider.accessToken;
      if (token != null) {
        await asistenciaProvider.fetchAsistencias(token, widget.clase.id, date: _selectedDate);
      }
    }
  }

  Widget _buildClassInfo(BuildContext context, BoxConstraints constraints) {
    final colors = context.colors;
    final spacing = context.spacing;
    
    // Extraer configuración de notificaciones para mostrar al profesor
    final config = widget.clase.institucion.configuraciones;
    final bool notifActivas = config?.notificacionesActivas ?? false;
    final String modo = config?.modoNotificacionAsistencia ?? 'MANUAL_ONLY';
    final String hora = config?.horaDisparoNotificacion?.substring(0, 5) ?? '18:00';

    String mensajeNotificacion = '';
    IconData iconoNotificacion = Icons.info_outline;
    Color colorNotificacion = colors.textSecondary;

    if (!notifActivas) {
      mensajeNotificacion = 'El envío de notificaciones está desactivado para esta institución.';
    } else {
      if (modo == 'INSTANT') {
        mensajeNotificacion = 'Las ausencias se notifican inmediatamente por WhatsApp/SMS.';
        iconoNotificacion = Icons.send;
        colorNotificacion = colors.warning;
      } else if (modo == 'END_OF_DAY') {
        mensajeNotificacion = 'El reporte de asistencia se enviará automáticamente a las $hora.';
        iconoNotificacion = Icons.schedule_send;
        colorNotificacion = colors.info;
      } else {
        mensajeNotificacion = 'El envío es manual. Usa el botón "Megáfono" para notificar.';
        iconoNotificacion = Icons.touch_app;
        colorNotificacion = colors.primary;
      }
    }

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
          // Materia y grupo + acciones
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.clase.materia.nombre,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
              ),
              // Botón de notificación manual - solo visible cuando modo es MANUAL_ONLY
              if (widget.clase.institucion.isModoManual && 
                  widget.clase.institucion.notificacionesActivas)
                IconButton(
                  tooltip: 'Enviar notificaciones de ausencias',
                  icon: Icon(Icons.campaign, color: colors.primary),
                  onPressed: () => _showManualTriggerOptions(context),
                ),
            ],
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
          SizedBox(height: spacing.md),
          // NUEVA SECCIÓN: Información de notificación para el profesor
          Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: colorNotificacion.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.borderRadius),
              border: Border.all(color: colorNotificacion.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(iconoNotificacion, size: 16, color: colorNotificacion),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    mensajeNotificacion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualTriggerOptions(BuildContext context) async {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token == null) {
      _showTopSnackBar(context, message: 'Error: No estás autenticado', backgroundColor: context.colors.error, leading: Icon(Icons.error, color: context.colors.white));
      return;
    }

    final scope = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Última clase'),
              onTap: () => Navigator.of(context).pop('LAST_CLASS'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Último día'),
              onTap: () => Navigator.of(context).pop('LAST_DAY'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Última semana'),
              onTap: () => Navigator.of(context).pop('LAST_WEEK'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelar'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );

    if (scope == null) return;

    try {
      _showTopSnackBar(context, message: 'Disparando notificaciones...', leading: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(context.colors.white))));
      await asistenciaProvider.triggerManualNotifications(
        accessToken: token,
        institutionId: widget.clase.institucion.id,
        classId: widget.clase.id,
        scope: scope,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showTopSnackBar(context, message: 'Notificaciones disparadas correctamente', backgroundColor: context.colors.success);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showTopSnackBar(context, message: 'Error al disparar notificaciones: $e', backgroundColor: context.colors.error);
    }
  }

  Widget _buildAttendanceStats(BuildContext context, AsistenciaProvider provider, BoxConstraints constraints) {
    final colors = context.colors;
    final spacing = context.spacing;
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
            _buildStatItem(context, 'Presentes', stats['presentes']!, colors.success),
            _buildStatItem(context, 'Ausentes', stats['ausentes']!, colors.error),
                  ],
                ),
                SizedBox(height: spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                    _buildStatItem(context, 'Sin registrar', stats['sinRegistrar']!, colors.textMuted),
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
                      _buildStatItem(context, 'Presentes', stats['presentes']!, colors.success),
                      _buildStatItem(context, 'Ausentes', stats['ausentes']!, colors.error),
                      _buildStatItem(context, 'Sin registrar', stats['sinRegistrar']!, colors.textMuted),
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

  Widget _buildStatItem(BuildContext context, String label, int value, Color color) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Column(
      children: [
        Text(
          value.toString(),
          style: textStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
      style: textStyles.bodySmall.copyWith(
        color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(BuildContext context, List<AsistenciaEstudiante> asistencias) {
    final colors = context.colors;
    final spacing = context.spacing;
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

    return Column(
      children: [
        // Barra de acciones múltiples (visible cuando hay selección)
        if (_multiSelectMode) _buildMultiSelectActionBar(context),
        
        // Lista de estudiantes
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(spacing.md),
            itemCount: asistencias.length,
            itemBuilder: (context, index) {
              final estudiante = asistencias[index];
              return _buildStudentItem(context, estudiante, colors, spacing);
            },
          ),
        ),
      ],
    );
  }

  /// Construye cada item de estudiante con swipe gestures
  Widget _buildStudentItem(
    BuildContext context,
    AsistenciaEstudiante estudiante,
    dynamic colors,
    dynamic spacing,
  ) {
    final puedeMarcarManualmente = estudiante.sinRegistrar || estudiante.estaAusente;
    final estaSeleccionado = _estudianteSeleccionadoId == estudiante.estudianteId;
    final estaEnMultiSelect = _selectedStudentIds.contains(estudiante.estudianteId);

    // Envolver en Dismissible para swipe gestures
    return Dismissible(
      key: Key('student_${estudiante.estudianteId}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Deslizar a la derecha → Marcar PRESENTE
          await _quickMarkAttendance(estudiante, 'PRESENTE');
        } else if (direction == DismissDirection.endToStart) {
          // Deslizar a la izquierda → Marcar AUSENTE
          await _quickMarkAttendance(estudiante, 'AUSENTE');
        }
        // Siempre retornar false para no eliminar el item
        return false;
      },
      background: Container(
        margin: EdgeInsets.only(bottom: spacing.sm),
        decoration: BoxDecoration(
          color: colors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: spacing.lg),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.white, size: 28),
            SizedBox(width: spacing.sm),
            Text(
              'PRESENTE',
              style: TextStyle(
                color: colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: spacing.sm),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: spacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'AUSENTE',
              style: TextStyle(
                color: colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: spacing.sm),
            Icon(Icons.cancel, color: colors.white, size: 28),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: spacing.sm),
        color: _multiSelectMode && estaEnMultiSelect
            ? colors.primary.withValues(alpha: 0.15)
            : estaSeleccionado
                ? colors.warning.withValues(alpha: 0.15)
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
            // Agregar long press para activar modo multi-selección
            onLongPress: () => _toggleMultiSelectMode(estudiante),
          ),
        ),
    );
  }

  /// Acción rápida de marcado de asistencia con deslizamiento
  /// Maneja automáticamente si es crear o actualizar
  Future<void> _quickMarkAttendance(AsistenciaEstudiante estudiante, String estado) async {
    final colors = context.colors;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      _showTopSnackBar(context,
        message: 'Error: No estás autenticado',
        backgroundColor: colors.error,
        leading: Icon(Icons.error, color: colors.white),
      );
      return;
    }

    try {
      bool success = false;
      
      if (estudiante.id != null && estudiante.id!.isNotEmpty) {
        // Tiene ID de asistencia -> Actualizar registro existente
        debugPrint('🔄 Actualizando asistencia existente: ${estudiante.id}');
        success = await asistenciaProvider.updateAsistencia(
          token,
          estudiante.id!,
          estado,
        );
      } else {
        // No tiene ID -> Intentar crear, si falla por duplicado, buscar y actualizar
        debugPrint('➕ Creando nueva asistencia para: ${estudiante.estudianteId}');
        try {
          success = await asistenciaProvider.registrarAsistenciaManual(
            token,
            widget.clase.id,
            estudiante.estudianteId,
            estado: estado,
          );
        } catch (e) {
          // Si falla porque ya existe, recargar lista y reintentar como actualización
          if (e.toString().contains('ya tiene registrada')) {
            debugPrint('⚠️ Ya existe asistencia, recargando lista y actualizando...');
            // Recargar la lista para obtener el ID correcto
            await _loadAsistencias();
            
            // DEBUG: Log all students after reload
            debugPrint('📋 Lista recargada, buscando estudianteId: ${estudiante.estudianteId}');
            for (var a in asistenciaProvider.asistencias) {
              debugPrint('   - ${a.estudianteId} -> id: ${a.id}, estado: ${a.estado}');
            }
            
            // Buscar el estudiante actualizado con su ID de asistencia
            final estudianteActualizado = asistenciaProvider.asistencias.firstWhere(
              (a) => a.estudianteId == estudiante.estudianteId,
              orElse: () => estudiante,
            );
            
            debugPrint('🔍 Estudiante encontrado: id=${estudianteActualizado.id}, estado=${estudianteActualizado.estado}');
            
            if (estudianteActualizado.id != null && estudianteActualizado.id!.isNotEmpty) {
              debugPrint('🔄 Reintentando como actualización: ${estudianteActualizado.id}');
              success = await asistenciaProvider.updateAsistencia(
                token,
                estudianteActualizado.id!,
                estado,
              );
            } else {
              debugPrint('❌ No se encontró ID de asistencia después de recargar');
              // Si aún no tiene ID, relanzar el error original
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }

      if (mounted && success) {
        // Recargar la lista para reflejar cambios
        await _loadAsistencias();
        
        final emoji = estado == 'PRESENTE' ? '✓' : (estado == 'AUSENTE' ? '✗' : '⏰');
        final estadoTexto = estado.toLowerCase();
        _showTopSnackBar(context,
          message: '$emoji ${estudiante.nombreCompleto} marcado como $estadoTexto',
          backgroundColor: estado == 'PRESENTE' ? colors.success : 
                          (estado == 'AUSENTE' ? colors.error : colors.warning),
          leading: Icon(
            estado == 'PRESENTE' ? Icons.check_circle : 
            (estado == 'AUSENTE' ? Icons.cancel : Icons.schedule),
            color: colors.white,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showTopSnackBar(context,
          message: 'Error: ${e.toString()}',
          backgroundColor: colors.error,
          leading: Icon(Icons.error, color: colors.white),
        );
      }
    }
  }

  /// Alterna el modo de selección múltiple
  void _toggleMultiSelectMode(AsistenciaEstudiante estudiante) {
    setState(() {
      if (_multiSelectMode) {
        // Ya estamos en modo multi-select, toggle estudiante
        if (_selectedStudentIds.contains(estudiante.estudianteId)) {
          _selectedStudentIds.remove(estudiante.estudianteId);
          if (_selectedStudentIds.isEmpty) {
            _multiSelectMode = false;
          }
        } else {
          _selectedStudentIds.add(estudiante.estudianteId);
        }
      } else {
        // Activar modo multi-select
        _multiSelectMode = true;
        _selectedStudentIds.clear();
        _selectedStudentIds.add(estudiante.estudianteId);
        _estudianteSeleccionadoId = null; // Limpiar selección simple
      }
    });
  }

  /// Barra de acciones para selección múltiple
  Widget _buildMultiSelectActionBar(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
      decoration: BoxDecoration(
        color: colors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón cancelar
          IconButton(
            icon: Icon(Icons.close, color: colors.white),
            onPressed: () {
              setState(() {
                _multiSelectMode = false;
                _selectedStudentIds.clear();
              });
            },
            tooltip: 'Cancelar selección',
          ),
          // Contador
          Text(
            '${_selectedStudentIds.length} seleccionados',
            style: TextStyle(
              color: colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Botones de acción rápida
          _buildMultiSelectButton(
            context,
            icon: Icons.check_circle,
            label: 'Presente',
            color: colors.success,
            onPressed: () => _applyBatchAction('PRESENTE'),
          ),
          SizedBox(width: spacing.sm),
          _buildMultiSelectButton(
            context,
            icon: Icons.cancel,
            label: 'Ausente',
            color: colors.error,
            onPressed: () => _applyBatchAction('AUSENTE'),
          ),
          SizedBox(width: spacing.sm),
          _buildMultiSelectButton(
            context,
            icon: Icons.schedule,
            label: 'Tardanza',
            color: colors.warning,
            onPressed: () => _applyBatchAction('TARDANZA'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  /// Aplica una acción en lote a todos los estudiantes seleccionados
  Future<void> _applyBatchAction(String estado) async {
    final colors = context.colors;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null || _selectedStudentIds.isEmpty) return;

    // Mostrar loading
    _showTopSnackBar(context,
      message: 'Aplicando cambios a ${_selectedStudentIds.length} estudiantes...',
      leading: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.white),
        ),
      ),
    );

    // Primero recargar la lista para tener los IDs actualizados
    await _loadAsistencias();

    int successCount = 0;
    int failCount = 0;

    // Obtener la lista actualizada de asistencias
    final asistencias = asistenciaProvider.asistencias;

    for (final studentId in _selectedStudentIds) {
      try {
        final estudiante = asistencias.firstWhere(
          (a) => a.estudianteId == studentId,
        );

        bool success = false;
        if (estudiante.id != null && estudiante.id!.isNotEmpty) {
          // Tiene ID -> actualizar
          success = await asistenciaProvider.updateAsistencia(token, estudiante.id!, estado);
        } else {
          // No tiene ID -> crear
          try {
            success = await asistenciaProvider.registrarAsistenciaManual(
              token,
              widget.clase.id,
              studentId,
              estado: estado,
            );
          } catch (e) {
            // Si falla por duplicado, intentar actualizar
            if (e.toString().contains('ya tiene registrada')) {
              await _loadAsistencias();
              final estudianteActualizado = asistenciaProvider.asistencias.firstWhere(
                (a) => a.estudianteId == studentId,
                orElse: () => estudiante,
              );
              if (estudianteActualizado.id != null) {
                success = await asistenciaProvider.updateAsistencia(
                  token, estudianteActualizado.id!, estado);
              }
            } else {
              rethrow;
            }
          }
        }

        if (success) successCount++; else failCount++;
      } catch (e) {
        debugPrint('Error procesando estudiante $studentId: $e');
        failCount++;
      }
    }

    // Salir del modo multi-select
    setState(() {
      _multiSelectMode = false;
      _selectedStudentIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showTopSnackBar(context,
        message: '✓ $successCount marcados como $estado${failCount > 0 ? ' ($failCount errores)' : ''}',
        backgroundColor: failCount == 0 ? colors.success : colors.warning,
      );
      
      // Recargar lista
      _loadAsistencias();
    }
  }

  void _onEstudianteTap(AsistenciaEstudiante estudiante) {
    // Si estamos en modo multi-select, toggle selección
    if (_multiSelectMode) {
      _toggleMultiSelectMode(estudiante);
      return;
    }
    
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
    final colors = context.colors;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      _showTopSnackBar(context,
        message: 'Error: No estás autenticado',
        backgroundColor: colors.error,
        leading: Icon(Icons.error, color: colors.white),
      );
      return;
    }

    // Limpiar selección
    setState(() {
      _estudianteSeleccionadoId = null;
    });

    // Mostrar indicador de carga
    _showTopSnackBar(context,
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
          _showTopSnackBar(context,
            message: '✓ ${estudiante.nombreCompleto} marcado como presente',
            backgroundColor: colors.success,
            leading: Icon(Icons.check_circle, color: colors.white),
          );
        } else {
          _showTopSnackBar(context,
            message: 'Error al registrar asistencia',
            backgroundColor: colors.error,
            leading: Icon(Icons.error, color: colors.white),
          );
        }
      }
    } catch (e) {
      // Recuperación automática: si el registro ya existe, actualizar
      if (e.toString().contains('ya tiene registrada')) {
        debugPrint('_registrarAsistenciaManual: Conflicto detectado, recuperando...');
        
        // Recargar lista para obtener IDs actualizados
        await _loadAsistencias();
        
        // Buscar el estudiante en la lista actualizada
        final provider = Provider.of<AsistenciaProvider>(context, listen: false);
        final updatedStudent = provider.asistencias.firstWhere(
          (a) => a.estudianteId == estudiante.estudianteId,
          orElse: () => estudiante,
        );
        
        if (updatedStudent.id != null) {
          // Ahora actualizar en lugar de crear
          final updateSuccess = await provider.updateAsistencia(
            token,
            updatedStudent.id!,
            'PRESENTE',
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (updateSuccess) {
              _showTopSnackBar(context,
                message: '✓ ${estudiante.nombreCompleto} marcado como presente',
                backgroundColor: colors.success,
                leading: Icon(Icons.check_circle, color: colors.white),
              );
            }
          }
          return;
        }
      }
      
      // Error real
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showTopSnackBar(context,
          message: 'Error: ${e.toString()}',
          backgroundColor: colors.error,
          leading: Icon(Icons.error, color: colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<void> _showEditDialog(AsistenciaEstudiante estudiante) async {
    final appCtx = context; // to avoid shadowing inside builder
    final colors = appCtx.colors;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    String estado = estudiante.estado ?? 'PRESENTE';
    // Si el estado es vacío, por defecto PRESENTE
    if (estado.isEmpty) estado = 'PRESENTE';
    
    final String observacion = estudiante.observaciones ?? '';
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
                    _showTopSnackBar(context,
                      message: 'Guardando asistencia...',
                      leading: CircularProgressIndicator(color: colors.white),
                    );

                    try {
                      bool success = false;

                      // LÓGICA INTELIGENTE:
                      // Si tiene ID de asistencia, actualizamos. Si no tiene ID (es null o vacío), creamos.
                      if (estudiante.id != null && estudiante.id!.isNotEmpty) {
                        // --- ACTUALIZAR registro existente ---
                        success = await asistenciaProvider.updateAsistencia(
                          token,
                          estudiante.id!,
                          estado,
                          observacion: observacionController.text,
                          justificada: justificada,
                        );
                      } else {
                        // --- CREAR NUEVO REGISTRO directamente con el estado seleccionado ---
                        success = await asistenciaProvider.registrarAsistenciaManual(
                          token,
                          widget.clase.id, // ID del Horario
                          estudiante.estudianteId, // ID del Estudiante
                          estado: estado, // El estado seleccionado (AUSENTE, TARDANZA, etc.)
                          observacion: observacionController.text,
                          justificada: justificada,
                        );
                      }

                      if (success) {
                        _showTopSnackBar(context,
                          message: 'Asistencia guardada correctamente',
                          backgroundColor: colors.success,
                        );
                        // Recargar la lista
                        _loadAsistencias();
                      } else {
                        _showTopSnackBar(context,
                          message: 'Error al guardar',
                          backgroundColor: colors.error,
                        );
                      }
                    } catch (e) {
                        _showTopSnackBar(context,
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

  /// Construye un chip de estado INTERACTIVO
  /// Al tocarlo, muestra un menú rápido para cambiar el estado
  Widget _buildStatusChip(AsistenciaEstudiante estudiante) {
    final colors = context.colors;
    final spacing = context.spacing;
    final Color chipColor;
    final String statusText;
    final IconData statusIcon;

    if (estudiante.estaPresente) {
      chipColor = colors.success;
      statusText = 'Presente';
      statusIcon = Icons.check_circle;
    } else if (estudiante.estaAusente) {
      chipColor = colors.error;
      statusText = 'Ausente';
      statusIcon = Icons.cancel;
    } else if (estudiante.tieneTardanza) {
      chipColor = colors.warning;
      statusText = 'Tardanza';
      statusIcon = Icons.schedule;
    } else if (estudiante.estaJustificado) {
      chipColor = colors.info;
      statusText = 'Justificado';
      statusIcon = Icons.assignment_turned_in;
    } else {
      chipColor = colors.textMuted;
      statusText = 'Sin registrar';
      statusIcon = Icons.help_outline;
    }

    // Chip interactivo con PopupMenu
    return PopupMenuButton<String>(
      tooltip: 'Cambiar estado',
      onSelected: (nuevoEstado) => _quickMarkAttendance(estudiante, nuevoEstado),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildStatusMenuItem('PRESENTE', 'Presente', Icons.check_circle, colors.success, estudiante.estado),
        _buildStatusMenuItem('AUSENTE', 'Ausente', Icons.cancel, colors.error, estudiante.estado),
        _buildStatusMenuItem('TARDANZA', 'Tardanza', Icons.schedule, colors.warning, estudiante.estado),
        _buildStatusMenuItem('JUSTIFICADO', 'Justificado', Icons.assignment_turned_in, colors.info, estudiante.estado),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: Colors.white, size: 14),
            SizedBox(width: spacing.xs),
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: spacing.xs),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  /// Construye un item del menú de estado
  PopupMenuItem<String> _buildStatusMenuItem(
    String value,
    String label,
    IconData icon,
    Color color,
    String? currentStatus,
  ) {
    final isSelected = currentStatus == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, color: color, size: 18),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AsistenciaProvider>(
      builder: (context, asistenciaProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Asistencia'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _pickDate(context),
                tooltip: 'Seleccionar fecha',
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _onScanQR,
                tooltip: 'Escanear QR',
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _buildClassInfo(context, constraints),
                  _buildAttendanceStats(context, asistenciaProvider, constraints),
                  Expanded(
                    child: _buildStudentsList(context, asistenciaProvider.asistencias),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}