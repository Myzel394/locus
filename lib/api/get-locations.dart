import 'dart:io';

import 'package:locus/services/location_point_service.dart';
import 'package:nostr/nostr.dart';

Future<void Function()> getLocations({
  required final String nostrPublicKey,
  required final String viewPrivateKey,
  required final String signPublicKey,
  required final List<String> relays,
  required void Function(LocationPointService) onLocationFetched,
  required void Function() onEnd,
  required void Function() onError,
}) async {
  final request = Request(generate64RandomHexChars(), [
    Filter(
      kinds: [1000],
      authors: [nostrPublicKey],
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
          viewPrivateKey,
          signPublicKey,
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

        if (decryptionProcesses.isEmpty && hasReceivedEvent) {
          onEnd();
        }

        Future.delayed(const Duration(seconds: 20)).then((_) {
          if (!hasReceivedEvent) {
            // Something went wrong, there should be at least one event after this time
            onError();
          }
        });

        break;
    }
  });

  return () {
    socket.close();
  };
}
