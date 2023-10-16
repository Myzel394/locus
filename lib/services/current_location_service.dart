// Helper class to get the current location of the user
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/screens/LocationsOverviewScreen.dart';

class CurrentLocationService extends ChangeNotifier {
  final StreamController<Position> _positionStreamController =
      StreamController.broadcast();
  final StreamController<LocationMarkerPosition>
      _locationMarkerStreamController = StreamController.broadcast();
  Position? currentPosition;
  LocationStatus locationStatus = LocationStatus.stale;

  Stream<Position> get stream => _positionStreamController.stream;

  Stream<LocationMarkerPosition> get locationMarkerStream =>
      _locationMarkerStreamController.stream;

  Future<void> updateCurrentPosition(final Position newPosition) async {
    currentPosition = newPosition;

    _positionStreamController.add(newPosition);
    _locationMarkerStreamController.add(
      LocationMarkerPosition(
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
        accuracy: newPosition.accuracy,
      ),
    );

    notifyListeners();
  }
}
