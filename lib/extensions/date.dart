import 'package:flutter/material.dart';

extension DateTimeExtension on DateTime {
  DateTime next(int day) {
    return this.add(
      Duration(
        days: (day - this.weekday) % DateTime.daysPerWeek,
      ),
    );
  }
}

extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    return DateTime(2004, 0, 0, hour, minute);
  }
}
