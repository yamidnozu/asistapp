import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus_detector/focus_detector.dart';

import '../../models/grupo.dart';
import '../../models/horario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grupo_provider.dart';
import '../../providers/horario_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/periodo_academico_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';
import '../../widgets/horarios/create_class_dialog.dart';
import '../../widgets/horarios/edit_class_dialog.dart';
import '../../widgets/horarios/weekly_calendar.dart';

const List<String> _horas = [
  '07:00',
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
  '18:00',
];

const List<String> _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<int> _diasSemanaValues = [1, 2, 3, 4, 5, 6, 7];

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  Grupo? _selectedGrupo;
  PeriodoAcademico? _selectedPeriodo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token == null) return;

    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await periodoProvider.loadPeriodosActivos(token);

      if (periodoProvider.periodosActivos.isNotEmpty) {
        final periodo = periodoProvider.periodosActivos.first;
        if (!mounted) return;
        setState(() => _selectedPeriodo = periodo);
        await grupoProvider.loadGrupos(token, periodoId: periodo.id);
      } else {
        await grupoProvider.loadGrupos(token);
      }

      if (!mounted) return;
      if (grupoProvider.items.isNotEmpty) {
        setState(() => _selectedGrupo = grupoProvider.items.first);
        await _loadHorariosForGrupo(_selectedGrupo!.id);
      }

      await materiaProvider.loadMaterias(token);

      final institutionId = authProvider.selectedInstitutionId;
      if (institutionId != null) {
        await userProvider.loadUsersByInstitution(token, institutionId);
      } else {
        await userProvider.loadUsers(token, roles: ['profesor']);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando datos iniciales: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onFocusGained: _onFocusGained,
      child: Consumer4<PeriodoAcademicoProvider, GrupoProvider, HorarioProvider, MateriaProvider>(
        builder: (context, periodoProvider, grupoProvider, horarioProvider, materiaProvider, child) {
          return ClarityManagementPage(
            title: 'Horarios',
            backRoute: '/academic',
            isLoading: horarioProvider.isLoading,
            hasError: horarioProvider.hasError,
            errorMessage: horarioProvider.errorMessage,
            itemCount: _selectedGrupo != null ? 1 : 0,
            itemBuilder: (context, index) => WeeklyCalendar(
              horarioProvider: horarioProvider,
              horas: _horas,
              diasSemana: _diasSemana,
              diasSemanaValues: _diasSemanaValues,
              onEmptyCellTap: _handleEmptyCellTap,
              onHorarioTap: _handleHorarioTap,
            ),
            filterWidgets: _buildFilterWidgets(context, periodoProvider, grupoProvider, materiaProvider),
            onRefresh: () async {
              if (_selectedGrupo != null) {
                await _loadHorariosForGrupo(_selectedGrupo!.id);
              }
              // También recargar materias por si acaso
              await materiaProvider.loadMaterias(
                Provider.of<AuthProvider>(context, listen: false).accessToken!
              );
            },
            scrollController: null,
            emptyStateWidget: ClarityEmptyState(
              icon: Icons.calendar_month,
              title: _selectedGrupo == null ? 'Selecciona un grupo' : 'No hay clases en el grupo',
              subtitle: _selectedGrupo == null
                  ? 'Selecciona un grupo para ver el calendario semanal'
                  : 'Crea la primera clase para este grupo',
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                if (_selectedGrupo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecciona un grupo para crear una clase')),
                  );
                  return;
                }
                _handleEmptyCellTap(_horas.first, _diasSemanaValues.first);
              },
              tooltip: 'Crear Clase',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onFocusGained() async {
    // Recargar datos "ligeros" que podrían haber cambiado en otras pantallas (Materias, Grupos)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token == null) return;

    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

    // Recargar materias silenciosamente
    await materiaProvider.loadMaterias(token);
    
    // Opcional: Recargar grupos si es necesario
    // await grupoProvider.loadGrupos(token, periodoId: _selectedPeriodo?.id);
  }

  List<Widget> _buildFilterWidgets(
    BuildContext context,
    PeriodoAcademicoProvider periodoProvider,
    GrupoProvider grupoProvider,
    MateriaProvider materiaProvider,
  ) {
    final spacing = context.spacing;

    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
          final itemWidth = (width - ((columns - 1) * 12)) / columns;

          // Sincronizar selectedPeriodo con la instancia actual del provider (evita mismatches en el Dropdown)
          final periodos = periodoProvider.periodosActivos;
          PeriodoAcademico? periodoValue;
          if (_selectedPeriodo != null && periodos.isNotEmpty) {
            PeriodoAcademico? matching;
            for (var p in periodos) {
              if (p.id == _selectedPeriodo!.id) {
                matching = p;
                break;
              }
            }
            // Usar la instancia encontrada para la UI inmediatamente (sin mutar el estado durante build)
            periodoValue = matching;
            if (matching != null && matching != _selectedPeriodo) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedPeriodo = matching);
              });
            } else if (matching == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedPeriodo = null);
              });
            }
          } else {
            periodoValue = _selectedPeriodo;
          }

          // Sincronizar selectedGrupo con la instancia actual de grupoProvider (si aplica)
          final grupos = _selectedPeriodo == null
              ? grupoProvider.items
              : grupoProvider.items.where((g) => g.periodoId == _selectedPeriodo!.id).toList();
          Grupo? grupoValue;
          if (_selectedGrupo != null && grupos.isNotEmpty) {
            Grupo? matchingGrupo;
            for (var g in grupos) {
              if (g.id == _selectedGrupo!.id) {
                matchingGrupo = g;
                break;
              }
            }
            // Mostrar la instancia encontrada en la UI inmediatamente
            grupoValue = matchingGrupo;
            if (matchingGrupo != null && matchingGrupo != _selectedGrupo) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedGrupo = matchingGrupo);
              });
            } else if (matchingGrupo == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedGrupo = grupos.isNotEmpty ? grupos.first : null);
              });
            }
          } else {
            grupoValue = _selectedGrupo;
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<PeriodoAcademico>(
                  isExpanded: true,
                  value: periodoValue,
                  decoration: InputDecoration(
                    labelText: 'Período Académico',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
                  ),
                  style: context.textStyles.bodyLarge.copyWith(color: context.colors.textPrimary),
                  items: periodoProvider.periodosActivos
                      .map(
                        (periodo) => DropdownMenuItem<PeriodoAcademico>(
                          value: periodo,
                          child: Text(periodo.nombre, overflow: TextOverflow.ellipsis, maxLines: 1),
                        ),
                      )
                      .toList(),
                  onChanged: (periodo) => _onPeriodoChanged(periodo, grupoProvider),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<Grupo>(
                  isExpanded: true,
                  value: grupoValue,
                  decoration: const InputDecoration(labelText: 'Grupo'),
                  items: _buildGrupoItems(grupoProvider),
                  onChanged: _handleGrupoDropdownChanged,
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<DropdownMenuItem<Grupo>> _buildGrupoItems(GrupoProvider grupoProvider) {
    final grupos = _selectedPeriodo == null
        ? grupoProvider.items
        : grupoProvider.items.where((grupo) => grupo.periodoId == _selectedPeriodo!.id).toList();

    return grupos
        .map(
          (grupo) => DropdownMenuItem<Grupo>(
            value: grupo,
            child: Text('${grupo.nombre} - ${grupo.grado}', overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        )
        .toList();
  }

  Future<void> _onPeriodoChanged(PeriodoAcademico? periodo, GrupoProvider grupoProvider) async {
    if (!mounted) return;

    setState(() {
      _selectedPeriodo = periodo;
      _selectedGrupo = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    if (periodo != null) {
      await grupoProvider.loadGrupos(token, periodoId: periodo.id);
    } else {
      await grupoProvider.loadGrupos(token);
    }

    if (!mounted) return;

    if (grupoProvider.items.isNotEmpty) {
      setState(() => _selectedGrupo = grupoProvider.items.first);
      await _loadHorariosForGrupo(_selectedGrupo!.id);
    }
  }

  void _handleGrupoDropdownChanged(Grupo? grupo) {
    _onGrupoChanged(grupo);
  }

  Future<void> _onGrupoChanged(Grupo? grupo) async {
    if (!mounted) return;

    setState(() => _selectedGrupo = grupo);

    if (grupo != null) {
      await _loadHorariosForGrupo(grupo.id);
    }
  }

  Future<void> _loadHorariosForGrupo(String grupoId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token == null) return;

    try {
      if (_selectedPeriodo != null) {
        await horarioProvider.loadHorariosForGrupoWithConflictDetection(token, grupoId, _selectedPeriodo!.id);
      } else {
        await horarioProvider.loadHorariosByGrupo(token, grupoId);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando horarios: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _handleEmptyCellTap(String horaInicio, int diaSemana) async {
    if (_selectedGrupo == null) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => CreateClassDialog(
        grupo: _selectedGrupo!,
        horaInicio: horaInicio,
        diaSemana: diaSemana,
      ),
    );

    if (created == true && _selectedGrupo != null) {
      await _loadHorariosForGrupo(_selectedGrupo!.id);
    }
  }

  Future<void> _handleHorarioTap(Horario horario) async {
    final edited = await showDialog<bool>(
      context: context,
      builder: (context) => EditClassDialog(horario: horario),
    );

    if (edited == true && _selectedGrupo != null) {
      await _loadHorariosForGrupo(_selectedGrupo!.id);
    }
  }
}
