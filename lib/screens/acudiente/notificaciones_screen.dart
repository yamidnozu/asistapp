import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/acudiente_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notificacion_in_app.dart';
import '../../theme/theme_extensions.dart';

/// Pantalla de notificaciones para el acudiente
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
  }

  Future<void> _loadNotificaciones() async {
    final authProvider = context.read<AuthProvider>();
    final acudienteProvider = context.read<AcudienteProvider>();

    if (authProvider.accessToken != null) {
      await acudienteProvider.cargarNotificaciones(authProvider.accessToken!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    final authProvider = context.read<AuthProvider>();
    final acudienteProvider = context.read<AcudienteProvider>();

    if (authProvider.accessToken != null) {
      final count = await acudienteProvider.marcarTodasComoLeidas(
        authProvider.accessToken!,
      );
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count notificaciones marcadas como leídas')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Consumer<AcudienteProvider>(
            builder: (context, provider, _) {
              if (provider.notificacionesNoLeidas > 0) {
                return TextButton.icon(
                  onPressed: _marcarTodasComoLeidas,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Marcar todas'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotificaciones,
              child: Consumer<AcudienteProvider>(
                builder: (context, provider, _) {
                  if (provider.notificaciones.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildNotificacionesList(provider);
                },
              ),
            ),
    );
  }

  Widget _buildNotificacionesList(AcudienteProvider provider) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      itemCount: provider.notificaciones.length,
      itemBuilder: (context, index) {
        final notificacion = provider.notificaciones[index];
        return _buildNotificacionItem(notificacion, provider);
      },
    );
  }

  Widget _buildNotificacionItem(
    NotificacionInApp notificacion,
    AcudienteProvider provider,
  ) {
    IconData icon;
    Color color;

    switch (notificacion.tipo) {
      case 'ausencia':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'tardanza':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'justificado':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'sistema':
        icon = Icons.info;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = context.colors.primary;
    }

    return Dismissible(
      key: Key(notificacion.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        // Aquí podrías agregar lógica para eliminar la notificación
      },
      child: InkWell(
        onTap: () => _marcarComoLeida(notificacion, provider),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: notificacion.leida
                ? Colors.transparent
                : context.colors.primary.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: context.colors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: context.spacing.md),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: context.textStyles.bodyMedium.copyWith(
                              fontWeight: notificacion.leida
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notificacion.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      notificacion.mensaje,
                      style: context.textStyles.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      notificacion.tiempoRelativo,
                      style: context.textStyles.bodySmall.copyWith(
                        color: context.colors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _marcarComoLeida(
    NotificacionInApp notificacion,
    AcudienteProvider provider,
  ) async {
    if (notificacion.leida) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.accessToken != null) {
      await provider.marcarNotificacionComoLeida(
        authProvider.accessToken!,
        notificacion.id,
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: context.spacing.lg),
          Text(
            'No tienes notificaciones',
            style: context.textStyles.headlineSmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            'Cuando tus hijos tengan inasistencias,\nserás notificado aquí.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
