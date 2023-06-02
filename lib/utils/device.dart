import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<bool> fetchIsMIUI() async {
  if (!Platform.isAndroid) {
    return false;
  }

  final deviceInfo = await DeviceInfoPlugin().androidInfo;

  return deviceInfo.manufacturer == "Xiaomi";
}
