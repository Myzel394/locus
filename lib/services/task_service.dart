import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/services/manager_service.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import 'timers_service.dart';

const storage = FlutterSecureStorage();
const KEY = "tasks_settings";

enum TaskType {
  share,
  self,
}

enum TaskProgress {
  creationStartsSoon,
  creatingViewKeys,
  creatingSignKeys,
  creatingTask,
}

const uuid = Uuid();

class Task extends ChangeNotifier {
  final String id;
  final DateTime createdAt;
  String name;
  final String signPGPPrivateKey;
  final String signPGPPublicKey;
  String? viewPGPPrivateKey;
  String viewPGPPublicKey;
  final String nostrPrivateKey;
  Duration frequency;
  List<String> relays = [];
  final List<TaskRuntimeTimer> timers;
  bool deleteAfterRun;
  String? _nextRunWorkManagerID;

  Task({
    required this.id,
    required this.name,
    required this.frequency,
    required this.viewPGPPublicKey,
    required this.signPGPPrivateKey,
    required this.signPGPPublicKey,
    required this.createdAt,
    required this.nostrPrivateKey,
    this.viewPGPPrivateKey,
    this.relays = const [],
    this.timers = const [],
    this.deleteAfterRun = false,
    String? nextRunWorkManagerID,
  }) : _nextRunWorkManagerID = nextRunWorkManagerID;

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json["id"],
      name: json["name"],
      viewPGPPrivateKey: json["viewPGPPrivateKey"],
      viewPGPPublicKey: json["viewPGPPublicKey"],
      signPGPPrivateKey: json["signPGPPrivateKey"],
      signPGPPublicKey: json["signPGPPublicKey"],
      nostrPrivateKey: json["nostrPrivateKey"],
      frequency: Duration(seconds: json["frequency"]),
      createdAt: DateTime.parse(json["createdAt"]),
      relays: List<String>.from(json["relays"]),
      deleteAfterRun: json["deleteAfterRun"] == "true",
      timers: List<TaskRuntimeTimer>.from(json["timers"].map((timer) {
        switch (timer["_IDENTIFIER"]) {
          case WeekdayTimer.IDENTIFIER:
            return WeekdayTimer.fromJSON(timer);
          case TimedTimer.IDENTIFIER:
            return TimedTimer.fromJSON(timer);
          default:
            throw Exception("Unknown timer type");
        }
      })),
      nextRunWorkManagerID: json["nextRunWorkManagerID"],
    );
  }

  String get taskKey => "Task:$id";

  String get nostrPublicKey => Keychain(nostrPrivateKey).public;

  TaskType get type {
    if (viewPGPPrivateKey == null) {
      return TaskType.share;
    }

    return TaskType.self;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "frequency": frequency.inSeconds,
      "viewPGPPrivateKey": viewPGPPrivateKey,
      "viewPGPPublicKey": viewPGPPublicKey,
      "signPGPPrivateKey": signPGPPrivateKey,
      "signPGPPublicKey": signPGPPublicKey,
      "nostrPrivateKey": nostrPrivateKey,
      "createdAt": createdAt.toIso8601String(),
      "relays": relays,
      "timers": timers.map((timer) => timer.toJSON()).toList(),
      "deleteAfterRun": deleteAfterRun.toString(),
      "nextRunWorkManagerID": _nextRunWorkManagerID,
    };
  }

  static Future<Task> create(
    final String name,
    final Duration frequency,
    final List<String> relays, {
    Function(TaskProgress)? onProgress,
    List<TaskRuntimeTimer> timers = const [],
    bool deleteAfterRun = false,
  }) async {
    onProgress?.call(TaskProgress.creatingViewKeys);
    final viewKeyPair = await OpenPGP.generate(
      options: (Options()
        ..keyOptions = (KeyOptions()..rsaBits = 4096)
        ..name = "Locus"
        ..email = "user@locus.example"),
    );

    onProgress?.call(TaskProgress.creatingSignKeys);
    final signKeyPair = await OpenPGP.generate(
      options: (Options()
        ..keyOptions = (KeyOptions()..rsaBits = 4096)
        ..name = "Locus"
        ..email = "user@locus.example"),
    );

    onProgress?.call(TaskProgress.creatingTask);
    return Task(
      id: uuid.v4(),
      name: name,
      frequency: frequency,
      viewPGPPrivateKey: viewKeyPair.privateKey,
      viewPGPPublicKey: viewKeyPair.publicKey,
      signPGPPrivateKey: signKeyPair.privateKey,
      signPGPPublicKey: signKeyPair.publicKey,
      nostrPrivateKey: Keychain.generate().private,
      relays: relays,
      createdAt: DateTime.now(),
      timers: timers,
      deleteAfterRun: deleteAfterRun,
    );
  }

  Future<bool> isRunning() async {
    final status = await getStatus();

    return status != null;
  }

  Future<Map<String, dynamic>?> getStatus() async {
    final rawData = await storage.read(key: taskKey);

    if (rawData == null || rawData == "") {
      return null;
    }

    final data = jsonDecode(rawData);

    return {
      ...data,
      "runFrequency": Duration(seconds: data["runFrequency"]),
      "startedAt": DateTime.parse(data["startedAt"]),
    };
  }

  DateTime? nextStartDate({final DateTime? date}) => findNextStartDate(timers, startDate: date);

  DateTime? nextEndDate() => findNextEndDate(timers);

  bool shouldRun() {
    final now = DateTime.now();

    return timers.any((timer) => timer.shouldRun(now));
  }

  bool isInfinite() => timers.any((timer) => timer.isInfinite());

  void _stopSchedule() {
    if (_nextRunWorkManagerID != null) {
      Workmanager().cancelByUniqueName(_nextRunWorkManagerID!);
      _nextRunWorkManagerID = null;
    }
  }

  // Returns the delay until the next expected run of the task. This is used to schedule the task to run at the next
  // expected time. If the task is not scheduled to run, this will return null.
  // If the task is scheduled to run in the past, this will return `Duration.zero`.
  Duration _getScheduleDelay(final DateTime date) {
    final initialDelay = date.difference(DateTime.now());

    return initialDelay > Duration.zero ? initialDelay : Duration.zero;
  }

  // Starts the task. This will schedule the task to run at the next expected time.
  // You can find out when the task will run by calling `nextStartDate`.
  // Returns the next start date of the task OR `null` if the task is not scheduled to run.
  DateTime? startSchedule({final bool startNowIfNextRunIsUnknown = false, final DateTime? startDate}) {
    final now = startDate ?? DateTime.now();
    DateTime? nextStartDate = this.nextStartDate(date: now);

    if (nextStartDate == null) {
      if (startNowIfNextRunIsUnknown) {
        nextStartDate = now;
      } else {
        return null;
      }
    }

    final initialDelay = _getScheduleDelay(nextStartDate);

    _stopSchedule();

    _nextRunWorkManagerID = uuid.v4();

    Workmanager().registerOneOffTask(
      _nextRunWorkManagerID!,
      TASK_SCHEDULE_KEY,
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        "taskID": id,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    return nextStartDate;
  }

  // Starts the schedule tomorrow night. This should be used when the user manually stops the execution of the task, but
  // still wants the task to run at the next expected time. If `startSchedule` is used, the schedule might start,
  // immediately, which is not what the user wants.
  // Returns the next date the task will run OR `null` if the task is not scheduled to run.
  DateTime? startScheduleTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0, 0);

    return startSchedule(startDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0, 0));
  }

  // Starts the actual execution of the task. You should only call this if either the user wants to manually start the
  // task or if the task is scheduled to run.
  Future<void> startExecutionImmediately() async {
    _stopSchedule();

    Workmanager().registerPeriodicTask(
      id,
      TASK_EXECUTION_KEY,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        "taskID": id,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    await storage.write(
      key: taskKey,
      value: jsonEncode({
        "runFrequency": frequency.inSeconds,
        "startedAt": DateTime.now().toIso8601String(),
      }),
    );

    notifyListeners();
  }

  // Stops the actual execution of the task. You should only call this if either the user wants to manually stop the
  // task or if the task is scheduled to stop.
  Future<void> stopExecutionImmediately() async {
    Workmanager().cancelByUniqueName(id);

    await storage.delete(key: taskKey);

    notifyListeners();
  }

  Future<void> update({
    String? name,
    Duration? frequency,
    List<String>? relays,
    List<TaskRuntimeTimer>? timers,
    bool? deleteAfterRun,
  }) async {
    if (name != null) {
      this.name = name;
    }

    if (frequency != null) {
      this.frequency = frequency;
    }

    if (relays != null) {
      this.relays = relays;
    }

    if (timers != null) {
      this.timers.clear();
      this.timers.addAll(timers);
    }

    if (deleteAfterRun != null) {
      this.deleteAfterRun = deleteAfterRun;
    }

    notifyListeners();
  }

  String generateViewKeyContent() {
    return jsonEncode({
      "signPublicKey": signPGPPublicKey,
      "viewPrivateKey": viewPGPPrivateKey,
      "nostrPublicKey": nostrPublicKey,
      "relays": relays,
    });
  }
}

class TaskService extends ChangeNotifier {
  List<Task> _tasks;

  TaskService(List<Task> tasks) : _tasks = tasks;

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  static Future<List<Task>> get() async {
    final tasks = await storage.read(key: KEY);

    if (tasks == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(jsonDecode(tasks)).map((e) => Task.fromJson(e)).toList();
  }

  static Future<Task> getTask(final String taskID) async {
    final tasks = await get();

    return tasks.firstWhere((task) => task.id == taskID);
  }

  static Future<TaskService> restore() async {
    final tasks = await get();

    return TaskService(tasks);
  }

  Future<void> save() async {
    final data = jsonEncode(tasks.map((e) => e.toJson()).toList());

    await storage.write(key: KEY, value: data);
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

  void update(final Task task) {
    final index = _tasks.indexWhere((element) => element.id == task.id);

    _tasks[index] = task;

    notifyListeners();
    save();
  }
}

DateTime? findNextStartDate(final List<TaskRuntimeTimer> timers, {final DateTime? startDate}) {
  final now = startDate ?? DateTime.now();

  final nextDates = List<DateTime>.from(timers.map((timer) => timer.nextStartDate(now)).where((date) => date != null));

  if (nextDates.isEmpty) {
    return null;
  }

  // Find earliest date
  return nextDates.reduce((value, element) => value.isBefore(element) ? value : element);
}

DateTime? findNextEndDate(final List<TaskRuntimeTimer> timers, {final DateTime? startDate}) {
  final now = startDate ?? DateTime.now();

  DateTime? date;

  for (final timer in timers) {
    final timerDate = timer.nextEndDate(now);

    if (timer is WeekdayTimer) {
      if (timer.day < now.weekday) {
        continue;
      }
    }

    if (timerDate == null) {
      continue;
    }

    if (date == null) {
      date = timerDate;
      continue;
    }

    if (timer is WeekdayTimer) {
      if (timerDate.isAfter(date)) {
        date = timerDate;
      }

      continue;
    } else {
      if (timerDate.isBefore(date)) {
        date = timerDate;
      }

      continue;
    }
  }

  return date;
}
