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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final LifeController life;
  late final TiltController tilt;
  EventResult? pendingEvent;

  @override
  void initState() {
    super.initState();
    final apiKey = const String.fromEnvironment('GEMINI_API_KEY'); // pasar con --dart-define
    final gemini = apiKey.isNotEmpty ? GeminiService.fromApiKey(apiKey) : null;
    life = LifeController(eventEngine: EventEngine(ai: gemini));
    tilt = TiltController((dir) async {
      if (dir == TiltDirection.forward) {
        await _simulate();
      } else if (dir == TiltDirection.backward) {
        setState(() => life.rewindOneDay());
      }
    })..start();
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
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    final s = life.state;
    return Container(
      color: ChronoTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Flexible(child: Text('ChronoLife — Día ${s.day}', style: ChronoTheme.baseText.copyWith(fontSize: 22))),
                  const Spacer(),
                  _pill('Avanza: inclina adelante'),
                  const SizedBox(width: 8),
                  _pill('Rebobina: inclina atrás'),
                ],
              ),
              const SizedBox(height: 14),
              GlassContainer(
                child: IndicatorsRow(money: s.money, physical: s.physical.value, mental: s.mental.value),
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
                            setState(()=> life.currentPlan = DayState(life.state.day, plan));
                          },
                        ),
                      ));
                    }),
                    _actionButton('Simular (tap)', () async => await _simulate()),
                    _actionButton('Retroceder (tap)', () { setState(()=> life.rewindOneDay()); }),
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
          if (pendingEvent != null) _eventOverlay(pendingEvent!)
        ],
      ),
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
}