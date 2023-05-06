import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/timers_service.dart';

import 'WeekdaySelection.dart';

class TimerController extends ChangeNotifier {
  final List<TaskRuntimeTimer> _timers = [];

  UnmodifiableListView<TaskRuntimeTimer> get timers =>
      UnmodifiableListView(_timers);

  void add(final TaskRuntimeTimer timer) {
    // Merge the new timer if a timer for the same weekday already exists
    final existingTimer = _timers.firstWhereOrNull(
          (currentTimer) {
        if (timer is WeekdayTimer) {
          if (currentTimer is WeekdayTimer && currentTimer.day == timer.day) {
            return true;
          }
        }

        if (timer is DurationTimer) {
          if (currentTimer is DurationTimer) {
            return true;
          }
        }

        return false;
      },
    );

    if (existingTimer != null) {
      _timers.remove(existingTimer);
    }

    _timers.add(timer);
    notifyListeners();
  }

  void remove(final TaskRuntimeTimer timer) {
    _timers.remove(timer);
    notifyListeners();
  }

  void removeAt(final int index) {
    _timers.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _timers.clear();
    notifyListeners();
  }

  void addAll(final List<TaskRuntimeTimer> timers) {
    _timers.addAll(timers);
    notifyListeners();
  }
}

class TimerWidget extends StatefulWidget {
  final TimerController? controller;
  final List<TaskRuntimeTimer> timers;
  final bool allowEdit;
  final ScrollPhysics? physics;

  const TimerWidget({
    this.controller,
    this.timers = const [],
    this.allowEdit = true,
    this.physics,
    Key? key,
  }) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late final TimerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TimerController();

    if (widget.controller == null) {
      _controller.addAll(widget.timers);
    } else {
      widget.controller!.addListener(rebuild);
    }
  }

  void rebuild() {
    // Rebuild the widget when the controller changes
    setState(() {});
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      widget.controller!.addListener(rebuild);
    }

    super.dispose();
  }

  List<TaskRuntimeTimer> get sortedTimers =>
      _controller.timers.toList()
        ..sort((a, b) {
          if (a is WeekdayTimer && b is WeekdayTimer) {
            return a.day.compareTo(b.day);
          }

          return 0;
        });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: widget.physics,
      itemCount: _controller.timers.length,
      itemBuilder: (_, index) {
        final timer = sortedTimers[index];

        return PlatformListTile(
            title: Text(timer.format(context)),
            trailing: widget.allowEdit
                ? PlatformIconButton(
              icon: PlatformWidget(
                material: (_, __) => const Icon(Icons.cancel),
                cupertino: (_, __) => const Icon(CupertinoIcons.clear_thick_circled),
              ),
              onPressed: () {
                _controller.removeAt(index);
              },
            )
                : const SizedBox.shrink(),
            onTap: (widget.allowEdit && timer is WeekdayTimer)
                ? () async {
              final data = await showPlatformDialog(
                context: context,
                builder: (_) =>
                    WeekdaySelection(
                      weekday: timer.day,
                      startTime: timer.startTime,
                      endTime: timer.endTime,
                      lockWeekday: true,
                    ),
              );

              if (data != null) {
                _controller.timers.add(
                  WeekdayTimer(
                    day: data["weekday"] as int,
                    startTime: data["startTime"] as TimeOfDay,
                    endTime: data["endTime"] as TimeOfDay,
                  ),
                );
              }
            }
                : null);
      },
    );
  }
}
