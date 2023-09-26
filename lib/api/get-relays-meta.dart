import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:locus/utils/access-deeply-nested-key.dart';
import 'package:locus/utils/nostr_fetcher/BasicNostrFetchSocket.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';
import 'package:nostr/nostr.dart';

const MIN_LENGTH = 5000;

class RelaysMetaFetcher extends BasicNostrFetchSocket {
  List<RelayMeta> meta = [];

  RelaysMetaFetcher({
    required super.relay,
    super.timeout,
  });

  @override
  void onEndOfStream() {
    closeConnection();
  }

  @override
  void onNostrEvent(final Message message) {
    // Relay URL, canWrite and canRead are in message.tags
    // Latencies are saved in content, separated per region
    // with the following schema:
    //  [
    //    [<connection speed>],
    //    [<read speed>],
    //    [<write speed>],
    //  ]
    final event = message.message as Event;

    final relayMeta = RelayMeta.fromFetchedContent(
      canWrite: event.tags[1][1] == "true",
      canRead: event.tags[2][1] == "true",
      relay: event.tags[0][1],
      content: jsonDecode(event.content),
      worldRegion: "eu-west",
    );

    meta.add(relayMeta);
  }

  @override
  void onError(error) {
    closeConnection();
  }
}

class RelayMeta {
  final String relay;
  final bool canWrite;
  final bool canRead;
  final String contactInfo;
  final String description;
  final String name;

  final List<int> connectionLatencies;
  final List<int> readLatencies;
  final List<int> writeLatencies;

  final int maxMessageLength;
  final int maxContentLength;

  final int minPowDifficulty;
  final bool requiresPayment;

  const RelayMeta({
    required this.relay,
    required this.canWrite,
    required this.canRead,
    required this.contactInfo,
    required this.description,
    required this.name,
    required this.connectionLatencies,
    required this.readLatencies,
    required this.writeLatencies,
    required this.maxMessageLength,
    required this.maxContentLength,
    required this.minPowDifficulty,
    required this.requiresPayment,
  });

  factory RelayMeta.fromFetchedContent({
    required final Map<String, dynamic> content,
    required final String relay,
    required final bool canRead,
    required final bool canWrite,
    required final String worldRegion,
  }) =>
      RelayMeta(
          relay: relay,
          canRead: canRead,
          canWrite: canWrite,
          name: adnk(content, "info.name") ?? relay,
          contactInfo: adnk(content, "info.contact") ?? "",
          description: adnk(content, "info.description") ?? "",
          connectionLatencies:
              List<int?>.from(adnk(content, "latency$worldRegion.0") ?? [])
                  .where((value) => value != null)
                  .toList()
                  .cast<int>(),
          readLatencies:
              List<int?>.from(adnk(content, "latency$worldRegion.1") ?? [])
                  .where((value) => value != null)
                  .toList()
                  .cast<int>(),
          writeLatencies:
              List<int?>.from(adnk(content, "latency$worldRegion.2") ?? [])
                  .where((value) => value != null)
                  .toList()
                  .cast<int>(),
          maxContentLength:
              adnk(content, "info.limitations.max_content_length") ?? 0,
          maxMessageLength:
              adnk(content, "info.limitations.max_message_length") ?? 0,
          requiresPayment:
              adnk(content, "info.limitations.payment_required") ?? false,
          minPowDifficulty:
              adnk(content, "info.limitations.min_pow_difficulty") ?? 0);

  bool get isSuitable =>
      canWrite &&
      canRead &&
      !requiresPayment &&
      minPowDifficulty == 0 &&
      maxContentLength >= MIN_LENGTH;

  // Calculate average latency, we use the average as we want extreme highs
  // to be taken into account.
  double get score {
    if (connectionLatencies.isEmpty ||
        readLatencies.isEmpty ||
        writeLatencies.isEmpty) {
      // If there is no data available, we don't know if the relay is fully intact
      return double.infinity;
    }

    // Each latency has it's own factor to give each of them a different weight
    // Lower latency = better - Because of this
    // a factor closer to 0 resembles a HIGHER weight
    // We prioritize read latency as we want to be able to provide a fast app
    return (connectionLatencies.average * 0.9 +
            readLatencies.average * 0.5 +
            writeLatencies.average) +
        (maxContentLength - MIN_LENGTH) * 0.0001;
  }
}

final REQUEST_DATA = NostrSocket.createNostrRequestData(
  kinds: [30304],
  limit: 10,
  authors: ["b3b0d247f66bf40c4c9f4ce721abfe1fd3b7529fbc1ea5e64d5f0f8df3a4b6e6"],
);

Future<void> fetchRelaysMeta() async {
  final fetcher = RelaysMetaFetcher(
    relay: "wss://history.nostr.watch",
  );
  await fetcher.connect();
  fetcher.addData(
    Request(
      generate64RandomHexChars(),
      [
        REQUEST_DATA,
      ],
    ).serialize(),
  );
  await fetcher.onComplete;

  print(fetcher.meta);
}
