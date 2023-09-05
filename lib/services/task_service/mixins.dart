import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:locus/services/location_fetch_controller.dart';
import 'package:locus/services/location_point_service.dart';

import '../../api/get-locations.dart' as get_locations_api;

mixin LocationBase {
  late final SecretKey _encryptionPassword;
  late final List<String> relays;
  late final String nostrPublicKey;

  VoidCallback getLocations({
    required void Function(LocationPointService) onLocationFetched,
    required void Function() onEnd,
    int? limit,
    DateTime? from,
  }) =>
      get_locations_api.getLocations(
        encryptionPassword: _encryptionPassword,
        nostrPublicKey: nostrPublicKey,
        relays: relays,
        onLocationFetched: onLocationFetched,
        onEnd: onEnd,
        from: from,
        limit: limit,
      );

  LocationFetcher createLocationFetcher({
    required void Function(LocationPointService) onLocationFetched,
    int? limit,
    DateTime? from,
  }) =>
      LocationFetcher(
        location: this,
        onLocationFetched: onLocationFetched,
        limit: limit,
        from: from,
      );
}
