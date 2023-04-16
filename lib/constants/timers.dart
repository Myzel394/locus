import 'package:locus/services/timers_service.dart';

final WEEKDAY_TIMERS = [
  {
    "name": "Weekdays 24/7",
    "timers": [
      WeekdayTimer.allDay(DateTime.monday),
      WeekdayTimer.allDay(DateTime.tuesday),
      WeekdayTimer.allDay(DateTime.wednesday),
      WeekdayTimer.allDay(DateTime.thursday),
      WeekdayTimer.allDay(DateTime.friday),
    ]
  }
];
