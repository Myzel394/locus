import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/theme.dart';

import '../../services/task_service.dart';

List<TaskExample> getExamples(final BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return [
    TaskExample(
      name: l10n.tasks_examples_weekend,
      frequency: const Duration(minutes: 30),
      timers: const [
        WeekdayTimer(
          day: DateTime.friday,
          startTime: TimeOfDay(hour: 16, minute: 0),
          endTime: TimeOfDay(hour: 23, minute: 59),
        ),
        WeekdayTimer(
          day: DateTime.saturday,
          startTime: TimeOfDay(hour: 10, minute: 0),
          endTime: TimeOfDay(hour: 23, minute: 0),
        ),
        WeekdayTimer(
          day: DateTime.sunday,
          startTime: TimeOfDay(hour: 10, minute: 0),
          endTime: TimeOfDay(hour: 23, minute: 0),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_examples_school,
      frequency: const Duration(minutes: 30),
      timers: const [
        WeekdayTimer(
          day: DateTime.monday,
          startTime: TimeOfDay(hour: 7, minute: 0),
          endTime: TimeOfDay(hour: 14, minute: 0),
        ),
        WeekdayTimer(
          day: DateTime.tuesday,
          startTime: TimeOfDay(hour: 7, minute: 0),
          endTime: TimeOfDay(hour: 14, minute: 0),
        ),
        WeekdayTimer(
          day: DateTime.wednesday,
          startTime: TimeOfDay(hour: 7, minute: 0),
          endTime: TimeOfDay(hour: 14, minute: 0),
        ),
        WeekdayTimer(
          day: DateTime.thursday,
          startTime: TimeOfDay(hour: 7, minute: 0),
          endTime: TimeOfDay(hour: 14, minute: 0),
        ),
        WeekdayTimer(
          day: DateTime.friday,
          startTime: TimeOfDay(hour: 7, minute: 0),
          endTime: TimeOfDay(hour: 14, minute: 0),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_example_hourDuration(1),
      frequency: const Duration(minutes: 1),
      realtime: true,
      timers: [
        DurationTimer(
          duration: const Duration(hours: 1),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_example_hourDuration(6),
      frequency: const Duration(minutes: 15),
      timers: [
        DurationTimer(
          duration: const Duration(hours: 6),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_example_hourDuration(12),
      frequency: const Duration(minutes: 15),
      timers: [
        DurationTimer(
          duration: const Duration(hours: 12),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_example_hourDuration(24),
      frequency: const Duration(minutes: 20),
      timers: [
        DurationTimer(
          duration: const Duration(hours: 24),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_example_daysDuration(3),
      frequency: const Duration(minutes: 30),
      timers: [
        DurationTimer(
          duration: const Duration(days: 3),
        ),
      ],
    ),
    TaskExample(
      name: l10n.tasks_example_daysDuration(7),
      frequency: const Duration(minutes: 30),
      timers: [
        DurationTimer(
          duration: const Duration(days: 7),
        ),
      ],
    ),
  ];
}

class ExampleTasksRoulette extends StatelessWidget {
  final void Function(TaskExample) onSelected;
  final bool disabled;

  const ExampleTasksRoulette({
    required this.onSelected,
    this.disabled = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: getExamples(context)
            .mapIndexed(
              (index, example) => PlatformTextButton(
                padding: getSmallButtonPadding(context),
                onPressed: disabled
                    ? null
                    : () {
                        onSelected(example);
                      },
                child: Text(
                  example.name,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ).animate().then(delay: 200.ms * index).fadeIn(duration: 800.ms).slideX(duration: 800.ms, begin: -0.1),
            )
            .toList(),
      ),
    );
  }
}
