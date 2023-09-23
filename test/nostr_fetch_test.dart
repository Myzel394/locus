import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/utils/cryptography/utils.dart';
import 'package:locus/utils/nostr_fetcher/LocationPointDecrypter.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';

import 'utils.dart';

// Trustable relay for testing
const RELAY_URI = "wss://relay.damus.io";
// DuckDuckGo's headquarter
final CENTER = LatLng(40.04114, -75.48702);
final LOCATION_POINT = LocationPointService.dummyFromLatLng(CENTER);

void main() {
  group("Nostr Fetchers", () {
    testWidgets("throws error on non-existent relay", (tester) async {
      setupFlutterLogs(tester);

      await tester.runAsync(() async {
        final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString();
        final nonExistent =
            "wss://donotbuythisdomainxasdyxcybvbnhzhj$randomSuffix.com";
        final secretKey = await generateSecretKey();

        final fetcher = NostrSocket(
          relay: nonExistent,
          decryptMessage: LocationPointDecrypter(
            secretKey,
          ).decryptFromNostrMessage,
        );

        try {
          await fetcher.connect();
        } on SocketException catch (error) {
          return;
        }
      });
    });

    testWidgets("can save and fetch location point", (tester) async {
      setupFlutterLogs(tester);

      await tester.runAsync(() async {
        // Publish
        final task = await Task.create("Test", [RELAY_URI]);
        await task.publisher.publishLocation(LOCATION_POINT);

        // Fetch
        final fetcher = NostrSocket(
          relay: RELAY_URI,
          decryptMessage: task.cryptography.decryptFromNostrMessage,
        );

        await fetcher.connect();
        fetcher.addData(
          NostrSocket.createNostrRequestDataFromTask(task, limit: 1)
              .serialize(),
        );

        final locations = await fetcher.stream.toList();

        expect(locations.length, 1);
        expect(locations[0].latitude, LOCATION_POINT.latitude);
        expect(locations[0].longitude, LOCATION_POINT.longitude);
      });
    });
  });
}
