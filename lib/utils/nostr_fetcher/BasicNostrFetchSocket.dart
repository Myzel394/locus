import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/utils/nostr_fetcher/Socket.dart';
import 'package:nostr/nostr.dart';

abstract class BasicNostrFetchSocket extends Socket {
  BasicNostrFetchSocket({
    required final String relay,
    super.timeout,
  }) : super(uri: ensureProtocol(relay));

  static ensureProtocol(final String relay) {
    if (!relay.startsWith("ws://") && !relay.startsWith("wss://")) {
      return "wss://$relay";
    }

    return relay;
  }

  @override
  void onEvent(final event) {
    final message = Message.deserialize(event);

    FlutterLogs.logInfo(LOG_TAG, "Nostr Socket", "New event received");

    switch (event.type) {
      case "EOSE":
        FlutterLogs.logInfo(
          LOG_TAG,
          "Nostr Socket",
          "    -> It is: End of stream event; Closing socket.",
        );

        onEndOfStream();
        break;
      case "EVENT":
        FlutterLogs.logInfo(
          LOG_TAG,
          "Nostr Socket",
          "    -> It is: Event; Passing down.",
        );

        onNostrEvent(message);
        break;
    }
  }

  void onEndOfStream();

  void onNostrEvent(final Message message);
}
