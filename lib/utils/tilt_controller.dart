import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

typedef TiltCallback = void Function(TiltDirection dir);

enum TiltDirection { forward, backward, neutral }

class TiltController {
  TiltController(this.onTilt);
  final TiltCallback onTilt;

  StreamSubscription? _sub;
  static const double _threshold = 0.7; // sensible pero estable

  void start() {
    _sub = gyroscopeEventStream().listen((e) {
      // e.y ~ inclinación adelante/atrás dependiendo del dispositivo
      if (e.y > _threshold) {
        onTilt(TiltDirection.forward);
      } else if (e.y < -_threshold) {
        onTilt(TiltDirection.backward);
      } else {
        onTilt(TiltDirection.neutral);
      }
    });
  }

  void dispose() => _sub?.cancel();
}