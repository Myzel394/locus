import 'package:flutter/widgets.dart';
import 'package:locus/utils/permission.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkIfHasBluetoothPermission() async {
  final bluetoothGranted = (await Future.wait([
    Permission.bluetoothAdvertise.isGranted,
    Permission.bluetoothConnect.isGranted,
    Permission.bluetoothScan.isGranted
  ])).every((element) => element == true);

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

abstract class BluetoothPermissionMixin {
  bool hasGrantedBluetoothPermission = false;

  setState(VoidCallback fn);

  Future<void> checkBluetoothPermission() async {
    final hasGranted = await checkIfHasBluetoothPermission();

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
