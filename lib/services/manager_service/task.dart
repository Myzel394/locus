import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/manager_service/helpers.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/device/index.dart';

Future<void> runBackgroundTask() async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Restoring settings.",
  );

  final settings = await SettingsService.restore();
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Checking battery saver.",
  );
  final isDeviceBatterySaverEnabled = await isBatterySaveModeEnabled();

  if ((isDeviceBatterySaverEnabled || settings.alwaysUseBatterySaveMode) &&
      settings.lastHeadlessRun != null &&
      DateTime.now().difference(settings.lastHeadlessRun!).abs() <=
          BATTERY_SAVER_ENABLED_MINIMUM_TIME_BETWEEN_HEADLESS_RUNS) {
    // We don't want to run the headless task too often when the battery saver is enabled.
    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task",
      "Battery saver mode is enabled and the last headless run was too recent. Skipping headless task.",
    );
    return;
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Executing headless task now.",
  );

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating Location...",
  );
  await updateLocation();
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating Location... Done!",
  );

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Checking View alarms...",
  );
  await checkViewAlarmsFromBackground();
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Checking View alarms... Done!",
  );

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating settings' lastRun.",
  );

  settings.lastHeadlessRun = DateTime.now();
  await settings.save();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Finished headless task.",
  );
}
