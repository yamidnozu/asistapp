import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notificaciones = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
  }

  Future<void> _loadNotificaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener el token de autenticación';
          _isLoading = false;
        });
        return;
      }

      // TODO: Implementar llamada al backend GET /estudiantes/dashboard/notificaciones
      // Por ahora, datos de ejemplo
      await Future.delayed(const Duration(seconds: 1)); // Simular carga

      setState(() {
        _notificaciones = [
          {
            'id': '1',
            'titulo': 'Nueva tarea de Matemáticas',
            'mensaje': 'Se ha asignado una nueva tarea: "Ecuaciones cuadráticas". Fecha límite: 20/01/2024',
            'tipo': 'tarea',
            'fecha': '2024-01-15T10:30:00Z',
            'leida': false,
            'importante': true,
          },
          {
            'id': '2',
            'titulo': 'Cambio de horario',
            'mensaje': 'La clase de Física del martes ha sido cambiada a las 14:00',
            'tipo': 'horario',
            'fecha': '2024-01-14T16:45:00Z',
            'leida': true,
            'importante': false,
          },
          {
            'id': '3',
            'titulo': 'Recordatorio de asistencia',
            'mensaje': 'No olvides marcar tu asistencia al inicio de cada clase',
            'tipo': 'recordatorio',
            'fecha': '2024-01-13T08:00:00Z',
            'leida': true,
            'importante': false,
          },
          {
            'id': '4',
            'titulo': 'Anuncio importante',
            'mensaje': 'Mañana no habrá clases debido a mantenimiento del edificio',
            'tipo': 'anuncio',
            'fecha': '2024-01-12T12:00:00Z',
            'leida': false,
            'importante': true,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar notificaciones: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) return;

      // TODO: Implementar llamada al backend PUT /estudiantes/dashboard/notificaciones/{id}/leer
      // Por ahora, actualizar localmente
      setState(() {
        final index = _notificaciones.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notificaciones[index]['leida'] = true;
        }
      });
    } catch (e) {
      // Manejar error silenciosamente por ahora
      // Error al marcar como leída: $e
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones', style: textStyles.headlineMedium),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildNotificationsContent(),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (final notif in _notificaciones) {
        notif['leida'] = true;
      }
    });
  }

  Widget _buildErrorState() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: colors.error),
          SizedBox(height: spacing.lg),
          Text(
            'Error al cargar notificaciones',
            style: textStyles.headlineSmall.copyWith(color: colors.error),
          ),
          SizedBox(height: spacing.sm),
          Text(
            _errorMessage ?? 'Ocurrió un error desconocido',
            style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.xl),
          ElevatedButton.icon(
            onPressed: _loadNotificaciones,
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    if (_notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: colors.textMuted),
            SizedBox(height: spacing.lg),
            Text(
              'No tienes notificaciones',
              style: textStyles.headlineSmall.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Las notificaciones aparecerán aquí cuando tengas mensajes nuevos',
              style: textStyles.bodyMedium.copyWith(color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final unreadCount = _notificaciones.where((n) => !(n['leida'] as bool)).length;

    return RefreshIndicator(
      onRefresh: _loadNotificaciones,
      child: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          if (unreadCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
              child: Text(
                '$unreadCount notificación${unreadCount != 1 ? 'es' : ''} sin leer',
                style: textStyles.labelLarge.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (unreadCount > 0) SizedBox(height: spacing.lg),

          ..._notificaciones.map((notif) => _buildNotificationCard(notif)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notificacion) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final leida = notificacion['leida'] as bool;
    final importante = notificacion['importante'] as bool;
    final tipo = notificacion['tipo'] as String;

    return Dismissible(
      key: Key(notificacion['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: spacing.lg),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(spacing.borderRadius),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _notificaciones.removeWhere((n) => n['id'] == notificacion['id']);
        });
      },
      child: Card(
        margin: EdgeInsets.only(bottom: spacing.md),
        color: leida ? colors.surface : colors.primary.withValues(alpha: 0.05),
        child: InkWell(
          onTap: () => _markAsRead(notificacion['id']),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(tipo, colors).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                  child: Icon(
                    _getNotificationIcon(tipo),
                    color: _getNotificationColor(tipo, colors),
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notificacion['titulo'],
                              style: textStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (importante)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '!',
                                style: textStyles.labelSmall.copyWith(
                                  color: colors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (!leida)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        notificacion['mensaje'],
                        style: textStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        _formatDate(notificacion['fecha']),
                        style: textStyles.bodySmall.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String tipo, dynamic colors) {
    switch (tipo) {
      case 'tarea': return colors.primary;
      case 'horario': return colors.warning;
      case 'recordatorio': return colors.info;
      case 'anuncio': return colors.success;
      default: return colors.textSecondary;
    }
  }

  IconData _getNotificationIcon(String tipo) {
    switch (tipo) {
      case 'tarea': return Icons.assignment;
      case 'horario': return Icons.schedule;
      case 'recordatorio': return Icons.notifications;
      case 'anuncio': return Icons.campaign;
      default: return Icons.notifications_none;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} días atrás';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}