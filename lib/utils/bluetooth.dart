import 'package:locus/utils/permission.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkIfHasBluetoothPermission() async {
  final bluetoothGranted = await Nearby().checkBluetoothPermission();

  print("Bluetooth granted: $bluetoothGranted");

  if (!bluetoothGranted) {
    Nearby().askBluetoothPermission();

    return false;
  }

  final hasWifiPermission = await hasOSBluetoothPermission();

  if (!hasWifiPermission) {
    return true;
  }

  final wifiGranted = await Permission.nearbyWifiDevices.request();
  print("Wifi granted: $wifiGranted");

  if (wifiGranted != PermissionStatus.granted) {
    return false;
  }

  return true;
}
