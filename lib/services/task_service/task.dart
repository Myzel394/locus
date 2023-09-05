import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/api/nostr-events.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/utils/cryptography/encrypt.dart';
import 'package:locus/utils/cryptography/utils.dart';
import 'package:locus/utils/location/index.dart';
import 'package:nostr/nostr.dart';
import 'package:uuid/uuid.dart';

import '../../api/get-locations.dart' as get_locations_api;
import '../timers_service.dart';
import 'constants.dart';
import 'enums.dart';
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

  Task({
    required this.id,
    required this.name,
    required this.createdAt,
    required SecretKey encryptionPassword,
    required this.nostrPrivateKey,
    required this.relays,
    required this.timers,
    this.deleteAfterRun = false,
  }) : _encryptionPassword = encryptionPassword;

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

  Future<String> generateViewKeyContent() async {
    return jsonEncode({
      "encryptionPassword": await _encryptionPassword.extractBytes(),
      "nostrPublicKey": nostrPublicKey,
      "relays": relays,
    });
  }

  // Generates a link that can be used to retrieve the task
  // This link is primarily used for sharing the task to the web app
  // Here's the process:
  // 1. Generate a random password
  // 2. Encrypt the task with the password
  // 3. Publish the encrypted task to a random Nostr relay
  // 4. Generate a link that contains the password and the Nostr relay ID
  Future<String> generateLink(
    final String host, {
    final void Function(TaskLinkPublishProgress progress)? onProgress,
  }) async {
    onProgress?.call(TaskLinkPublishProgress.startsSoon);

    final message = await generateViewKeyContent();

    onProgress?.call(TaskLinkPublishProgress.encrypting);

    final passwordSecretKey = await generateSecretKey();
    final password = await passwordSecretKey.extractBytes();
    final cipherText = await encryptUsingAES(message, passwordSecretKey);

    onProgress?.call(TaskLinkPublishProgress.publishing);

    final manager = NostrEventsManager(
      relays: relays,
      privateKey: nostrPrivateKey,
    );
    final publishedEvent = await manager.publishMessage(cipherText, kind: 1001);

    onProgress?.call(TaskLinkPublishProgress.creatingURI);

    final parameters = {
      // Password
      "p": password,
      // Key
      "k": nostrPublicKey,
      // ID
      "i": publishedEvent.id,
      // Relay
      "r": relays,
    };

    final fragment = base64Url.encode(jsonEncode(parameters).codeUnits);
    final uri = Uri(
      scheme: "https",
      host: host,
      path: "/",
      fragment: fragment,
    );

    onProgress?.call(TaskLinkPublishProgress.done);
    passwordSecretKey.destroy();

    return uri.toString();
  }

  Future<void> publishLocation(
    final LocationPointService locationPoint,
  ) async {
    final eventManager = NostrEventsManager.fromTask(this);

    final rawMessage = jsonEncode(locationPoint.toJSON());
    final message = await encryptUsingAES(rawMessage, _encryptionPassword);

    await eventManager.publishMessage(message);
  }

  Future<LocationPointService> publishCurrentPosition() async {
    final position = await getCurrentPosition();
    final locationPoint = await LocationPointService.fromPosition(position);

    await publishLocation(locationPoint);

    return locationPoint;
  }

  @override
  VoidCallback getLocations({
    required void Function(LocationPointService) onLocationFetched,
    required void Function() onEnd,
    int? limit,
    DateTime? from,
  }) =>
      get_locations_api.getLocations(
        encryptionPassword: _encryptionPassword,
        nostrPublicKey: nostrPublicKey,
        relays: relays,
        onLocationFetched: onLocationFetched,
        onEnd: onEnd,
        from: from,
        limit: limit,
      );

  @override
  void dispose() {
    _encryptionPassword.destroy();

    super.dispose();
  }
}
