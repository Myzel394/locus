import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/timers.dart';
import 'package:locus/screens/create_task_screen_widgets/WeekdaySelection.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/LongPressPopup.dart';
import 'package:locus/widgets/ModalSheet.dart';

class TimerWidgetSheet extends StatefulWidget {
  const TimerWidgetSheet({Key? key}) : super(key: key);

  @override
  State<TimerWidgetSheet> createState() => _TimerWidgetSheetState();
}

class _TimerWidgetSheetState extends State<TimerWidgetSheet> {
  final List<TaskRuntimeTimer> _timers = <TaskRuntimeTimer>[];
  late final _sheetController;

  @override
  void initState() {
    super.initState();

    _sheetController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  List<TaskRuntimeTimer> get sortedTimers => _timers.toList()
    ..sort((a, b) {
      if (a is WeekdayTimer && b is WeekdayTimer) {
        return a.day.compareTo(b.day);
      }

      return 0;
    });

  void addWeekdayTimer(final WeekdayTimer timer) {
    setState(() {
      // Merge the new timer if a timer for the same weekday already exists
      final existingTimer =
          _timers.firstWhereOrNull((currentTimer) => currentTimer is WeekdayTimer && currentTimer.day == timer.day);

      if (existingTimer != null) {
        _timers.remove(existingTimer);
      }

      _timers.add(timer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      controller: _sheetController,
      minChildSize: 0.4,
      maxChildSize: 0.6,
      expand: false,
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
                    if (_timers.any((timer) => timer.isInfinite())) ...[
                      const SizedBox(height: SMALL_SPACE),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.warning_rounded,
                            color: Colors.yellow,
                          ),
                          const SizedBox(width: TINY_SPACE),
                          Text(
                            "This task will run until you stop it manually.",
                            style: getCaptionTextStyle(context).copyWith(
                              color: Colors.yellow,
                            ),
                          ),
                        ],
                      )
                    ]
                  ],
                  const SizedBox(height: MEDIUM_SPACE),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      LongPressPopup<String>(
                        items: List<PopupMenuEntry<String>>.from(
                          WEEKDAY_TIMERS.entries.map(
                            (entry) => PopupMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value["name"] as String),
                            ),
                          ),
                        ),
                        onSelected: (final dynamic id) {
                          setState(() {
                            _timers.clear();
                          });

                          final timers = WEEKDAY_TIMERS[id]!["timers"] as List<TaskRuntimeTimer>;

                          for (final timer in timers) {
                            addWeekdayTimer(timer as WeekdayTimer);
                          }
                        },
                        child: PlatformElevatedButton(
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
                              addWeekdayTimer(
                                WeekdayTimer(
                                  day: data["weekday"] as int,
                                  startTime: data["startTime"] as TimeOfDay,
                                  endTime: data["endTime"] as TimeOfDay,
                                ),
                              );
                            }
                          },
                        ),
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
