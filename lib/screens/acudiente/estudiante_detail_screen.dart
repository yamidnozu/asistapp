import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/acudiente_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/acudiente_service.dart';
import '../../theme/theme_extensions.dart';

/// Pantalla de detalle de un hijo para el acudiente
/// Muestra estadísticas, historial y gráficos

class EstudianteDetailScreen extends StatefulWidget {
  final String estudianteId;

  const EstudianteDetailScreen({super.key, required this.estudianteId});

  @override
  State<EstudianteDetailScreen> createState() => _EstudianteDetailScreenState();
}

class _EstudianteDetailScreenState extends State<EstudianteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  HijoResponse? _hijo;
  EstadisticasCompletas? _estadisticas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final acudienteProvider = context.read<AcudienteProvider>();

    if (authProvider.accessToken != null) {
      await acudienteProvider.seleccionarHijo(
        authProvider.accessToken!,
        widget.estudianteId,
      );
      await acudienteProvider.cargarEstadisticas(
        authProvider.accessToken!,
        widget.estudianteId,
      );
      await acudienteProvider.cargarHistorialAsistencias(
        authProvider.accessToken!,
        widget.estudianteId,
      );
    }

    if (mounted) {
      setState(() {
        _hijo = acudienteProvider.hijoSeleccionado;
        _estadisticas = acudienteProvider.estadisticas;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_hijo?.nombreCompleto ?? 'Detalle del Estudiante'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AcudienteProvider>(
              builder: (context, provider, _) {
                if (provider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage ?? 'Error desconocido'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEstadisticasTab(provider),
                    _buildHistorialTab(provider),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEstadisticasTab(AcudienteProvider provider) {
    final estadisticas = provider.estadisticas;
    if (estadisticas == null) {
      return const Center(child: Text('No hay estadísticas disponibles'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildResumenCard(estadisticas.resumen),
          SizedBox(height: context.spacing.lg),

          // Estadísticas por materia
          Text(
            'Asistencia por Materia',
            style: context.textStyles.headlineSmall,
          ),
          SizedBox(height: context.spacing.md),
          ...estadisticas.porMateria.map(_buildMateriaCard),
          SizedBox(height: context.spacing.lg),

          // Últimas faltas
          if (estadisticas.ultimasFaltas.isNotEmpty) ...[
            Text(
              'Últimas Inasistencias',
              style: context.textStyles.headlineSmall,
            ),
            SizedBox(height: context.spacing.md),
            ...estadisticas.ultimasFaltas.map(_buildFaltaItem),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenCard(EstadisticasResumen resumen) {
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${resumen.porcentajeAsistencia}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Porcentaje de Asistencia',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: context.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Total', resumen.totalClases, Colors.white),
              _buildStatColumn(
                  'Presente', resumen.presentes, Colors.green.shade300),
              _buildStatColumn(
                  'Ausente', resumen.ausentes, Colors.red.shade300),
              _buildStatColumn(
                  'Tardanza', resumen.tardanzas, Colors.orange.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMateriaCard(EstadisticaPorMateria materia) {
    final porcentaje = materia.porcentajeAsistencia;
    final color = porcentaje >= 80
        ? Colors.green
        : porcentaje >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia.materiaNombre,
                    style: context.textStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  Row(
                    children: [
                      Text(
                        '${materia.totalClases} clases',
                        style: context.textStyles.bodySmall,
                      ),
                      const Text(' • '),
                      Text(
                        '${materia.ausentes} faltas',
                        style: context.textStyles.bodySmall.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const Text(' • '),
                      Text(
                        '${materia.tardanzas} tardanzas',
                        style: context.textStyles.bodySmall.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$porcentaje%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaltaItem(AsistenciaHistorialItem falta) {
    final isAusencia = falta.estado == 'AUSENTE';
    final color = isAusencia ? Colors.red : Colors.orange;
    final icon = isAusencia ? Icons.close : Icons.schedule;

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(falta.materia.nombre),
        subtitle: Text(
          '${_formatDate(falta.fecha)} • ${falta.horario.horaInicio} - ${falta.horario.horaFin}',
        ),
        trailing: Chip(
          label: Text(
            falta.estado,
            style: TextStyle(color: color, fontSize: 11),
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildHistorialTab(AcudienteProvider provider) {
    final historial = provider.historialAsistencias;

    if (historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: context.colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay registros de asistencia',
              style: context.textStyles.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.spacing.md),
      itemCount: historial.length,
      itemBuilder: (context, index) {
        final item = historial[index];
        return _buildHistorialItem(item);
      },
    );
  }

  Widget _buildHistorialItem(AsistenciaHistorialItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.estado) {
      case 'PRESENTE':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'AUSENTE':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'TARDANZA':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'JUSTIFICADO':
        statusColor = Colors.blue;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(item.materia.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(item.fecha)),
            Text(
              '${item.horario.horaInicio} - ${item.horario.horaFin}',
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.estado,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
