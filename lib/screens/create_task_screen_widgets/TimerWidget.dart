import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/create_task_screen_widgets/WeekdaySelection.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/ModalSheet.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({Key? key}) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  final List<TaskRuntimeTimer> _timers = <TaskRuntimeTimer>[];

  List<TaskRuntimeTimer> get sortedTimers => _timers.toList()
    ..sort((a, b) {
      if (a is WeekdayTimer && b is WeekdayTimer) {
        return a.day.compareTo(b.day);
      }

      return 0;
    });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      builder: (_, __) => ModalSheet(
        child: Column(
          children: <Widget>[
            Text("Timers", style: getTitleTextStyle(context)),
            const SizedBox(height: MEDIUM_SPACE),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_timers.isNotEmpty) ...[
                    Expanded(
                      child: ListView.builder(
                        itemCount: _timers.length,
                        itemBuilder: (_, index) => ListTile(
                          title: Text(sortedTimers[index].format(context)),
                          trailing: PlatformIconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                _timers.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    // Month, date and time
                    Text(
                      "Next execution will start at ${DateFormat('MMMM d, HH:mm').format(findNextStartDate(_timers)!)}",
                    ),
                  ],
                  const SizedBox(height: MEDIUM_SPACE),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      PlatformElevatedButton(
                        child: Text("Add Weekday"),
                        material: (_, __) => MaterialElevatedButtonData(
                          icon: Icon(Icons.date_range_rounded),
                        ),
                        onPressed: () async {
                          final data = await showPlatformDialog(
                            context: context,
                            builder: (_) => WeekdaySelection(),
                          );

                          if (data != null) {
                            setState(() {
                              // Merge the new timer if a timer for the same weekday already exists
                              final existingTimer = _timers.firstWhereOrNull(
                                  (timer) => timer is WeekdayTimer && timer.day == data["weekday"]) as WeekdayTimer?;

                              if (existingTimer != null) {
                                _timers.remove(existingTimer);
                              }

                              _timers.add(WeekdayTimer(
                                day: data["weekday"] as int,
                                startTime: data["startTime"] as TimeOfDay,
                                endTime: data["endTime"] as TimeOfDay,
                              ));
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
