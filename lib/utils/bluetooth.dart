import 'package:flutter/widgets.dart';
import 'package:locus/utils/permission.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkIfHasBluetoothPermission() async {
  final bluetoothGranted = await Nearby().checkBluetoothPermission();

  if (!bluetoothGranted) {
    Nearby().askBluetoothPermission();

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

abstract class BluetoothPermissionMixin {
  bool hasGrantedBluetoothPermission = false;

  setState(VoidCallback fn);

  Future<void> checkBluetoothPermission() async {
    final hasGranted = await checkIfHasBluetoothPermission();

    setState(() {
      hasGrantedBluetoothPermission = hasGranted;
    });
  }

  void onBluetoothPermissionGranted() {}
}
