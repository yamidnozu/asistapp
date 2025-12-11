import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/acudiente_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/acudiente_service.dart';
import '../../theme/theme_extensions.dart';

/// Dashboard principal para el rol Acudiente
/// Muestra resumen de hijos, estadísticas y notificaciones
class AcudienteDashboardScreen extends StatefulWidget {
  const AcudienteDashboardScreen({super.key});

  @override
  State<AcudienteDashboardScreen> createState() =>
      _AcudienteDashboardScreenState();
}

class _AcudienteDashboardScreenState extends State<AcudienteDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final acudienteProvider = context.read<AcudienteProvider>();

    if (authProvider.accessToken != null) {
      await acudienteProvider.cargarHijos(authProvider.accessToken!);
      await acudienteProvider
          .actualizarConteoNoLeidas(authProvider.accessToken!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hijos'),
        actions: [
          Consumer<AcudienteProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/acudiente/notificaciones'),
                  ),
                  if (provider.notificacionesNoLeidas > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${provider.notificacionesNoLeidas}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Consumer<AcudienteProvider>(
                builder: (context, provider, _) {
                  if (provider.hasError) {
                    return _buildErrorWidget(provider.errorMessage!);
                  }

                  if (!provider.tieneHijos) {
                    return _buildEmptyWidget();
                  }

                  return _buildContent(provider);
                },
              ),
            ),
    );
  }

  Widget _buildContent(AcudienteProvider provider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildResumenCard(provider),
          SizedBox(height: context.spacing.lg),

          // Lista de hijos
          Text(
            'Mis Hijos',
            style: context.textStyles.headlineSmall,
          ),
          SizedBox(height: context.spacing.md),
          ...provider.hijos.map((hijo) => _buildHijoCard(hijo)),
        ],
      ),
    );
  }

  Widget _buildResumenCard(AcudienteProvider provider) {
    final totalFaltas = provider.hijos.fold<int>(
      0,
      (sum, hijo) => sum + hijo.estadisticasResumen.ausentes,
    );
    final totalTardanzas = provider.hijos.fold<int>(
      0,
      (sum, hijo) => sum + hijo.estadisticasResumen.tardanzas,
    );
    final promedioAsistencia = provider.hijos.isNotEmpty
        ? provider.hijos.fold<int>(
              0,
              (sum, hijo) =>
                  sum + hijo.estadisticasResumen.porcentajeAsistencia,
            ) ~/
            provider.hijos.length
        : 100;

    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing.borderRadius),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.white, size: 28),
              SizedBox(width: context.spacing.sm),
              Text(
                'Resumen General',
                style: context.textStyles.headlineSmall
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: context.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.person,
                value: '${provider.hijos.length}',
                label: 'Hijos',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: '$promedioAsistencia%',
                label: 'Asistencia',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.warning_amber,
                value: '$totalFaltas',
                label: 'Faltas',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.schedule,
                value: '$totalTardanzas',
                label: 'Tardanzas',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: context.spacing.xs),
        Text(
          value,
          style: context.textStyles.headlineMedium.copyWith(color: color),
        ),
        Text(
          label,
          style: context.textStyles.bodySmall.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildHijoCard(HijoResponse hijo) {
    final porcentaje = hijo.estadisticasResumen.porcentajeAsistencia;
    final colorAsistencia = porcentaje >= 80
        ? Colors.green
        : porcentaje >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.spacing.borderRadius),
      ),
      child: InkWell(
        onTap: () => context.push('/acudiente/hijos/${hijo.id}'),
        borderRadius: BorderRadius.circular(context.spacing.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        context.colors.primary.withValues(alpha: 0.1),
                    child: Text(
                      hijo.nombres.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hijo.nombreCompleto,
                          style: context.textStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: context.spacing.xs),
                        if (hijo.grupo != null)
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 14,
                                color: context.colors.textSecondary,
                              ),
                              SizedBox(width: context.spacing.xs),
                              Text(
                                '${hijo.grupo!.grado}° ${hijo.grupo!.seccion ?? ''} - ${hijo.grupo!.nombre}',
                                style: context.textStyles.bodySmall.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: context.spacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 14,
                              color: context.colors.textSecondary,
                            ),
                            SizedBox(width: context.spacing.xs),
                            Text(
                              hijo.parentesco.substring(0, 1).toUpperCase() +
                                  hijo.parentesco.substring(1),
                              style: context.textStyles.bodySmall.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Indicador de asistencia
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.sm,
                      vertical: context.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorAsistencia.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$porcentaje%',
                          style: TextStyle(
                            color: colorAsistencia,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Asistencia',
                          style: TextStyle(
                            color: colorAsistencia,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.md),
              // Estadísticas resumidas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    'Clases',
                    '${hijo.estadisticasResumen.totalClases}',
                    Icons.class_,
                  ),
                  _buildMiniStat(
                    'Presente',
                    '${hijo.estadisticasResumen.presentes}',
                    Icons.check,
                    color: Colors.green,
                  ),
                  _buildMiniStat(
                    'Ausente',
                    '${hijo.estadisticasResumen.ausentes}',
                    Icons.close,
                    color: Colors.red,
                  ),
                  _buildMiniStat(
                    'Tardanza',
                    '${hijo.estadisticasResumen.tardanzas}',
                    Icons.schedule,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? context.colors.textSecondary),
            SizedBox(width: 4),
            Text(
              value,
              style: context.textStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? context.colors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: context.textStyles.bodySmall.copyWith(
            color: context.colors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: context.spacing.lg),
          Text(
            'No tienes hijos vinculados',
            style: context.textStyles.headlineSmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            'Contacta al administrador de la institución\npara vincular a tus hijos.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            'Error al cargar datos',
            style: context.textStyles.headlineSmall,
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.spacing.lg),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
