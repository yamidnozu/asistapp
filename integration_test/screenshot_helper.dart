// ignore_for_file: avoid_print
/// ============================================================================
/// 📸 SCREENSHOT HELPER - Captura de pantallas para documentación
/// ============================================================================
///
/// Este helper permite capturar screenshots durante los tests E2E
/// para generar automáticamente las imágenes del manual de usuario.
///
/// Uso:
///   await screenshots.capture('login_screen');
///   await screenshots.captureForDocs('login_screen', 'Pantalla de login');
///
/// Las imágenes se guardan en: docs/images/
///
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Helper para capturar screenshots durante tests E2E
class ScreenshotHelper {
  final IntegrationTestWidgetsFlutterBinding binding;
  final String outputDir;
  int _screenshotCounter = 0;
  final List<ScreenshotInfo> capturedScreenshots = [];

  ScreenshotHelper({
    required this.binding,
    this.outputDir = 'docs/images',
  });

  /// Inicializa el directorio de salida
  Future<void> init() async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('📁 Directorio de screenshots creado: $outputDir');
    }
  }

  /// Captura un screenshot básico
  Future<void> capture(
    WidgetTester tester,
    String name, {
    Duration waitBefore = const Duration(milliseconds: 500),
  }) async {
    // Esperar un poco para que la UI se estabilice
    await tester.pump(waitBefore);

    try {
      _screenshotCounter++;
      final fileName =
          '${_screenshotCounter.toString().padLeft(2, '0')}_$name.png';
      final filePath = '$outputDir/$fileName';

      // Capturar usando el binding de integration test
      final bytes = await binding.takeScreenshot(name);

      // Guardar el archivo
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      print('📸 Screenshot capturado: $fileName');

      capturedScreenshots.add(ScreenshotInfo(
        name: name,
        fileName: fileName,
        filePath: filePath,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      print('⚠️ Error capturando screenshot "$name": $e');
    }
  }

  /// Captura un screenshot para la documentación con descripción
  Future<void> captureForDocs(
    WidgetTester tester,
    String name,
    String description, {
    Duration waitBefore = const Duration(milliseconds: 500),
  }) async {
    await capture(tester, name, waitBefore: waitBefore);

    // Añadir descripción al último screenshot
    if (capturedScreenshots.isNotEmpty) {
      capturedScreenshots.last.description = description;
    }
  }

  /// Genera un reporte de todos los screenshots capturados
  void printReport() {
    print('\n${'=' * 60}');
    print('📊 REPORTE DE SCREENSHOTS CAPTURADOS');
    print('${'=' * 60}');
    print('Total: ${capturedScreenshots.length} screenshots');
    print('Directorio: $outputDir\n');

    for (final ss in capturedScreenshots) {
      print('📸 ${ss.fileName}');
      if (ss.description != null) {
        print('   📝 ${ss.description}');
      }
    }
    print('${'=' * 60}\n');
  }

  /// Genera un archivo markdown con la lista de screenshots
  Future<void> generateMarkdownIndex() async {
    final buffer = StringBuffer();
    buffer.writeln('# Screenshots de AsistApp');
    buffer.writeln('');
    buffer.writeln('*Generado automáticamente por los tests E2E*');
    buffer.writeln('');
    buffer.writeln('Fecha: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('## Lista de Capturas');
    buffer.writeln('');

    for (final ss in capturedScreenshots) {
      buffer.writeln('### ${ss.name}');
      buffer.writeln('');
      buffer.writeln('![${ss.name}](${ss.fileName})');
      buffer.writeln('');
      if (ss.description != null) {
        buffer.writeln('**Descripción:** ${ss.description}');
        buffer.writeln('');
      }
    }

    final indexFile = File('$outputDir/SCREENSHOTS_INDEX.md');
    await indexFile.writeAsString(buffer.toString());
    print('📝 Índice de screenshots generado: $outputDir/SCREENSHOTS_INDEX.md');
  }
}

/// Información de un screenshot capturado
class ScreenshotInfo {
  final String name;
  final String fileName;
  final String filePath;
  final DateTime timestamp;
  String? description;

  ScreenshotInfo({
    required this.name,
    required this.fileName,
    required this.filePath,
    required this.timestamp,
    this.description,
  });
}

/// Puntos de captura predefinidos para el manual de usuario
class DocScreenshots {
  static const String login = 'login_screen';
  static const String superAdminDashboard = 'super_admin_dashboard';
  static const String institutionsList = 'institutions_list';
  static const String institutionForm = 'institution_form';
  static const String usersList = 'users_list';
  static const String userForm = 'user_form';
  static const String tempPasswordDialog = 'temp_password_dialog';
  static const String adminDashboard = 'admin_dashboard';
  static const String periodosList = 'periodos_list';
  static const String materiasList = 'materias_list';
  static const String gruposList = 'grupos_list';
  static const String grupoDetail = 'grupo_detail';
  static const String horariosList = 'horarios_screen';
  static const String vincularAcudiente = 'vincular_acudiente';
  static const String teacherDashboard = 'teacher_dashboard';
  static const String attendanceScreen = 'attendance_screen';
  static const String qrScanner = 'qr_scanner';
  static const String studentDashboard = 'student_dashboard';
  static const String myQrCode = 'my_qr_code';
  static const String studentSchedule = 'student_schedule';
  static const String studentAttendance = 'student_attendance';
  static const String acudienteDashboard = 'acudiente_dashboard';
  static const String estudianteDetail = 'estudiante_detail';
  static const String notificacionesList = 'notificaciones_screen';
  static const String settingsScreen = 'settings_screen';
}
