import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/services/manager_service.dart';
import 'package:openpgp/openpgp.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();
const KEY = "tasks_settings";

const uuid = Uuid();

class Task {
  final String id;
  String name;
  String privateKey;
  Duration frequency;

  Task({
    required this.id,
    required this.name,
    required this.frequency,
    required this.privateKey,
  });

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json["id"],
      name: json["name"],
      privateKey: json["privateKey"],
      frequency: Duration(seconds: json["frequency"]),
    );
  }

  get taskKey => "Task:$id";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "frequency": frequency.inSeconds,
      "privateKey": privateKey,
    };
  }

  static Future<Task> create(
    String name,
    Duration frequency,
  ) async {
    final keyPair = await OpenPGP.generate(
      options: Options()..keyOptions = (KeyOptions()..rsaBits = 2048),
    );

    return Task(
      id: uuid.v4(),
      name: name,
      frequency: frequency,
      privateKey: keyPair.privateKey,
    );
  }

  Future<bool> isRunning() async {
    final value = await storage.read(key: taskKey);

    if (value == null) {
      return false;
    }

    final data = jsonDecode(value);

    return data["runFrequency"] == frequency.inSeconds;
  }

  Future<void> start() async {
    Workmanager().registerPeriodicTask(
      id,
      WORKMANAGER_KEY,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    await storage.write(
      key: taskKey,
      value: jsonEncode({
        "runFrequency": frequency.inSeconds,
        "startedAt": DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> stop() async {
    Workmanager().cancelByUniqueName(id);

    await storage.delete(key: taskKey);
  }
}

class TaskService {
  List<Task> tasks;

  TaskService(this.tasks);

  static Future<List<Task>> get() async {
    final tasks = await storage.read(key: KEY);

    if (tasks == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(jsonDecode(tasks))
        .map((e) => Task.fromJson(e))
        .toList();
  }

  static Future<TaskService> restore() async {
    final tasks = await get();

    return TaskService(tasks);
  }

  Future<void> save() async {
    final data = jsonEncode(tasks.map((e) => e.toJson()).toList());

    await storage.write(key: KEY, value: data);
  }
}
