import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/horario_provider.dart';
import '../theme/theme_extensions.dart';
import '../models/clase_del_dia.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider =
        Provider.of<HorarioProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      await horarioProvider.cargarClasesDelDia(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final horarioProvider = Provider.of<HorarioProvider>(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Profesor';

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header minimalista
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child:
                            Icon(Icons.person, color: colors.primary, size: 24),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, $userName',
                              style: textStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getFormattedDate(),
                              style: textStyles.bodySmall
                                  .copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadData,
                        icon: Icon(Icons.refresh,
                            color: colors.textMuted, size: 20),
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Título de sección
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Clases de hoy',
                      style: textStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: spacing.sm, vertical: spacing.xs),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(spacing.borderRadius),
                      ),
                      child: Text(
                        '${horarioProvider.clasesDelDiaCount}',
                        style: textStyles.labelMedium.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: spacing.md)),

            // Lista de clases o estado vacío/loading
            if (horarioProvider.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: colors.primary),
                ),
              )
            else if (horarioProvider.clasesDelDia.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final clases = horarioProvider.getClasesDelDiaOrdenadas();
                      if (index >= clases.length) return null;
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing.sm),
                        child: _ClaseCard(clase: clases[index]),
                      );
                    },
                    childCount: horarioProvider.clasesDelDiaCount,
                  ),
                ),
              ),

            // Espacio inferior
            SliverToBoxAdapter(child: SizedBox(height: spacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 64,
              color: colors.primary.withValues(alpha: 0.4),
            ),
            SizedBox(height: spacing.lg),
            Text(
              '¡Día libre!',
              style: textStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'No tienes clases programadas para hoy',
              style:
                  textStyles.bodyMedium.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${dias[now.weekday % 7]}, ${now.day} ${meses[now.month - 1]}';
  }
}

/// Card minimalista para mostrar una clase
class _ClaseCard extends StatelessWidget {
  final ClaseDelDia clase;

  const _ClaseCard({required this.clase});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(spacing.borderRadius),
      child: InkWell(
        onTap: () => context.pushNamed('teacher-attendance', extra: clase),
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        child: Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            border: Border.all(color: colors.borderLight),
          ),
          child: Row(
            children: [
              // Indicador de hora
              Container(
                width: 56,
                padding: EdgeInsets.symmetric(vertical: spacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                ),
                child: Column(
                  children: [
                    Text(
                      clase.horaInicio.substring(0, 5),
                      style: textStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 1,
                      margin: EdgeInsets.symmetric(vertical: spacing.xs),
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                    Text(
                      clase.horaFin.substring(0, 5),
                      style: textStyles.bodySmall.copyWith(
                        color: colors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.md),
              // Info de la clase
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clase.materia.nombre,
                      style: textStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      clase.grupo.nombreCompleto,
                      style: textStyles.bodySmall
                          .copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Acción
              Icon(
                Icons.chevron_right,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
