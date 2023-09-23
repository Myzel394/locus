import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/utils/cryptography/utils.dart';
import 'package:locus/utils/nostr_fetcher/LocationPointDecrypter.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';

import 'utils.dart';

// Trustable relay for testing
const RELAY_URI = "wss://relay.damus.io";

void main() {
  group("Nostr Fetchers", () {
    testWidgets("throws error on non-existent relay", (tester) async {
      setupFlutterLogs(tester);

      await tester.runAsync(() async {
        final randomSuffix = DateTime
            .now()
            .millisecondsSinceEpoch
            .toString();
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
  });
}
