import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/horario_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/components/index.dart';
import '../models/clase_del_dia.dart';
// AttendanceScreen route is opened via go_router; import not required here

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);

        final token = authProvider.accessToken;
        if (token != null) {
          await horarioProvider.cargarClasesDelDia(token);
          // Iniciar animación después de cargar datos
          _fadeController.forward();
        }
      } catch (e) {
        debugPrint('TeacherDashboard init load error: $e');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final horarioProvider = Provider.of<HorarioProvider>(context);
    final colors = context.colors;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Profesor';

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final token = authProvider.accessToken;
          if (token != null) {
            await horarioProvider.cargarClasesDelDia(token);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con gradiente
              _buildHeader(context, userName),

              SizedBox(height: spacing.xl),

              // Estadísticas principales
              _buildStatsSection(context, horarioProvider),

              SizedBox(height: spacing.xl),

              // Sección de clases del día
              _buildClasesSection(context, horarioProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.8),
            colors.secondary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(spacing.xl),
          bottomRight: Radius.circular(spacing.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.md),
                  decoration: BoxDecoration(
                    color: colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(spacing.borderRadiusLarge),
                  ),
                  child: Icon(
                    Icons.school,
                    color: colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(width: spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $userName!',
                        style: textStyles.displayMedium.copyWith(
                          color: colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        'Bienvenido a tu panel docente',
                        style: textStyles.bodyLarge.copyWith(
                          color: colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            // Fecha actual
            Container(
              padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
              decoration: BoxDecoration(
                color: colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(spacing.borderRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: colors.white,
                    size: 18,
                  ),
                  SizedBox(width: spacing.sm),
                  Flexible(
                    child: Text(
                      _getCurrentDate(),
                      style: textStyles.bodyMedium.copyWith(
                        color: colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, HorarioProvider horarioProvider) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Día',
            style: context.textStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: spacing.md),
          // Usar LayoutBuilder para detectar el ancho disponible
          LayoutBuilder(
            builder: (context, constraints) {
              // Si el ancho es pequeño, usar columna en lugar de fila
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    ClarityKPICard(
                      value: horarioProvider.clasesDelDiaCount.toString(),
                      label: 'Clases Hoy',
                      icon: Icons.class_,
                      iconColor: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: 0.05),
                    ),
                    SizedBox(height: spacing.md),
                    ClarityKPICard(
                      value: _calculateTotalStudents(horarioProvider).toString(),
                      label: 'Estudiantes',
                      icon: Icons.people,
                      iconColor: colors.info,
                      backgroundColor: colors.info.withValues(alpha: 0.05),
                    ),
                    SizedBox(height: spacing.md),
                    ClarityKPICard(
                      value: '95%', // TODO: Calcular asistencia real
                      label: 'Asistencia Promedio',
                      icon: Icons.check_circle,
                      iconColor: colors.success,
                      backgroundColor: colors.success.withValues(alpha: 0.05),
                    ),
                  ],
                );
              } else {
                // Para anchos mayores, usar Row
                return Row(
                  children: [
                    Expanded(
                      child: ClarityKPICard(
                        value: horarioProvider.clasesDelDiaCount.toString(),
                        label: 'Clases Hoy',
                        icon: Icons.class_,
                        iconColor: colors.primary,
                        backgroundColor: colors.primary.withValues(alpha: 0.05),
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: ClarityKPICard(
                        value: _calculateTotalStudents(horarioProvider).toString(),
                        label: 'Estudiantes',
                        icon: Icons.people,
                        iconColor: colors.info,
                        backgroundColor: colors.info.withValues(alpha: 0.05),
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: ClarityKPICard(
                        value: '95%', // TODO: Calcular asistencia real
                        label: 'Asistencia Promedio',
                        icon: Icons.check_circle,
                        iconColor: colors.success,
                        backgroundColor: colors.success.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClasesSection(BuildContext context, HorarioProvider horarioProvider) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mis Clases de Hoy',
                  style: textStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final token = authProvider.accessToken;
                  if (token != null) {
                    await horarioProvider.cargarClasesDelDia(token);
                  }
                },
                icon: Icon(Icons.refresh, color: colors.primary),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          SizedBox(height: spacing.md),

          if (horarioProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (horarioProvider.clasesDelDia.isEmpty)
            _buildEmptyState(context)
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildClasesList(context, horarioProvider.getClasesDelDiaOrdenadas()),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadiusLarge),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 48,
              color: colors.primary,
            ),
          ),
          SizedBox(height: spacing.lg),
          Text(
            '¡Día Libre!',
            style: textStyles.headlineMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.sm),
          Text(
            'No tienes clases programadas para hoy.\n¡Disfruta tu tiempo libre!',
            style: textStyles.bodyLarge.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.lg),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navegar a horario semanal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Horario semanal próximamente')),
              );
            },
            icon: const Icon(Icons.calendar_view_week),
            label: const Text('Ver Horario Semanal'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClasesList(BuildContext context, List<ClaseDelDia> clases) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clases.length,
      itemBuilder: (context, index) {
        final clase = clases[index];
        return Padding(
          padding: EdgeInsets.only(bottom: context.spacing.md),
          child: ClaseCardPro(clase: clase, index: index),
        );
      },
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

    return '${dias[now.weekday % 7]} ${now.day} de ${meses[now.month - 1]}';
  }

  int _calculateTotalStudents(HorarioProvider horarioProvider) {
    // TODO: Implementar cálculo real de estudiantes totales
    // Por ahora, estimamos 25 estudiantes por clase
    return horarioProvider.clasesDelDiaCount * 25;
  }
}

// Widget mejorado para mostrar una clase del día
class ClaseCardPro extends StatefulWidget {
  final ClaseDelDia clase;
  final int index;

  const ClaseCardPro({
    super.key,
    required this.clase,
    required this.index,
  });

  @override
  State<ClaseCardPro> createState() => _ClaseCardProState();
}

class _ClaseCardProState extends State<ClaseCardPro> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Animar entrada con delay escalonado
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.surface,
              colors.surface.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(spacing.borderRadiusLarge),
          border: Border.all(color: colors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navegar a detalles de la clase
            },
            borderRadius: BorderRadius.circular(spacing.borderRadiusLarge),
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con materia y grupo
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.sm),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                        ),
                        child: Icon(
                          Icons.book,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.clase.materia.nombre,
                              style: textStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              widget.clase.grupo.nombreCompleto,
                              style: textStyles.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(spacing.borderRadius),
                        ),
                        child: Text(
                          'Activa',
                          style: textStyles.labelSmall.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.lg),

                  // Información de horario
                  Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(spacing.borderRadius),
                      border: Border.all(color: colors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: colors.primary,
                          size: 20,
                        ),
                        SizedBox(width: spacing.sm),
                        Text(
                          widget.clase.horarioFormato,
                          style: textStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: colors.textMuted,
                                size: 18,
                              ),
                              SizedBox(width: spacing.xs),
                              Flexible(
                                child: Text(
                                  'Aula 101', // TODO: Agregar información real de aula
                                  style: textStyles.bodyMedium.copyWith(
                                    color: colors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: spacing.lg),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Navegar a la pantalla de asistencia
                            // Navigate via go_router so routing works consistently
                            context.pushNamed('teacher-attendance', extra: widget.clase);

                            // Después de regresar, podríamos refrescar datos si fuera necesario
                            // Por ahora, la pantalla de asistencia maneja su propio estado
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Tomar Asistencia'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.white,
                            padding: EdgeInsets.symmetric(vertical: spacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(spacing.borderRadius),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: () {
                            // TODO: Mostrar menú de opciones
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opciones próximamente')),
                            );
                          },
                          icon: Icon(Icons.more_vert, color: colors.textMuted),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.surface,
                            side: BorderSide(color: colors.borderLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}