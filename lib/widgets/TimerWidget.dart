import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/timers_service.dart';

import 'WeekdaySelection.dart';

class TimerController extends ChangeNotifier {
  final List<TaskRuntimeTimer> _timers = [];

  UnmodifiableListView<TaskRuntimeTimer> get timers => UnmodifiableListView(_timers);

  void add(final TaskRuntimeTimer timer) {
    // Merge the new timer if a timer for the same weekday already exists
    final existingTimer = _timers.firstWhereOrNull(
        (currentTimer) => currentTimer is WeekdayTimer && timer is WeekdayTimer && currentTimer.day == timer.day);

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

  const TimerWidget({
    this.controller,
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

    if (widget.controller != null) {
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

  List<TaskRuntimeTimer> get sortedTimers => _controller.timers.toList()
    ..sort((a, b) {
      if (a is WeekdayTimer && b is WeekdayTimer) {
        return a.day.compareTo(b.day);
      }

      return 0;
    });

  void addWeekdayTimer(final WeekdayTimer timer) {
    setState(() {
      // Merge the new timer if a timer for the same weekday already exists
      final existingTimer = _controller.timers
          .firstWhereOrNull((currentTimer) => currentTimer is WeekdayTimer && currentTimer.day == timer.day);

      if (existingTimer != null) {
        _controller.remove(existingTimer);
      }

      _controller.add(timer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _controller.timers.length,
      itemBuilder: (_, index) {
        final timer = sortedTimers[index];

        return ListTile(
            title: Text(timer.format(context)),
            trailing: PlatformIconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                _controller.removeAt(index);
              },
            ),
            onTap: timer is WeekdayTimer
                ? () async {
                    final data = await showPlatformDialog(
                      context: context,
                      builder: (_) => WeekdaySelection(
                        weekday: timer.day,
                        startTime: timer.startTime,
                        endTime: timer.endTime,
                        lockWeekday: true,
                      ),
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
                  }
                : null);
      },
    );
  }
}
