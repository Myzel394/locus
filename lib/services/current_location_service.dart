// Helper class to get the current location of the user
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

class CurrentLocationService extends ChangeNotifier {
  Position? currentPosition;

  Future<void> updateCurrentPosition(final Position newPosition) async {
    currentPosition = newPosition;
    notifyListeners();
  }
}