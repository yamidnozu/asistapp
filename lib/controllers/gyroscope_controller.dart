import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../controllers/life_controller.dart';

class GyroscopeController {
  final LifeController lifeController;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  GyroscopeController(this.lifeController);

  void startListening() {
    _gyroSubscription = gyroscopeEvents.listen((event) {
      if (event.z > 1.0) {
        lifeController.nextDay();
      } else if (event.z < -1.0) {
        lifeController.rewindDay();
      }
    });
  }

  void stopListening() {
    _gyroSubscription?.cancel();
  }
}