import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PlatformDialogActionButton.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  return permissionStatus == LocationPermission.always || permissionStatus == LocationPermission.whileInUse;
}

Future<bool> requestBasicLocationPermission() async {
  if (await hasGrantedLocationPermission()) {
    return true;
  }

  final permissionStatus = await Geolocator.requestPermission();

  return permissionStatus == LocationPermission.always || permissionStatus == LocationPermission.whileInUse;
}
