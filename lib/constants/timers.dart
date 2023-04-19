import 'package:flutter/material.dart';
import 'package:locus/services/timers_service.dart';

final WEEKDAY_TIMERS = {
  "weekdays_24_7": {
    "name": "Weekdays 24/7",
    "timers": [
      WeekdayTimer.allDay(DateTime.monday),
      WeekdayTimer.allDay(DateTime.tuesday),
      WeekdayTimer.allDay(DateTime.wednesday),
      WeekdayTimer.allDay(DateTime.thursday),
      WeekdayTimer.allDay(DateTime.friday),
    ]
  },
  "weekdays_08_00_20_00": {
    "name": "Weekdays 08:00 - 20:00",
    "timers": const [
      WeekdayTimer(
        day: DateTime.monday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
      WeekdayTimer(
        day: DateTime.tuesday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
      WeekdayTimer(
        day: DateTime.wednesday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
      WeekdayTimer(
        day: DateTime.thursday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
      WeekdayTimer(
        day: DateTime.friday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
    ]
  },
  "weekends_24_7": {
    "name": "Weekends 24/7",
    "timers": [
      WeekdayTimer.allDay(DateTime.saturday),
      WeekdayTimer.allDay(DateTime.sunday),
    ]
  },
  "weekends_08_00_20_00": {
    "name": "Weekends 08:00 - 20:00",
    "timers": const [
      WeekdayTimer(
        day: DateTime.saturday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
      WeekdayTimer(
        day: DateTime.sunday,
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 20, minute: 0),
      ),
    ]
  },
};
