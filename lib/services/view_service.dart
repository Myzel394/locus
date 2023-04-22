import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:nostr/nostr.dart';

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

class TaskView {
  final String signPublicKey;
  final String viewPrivateKey;
  final String nostrPublicKey;
  final List<String> relays;

  const TaskView({
    required this.signPublicKey,
    required this.viewPrivateKey,
    required this.nostrPublicKey,
    required this.relays,
  });

  static ViewServiceLinkParameters parseLink(final String url) {
    final uri = Uri.parse(url);
    final fragment = uri.fragment;

    final rawParameters = Utf8Decoder().convert(base64Url.decode(fragment));
    final parameters = jsonDecode(rawParameters);

    return ViewServiceLinkParameters(
        password: List<int>.from(parameters['p']),
        nostrPublicKey: parameters['k'],
        nostrMessageID: parameters['i'],
        relay: parameters['r'],
        initialVector: List<int>.from(parameters['v']),
        mac: List<int>.from(parameters["m"]));
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
}
