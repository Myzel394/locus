import 'dart:collection';

import 'package:locus/services/location_point_service.dart';

class Locations {
  final Set<LocationPointService> _locations = {};

  List<LocationPointService> get locations => _locations.toList(growable: false)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Locations();

  void add(final LocationPointService location) {
    _locations.add(location);
  }
}
