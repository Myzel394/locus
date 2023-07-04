// Creates a DateTime that represents the given weekday in the year 2004. Primarily only used for formatting weekdays.
DateTime createDateFromWeekday(final int day) => DateTime(
      2004,
      0,
      day,
      0,
      0,
      0,
      0,
    );

extension DateTimeExtension on DateTime {
  bool isSameDay(final DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
