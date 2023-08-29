import 'dart:ui';

import 'package:nearby_connections/nearby_connections.dart';

import 'has-granted.dart';

abstract class BluetoothPermissionMixin {
  bool hasGrantedBluetoothPermission = false;

  setState(VoidCallback fn);

  Future<void> checkBluetoothPermission() async {
    final hasGranted = await hasGrantedAllBluetoothPermissions();

    setState(() {
      hasGrantedBluetoothPermission = hasGranted;
    });

    if (hasGranted) {
      onBluetoothPermissionGranted();
    }
  }

  void closeBluetooth() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
  }

  void onBluetoothPermissionGranted();
}
