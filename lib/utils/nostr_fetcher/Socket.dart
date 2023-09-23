import 'dart:async';
import 'dart:io';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';

const TIMEOUT_ERROR = "Timeout reached";

abstract class Socket {
  final String uri;
  final Duration timeout;

  Socket({
    required this.uri,
    this.timeout = const Duration(seconds: 10),
  });

  WebSocket? _socket;

  bool get isConnected => _socket != null;

  Timer? _timeoutTimer;

  void closeConnection() {
    _socket?.close();
    _socket = null;
    _timeoutTimer?.cancel();
  }

  void _abort(final dynamic error) {
    FlutterLogs.logError(
      LOG_TAG,
      "Socket",
      "Error while fetching events from $uri: $error",
    );

    closeConnection();

    onError(error);
  }

  void _resetTimer() {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(timeout, () {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Socket",
        "Timeout reached, closing stream.",
      );

      _abort(TIMEOUT_ERROR);
    });
  }

  void addData(final dynamic data) {
    assert(isConnected,
        "Socket is not connected. Make sure to call `connect` first.");

    _socket!.add(data);
  }

  void _registerSocket() {
    _socket!.listen((event) {
      if (!isConnected) {
        closeConnection();
        return;
      }

      _resetTimer();

      onEvent(event);
    });
  }

  Future<void> connect() async {
    if (isConnected) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Socket",
        "Socket already exists, no action taken.",
      );

      return;
    }

    _resetTimer();
    FlutterLogs.logInfo(
      LOG_TAG,
      "Socket",
      "Connecting to $uri...",
    );

    _socket = await WebSocket.connect(uri);
    _registerSocket();
  }

  void onError(final dynamic error);

  void onEvent(final dynamic event);
}
