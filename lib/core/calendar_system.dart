class CalendarSystem {
  static const weekdays = [
    'Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'
  ];

  static String weekdayName(int day) => weekdays[(day - 1) % 7];

  static int weekNumber(int day) => ((day - 1) ~/ 7) + 1;

  static bool isWeekend(int day) {
    final wd = (day - 1) % 7;
    return wd == 5 || wd == 6;
  }
}