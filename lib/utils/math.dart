import 'dart:math';

import 'package:latlong2/latlong.dart';

// Calculate the rotation between two points in radians.
double getRotationBetweenTwoPoints(
  final LatLng firstPoint,
  final LatLng secondPoint,
) {
  final diffLongitude = secondPoint.longitude - firstPoint.longitude;
  final diffLatitude = secondPoint.latitude - firstPoint.latitude;

  return atan2(diffLatitude, diffLongitude) + pi;
}
