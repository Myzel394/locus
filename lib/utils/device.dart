import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

bool _isMIUICache = false;

bool isMIUI() => _isMIUICache;

Future<void> fetchIsMIUI() async {
  if (!Platform.isAndroid) {
    return;
  }

  final deviceInfo = await DeviceInfoPlugin().androidInfo;

  _isMIUICache = deviceInfo.manufacturer == "Xiaomi";
}
