import 'package:geolocator/geolocator.dart';

import 'has-granted.dart';

Future<bool> requestBasicLocationPermission() async {
  if (await hasGrantedLocationPermission()) {
    return true;
  }

  final permissionStatus = await Geolocator.requestPermission();

  return permissionStatus == LocationPermission.always ||
      permissionStatus == LocationPermission.whileInUse;
}
