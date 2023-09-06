import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/models/log.dart';
import 'package:locus/services/log_service.dart' hide KEY, storage;
import 'package:locus/services/task_service/task.dart';
import 'package:locus/services/timers_service.dart';

import 'constants.dart';

class TaskService extends ChangeNotifier {
  final List<Task> _tasks;

  TaskService({
    required List<Task> tasks,
  }) : _tasks = tasks;

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  static Future<TaskService> restore() async {
    final rawTasks = await storage.read(key: KEY);

    if (rawTasks == null) {
      return TaskService(
        tasks: [],
      );
    }

    return TaskService(
      tasks: List<Task>.from(
        List<Map<String, dynamic>>.from(
          jsonDecode(rawTasks),
        ).map(
          Task.fromJSON,
        ),
      ).toList(),
    );
  }

  Future<void> save() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Task Service",
      "Saving tasks...",
    );

    // await all `toJson` functions
    final data = await Future.wait<Map<String, dynamic>>(
      _tasks.map(
        (task) => task.toJSON(),
      ),
    );

    await storage.write(key: KEY, value: jsonEncode(data));
    FlutterLogs.logInfo(
      LOG_TAG,
      "Task Service",
      "Saved tasks successfully!",
    );
  }

  Task getByID(final String id) {
    return _tasks.firstWhere((task) => task.id == id);
  }

  void add(Task task) {
    _tasks.add(task);

    notifyListeners();
  }

  void remove(final Task task) {
    task.stopExecutionImmediately();
    _tasks.remove(task);

    notifyListeners();
  }

  void forceListenerUpdate() {
    notifyListeners();
  }

  void update(final Task task) {
    final index = _tasks.indexWhere((element) => element.id == task.id);

    _tasks[index] = task;

    notifyListeners();
    save();
  }

  // Does a general check up state of the task.
  // Checks if the task should be running / should be deleted etc.
  Future<void> checkup(final LogService logService) async {
    FlutterLogs.logInfo(LOG_TAG, "Task Service", "Doing checkup...");

    final tasksToRemove = <Task>{};

    for (final task in tasks) {
      final isRunning = await task.isRunning();
      final shouldRun = await task.shouldRunNow();
      final isQuickShare = task.deleteAfterRun &&
          task.timers.length == 1 &&
          task.timers[0] is DurationTimer;

      if (isQuickShare) {
        final durationTimer = task.timers[0] as DurationTimer;

        if (durationTimer.startDate != null && !shouldRun) {
          FlutterLogs.logInfo(LOG_TAG, "Task Service", "Removing task.");

          tasksToRemove.add(task);
        }
      } else {
        if ((!task.isInfinite() && task.nextEndDate() == null)) {
          FlutterLogs.logInfo(LOG_TAG, "Task Service", "Removing task.");

          tasksToRemove.add(task);
        } else if (!shouldRun && isRunning) {
          FlutterLogs.logInfo(LOG_TAG, "Task Service", "Stopping task.");
          await task.stopExecutionImmediately();

          await logService.addLog(
            Log.taskStatusChanged(
              initiator: LogInitiator.system,
              taskId: task.id,
              taskName: task.name,
              active: false,
            ),
          );
        } else if (shouldRun && !isRunning) {
          FlutterLogs.logInfo(LOG_TAG, "Task Service", "Start task.");
          await task.startExecutionImmediately();

          await logService.addLog(
            Log.taskStatusChanged(
              initiator: LogInitiator.system,
              taskId: task.id,
              taskName: task.name,
              active: true,
            ),
          );
        }
      }
    }

    for (final task in tasksToRemove) {
      remove(task);
    }

    await save();

    FlutterLogs.logInfo(LOG_TAG, "Task Service", "Checkup done.");
  }

  Stream<Task> getRunningTasks() async* {
    for (final task in tasks) {
      if (await task.isRunning()) {
        yield task;
      }
    }
  }
}
