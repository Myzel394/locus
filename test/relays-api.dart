import 'package:flutter_test/flutter_test.dart';
import 'package:locus/api/nostr-relays.dart';
import 'package:locus/utils/nostr/select-random-relays.dart';

void main() {
  group("relays api", () async {
    final results = await getNostrRelays();
    final relays = List<String>.from(results["relays"] as Iterable);

    test("can select random relays", () async {
      const AMOUNT = 5;
      final selected = await selectRandomRelays(relays, AMOUNT);

      expect(selected.length, AMOUNT);
    });
  });
}