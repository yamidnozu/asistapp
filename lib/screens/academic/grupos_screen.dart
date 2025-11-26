import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final AppColors colors = AppColors.instance;
  final AppSpacing spacing = AppSpacing.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/academic');
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 64,
              color: colors.textMuted,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Pantalla de Grupos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Esta funcionalidad está en desarrollo',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
