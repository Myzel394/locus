import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:locus/services/timers_service.dart';
import 'package:collection/collection.dart';
import 'package:locus/utils/theme.dart';

import '../../services/task_service.dart';

const STATIC_EXAMPLES = [
  TaskExample(
    name: "Weekend Getaway",
    frequency: Duration(minutes: 30),
    timers: [
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
    name: "Elementary School",
    frequency: Duration(minutes: 30),
    timers: [
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
    name: "1 Hour",
    frequency: Duration(minutes: 1),
    realtime: true,
    timers: [
      DurationTimer(duration: Duration(hours: 1)),
    ],
  ),
  TaskExample(
    name: "6 Hour",
    frequency: Duration(minutes: 15),
    timers: [
      DurationTimer(duration: Duration(hours: 6)),
    ],
  ),
  TaskExample(
    name: "12 Hour",
    frequency: Duration(minutes: 15),
    timers: [
      DurationTimer(duration: Duration(hours: 12)),
    ],
  ),
  TaskExample(
    name: "24 hours",
    frequency: Duration(minutes: 20),
    timers: [
      DurationTimer(duration: Duration(hours: 24)),
    ],
  ),
  TaskExample(
    name: "3 days",
    frequency: Duration(minutes: 30),
    timers: [
      DurationTimer(duration: Duration(days: 3)),
    ],
  ),
  TaskExample(
    name: "7 days",
    frequency: Duration(minutes: 30),
    timers: [
      DurationTimer(duration: Duration(days: 7)),
    ],
  ),
];

class ExampleTasksRoulette extends StatelessWidget {
  final void Function(TaskExample) onSelected;

  const ExampleTasksRoulette({
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: STATIC_EXAMPLES
            .mapIndexed(
              (index, example) => PlatformTextButton(
                padding: getSmallButtonPadding(context),
                onPressed: () {
                  onSelected(example);
                },
                child: Text(
                  example.name,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              )
                  .animate()
                  .then(delay: 200.ms * index)
                  .fadeIn(duration: 800.ms)
                  .slideX(duration: 800.ms, begin: -0.1),
            )
            .toList(),
      ),
    );
  }
}
