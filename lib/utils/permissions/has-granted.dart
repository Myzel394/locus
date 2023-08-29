import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'os-existence-check.dart';

Future<bool> hasGrantedNotificationPermission() async {
  // TODO: Check this again once https://github.com/flutter/flutter/issues/128691 is fixed
  if (!(await hasOSNotificationPermission())) {
    return true;
  }

  final permissionStatus = await Permission.notification.status;

  return permissionStatus.isGranted;
}

Future<bool> hasGrantedAlwaysLocationPermission() async {
  final permissionStatus = await Geolocator.checkPermission();

  return permissionStatus == LocationPermission.always;
}

Future<bool> hasGrantedLocationPermission() async {
  final permissionStatus = await Geolocator.checkPermission();

  return permissionStatus == LocationPermission.always ||
      permissionStatus == LocationPermission.whileInUse;
}

Future<bool> hasGrantedAllBluetoothPermissions() async {
  final bluetoothGranted = (await Future.wait([
    Permission.bluetoothAdvertise.isGranted,
    Permission.bluetoothConnect.isGranted,
    Permission.bluetoothScan.isGranted
  ]))
      .every((element) => element == true);

  if (!bluetoothGranted) {
    await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    return false;
  }

  final hasWifiPermission = await hasOSBluetoothPermission();

  if (!hasWifiPermission) {
    return true;
  }

  final wifiGranted = await Permission.nearbyWifiDevices.request();

  if (wifiGranted != PermissionStatus.granted) {
    return false;
  }

  return true;
}
