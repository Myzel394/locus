import 'dart:io';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:nostr/nostr.dart';

import '../services/task_service.dart';

class NostrEventsManager {
  final List<String> relays;
  final String _privateKey;
  final WebSocket? _socket;

  NostrEventsManager({
    required this.relays,
    required String privateKey,
    WebSocket? socket,
  })
      : _privateKey = privateKey,
        _socket = socket;

  static NostrEventsManager fromTask(final Task task) {
    return NostrEventsManager(
      relays: task.relays,
      privateKey: task.nostrPrivateKey,
    );
  }

  Future<void> _sendEvent(Event event, String url) async {
    if (_socket != null) {
      _socket!.add(event.serialize());
      return;
    }

    final socket = await WebSocket.connect(url);

    socket.add(event.serialize());

    await socket.close();
  }

  Future<Event> publishMessage(String message, {final int kind = 1000}) async {
    final event = Event.from(
      kind: kind,
      tags: [],
      content: message,
      privkey: _privateKey,
    );

    FlutterLogs.logInfo(
        LOG_TAG,
        "NostrEventsManager",
        "publishMessage: Publishing new event."
    );

    var failedRelaysNumber = 0;

    for (final relay in relays) {
      try {
        await _sendEvent(event, relay);
      } catch (error) {
        FlutterLogs.logError(
          LOG_TAG,
          "NostrEventsManager",
          "publishMessage: Failed to publish event for relay $relay.",
        );

        failedRelaysNumber++;
      }
    }

    if (failedRelaysNumber == relays.length) {
      FlutterLogs.logError(
        LOG_TAG,
        "NostrEventsManager",
        "publishMessage: Failed to publish event to all relays!",
      );

      throw Exception("Failed to publish event to all relays.");
    }

    return event;
  }
}
