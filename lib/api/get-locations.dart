import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:nostr/nostr.dart';

import 'nostr-fetch.dart';

VoidCallback getLocations({
  required final String nostrPublicKey,
  required final SecretKey encryptionPassword,
  required final List<String> relays,
  required void Function(LocationPointService) onLocationFetched,
  required void Function() onEnd,
  final VoidCallback? onEmptyEnd,
  final VoidCallback? onError,
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

  final nostrFetch = NostrFetch(
    relays: relays,
    request: request,
  );

  return nostrFetch.fetchEvents(
    onEvent: (message, _) async {
      FlutterLogs.logInfo(
        LOG_TAG,
        "GetLocations",
        "New message. Decrypting...",
      );

      final location = await LocationPointService.fromEncrypted(
        message.message.content,
        encryptionPassword,
      );

      FlutterLogs.logInfo(
        LOG_TAG,
        "GetLocations",
        "New message. Decrypting... Done!",
      );

      onLocationFetched(location);
    },
    onEnd: onEnd,
    onEmptyEnd: onEmptyEnd,
    onError: onError,
  );
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

  int doneAmount = 0;
  final List<LocationPointService> locations = [];

  final onAnyEnd = () {
    doneAmount++;

    FlutterLogs.logInfo(
      LOG_TAG,
      "GetLocations",
      "Relay done! $doneAmount / ${relays.length}",
    );

    if (doneAmount == relays.length) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "GetLocations",
        "All relays done!",
      );

      completer.complete(locations);
    }
  };

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
    onEnd: onAnyEnd,
    onEmptyEnd: onAnyEnd,
    onError: onAnyEnd,
  );

  return completer.future;
}
