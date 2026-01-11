import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      // Crear directorio si no existe
      final dir = Directory('docs/images');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Guardar screenshot
      final file = File('docs/images/$screenshotName.png');
      await file.writeAsBytes(screenshotBytes);
      print('📸 Screenshot guardado: docs/images/$screenshotName.png');
      return true;
    },
  );
}
