import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:cryptography/cryptography.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:nostr/nostr.dart';

Future<void Function()> getLocations({
  required final String nostrPublicKey,
  required final SecretKey encryptionPassword,
  required final List<String> relays,
  required void Function(LocationPointService) onLocationFetched,
  required void Function() onEnd,
  bool onlyLatestPosition = false,
  DateTime? from,
}) async {
  final request = Request(generate64RandomHexChars(), [
    Filter(
      kinds: [1000],
      authors: [nostrPublicKey],
      limit: onlyLatestPosition ? 1 : null,
      since: from == null ? null : (from.millisecondsSinceEpoch / 1000).floor(),
    ),
  ]);

  final socket = await WebSocket.connect(
    relays.first,
  );
  final List<Future<LocationPointService>> decryptionProcesses = [];
  bool hasReceivedEndOfStream = false;
  bool hasReceivedEvent = false;

  socket.add(request.serialize());

  socket.listen((rawEvent) {
    final event = Message.deserialize(rawEvent);

    switch (event.type) {
      case "EVENT":
        hasReceivedEvent = true;

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

        break;
      case "EOSE":
        socket.close();

        hasReceivedEndOfStream = true;

        if ((decryptionProcesses.isEmpty && hasReceivedEvent) || !hasReceivedEvent) {
          onEnd();
        }
        break;
    }
  });

  return () {
    socket.close();
  };
}
