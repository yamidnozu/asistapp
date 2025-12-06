import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/academic/horario_service.dart';
import '../theme/theme_extensions.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _horarios = [];
  String? _errorMessage;
  final HorarioService _horarioService = HorarioService();

  @override
  void initState() {
    super.initState();
    _loadHorarios();
  }

  Future<void> _loadHorarios() async {
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

      final horarios = await _horarioService.getMisHorariosEstudiante(token);

      if (horarios != null) {
        setState(() {
          _horarios = horarios;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron cargar los horarios';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el horario: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Horario', style: textStyles.headlineMedium),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildScheduleContent(),
    );
  }

  Widget _buildErrorState() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          SizedBox(height: spacing.lg),
          Text(
            'Error al cargar horario',
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
            onPressed: _loadHorarios,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    if (_horarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: colors.textMuted),
            SizedBox(height: spacing.lg),
            Text(
              'No tienes clases programadas',
              style: textStyles.headlineSmall.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Tu horario aparecerá aquí cuando tengas clases asignadas',
              style: textStyles.bodyMedium.copyWith(color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupar por día de la semana
    final horariosPorDia = <int, List<Map<String, dynamic>>>{};
    for (final horario in _horarios) {
      final dia = horario['diaSemana'] as int;
      horariosPorDia.putIfAbsent(dia, () => []).add(horario);
    }

    // Ordenar por día
    final diasOrdenados = horariosPorDia.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadHorarios,
      child: ListView.builder(
        padding: EdgeInsets.all(spacing.lg),
        itemCount: diasOrdenados.length,
        itemBuilder: (context, index) {
          final dia = diasOrdenados[index];
          final horariosDelDia = horariosPorDia[dia]!;
          return _buildDiaSchedule(dia, horariosDelDia);
        },
      ),
    );
  }

  Widget _buildDiaSchedule(int diaSemana, List<Map<String, dynamic>> horarios) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final nombreDia = _getNombreDia(diaSemana);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(spacing.borderRadius),
          ),
          child: Text(
            nombreDia,
            style: textStyles.labelLarge.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        ...horarios.map((horario) => _buildHorarioCard(horario)),
        SizedBox(height: spacing.xl),
      ],
    );
  }

  Widget _buildHorarioCard(Map<String, dynamic> horario) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final materia = horario['materia'] as Map<String, dynamic>?;
    final profesor = horario['profesor'] as Map<String, dynamic>?;
    final grupo = horario['grupo'] as Map<String, dynamic>?;

    return Card(
      margin: EdgeInsets.only(bottom: spacing.md),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    horario['horaInicio'] ?? '--:--',
                    style: textStyles.labelMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-',
                    style: textStyles.bodySmall.copyWith(color: colors.primary),
                  ),
                  Text(
                    horario['horaFin'] ?? '--:--',
                    style: textStyles.labelMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia?['nombre'] ?? 'Sin nombre',
                    style: textStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  if (profesor != null)
                    Text(
                      'Prof. ${profesor['nombres'] ?? ''} ${profesor['apellidos'] ?? ''}',
                      style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
                    ),
                  SizedBox(height: spacing.xs),
                  Text(
                    grupo?['nombre'] ?? 'Sin grupo',
                    style: textStyles.bodySmall.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNombreDia(int diaSemana) {
    switch (diaSemana) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Día $diaSemana';
    }
  }
}