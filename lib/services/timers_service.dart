

abstract class TaskRuntimeTimer {
  // Abstract class that all timers should extend from

  // A static value that should return whether the timer can potentially run forever
  bool isInfinite();

  bool shouldRun(final DateTime now);

  DateTime? nextStartDate(final DateTime now);

  DateTime? nextEndDate(final DateTime now);

  Map<String, dynamic> toJSON();
}

class WeekdayTimer extends TaskRuntimeTimer {
  // A timer based on weekdays and times
  final int day;
  final DateTime startTime;
  final DateTime endTime;

  WeekdayTimer({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  static const IDENTIFIER = "weekday";

  get isAllDay => startTime.hour == 0 && startTime.minute == 0 && endTime.hour == 23 && endTime.minute == 59;

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

    final start = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final end = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    return now.isAfter(start) && now.isBefore(end);
  }

  @override
  Map<String, dynamic> toJSON() {
    return {
      "day": day,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
    };
  }

  @override
  DateTime nextStartDate(final DateTime now) {
    if (now.weekday != day) {
      // Find next day that matches the weekday
      final nextDay = now.add(Duration(days: day - now.weekday));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, startTime.hour, startTime.minute);
    }

    // Check if start time is in the future, if yes, return that
    final start = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    if (now.isBefore(start)) {
      return start;
    }

    // Check if end time is in the future, if yes, return now
    final end = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
    if (now.isBefore(end)) {
      return now;
    }

    // Find next day that matches the weekday
    final nextDay = now.add(Duration(days: day - now.weekday));
    return DateTime(nextDay.year, nextDay.month, nextDay.day, startTime.hour, startTime.minute);
  }

  @override
  DateTime nextEndDate(final DateTime now) {
    if (now.weekday != day) {
      // Find next day that matches the weekday
      final nextDay = now.add(Duration(days: day - now.weekday));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, endTime.hour, endTime.minute);
    }

    return DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
  }

  static WeekdayTimer fromJSON(final Map<String, dynamic> json) {
    return WeekdayTimer(
      day: json["day"],
      startTime: DateTime.parse(json["startTime"]),
      endTime: DateTime.parse(json["endTime"]),
    );
  }
}

class TimedTimer extends TaskRuntimeTimer {
  // A timer that runs for a certain amount of time
  final DateTime startTime;
  final DateTime endTime;

  TimedTimer({
    required this.startTime,
    required this.endTime,
  });

  static const IDENTIFIER = "timed";

  @override
  bool isInfinite() => false;

  @override
  bool shouldRun(final DateTime now) {
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  @override
  Map<String, dynamic> toJSON() {
    return {
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
    };
  }

  @override
  DateTime? nextStartDate(final DateTime now) {
    // Check if start time is in the future, if yes, return that
    if (now.isBefore(startTime)) {
      return startTime;
    }

    // Check if end time is in the future, if yes, return now
    if (now.isBefore(endTime)) {
      return now;
    }

    // Timer already ended
    return null;
  }

  static TimedTimer fromJSON(final Map<String, dynamic> json) {
    return TimedTimer(
      startTime: DateTime.parse(json["startTime"]),
      endTime: DateTime.parse(json["endTime"]),
    );
  }

  @override
  DateTime? nextEndDate(final DateTime now) {
    if (now.isBefore(endTime)) {
      return endTime;
    }

    return null;
  }
}
