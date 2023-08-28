import 'package:geolocator/geolocator.dart';
import "package:latlong2/latlong.dart";

import '../../constants/values.dart';
import '../../services/location_point_service.dart';

List<LocationPointService> mergeLocations(
  final List<LocationPointService> locations, {
  final double distanceThreshold = LOCATION_MERGE_DISTANCE_THRESHOLD,
}) {
  if (locations.length <= 1) {
    return locations;
  }

  final mergedLocations = <LocationPointService>[];

  var hasAddedFirstLocation = false;

  for (var index = 0; index < locations.length - 1; index++) {
    final location = locations[index];
    final nextLocation = locations[index + 1];

    final distance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      nextLocation.latitude,
      nextLocation.longitude,
    );

    if (distance > distanceThreshold) {
      hasAddedFirstLocation = false;
      mergedLocations.add(location);
      continue;
    }

    if (hasAddedFirstLocation) {
      continue;
    }

    final vector = LatLng(
      nextLocation.latitude - location.latitude,
      nextLocation.longitude - location.longitude,
    );

    final newLocation = location.copyWith(
      latitude: location.latitude + vector.latitude / 2,
      longitude: location.longitude + vector.longitude / 2,
      accuracy: (location.accuracy) + nextLocation.accuracy / 2,
    );

    mergedLocations.add(newLocation);
    hasAddedFirstLocation = true;
  }

  return mergedLocations;
}
