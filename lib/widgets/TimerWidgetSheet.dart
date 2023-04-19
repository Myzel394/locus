import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/timers.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/LongPressPopup.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:locus/widgets/WeekdaySelection.dart';

class TimerWidgetSheet extends StatefulWidget {
  final TimerController controller;

  const TimerWidgetSheet({
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<TimerWidgetSheet> createState() => _TimerWidgetSheetState();
}

class _TimerWidgetSheetState extends State<TimerWidgetSheet> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(rebuild);
  }

  void rebuild() {
    setState(() {});
  }


  @override
  void dispose() {
    widget.controller.removeListener(rebuild);

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.6,
      maxChildSize: 0.6,
      expand: false,
      builder: (_, __) =>
          ModalSheet(
            child: Column(
              children: <Widget>[
                Text("Timers", style: getTitleTextStyle(context)),
                const SizedBox(height: MEDIUM_SPACE),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.controller.timers.isNotEmpty) ...[
                        Expanded(
                          child: TimerWidget(
                            controller: widget.controller,
                          ),
                        ),
                        const SizedBox(height: SMALL_SPACE),
                        // Month, date and time
                        Text(
                          "Next execution will start at ${DateFormat('MMMM d, HH:mm').format(findNextStartDate(widget
                              .controller.timers)!)}",
                        ),
                        if (widget.controller.timers
                            .any((timer) => timer.isInfinite())) ...[
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
                                    (entry) =>
                                    PopupMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value["name"] as String),
                                    ),
                              ),
                            ),
                            onSelected: (final dynamic id) {
                              widget.controller.clear();

                              final timers = WEEKDAY_TIMERS[id]!["timers"]
                              as List<TaskRuntimeTimer>;
                              widget.controller.addAll(timers);
                            },
                            child: PlatformTextButton(
                              child: Text("Add Weekday"),
                              material: (_, __) =>
                                  MaterialTextButtonData(
                                    icon: Icon(Icons.date_range_rounded),
                                  ),
                              onPressed: () async {
                                final data = await showPlatformDialog(
                                  context: context,
                                  builder: (_) => WeekdaySelection(),
                                );

                                if (data != null) {
                                  widget.controller.add(
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
                      if (widget.controller.timers.isNotEmpty) ...[
                        const SizedBox(height: MEDIUM_SPACE),
                        PlatformElevatedButton(
                          child: Text("Save"),
                          material: (_, __) =>
                              MaterialElevatedButtonData(
                                icon: Icon(Icons.check),
                              ),
                          onPressed: () {
                            Navigator.of(context).pop(widget.controller.timers);
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
