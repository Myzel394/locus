// Selects a random provider from the list of available providers, not including
// the system provider.
import 'dart:math';

import 'enums.dart';

GeocoderProvider selectRandomProvider() {
  final providers = GeocoderProvider.values
      .where((element) => element != GeocoderProvider.system)
      .toList();

  return providers[Random().nextInt(providers.length)];
}
