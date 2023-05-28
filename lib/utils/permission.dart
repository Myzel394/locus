import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> hasOSNotificationPermission() async {
  if (!Platform.isAndroid) {
    return false;
  }

  final androidInfo = await DeviceInfoPlugin().androidInfo;

  return androidInfo.version.sdkInt >= 33;
}

Future<bool> hasOSBluetoothPermission() async {
  if (!Platform.isAndroid) {
    return false;
  }

  final androidInfo = await DeviceInfoPlugin().androidInfo;

  return androidInfo.version.sdkInt >= 33;
}

Future<bool> hasGrantedNotificationPermission() async {
  if (!(await hasOSNotificationPermission())) {
    return true;
  }

  final permissionStatus = await Permission.notification.status;

  return permissionStatus.isGranted;
}
