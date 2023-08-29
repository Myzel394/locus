import 'package:collection/collection.dart';
import 'package:locus/utils/nostr/check-connection.dart';

Future<List<String>> selectRandomRelays(final List<String> relays, [
  final int amount = 5,
]) async {
  final selectedRelays = <String>[];

  while (selectedRelays.length != amount) {
    relays.shuffle();

    final randomRelays = relays.take(selectedRelays.length - amount);

    // Check for each relays if it is reachable
    final response = await Future.wait(
        randomRelays.map(checkNostrConnection)
    );

    selectedRelays.addAll(
        response
            .where((reachable) => reachable)
            .mapIndexed((index, _) => randomRelays.elementAt(index))
    );
  }

  return selectedRelays;
}
