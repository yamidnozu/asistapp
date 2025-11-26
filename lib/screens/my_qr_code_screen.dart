import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/estudiante_service.dart';
import '../theme/theme_extensions.dart';

class MyQRCodeScreen extends StatefulWidget {
  const MyQRCodeScreen({super.key});

  @override
  State<MyQRCodeScreen> createState() => _MyQRCodeScreenState();
}

class _MyQRCodeScreenState extends State<MyQRCodeScreen> {
  final EstudianteService _estudianteService = EstudianteService();

  String? _qrCode;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final accessToken = authProvider.accessToken;

      if (accessToken == null) {
        throw Exception('Usuario no autenticado');
      }

      final estudianteInfo = await _estudianteService.getEstudianteInfo(
        accessToken: accessToken,
      );

      if (estudianteInfo == null) {
        throw Exception('No se pudo obtener la información del estudiante');
      }

      final qrCode = estudianteInfo['codigoQr'] as String?;
      if (qrCode == null || qrCode.isEmpty) {
        throw Exception('Código QR no disponible');
      }

      setState(() {
        _qrCode = qrCode;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';
    final userLastName = user?['apellidos'] ?? '';

  return LayoutBuilder(
      builder: (context, constraints) {
    final colors = context.colors;
    final spacing = context.spacing;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Código QR'),
            backgroundColor: colors.primary,
            foregroundColor: colors.white,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              children: [
                // Información del estudiante
                Container(
                  padding: EdgeInsets.all(spacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person,
                        size: 48,
                        color: colors.primary,
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        '$userName $userLastName',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        'Estudiante',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xl),

                // Código QR
                Container(
                  padding: EdgeInsets.all(spacing.xl),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: _buildQRContent(context, constraints),
                ),

                SizedBox(height: spacing.lg),

                // Instrucciones
                Text(
                  'Muestra este código QR a tu profesor para registrar tu asistencia',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQRContent(BuildContext context, BoxConstraints constraints) {
    final colors = context.colors;
    final spacing = context.spacing;
    // Ajustar tamaño del QR según el ancho de pantalla
    final qrSize = constraints.maxWidth < 400 ? 150.0 : 200.0;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colors.error,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Error al cargar el código QR',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing.sm),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing.lg),
            ElevatedButton.icon(
              onPressed: _loadQRCode,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_qrCode == null || _qrCode!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 48,
              color: colors.textMuted,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Código QR no disponible',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Código QR
        Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: QrImageView(
            data: _qrCode!,
            version: QrVersions.auto,
            size: qrSize,
            backgroundColor: Theme.of(context).brightness == Brightness.light ? colors.white : colors.surfaceLight,
          ),
        ),

        SizedBox(height: spacing.lg),

        // Información adicional
        Text(
          'ID: $_qrCode',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}