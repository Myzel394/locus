import 'dart:io';
import 'dart:ui';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:nostr/nostr.dart';

import '../constants/values.dart';

class NostrFetch {
  final List<String> relays;
  final Request request;

  NostrFetch({
    required this.relays,
    required this.request,
  });

  Future<WebSocket> _connectToRelay({
    required final String relay,
    required final Future<void> Function(Message message, String relay) onEvent,
    final void Function()? onEnd,
    final void Function()? onEmptyEnd,
  }) async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket $relay",
      "Creating socket...",
    );

    final List<Future<void>> decryptionProcesses = [];

    bool hasReceivedEvent = false;
    bool hasReceivedEndOfStream = false;

    final socket = await WebSocket.connect(relay);

    socket.add(request.serialize());

    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket $relay",
      "Socket created, listening...",
    );

    socket.listen((rawEvent) {
      final event = Message.deserialize(rawEvent);

      switch (event.type) {
        case "EVENT":
          FlutterLogs.logInfo(
            LOG_TAG,
            "Nostr Socket $relay - Event",
            "New event received",
          );

          hasReceivedEvent = true;

          try {
            final process = onEvent(event, relay);

            decryptionProcesses.add(process);

            process.then((location) {
              decryptionProcesses.remove(process);

              if (decryptionProcesses.isEmpty && hasReceivedEndOfStream) {
                onEnd?.call();
              }
            });
          } catch (error) {
            FlutterLogs.logError(
              LOG_TAG,
              "Nostr Socket $relay - Event",
              "Error for event: $error",
            );
          }

          break;
        case "EOSE":
          FlutterLogs.logInfo(
            LOG_TAG,
            "Nostr Socket $relay - End of Stream",
            "End of stream received.",
          );

          socket.close();

          hasReceivedEndOfStream = true;

          if (decryptionProcesses.isEmpty) {
            if (hasReceivedEvent) {
              onEnd?.call();
            } else {
              onEmptyEnd?.call();
            }
          }
          break;
      }
    });

    return socket;
  }

  VoidCallback fetchEvents({
    required final Future<void> Function(Message message, String relay) onEvent,
    required final void Function() onEnd,
  }) {
    final List<WebSocket> sockets = [];

    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket",
      "Creating sockets...",
    );

    for (final relay in relays) {
      _connectToRelay(
        relay: relay,
        onEvent: onEvent,
        onEnd: onEnd,
      ).then((socket) {
        sockets.add(socket);
      });
    }

    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket",
      "Sockets created.",
    );

    return () {
      for (final socket in sockets) {
        socket.close();
      }
    };
  }
}