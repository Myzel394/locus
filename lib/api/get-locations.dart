import 'dart:async';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:nostr/nostr.dart';

Future<WebSocket> openSocket({
  required final String url,
  required final Request request,
  required final SecretKey encryptionPassword,
  required void Function(LocationPointService) onLocationFetched,
  required void Function() onEnd,
}) async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Nostr Socket $url",
    "Creating socket...",
  );

  final List<Future<LocationPointService>> decryptionProcesses = [];

  bool hasReceivedEvent = false;
  bool hasReceivedEndOfStream = false;

  final socket = await WebSocket.connect(url);

  socket.add(request.serialize());

  FlutterLogs.logInfo(
    LOG_TAG,
    "Nostr Socket $url",
    "Socket created, listening...",
  );

  socket.listen((rawEvent) {
    final event = Message.deserialize(rawEvent);

    switch (event.type) {
      case "EVENT":
        FlutterLogs.logInfo(
          LOG_TAG,
          "Nostr Socket $url - Event",
          "New event received, decrypting...",
        );

        hasReceivedEvent = true;

        try {
          final locationProcess = LocationPointService.fromEncrypted(
            event.message.content,
            encryptionPassword,
          );

          decryptionProcesses.add(locationProcess);

          locationProcess.then((location) {
            onLocationFetched(location);
            decryptionProcesses.remove(locationProcess);

            if (decryptionProcesses.isEmpty && hasReceivedEndOfStream) {
              onEnd();
            }
          });
        } catch (error) {
          FlutterLogs.logErrorTrace(
            LOG_TAG,
            "Nostr Socket $url - Event",
            "Error while decrypting event.",
            error as Error,
          );
        }

        break;
      case "EOSE":
        FlutterLogs.logInfo(
          LOG_TAG,
          "Nostr Socket $url - End of Stream",
          "End of stream received.",
        );

        socket.close();

        hasReceivedEndOfStream = true;

        if ((decryptionProcesses.isEmpty && hasReceivedEvent) ||
            !hasReceivedEvent) {
          onEnd();
        }
        break;
    }
  });

  return socket;
}

VoidCallback getLocations({
  required final String nostrPublicKey,
  required final SecretKey encryptionPassword,
  required final List<String> relays,
  required void Function(LocationPointService) onLocationFetched,
  required void Function() onEnd,
  int? limit,
  DateTime? from,
  DateTime? until,
}) {
  final request = Request(generate64RandomHexChars(), [
    Filter(
      kinds: [1000],
      authors: [nostrPublicKey],
      limit: limit,
      until:
      until == null ? null : (until.millisecondsSinceEpoch / 1000).floor(),
      since: from == null ? null : (from.millisecondsSinceEpoch / 1000).floor(),
    ),
  ]);

  final List<String> existingIDs = [];
  final List<WebSocket> socketProcesses = [];
  int doneAmount = 0;

  for (final relay in relays) {
    openSocket(
      url: relay,
      request: request,
      encryptionPassword: encryptionPassword,
      onLocationFetched: (final LocationPointService location) {
        if (existingIDs.contains(location.id)) {
          return;
        }

        existingIDs.add(location.id);

        onLocationFetched(location);
      },
      onEnd: () {
        doneAmount++;

        if (doneAmount == relays.length) {
          onEnd();
        }
      },
    ).then(socketProcesses.add);
  }

  return () {
    for (final socketProcess in socketProcesses) {
      final socket = socketProcess;

      socket.close();
    }
  };
}

Future<List<LocationPointService>> getLocationsAsFuture({
  required final String nostrPublicKey,
  required final SecretKey encryptionPassword,
  required final List<String> relays,
  int? limit,
  DateTime? from,
  DateTime? until,
}) async {
  final completer = Completer<List<LocationPointService>>();

  final List<LocationPointService> locations = [];

  getLocations(
    nostrPublicKey: nostrPublicKey,
    encryptionPassword: encryptionPassword,
    relays: relays,
    limit: limit,
    from: from,
    until: until,
    onLocationFetched: (final LocationPointService location) {
      locations.add(location);
    },
    onEnd: () {
      completer.complete(locations);
    },
  );

  return completer.future;
}
