import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/api/nostr-events.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service/task_cryptography.dart';
import 'package:locus/services/task_service/task_publisher.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/cryptography/utils.dart';
import 'package:nostr/nostr.dart';
import 'package:uuid/uuid.dart';

import '../timers_service.dart';
import 'constants.dart';
import 'helpers.dart';
import 'mixins.dart';

const uuid = Uuid();

class Task extends ChangeNotifier with LocationBase {
  final String id;
  final DateTime createdAt;

  // Password for symmetric encryption of the locations
  final SecretKey _encryptionPassword;

  final String nostrPrivateKey;
  @override
  final List<String> relays;
  final List<TaskRuntimeTimer> timers;
  String name;
  bool deleteAfterRun;

  // List of location points that need to be published yet
  // To avoid infinite retries, we only try to publish each location point a
  // certain amount of time
  // This ´Map` stores the amount of tries for each location point
  late final Map<LocationPointService, int> outstandingLocations;

  Task({
    required this.id,
    required this.name,
    required this.createdAt,
    required SecretKey encryptionPassword,
    required this.nostrPrivateKey,
    required this.relays,
    required this.timers,
    Map<LocationPointService, int>? outstandingLocations,
    this.deleteAfterRun = false,
  })  : _encryptionPassword = encryptionPassword,
        outstandingLocations = outstandingLocations ?? {};

  factory Task.fromJSON(Map<String, dynamic> json) {
    return Task(
      id: json["id"],
      name: json["name"],
      encryptionPassword: SecretKey(List<int>.from(json["encryptionPassword"])),
      nostrPrivateKey: json["nostrPrivateKey"],
      createdAt: DateTime.parse(json["createdAt"]),
      relays: List<String>.from(json["relays"]),
      deleteAfterRun: json["deleteAfterRun"] == "true",
      timers: List<TaskRuntimeTimer>.from(json["timers"].map((timer) {
        switch (timer["_IDENTIFIER"]) {
          case WeekdayTimer.IDENTIFIER:
            return WeekdayTimer.fromJSON(timer);
          case DurationTimer.IDENTIFIER:
            return DurationTimer.fromJSON(timer);
          default:
            throw Exception("Unknown timer type");
        }
      })),
      outstandingLocations:
          Map<String, int>.from(json["outstandingLocations"] ?? {})
              .map<LocationPointService, int>(
        (rawLocationData, tries) => MapEntry(
          LocationPointService.fromJSON(jsonDecode(rawLocationData)),
          tries,
        ),
      ),
    );
  }

  String get taskKey => "Task:$id";

  String get scheduleKey => "Task:$id:Schedule";

  @override
  String get nostrPublicKey => Keychain(nostrPrivateKey).public;

  Future<Map<String, dynamic>> toJSON() async {
    return {
      "id": id,
      "name": name,
      "encryptionPassword": await _encryptionPassword.extractBytes(),
      "nostrPrivateKey": nostrPrivateKey,
      "createdAt": createdAt.toIso8601String(),
      "relays": relays,
      "timers": timers.map((timer) => timer.toJSON()).toList(),
      "deleteAfterRun": deleteAfterRun.toString(),
      "outstandingLocations": outstandingLocations.map(
        (locationData, tries) => MapEntry(
          locationData.toJSON(),
          tries,
        ),
      ),
    };
  }

  static Future<Task> create(
    final String name,
    final List<String> relays, {
    List<TaskRuntimeTimer> timers = const [],
    bool deleteAfterRun = false,
  }) async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Task",
      "Creating new task.",
    );

    final secretKey = await generateSecretKey();

    return Task(
      id: uuid.v4(),
      name: name,
      encryptionPassword: secretKey,
      nostrPrivateKey: Keychain.generate().private,
      relays: relays,
      createdAt: DateTime.now(),
      timers: timers,
      deleteAfterRun: deleteAfterRun,
    );
  }

  TaskCryptography get cryptography =>
      TaskCryptography(this, _encryptionPassword);

  TaskPublisher get publisher => TaskPublisher(this);

  Future<bool> isRunning() async {
    final status = await getExecutionStatus();

    return status != null;
  }

  Future<Map<String, dynamic>?> getExecutionStatus() async {
    final rawData = await storage.read(key: taskKey);

    if (rawData == null || rawData == "") {
      return null;
    }

    final data = jsonDecode(rawData);

    return {
      ...data,
      "startedAt": DateTime.parse(data["startedAt"]),
    };
  }

  Future<Map<String, dynamic>?> getScheduleStatus() async {
    final rawData = await storage.read(key: scheduleKey);

    if (rawData == null || rawData == "") {
      return null;
    }

    final data = jsonDecode(rawData);

    return {
      ...data,
      "startedAt": DateTime.parse(data["startedAt"]),
      "startsAt": DateTime.parse(data["startsAt"]),
    };
  }

  DateTime? nextStartDate({final DateTime? date}) =>
      findNextStartDate(timers, startDate: date);

  DateTime? nextEndDate() => findNextEndDate(timers);

  bool isInfinite() =>
      timers.any((timer) => timer.isInfinite()) || timers.isEmpty;

  Future<bool> shouldRunNow() async {
    final executionStatus = await getExecutionStatus();

    if (timers.isEmpty) {
      return executionStatus != null;
    }

    final shouldRunNowBasedOnTimers =
        timers.any((timer) => timer.shouldRun(DateTime.now()));

    if (shouldRunNowBasedOnTimers) {
      return true;
    }

    if (executionStatus != null) {
      final earliestNextRun = nextStartDate(date: executionStatus["startedAt"]);

      if (earliestNextRun == null) {
        return false;
      }

      return (executionStatus["startedAt"] as DateTime)
          .isBefore(earliestNextRun);
    }

    return false;
  }

  Future<void> stopSchedule() async {
    await storage.delete(key: scheduleKey);
  }

  // Starts the task. This will schedule the task to run at the next expected time.
  // You can find out when the task will run by calling `nextStartDate`.
  // Returns the next start date of the task OR `null` if the task is not scheduled to run.
  Future<DateTime?> startSchedule({
    final bool startNowIfNextRunIsUnknown = false,
    final DateTime? startDate,
  }) async {
    final now = startDate ?? DateTime.now();
    DateTime? nextStartDate = this.nextStartDate(date: now);

    if (nextStartDate == null) {
      if (startNowIfNextRunIsUnknown) {
        nextStartDate = now;
      } else {
        return null;
      }
    }

    final isNow = nextStartDate.subtract(SAME_TIME_THRESHOLD).isBefore(now);

    if (isNow) {
      await startExecutionImmediately();
    } else {
      await stopSchedule();

      await storage.write(
        key: scheduleKey,
        value: jsonEncode({
          "startedAt": DateTime.now().toIso8601String(),
          "startsAt": nextStartDate.toIso8601String(),
        }),
      );
    }

    return nextStartDate;
  }

  // Starts the schedule tomorrow morning. This should be used when the user manually stops the execution of the task, but
  // still wants the task to run at the next expected time. If `startSchedule` is used, the schedule might start,
  // immediately, which is not what the user wants.
  // Returns the next date the task will run OR `null` if the task is not scheduled to run.
  Future<DateTime?> startScheduleTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextDate =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0, 0);

    return startSchedule(startDate: nextDate);
  }

  // Starts the actual execution of the task. You should only call this if either the user wants to manually start the
  // task or if the task is scheduled to run.
  Future<void> startExecutionImmediately() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Task $id",
      "Starting execution of task...",
    );

    await storage.write(
      key: taskKey,
      value: jsonEncode({
        "startedAt": DateTime.now().toIso8601String(),
      }),
    );

    await stopSchedule();

    for (final timer in timers) {
      timer.executionStarted();
    }

    notifyListeners();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Task $id",
      "Execution of task started!",
    );
  }

  // Stops the actual execution of the task. You should only call this if either the user wants to manually stop the
  // task or if the task is scheduled to stop.
  Future<void> stopExecutionImmediately() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Task $id",
      "Stopping execution of task...",
    );

    await storage.delete(key: taskKey);

    for (final timer in timers) {
      timer.executionStopped();
    }

    notifyListeners();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Task $id",
      "Execution of task stopped!",
    );
  }

  Future<void> update({
    String? name,
    Iterable<String>? relays,
    Iterable<TaskRuntimeTimer>? timers,
    bool? deleteAfterRun,
  }) async {
    if (name != null) {
      this.name = name;
    }

    if (relays != null) {
      // We need to copy the relays as they somehow also get cleared when `this.relays.clear` is called.
      final newRelays = [...relays];
      this.relays.clear();
      this.relays.addAll(newRelays);
    }

    if (timers != null) {
      final newTimers = [...timers];
      this.timers.clear();
      this.timers.addAll(newTimers);
    }

    if (deleteAfterRun != null) {
      this.deleteAfterRun = deleteAfterRun;
    }

    notifyListeners();
  }

  bool get isQuickShare => isInfiniteQuickShare || isFiniteQuickShare;

  bool get isInfiniteQuickShare => deleteAfterRun && timers.isEmpty;

  bool get isFiniteQuickShare =>
      deleteAfterRun && timers.length == 1 && timers[0] is DurationTimer;

  @override
  void dispose() {
    _encryptionPassword.destroy();

    super.dispose();
  }

  TaskView createTaskView_onlyForTesting() => TaskView(
        encryptionPassword: _encryptionPassword,
        nostrPublicKey: nostrPublicKey,
        color: Colors.red,
        name: name,
        relays: relays,
        id: id,
      );
}
