import 'dart:io';

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
  })  : _privateKey = privateKey,
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

    for (final relay in relays) {
      await _sendEvent(event, relay);
    }

    return event;
  }
}
