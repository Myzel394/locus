import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/services/task_service.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';

const storage = FlutterSecureStorage();
const KEY = "view_service";

class ViewServiceLinkParameters {
  final List<int> password;
  final String nostrPublicKey;
  final String nostrMessageID;
  final String relay;
  final List<int> initialVector;
  final List<int> mac;

  ViewServiceLinkParameters({
    required this.password,
    required this.nostrPublicKey,
    required this.nostrMessageID,
    required this.relay,
    required this.initialVector,
    required this.mac,
  });
}

class TaskView extends ChangeNotifier {
  final String signPublicKey;
  final String viewPrivateKey;
  final String nostrPublicKey;
  final List<String> relays;
  String? name;

  TaskView({
    required this.signPublicKey,
    required this.viewPrivateKey,
    required this.nostrPublicKey,
    required this.relays,
    this.name,
  });

  static ViewServiceLinkParameters parseLink(final String url) {
    final uri = Uri.parse(url);
    final fragment = uri.fragment;

    final rawParameters = const Utf8Decoder().convert(base64Url.decode(fragment));
    final parameters = jsonDecode(rawParameters);

    return ViewServiceLinkParameters(
        password: List<int>.from(parameters['p']),
        nostrPublicKey: parameters['k'],
        nostrMessageID: parameters['i'],
        relay: parameters['r'],
        initialVector: List<int>.from(parameters['v']),
        mac: List<int>.from(parameters["m"]));
  }

  static TaskView fromJSON(final Map<String, dynamic> json) {
    return TaskView(
      signPublicKey: json["signPublicKey"],
      viewPrivateKey: json["viewPrivateKey"],
      nostrPublicKey: json["nostrPublicKey"],
      relays: List<String>.from(json["relays"]),
      name: json["name"],
    );
  }

  static Future<TaskView> fetchFromNostr(final ViewServiceLinkParameters parameters) async {
    final completer = Completer<TaskView>();

    final request = Request(generate64RandomHexChars(), [
      Filter(
        ids: [parameters.nostrMessageID],
      ),
    ]);

    final socket = await WebSocket.connect(
      parameters.relay,
    );

    bool hasEventReceived = false;

    socket.add(request.serialize());

    socket.listen((rawEvent) async {
      final event = Message.deserialize(rawEvent);

      switch (event.type) {
        case "EVENT":
          hasEventReceived = true;
          try {
            final encryptedMessage = List<int>.from(jsonDecode(event.message.content));

            final algorithm = AesCbc.with256bits(
              macAlgorithm: Hmac.sha256(),
            );
            final secretBox = SecretBox(
              encryptedMessage,
              nonce: parameters.initialVector,
              mac: Mac(parameters.mac),
            );
            final secretKey = SecretKey(parameters.password);
            final rawMessage = await algorithm.decryptString(secretBox, secretKey: secretKey);

            final data = jsonDecode(rawMessage);

            if (data["nostrPublicKey"] != parameters.nostrPublicKey) {
              completer.completeError("Invalid Nostr public key");
              return;
            }

            completer.complete(TaskView(
              signPublicKey: data['signPublicKey'],
              viewPrivateKey: data['viewPrivateKey'],
              nostrPublicKey: data['nostrPublicKey'],
              relays: List<String>.from(data['relays']),
            ));
          } catch (error) {
            completer.completeError(error);
          }
          break;
        case "EOSE":
          socket.close();

          if (!hasEventReceived) {
            completer.completeError("No event received");
          }

          break;
      }
    });

    return completer.future;
  }

  void update({
    final String? name,
  }) {
    if (name != null) {
      this.name = name;
    }

    notifyListeners();
  }

  Map<String, dynamic> toJSON() {
    return {
      "signPublicKey": signPublicKey,
      "viewPrivateKey": viewPrivateKey,
      "nostrPublicKey": nostrPublicKey,
      "relays": relays,
      "name": name,
    };
  }

  Future<String?> validate({
    required final TaskService taskService,
    required final ViewService viewService,
  }) async {
    if (relays.isEmpty) {
      return "No relays are present in the task.";
    }

    try {
      await OpenPGP.getPublicKeyMetadata(signPublicKey);
      await OpenPGP.getPrivateKeyMetadata(viewPrivateKey);
    } catch (error) {
      return "Invalid keys provided.";
    }

    final sameTask = taskService.tasks.firstWhereOrNull((element) =>
        element.signPGPPublicKey == signPublicKey ||
        element.nostrPublicKey == nostrPublicKey ||
        element.viewPGPPrivateKey == viewPrivateKey);

    if (sameTask != null) {
      return "This is a task from you (name: ${sameTask.name}).";
    }

    final sameView = viewService.views.firstWhereOrNull((element) =>
        element.signPublicKey == signPublicKey ||
        element.nostrPublicKey == nostrPublicKey ||
        element.viewPrivateKey == viewPrivateKey);

    if (sameView != null) {
      return "This is a view from you (name: ${sameView.name}).";
    }

    return null;
  }
}

class ViewService extends ChangeNotifier {
  final List<TaskView> _views;

  ViewService({
    required List<TaskView> views,
  }) : _views = views;

  UnmodifiableListView<TaskView> get views => UnmodifiableListView(_views);

  static Future<ViewService> restore() async {
    final rawViews = await storage.read(key: KEY);

    if (rawViews == null) {
      return ViewService(
        views: [],
      );
    }

    return ViewService(
      views: List<TaskView>.from(
        List<Map<String, dynamic>>.from(
          jsonDecode(rawViews),
        ).map(
          TaskView.fromJSON,
        ),
      ).toList(),
    );
  }

  Future<void> save() async {
    final data = jsonEncode(
      List<Map<String, dynamic>>.from(
        _views.map(
          (view) => view.toJSON(),
        ),
      ),
    );

    await storage.write(key: KEY, value: data);
  }

  void add(final TaskView view) {
    _views.add(view);

    notifyListeners();
  }

  void remove(final TaskView view) {
    _views.remove(view);

    notifyListeners();
  }
}
