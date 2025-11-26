import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/asistencia_service.dart';
import '../theme/theme_extensions.dart';

class QRScannerScreen extends StatefulWidget {
  final String horarioId;

  const QRScannerScreen({
    super.key,
    required this.horarioId,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? controller; // Cambiado a nullable para mejor manejo
  final AsistenciaService _asistenciaService = AsistenciaService();
  bool _isProcessing = false;
  bool _isScannerReady = false; // Nuevo: estado del scanner
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      controller = MobileScannerController();
      await controller!.start();
      if (mounted) {
        setState(() {
          _isScannerReady = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error inicializando scanner: $e');
      if (mounted) {
        _showErrorSnackBar('Error al inicializar la cámara');
        // Intentar reinicializar después de un delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _initializeScanner();
          }
        });
      }
    }
  }

  // Método seguro para detener el scanner
  Future<void> _safeStopScanner() async {
    if (controller == null || !_isScannerReady) {
      debugPrint('⚠️ Scanner no está listo para detenerse');
      return;
    }

    try {
      await controller!.stop();
      debugPrint('✅ Scanner detenido de forma segura');
    } catch (e) {
      debugPrint('❌ Error al detener scanner de forma segura: $e');
      // Si hay error al detener, marcar como no listo
      if (mounted) {
        setState(() {
          _isScannerReady = false;
        });
      }
      // Intentar reinicializar
      _initializeScanner();
    }
  }

  // Método seguro para iniciar el scanner
  Future<void> _safeStartScanner() async {
    if (controller == null) {
      debugPrint('⚠️ Controller es null, inicializando...');
      await _initializeScanner();
      return;
    }

    if (_isScannerReady) {
      debugPrint('⚠️ Scanner ya está listo');
      return;
    }

    try {
      await controller!.start();
      if (mounted) {
        setState(() {
          _isScannerReady = true;
        });
      }
      debugPrint('✅ Scanner iniciado de forma segura');
    } catch (e) {
      debugPrint('❌ Error al iniciar scanner de forma segura: $e');
      // Si hay error al iniciar, intentar reinicializar
      if (mounted) {
        setState(() {
          _isScannerReady = false;
        });
      }
      _initializeScanner();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Si ya está procesando, ignorar INMEDIATAMENTE
    if (_isProcessing) return;

    // CRÍTICO: Verificar que el scanner esté listo antes de procesar
    if (!_isScannerReady || controller == null) {
      debugPrint('⚠️ Scanner no está listo, ignorando detección');
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Si es el mismo código que ya procesamos, ignorar
    if (_lastScannedCode == code) return;

    // Control de cooldown: no permitir escaneos muy rápidos
    final now = DateTime.now();
    if (_lastScanTime != null) {
      final difference = now.difference(_lastScanTime!);
      if (difference.inMilliseconds < 500) {
        debugPrint('⚠️ Escaneo muy rápido, ignorando (${difference.inMilliseconds}ms)');
        return;
      }
    }

    // CRÍTICO: Marcar como procesando ANTES de hacer CUALQUIER cosa
    _isProcessing = true;
    _lastScannedCode = code;
    _lastScanTime = now;

    // CRÍTICO: Pausar el escáner INMEDIATAMENTE para evitar múltiples detecciones
    await _safeStopScanner();

    // Capturar context antes de usar async gaps
    final currentContext = context;

    try {
      // Obtener el token de autenticación
      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(currentContext, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        _showErrorSnackBar('Error de autenticación');
        return;
      }

      // Mostrar indicador de carga en la parte superior
      if (mounted) {
        final snackBarContext = context; // Capturar context localmente
        // ignore: use_build_context_synchronously
        final screenHeight = MediaQuery.of(snackBarContext).size.height;
        // ignore: use_build_context_synchronously
        final topPadding = MediaQuery.of(snackBarContext).padding.top;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(snackBarContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Theme.of(currentContext).colorScheme.onPrimary),
                const SizedBox(width: 16),
                const Expanded(child: Text('Registrando asistencia...')),
              ],
            ),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              top: topPadding + 16,
              left: 16,
              right: 16,
              bottom: screenHeight - 150,
            ),
          ),
        );
      }

      // Registrar asistencia
      final success = await _asistenciaService.registrarAsistencia(
        accessToken: token,
        horarioId: widget.horarioId,
        codigoQr: code,
      );

      if (success && mounted) {
        // Ocultar snackbar anterior
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();

        // Mostrar éxito en la parte superior
        final successSnackBarContext = context; // Capturar context localmente
        // ignore: use_build_context_synchronously
        final successScreenHeight = MediaQuery.of(successSnackBarContext).size.height;
        // ignore: use_build_context_synchronously
        final successTopPadding = MediaQuery.of(successSnackBarContext).padding.top;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(successSnackBarContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(successSnackBarContext).colorScheme.onSecondary),
                const SizedBox(width: 8),
                const Expanded(child: Text('¡Asistencia registrada exitosamente!')),
              ],
            ),
            backgroundColor: Theme.of(successSnackBarContext).colorScheme.secondary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              top: successTopPadding + 16,
              left: 16,
              right: 16,
              bottom: successScreenHeight - 150,
            ),
          ),
        );

        // Cerrar pantalla después de un breve delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(currentContext).pop(true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Ocultar snackbar anterior
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).hideCurrentSnackBar();

        // Mostrar error
        _showErrorSnackBar(e.toString());
        
        // Reiniciar el scanner para permitir escanear de nuevo
        await _safeStartScanner();
        
        // Limpiar el código escaneado después de un delay para permitir reintentos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _lastScannedCode = null;
            });
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Row(
          children: [
            Icon(Icons.error, color: context.colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: context.colors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height - 150,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajustar tamaño del marco según el ancho de pantalla
        final frameSize = constraints.maxWidth < 400 ? 200.0 : 250.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Escanear Código QR'),
            backgroundColor: context.colors.surface,
            foregroundColor: context.colors.textPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.flashlight_on),
                onPressed: () => controller?.toggleTorch(),
                tooltip: 'Alternar flash',
              ),
              IconButton(
                icon: const Icon(Icons.cameraswitch),
                onPressed: () => controller?.switchCamera(),
                tooltip: 'Cambiar cámara',
              ),
            ],
          ),
          body: Stack(
            children: [
              // Escáner de QR
              MobileScanner(
                controller: controller,
                onDetect: _onDetect,
              ),

              // Overlay con marco de escaneo
              Container(
                decoration: BoxDecoration(
                  color: context.colors.scrim.withValues(alpha: 0.5),
                ),
                child: Stack(
                  children: [
                    // Marco de escaneo centrado
                    Center(
                      child: Container(
                        width: frameSize,
                        height: frameSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Esquinas del marco
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: context.colors.primary, width: 4),
                                    left: BorderSide(color: context.colors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: context.colors.primary, width: 4),
                                    right: BorderSide(color: context.colors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: context.colors.primary, width: 4),
                                    left: BorderSide(color: context.colors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: context.colors.primary, width: 4),
                                    right: BorderSide(color: context.colors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Instrucciones
                    Positioned(
                      top: constraints.maxWidth < 400 ? 80 : 100,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.scrim.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Coloca el código QR dentro del marco para registrar la asistencia',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: constraints.maxWidth < 400 ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Botón de cancelar
                    Positioned(
                      bottom: 50,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: context.textStyles.bodyLarge.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.onError),
                        ),
                      ),
                    ),

                    // Indicador de procesamiento
                    if (_isProcessing)
                      Container(
                        color: context.colors.scrim.withValues(alpha: 0.7),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Procesando...',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}