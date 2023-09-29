import '../timers_service.dart';

DateTime? findNextStartDate(final List<TaskRuntimeTimer> timers,
    {final DateTime? startDate, final bool onlyFuture = true}) {
  final now = startDate ?? DateTime.now();

  final nextDates = timers
      .map((timer) => timer.nextStartDate(now))
      .where((date) => date != null && (date.isAfter(now) || date == now))
      .toList(growable: false);

  if (nextDates.isEmpty) {
    return null;
  }

  // Find earliest date
  nextDates.sort();
  return nextDates.first;
}

DateTime? findNextEndDate(
  final List<TaskRuntimeTimer> timers, {
  final DateTime? startDate,
}) {
  final now = startDate ?? DateTime.now();
  final nextDates = List<DateTime>.from(
    timers.map((timer) => timer.nextEndDate(now)).where((date) => date != null),
  )..sort();

  if (nextDates.isEmpty) {
    return null;
  }

  DateTime endDate = nextDates.first;

  for (final date in nextDates.sublist(1)) {
    final nextStartDate = findNextStartDate(timers, startDate: date);
    if (nextStartDate == null ||
        nextStartDate.difference(date).inMinutes.abs() > 15) {
      // No next start date found or the difference is more than 15 minutes, so this is the last date
      break;
    }
    endDate = date;
  }

  return endDate;
}
