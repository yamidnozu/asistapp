import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' show showDialog;
import '../providers/user_provider.dart';
import '../services/seed_service.dart';
import '../ui/widgets/index.dart';

class ResetSeedScreen extends StatefulWidget {
  const ResetSeedScreen({super.key});

  @override
  State<ResetSeedScreen> createState() => _ResetSeedScreenState();
}

class _ResetSeedScreenState extends State<ResetSeedScreen> {
  final SeedService _seedService = SeedService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (!userProvider.isSuperAdmin()) {
      return AppScaffold(
        title: 'Acceso Denegado',
        body: const Center(
          child: Text(
            'Solo super administradores pueden acceder a esta pantalla',
            style: TextStyle(color: Color(0xFFEDEDED)),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Reset y Seed',
      body: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset Base de Datos',
                  style: TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Borra todas las subcolecciones de taskmonitoring y recrea la configuración manteniendo los superAdminUids actuales.',
                  style: TextStyle(color: Color(0xFFCCCCCC)),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Reset BD',
                  onPressed: _isLoading ? () {} : _resetDatabase,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seed Demo',
                  style: TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inserta sedes, empleos, responsabilidades y tareas de ejemplo.',
                  style: TextStyle(color: Color(0xFFCCCCCC)),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Seed Demo',
                  onPressed: _isLoading ? () {} : _seedDemo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Borrar Seed',
                  style: TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elimina los datos insertados por Seed Demo.',
                  style: TextStyle(color: Color(0xFFCCCCCC)),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Borrar Seed',
                  onPressed: _isLoading ? () {} : _clearSeed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    setState(() => _isLoading = true);
    try {
      await _seedService.resetDatabase();
      _showMessage('Base de datos reseteada exitosamente');
    } catch (e) {
      _showMessage('Error al resetear BD: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seedDemo() async {
    setState(() => _isLoading = true);
    try {
      await _seedService.seedDemo();
      _showMessage('Seed demo completado exitosamente');
    } catch (e) {
      _showMessage('Error en seed demo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearSeed() async {
    setState(() => _isLoading = true);
    try {
      await _seedService.clearSeed();
      _showMessage('Seed borrado exitosamente');
    } catch (e) {
      _showMessage('Error al borrar seed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Resultado',
        message: message,
        actionLabel: 'OK',
        onAction: () => Navigator.pop(context),
      ),
    );
  }
}