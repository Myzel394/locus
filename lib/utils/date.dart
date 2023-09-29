// Creates a DateTime that represents the given weekday in the year 2004. Primarily only used for formatting weekdays.
import 'package:intl/intl.dart';

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

String formatDateTimeHumanReadable(
  final DateTime dateTime, [
  final DateTime? comparison,
]) {
  final compareValue = comparison ?? DateTime.now();

  if (dateTime.year != compareValue.year) {
    return DateFormat.yMMMMd().add_Hms().format(dateTime);
  }

  if (dateTime.month != compareValue.month) {
    return DateFormat.MMMMd().add_Hms().format(dateTime);
  }

  if (dateTime.day != compareValue.day) {
    return DateFormat.MMMd().add_Hms().format(dateTime);
  }

  return DateFormat.Hms().format(dateTime);
}
