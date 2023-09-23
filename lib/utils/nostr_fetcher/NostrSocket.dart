import 'dart:async';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/utils/nostr_fetcher/BasicNostrFetchSocket.dart';
import 'package:locus/utils/nostr_fetcher/Socket.dart';
import 'package:nostr/nostr.dart';
import 'package:queue/queue.dart';

class NostrSocket extends BasicNostrFetchSocket {
  NostrSocket({
    required super.relay,
    super.timeout,
    required this.decryptMessage,
    final int decryptionParallelProcesses = 4,
  }) : _decryptionQueue = Queue(parallel: decryptionParallelProcesses);

  final StreamController<LocationPointService> _controller =
  StreamController<LocationPointService>();

  Stream<LocationPointService> get stream => _controller.stream;

  late final Queue _decryptionQueue;

  late final Future<LocationPointService> Function(Message) decryptMessage;

  void _finish() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket",
      "Closing everything...",
    );

    await _decryptionQueue.onComplete;

    _decryptionQueue.dispose();
    _controller.close();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket",
      "Closing everything... Done!",
    );
  }

  @override
  void onEndOfStream() async {
    _finish();
  }

  @override
  void onNostrEvent(final Message message) {
    _decryptionQueue.add(() => _handleDecryption(message));
  }

  Future<void> _handleDecryption(final Message message) async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Nostr Socket",
      "Trying to decrypt message...",
    );

    try {
      final location = await decryptMessage(message);

      FlutterLogs.logInfo(
        LOG_TAG,
        "Nostr Socket",
        "    -> Decryption successful!",
      );

      _controller.add(location);
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Nostr Socket",
        "    -> Decryption failed: $error",
      );
    }
  }

  @override
  void onError(error) {
    if (error == TIMEOUT_ERROR) {
      _finish();
      return;
    }

    FlutterLogs.logError(
      LOG_TAG,
      "Nostr Socket",
      "Error while fetching events from $uri: $error; Closing everything.",
    );

    _decryptionQueue.cancel();
    _decryptionQueue.dispose();
    _controller.addError(error);
    _controller.close();
  }
}
