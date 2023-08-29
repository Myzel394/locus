import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:locus/constants/app.dart';

Future<bool> hasOSNotificationPermission() async {
  if (!Platform.isAndroid) {
    return false;
  }

  if (isFLOSSFlavor) {
    // GMS not available
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
