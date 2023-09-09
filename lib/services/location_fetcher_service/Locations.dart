import 'dart:collection';

import 'package:locus/services/location_point_service.dart';

class Locations {
  final Set<LocationPointService> _locations = {};

  List<LocationPointService> get sortedLocations =>
      _locations.toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  UnmodifiableSetView<LocationPointService> get locations =>
      UnmodifiableSetView(_locations);

  Locations();

  void add(final LocationPointService location) {
    _locations.add(location);
  }
}
