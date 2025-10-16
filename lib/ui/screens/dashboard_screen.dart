import 'package:flutter/widgets.dart';
import '../theme.dart';
import '../widgets/indicators_row.dart';
import '../primitives/glass_container.dart';
import '../../core/life_controller.dart';
import '../../utils/tilt_controller.dart';
import 'planner_screen.dart';
import 'summary_screen.dart';
import '../../core/event_engine.dart';
import '../../services/gemini_service.dart';
import '../../data/models.dart';
import '../../core/calendar_system.dart';
import 'weekly_summary_screen.dart';
import '../../ui/widgets/goal_panel.dart';

class MicroEvent {
  final String title;
  final String desc;
  final List<String> options;
  final List<VoidCallback> actions;

  MicroEvent(this.title, this.desc, this.options, this.actions);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final LifeController life;
  late final TiltController tilt;
  EventResult? pendingEvent;
  MicroEvent? pendingMicroEvent;
  Color backgroundColor = const Color(0xFF14213D);

  @override
  void initState() {
    super.initState();
    const apiKey = kGeminiKey;
    final gemini = (apiKey != null && apiKey.isNotEmpty) ? GeminiService.fromApiKey(apiKey, model: 'gemini-2.5-flash-lite') : null;
    life = LifeController(eventEngine: EventEngine(ai: gemini));
    tilt = TiltController((dir) async {
      if (dir == TiltDirection.forward) {
        await _simulate();
      } else if (dir == TiltDirection.backward) {
        setState(() => life.rewindOneDay());
      }
    })..start();

    life.timeNotifier.addListener(() => _checkMicroEvents(life.timeNotifier.value));
  }

  @override
  void dispose() {
    tilt.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    final event = await life.simulateDay();
    if (!mounted) return;
    if (event != null) {
      setState(() => pendingEvent = event);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSummary());
    }
  }

  Future<void> _showSummary() async {
    final s = life.state;
    final isSunday = CalendarSystem.weekdayName(s.day) == 'Domingo';
    if (isSunday) {
      // Calcular stats semanales (simplificado)
      final week = CalendarSystem.weekNumber(s.day);
      final balance = s.money; // asumir balance actual
      final healthAvg = s.physical.value;
      final stressAvg = 100 - s.mental.value; // estrés = 100 - mental
      final reputation = s.reputation;
      final goals = s.goals;
      final narrative = await _generateWeeklyNarrative(s, week);

      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => WeeklySummaryScreen(
          week: week,
          balance: balance,
          healthAvg: healthAvg,
          stressAvg: stressAvg,
          reputation: reputation,
          goals: goals,
          narrative: narrative,
        ),
      ));
    } else {
      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SummaryScreen(
          lines: [
            'Día ${s.day - 1} completado',
            'Dinero: \$${s.money.toStringAsFixed(2)}',
            'Salud física: ${s.physical.value.toStringAsFixed(0)}%',
            'Salud mental: ${s.mental.value.toStringAsFixed(0)}%',
          ],
          onContinue: () => Navigator.of(_).pop(),
        ),
      ));
    }
    setState(() {});
  }

  Future<String> _generateWeeklyNarrative(PlayerState s, int week) async {
    final ai = life.eventEngine?.ai;
    if (ai == null) return 'Sin narrativa disponible.';

    final prompt = '''
Genera una narrativa breve (3-4 frases) para el resumen semanal de ChronoLife.
Semana: $week
Dinero: ${s.money}
Salud física: ${s.physical.value}%
Salud mental: ${s.mental.value}%
Reputación: ${s.reputation}
Metas: ${s.goals.map((g) => '${g.title}: ${(g.progress * 100).toInt()}%').join(', ')}
Historia previa: ${life.narrativeHistory.join(' ')}
Incluye una decisión moral con 2 opciones.
''';

    try {
      final response = await ai.generateNarrative(prompt);
      final narrative = response ?? 'Narrativa generada.';
      life.narrativeHistory.add(narrative);
      life.saveState();
      return narrative;
    } catch (e) {
      return 'Error generando narrativa: $e';
    }
  }

  void _showGoalPanel() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => GoalPanel(
        goals: life.state.goals,
        onAddGoal: (goal) => setState(() => life.addGoal(goal)),
        onUpdateProgress: (id, progress) => setState(() => life.updateGoalProgress(id, progress)),
      ),
    ));
  }

  void _checkMicroEvents(GameTime time) {
    if (time.hour == 10 && life.state.physical.value < 40 && pendingMicroEvent == null) {
      setState(() => pendingMicroEvent = MicroEvent(
        'Fatiga Matutina',
        'Te sientes agotado esta mañana.',
        ['Descansar 10 min', 'Ignorar', 'Tomar café'],
        [
          () => setState(() {
            life.state.physical.value = (life.state.physical.value + 5).clamp(0,100);
            pendingMicroEvent = null;
          }),
          () => setState(() {
            life.state.mental.value = (life.state.mental.value - 2).clamp(0,100);
            pendingMicroEvent = null;
          }),
          () => setState(() {
            life.state.money -= 5;
            life.state.physical.value = (life.state.physical.value + 3).clamp(0,100);
            pendingMicroEvent = null;
          }),
        ],
      ));
    }
    // Más condiciones pueden agregarse
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameTime>(
      valueListenable: life.timeNotifier,
      builder: (context, time, child) {
        final weekday = CalendarSystem.weekdayName(life.timeKeeper.currentDay);
        final week = life.timeKeeper.week;
        final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} hrs';
        final progress = (time.hour * 60 + time.minute) / (24 * 60.0);
        backgroundColor = _calculateColor(time.hour);

        return AnimatedContainer(
          duration: const Duration(seconds: 1),
          color: backgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Flexible(child: Text('Semana $week — $weekday — $timeStr', style: ChronoTheme.baseText.copyWith(fontSize: 22))),
                      const Spacer(),
                      _pill('Avanza: inclina adelante'),
                      const SizedBox(width: 8),
                      _pill('Rebobina: inclina atrás'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(2)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(color: ChronoTheme.text, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassContainer(
                    child: IndicatorsRow(money: life.state.money, physical: life.state.physical.value, mental: life.state.mental.value, reputation: life.state.reputation.toDouble()),
                  ),
                  const SizedBox(height: 14),
                  GlassContainer(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _actionButton('Planear día', () {
                          Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (_, __, ___) => PlannerScreen(
                              initialPlan: life.currentPlan.plan,
                              onSave: (plan) {
                                setState(() => life.currentPlan = DayState(life.state.day, plan));
                              },
                            ),
                          ));
                        }),
                        _actionButton('Simular (tap)', () async => await _simulate()),
                        _actionButton('Retroceder (tap)', () { setState(() => life.rewindOneDay()); }),
                        _actionButton('Metas', () => _showGoalPanel()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GlassContainer(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Agenda del día: ${life.currentPlan.plan.map((e) => '${e.block.name}:${e.action}').join(', ')}',
                          style: ChronoTheme.baseText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              if (pendingEvent != null) _eventOverlay(pendingEvent!),
              if (pendingMicroEvent != null) _microEventOverlay(pendingMicroEvent!),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: ChronoTheme.baseText.copyWith(fontSize: 12, color: ChronoTheme.textDim)),
  );

  Widget _actionButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: ChronoTheme.baseText),
    ),
  );

  Widget _eventOverlay(EventResult e) {
    return Positioned.fill(
      child: Container(
        color: const Color(0x99000000),
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            decoration: ChronoTheme.glass(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.title, style: ChronoTheme.baseText.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                Text(e.desc, style: ChronoTheme.baseText.copyWith(color: ChronoTheme.textDim)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _actionButton(e.options[0].label, () {
                      setState(() {
                        e.options[0].apply(life.state);
                        pendingEvent = null;
                      });
                    })),
                    const SizedBox(width: 12),
                    if (e.options.length > 1)
                      Expanded(child: _actionButton(e.options[1].label, () {
                        setState(() {
                          e.options[1].apply(life.state);
                          pendingEvent = null;
                        });
                      })),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _calculateColor(int hour) {
    if (hour >= 6 && hour < 12) {
      double t = (hour - 6) / 6.0;
      return Color.lerp(const Color(0xFF14213D), const Color(0xFFFFDFA3), t)!;
    } else if (hour >= 12 && hour < 18) {
      double t = (hour - 12) / 6.0;
      return Color.lerp(const Color(0xFFFFDFA3), const Color(0xFFFCA311), t)!;
    } else {
      double t = hour < 6 ? (hour / 6.0) : ((hour - 18) / 6.0);
      return Color.lerp(const Color(0xFFFCA311), const Color(0xFF14213D), t)!;
    }
  }

  Widget _microEventOverlay(MicroEvent e) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.title, style: ChronoTheme.baseText.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(e.desc, style: ChronoTheme.baseText.copyWith(color: ChronoTheme.textDim)),
              const SizedBox(height: 12),
              Row(
                children: e.options.asMap().entries.map((entry) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _actionButton(entry.value, e.actions[entry.key]),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}