import 'package:flutter/widgets.dart';
import 'ui/theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/planner_screen.dart';
import 'ui/screens/summary_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ChronoApp extends StatelessWidget {
  const ChronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      navigatorKey: navigatorKey,
      color: ChronoTheme.background,
      textStyle: ChronoTheme.baseText,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => const DashboardScreen(),
            );
          case '/planner':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => PlannerScreen(initialPlan: const [], onSave: (_) {}),
            );
          case '/summary':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => SummaryScreen(lines: const [], onContinue: () {}),
            );
          default:
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => const DashboardScreen(),
            );
        }
      },
      initialRoute: '/',
    );
  }
}