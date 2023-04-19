import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/api/nostr-events.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/services/manager_service.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();
const KEY = "tasks_settings";

enum TaskType {
  share,
  self,
}

enum TaskCreationProgress {
  startsSoon,
  creatingViewKeys,
  creatingSignKeys,
  creatingTask,
}

enum TaskLinkPublishProgress {
  startsSoon,
  encrypting,
  publishing,
  creatingURI,
  done,
}

const uuid = Uuid();

class Task extends ChangeNotifier {
  final String id;
  final DateTime createdAt;
  String name;
  String signPGPPrivateKey;
  String signPGPPublicKey;
  String? viewPGPPrivateKey;
  String viewPGPPublicKey;
  String nostrPrivateKey;
  Duration frequency;
  List<String> relays = [];

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
  });

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
    };
  }

  static Future<Task> create(
    final String name,
    final Duration frequency,
    final List<String> relays, {
    Function(TaskCreationProgress)? onProgress,
  }) async {
    onProgress?.call(TaskCreationProgress.creatingViewKeys);
    final viewKeyPair = await OpenPGP.generate(
      options: (Options()
        ..keyOptions = (KeyOptions()..rsaBits = 4096)
        ..name = "Locus"
        ..email = "user@locus.example"),
    );

    onProgress?.call(TaskCreationProgress.creatingSignKeys);
    final signKeyPair = await OpenPGP.generate(
      options: (Options()
        ..keyOptions = (KeyOptions()..rsaBits = 4096)
        ..name = "Locus"
        ..email = "user@locus.example"),
    );

    onProgress?.call(TaskCreationProgress.creatingTask);
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

  Future<void> update({
    String? name,
    Duration? frequency,
    List<String>? relays,
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

  // Generates a link that can be used to retrieve the task
  // This link is primarily used for sharing the task to the web app
  // Here's the process:
  // 1. Generate a random password
  // 2. Encrypt the task with the password
  // 3. Publish the encrypted task to a random Nostr relay
  // 4. Generate a link that contains the password and the Nostr relay ID
  Future<String> generateLink({
    final void Function(TaskLinkPublishProgress progress)? onProgress,
  }) async {
    onProgress?.call(TaskLinkPublishProgress.startsSoon);

    final data = generateViewKeyContent();
    final message = data.toString();

    onProgress?.call(TaskLinkPublishProgress.encrypting);

    final algorithm = AesCbc.with256bits(
      macAlgorithm: Hmac.sha256(),
    );
    final secretKey = await algorithm.newSecretKey();

    final encrypted = await algorithm.encrypt(
      Uint8List.fromList(const Utf8Encoder().convert(message)),
      secretKey: secretKey,
    );

    onProgress?.call(TaskLinkPublishProgress.publishing);

    final password = base64Url.encode(await secretKey.extractBytes());

    final relay = relays[Random().nextInt(relays.length)];
    final manager = NostrEventsManager(
      relays: [relay],
      privateKey: nostrPrivateKey,
    );
    final nostrMessage = base64Url.encode(encrypted.cipherText);
    final publishedEvent = await manager.publishMessage(nostrMessage);

    onProgress?.call(TaskLinkPublishProgress.creatingURI);

    final parameters = {
      // Password
      "p": password,
      // Key
      "k": nostrPublicKey,
      // ID
      "i": publishedEvent.id,
      // Relay
      "r": relay,
    };

    final fragment = parameters.toString();
    final uri = Uri(
      scheme: "https",
      host: APP_URL_DOMAIN,
      path: "",
      fragment: fragment,
    );

    onProgress?.call(TaskLinkPublishProgress.done);

    return uri.toString();
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
    task.stop();
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
