import 'dart:io';

import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';

Future<bool> checkNostrConnection(final String domain) async {
  FlutterLogs.logInfo(
      LOG_TAG, "Check Nostr connection for $domain", "Checking connection...");

  try {
    final socket = await WebSocket.connect(addProtocol(domain));

    socket.close();

    FlutterLogs.logInfo(LOG_TAG, "Check Nostr connection for $domain",
        "Connection successful!");

    return true;
  } catch (error) {
    FlutterLogs.logError(LOG_TAG, "Check Nostr connection for $domain",
        "Connection failed: $error");

    return false;
  }
}
