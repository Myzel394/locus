import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/extensions/date.dart';
import 'package:locus/utils/date.dart';

abstract class TaskRuntimeTimer {
  // Abstract class that all timers should extend from

  const TaskRuntimeTimer();

  // A static value that should return whether the timer can potentially run forever
  bool isInfinite();

  bool shouldRun(final DateTime now);

  DateTime? nextStartDate(final DateTime now);

  DateTime? nextEndDate(final DateTime now);

  String format(final BuildContext context);

  Map<String, dynamic> toJSON();

  // Events
  void executionStarted();

  void executionStopped();
}

class WeekdayTimer extends TaskRuntimeTimer {
  // A timer based on weekdays and times
  final int day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const WeekdayTimer({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  static WeekdayTimer allDay(final int day) => WeekdayTimer(
        day: day,
        startTime: TimeOfDay(hour: 0, minute: 0),
        endTime: TimeOfDay(hour: 23, minute: 59),
      );

  static const IDENTIFIER = "weekday";

  @override
  void executionStarted() {}

  @override
  void executionStopped() {}

  @override
  String format(final BuildContext context) {
    final dayString = DateFormat.EEEE().format(createDateFromWeekday(day));

    if (isAllDay) {
      return "$dayString (All Day)";
    }

    return "$dayString ${startTime.format(context)} - ${endTime.format(context)}";
  }

  get isAllDay =>
      startTime.hour == 0 &&
      startTime.minute == 0 &&
      endTime.hour == 23 &&
      endTime.minute == 59;

  @override
  bool isInfinite() => true;

  @override
  bool shouldRun(final DateTime now) {
    if (now.weekday != day) {
      return false;
    }

    if (isAllDay) {
      return true;
    }

    final start = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);
    final end =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    return now.isAfter(start) && now.isBefore(end);
  }

  @override
  Map<String, dynamic> toJSON() {
    return {
      "_IDENTIFIER": IDENTIFIER,
      "day": day,
      "startTime": startTime.toDateTime().toIso8601String(),
      "endTime": endTime.toDateTime().toIso8601String(),
    };
  }

  @override
  DateTime nextStartDate(final DateTime now) {
    if (now.weekday != day) {
      // Find next day that matches the weekday
      final nextDay = now.next(day);
      return DateTime(nextDay.year, nextDay.month, nextDay.day, startTime.hour,
          startTime.minute);
    }

    // Check if start time is in the future, if yes, return that
    final start = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);
    if (now.isBefore(start)) {
      return start;
    }

    // Check if end time is in the future, if yes, return now
    final end =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
    if (now.isBefore(end)) {
      return now;
    }

    // Find next day that matches the weekday
    final nextDay = now.next(day);
    return DateTime(nextDay.year, nextDay.month, nextDay.day, startTime.hour,
        startTime.minute);
  }

  @override
  DateTime nextEndDate(final DateTime now) {
    if (now.weekday != day) {
      // Find next day that matches the weekday
      final nextDay = now.next(day);
      return DateTime(nextDay.year, nextDay.month, nextDay.day, endTime.hour,
          endTime.minute);
    }

    return DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
  }

  static WeekdayTimer fromJSON(final Map<String, dynamic> json) {
    return WeekdayTimer(
      day: json["day"],
      startTime: TimeOfDay.fromDateTime(DateTime.parse(json["startTime"])),
      endTime: TimeOfDay.fromDateTime(DateTime.parse(json["endTime"])),
    );
  }
}

class DurationTimer extends TaskRuntimeTimer {
  // A timer that runs for a certain amount of time
  Duration duration;
  DateTime? startDate;

  DurationTimer({
    required this.duration,
    this.startDate,
  });

  static const IDENTIFIER = "duration";

  @override
  String format(final BuildContext context) {
    return duration.toString();
  }

  @override
  bool isInfinite() => false;

  @override
  bool shouldRun(final DateTime now) {
    if (startDate == null) {
      return false;
    }

    final endDate = startDate!.add(duration);

    return now.isAfter(startDate!) && now.isBefore(endDate);
  }

  @override
  Map<String, dynamic> toJSON() {
    return {
      "_IDENTIFIER": IDENTIFIER,
      "duration": duration.inSeconds,
      "startDate": startDate?.toIso8601String(),
    };
  }

  @override
  DateTime? nextStartDate(final DateTime now) {
    return null;
  }

  static DurationTimer fromJSON(final Map<String, dynamic> json) {
    final duration = Duration(seconds: json["duration"]);
    final rawStartDate = json["startDate"];

    return DurationTimer(
      duration: duration,
      startDate: rawStartDate == null ? null : DateTime.parse(rawStartDate),
    );
  }

  @override
  DateTime? nextEndDate(final DateTime now) {
    if (startDate == null) {
      return startDate!.add(duration);
    } else {
      return now.add(duration);
    }
  }

  @override
  void executionStarted() {
    startDate = DateTime.now();
  }

  @override
  void executionStopped() {
    startDate = null;
  }
}
