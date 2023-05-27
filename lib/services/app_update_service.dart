import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

import '../api/get-newest-version.dart';

const storage = FlutterSecureStorage();
const KEY = "_app_update_service";

class AppUpdateService extends ChangeNotifier {
  // Since when the app is outdated
  DateTime? _outDateDate;
  bool _isUpdateAvailable;
  bool _hideBanner;
  bool _hideDialogue;

  AppUpdateService({
    DateTime? outDateDate,
    bool hideBanner = false,
    bool hideDialogue = false,
  })  : _outDateDate = outDateDate,
        _hideBanner = hideBanner,
        _hideDialogue = hideDialogue,
        _isUpdateAvailable = false;

  static Future<AppUpdateService> restore() async {
    final data = await storage.read(key: KEY);

    if (data == null) {
      return AppUpdateService();
    }

    return AppUpdateService.fromJSON(jsonDecode(data) as Map<String, dynamic>);
  }

  static AppUpdateService fromJSON(final Map<String, dynamic> data) => AppUpdateService(
        outDateDate: data['outDateDate'] == null ? null : DateTime.parse(data['outDateDate'] as String),
        hideBanner: data['hideBanner'] as bool,
        hideDialogue: data['hideDialogue'] as bool,
      );

  void _reset() {
    _outDateDate = null;
    _isUpdateAvailable = false;
    _hideBanner = false;
    _hideDialogue = false;
  }

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
      _reset();
    }

    notifyListeners();

    await save();
  }

  Map<String, dynamic> toJSON() => {
        "outDateDate": _outDateDate?.toIso8601String(),
        "hideBanner": _hideBanner,
        "hideDialogue": _hideDialogue,
      };

  Future<void> save() => storage.write(
        key: KEY,
        value: jsonEncode(toJSON()),
      );

  bool shouldShowBanner() {
    if (_outDateDate == null || _hideBanner) {
      return false;
    }

    final now = DateTime.now();
    final diff = now.difference(_outDateDate!);

    return diff.inDays >= 5 && diff.inDays <= 30;
  }

  bool shouldShowDialogue() {
    if (_outDateDate == null || _hideDialogue) {
      return false;
    }

    final now = DateTime.now();
    final diff = now.difference(_outDateDate!);

    return diff.inDays >= 30;
  }
}
