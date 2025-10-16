import 'dart:async';
import 'calendar_system.dart';
import 'package:flutter/foundation.dart';
import '../data/models.dart';

class TimeKeeper {
  int currentDay = 1;
  int hour = 6; // inicia a las 6:00 AM
  int minutes = 0;
  Duration tickRate = const Duration(milliseconds: 200); // cada tick = 5 min del juego

  int get week => CalendarSystem.weekNumber(currentDay);
  bool get isWeekend => CalendarSystem.isWeekend(currentDay);

  late ValueNotifier<GameTime> timeNotifier;

  TimeKeeper() {
    timeNotifier = ValueNotifier(GameTime(hour: hour, minute: minutes));
  }

  void start() {
    Timer.periodic(tickRate, (timer) {
      minutes += 5;
      if (minutes >= 60) {
        minutes = 0;
        hour += 1;
        if (hour >= 24) {
          hour = 0;
          currentDay += 1;
        }
      }
      timeNotifier.value = GameTime(hour: hour, minute: minutes);
    });
  }
}

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});
  String format() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String getWeekday(int day) {
  const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  return weekdays[(day - 1) % 7];
}