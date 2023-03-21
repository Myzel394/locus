import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/services/manager_service.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();
const KEY = "tasks_settings";

const uuid = Uuid();

class Task extends ChangeNotifier {
  final String id;
  final DateTime createdAt;
  String name;
  String pgpPrivateKey;

  // Deriving the public key from the private key doesn't work with encryption.
  // I guess this is a bug in OpenPGP, but if you know how to fix it, please
  // let me know.
  String pgpPublicKey;
  String nostrPrivateKey;
  Duration frequency;
  List<String> relays = [];

  Task({
    required this.id,
    required this.name,
    required this.frequency,
    required this.pgpPrivateKey,
    required this.pgpPublicKey,
    required this.nostrPrivateKey,
    required this.createdAt,
    this.relays = const [],
  });

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json["id"],
      name: json["name"],
      pgpPrivateKey: json["pgpPrivateKey"],
      pgpPublicKey: json["pgpPublicKey"],
      nostrPrivateKey: json["nostrPrivateKey"],
      frequency: Duration(seconds: json["frequency"]),
      createdAt: DateTime.parse(json["createdAt"]),
      relays: List<String>.from(json["relays"]),
    );
  }

  get taskKey => "Task:$id";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "frequency": frequency.inSeconds,
      "pgpPrivateKey": pgpPrivateKey,
      "pgpPublicKey": pgpPublicKey,
      "nostrPrivateKey": nostrPrivateKey,
      "createdAt": createdAt.toIso8601String(),
      "relays": relays,
    };
  }

  static Future<Task> create(
    String name,
    Duration frequency,
    List<String> relays,
  ) async {
    final keyOptions = KeyOptions()..rsaBits = 4096;
    final options = Options()
      ..keyOptions = keyOptions
      ..name = "Locus"
      ..email = "user@locus.example";
    final keyPair = await OpenPGP.generate(
      options: options,
    );

    final nostrKeyPair = Keychain.generate();

    return Task(
      id: uuid.v4(),
      name: name,
      frequency: frequency,
      pgpPrivateKey: keyPair.privateKey,
      pgpPublicKey: keyPair.publicKey,
      nostrPrivateKey: nostrKeyPair.private,
      relays: relays,
      createdAt: DateTime.now(),
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

  Future<void> stop() async {
    Workmanager().cancelByUniqueName(id);

    await storage.delete(key: taskKey);

    notifyListeners();
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

    return List<Map<String, dynamic>>.from(jsonDecode(tasks))
        .map((e) => Task.fromJson(e))
        .toList();
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

  void update() {
    notifyListeners();
  }
}
