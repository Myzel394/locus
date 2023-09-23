import 'dart:async';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/task_service/mixins.dart';
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
  }) : _decryptionQueue =
  Queue(parallel: decryptionParallelProcesses, timeout: timeout);

  int _processesInQueue = 0;
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

    if (_processesInQueue > 0) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Nostr Socket",
        "    -> Waiting for $_processesInQueue decryption processes to finish...",
      );

      await _decryptionQueue.onComplete;
    }

    _decryptionQueue.dispose();
    _controller.close();
    closeConnection();

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
    _processesInQueue++;
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
    } finally {
      _processesInQueue--;
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

  static Request createNostrRequestData({
    final String? subscriptionID,
    final List<int>? kinds,
    final int? limit,
    final DateTime? from,
    final DateTime? until,
  }) =>
      Request(
        subscriptionID ?? generate64RandomHexChars(),
        [
          Filter(
            kinds: kinds,
            limit: limit,
            since: from == null
                ? null
                : (from.millisecondsSinceEpoch / 1000).floor(),
            until: until == null
                ? null
                : (until.millisecondsSinceEpoch / 1000).floor(),
          ),
        ],
      );

  static Request createNostrRequestDataFromTask(final LocationBase task, {
    final int? limit,
    final DateTime? from,
    final DateTime? until,
  }) =>
      Request(
        generate64RandomHexChars(),
        [
          Filter(
            kinds: [1000],
            authors: [task.nostrPublicKey],
            limit: limit,
            since: from == null
                ? null
                : (from.millisecondsSinceEpoch / 1000).floor(),
            until: until == null
                ? null
                : (until.millisecondsSinceEpoch / 1000).floor(),
          ),
        ],
      );
}
