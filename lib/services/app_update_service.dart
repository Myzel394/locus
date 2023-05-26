import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

import '../api/get-newest-version.dart';

const storage = FlutterSecureStorage();
const KEY = "_app_update_service";

class AppUpdateService extends ChangeNotifier {
  DateTime? _outDateDate;
  bool _isUpdateAvailable;

  AppUpdateService({
    DateTime? outDateDate,
    bool isUpdateAvailable = false,
  })  : _outDateDate = outDateDate,
        _isUpdateAvailable = isUpdateAvailable;

  static Future<AppUpdateService> restore() async {
    final data = await storage.read(key: KEY);

    if (data == null) {
      return AppUpdateService();
    }

    return AppUpdateService.fromJSON(jsonDecode(data) as Map<String, dynamic>);
  }

  static AppUpdateService fromJSON(final Map<String, dynamic> data) =>
      AppUpdateService(
        outDateDate: data['outDateDate'] == null
            ? null
            : DateTime.parse(data['outDateDate'] as String),
      );

  bool get isUpdateAvailable => _isUpdateAvailable;

  Future<Version> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    return Version.parse(packageInfo.version);
  }

  Future<void> checkForUpdates({final bool force = false}) async {
    if (_outDateDate == null && !force) {
      return;
    }

    final currentVersion = await getCurrentVersion();
    final newestVersion = await getNewestVersion();

    _isUpdateAvailable = currentVersion < newestVersion;

    if (_isUpdateAvailable) {
      _outDateDate ??= DateTime.now();
    } else {
      _outDateDate = null;
    }

    notifyListeners();

    await save();
  }

  Map<String, dynamic> toJSON() => {
        "outDateDate": _outDateDate?.toIso8601String(),
      };

  Future<void> save() => storage.write(
        key: KEY,
        value: jsonEncode(toJSON()),
      );
}
