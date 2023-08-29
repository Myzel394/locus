import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locus/api/nostr-relays.dart';
import 'package:locus/utils/nostr/select-random-relays.dart';

void main() {
  group("relays api", () {
    late final List<String> relays;

    setUp(() async {
      WidgetsFlutterBinding.ensureInitialized();

      relays = await NostrWatchAPI.getAllNostrRelays();
    });

    test("can select random relays", () async {
      const AMOUNT = 5;

      // Currently not working because of FlutterLogs, see
      // https://github.com/umair13adil/flutter_logs/issues/54
      //final selected = await selectRandomRelays(relays, AMOUNT);

      //expect(selected.length, AMOUNT);
    });
  });
}
