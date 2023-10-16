import 'dart:convert';

import 'package:airplane_mode_checker/airplane_mode_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/notifications.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_history_service/index.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/manager_service/helpers.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/device/index.dart';
import 'package:locus/utils/permissions/has-granted.dart';

const PERMISSION_MISSING_NOTIFICATION_ID = 394001;

void _showPermissionMissingNotification({
  required final AppLocalizations l10n,
}) {
  final notifications = FlutterLocalNotificationsPlugin();

  notifications.show(
    PERMISSION_MISSING_NOTIFICATION_ID,
    l10n.permissionsMissing_title,
    l10n.permissionsMissing_message,
    NotificationDetails(
      android: AndroidNotificationDetails(
        AndroidChannelIDs.appIssues.name,
        l10n.androidNotificationChannel_appIssues_name,
        channelDescription:
            l10n.androidNotificationChannel_appIssues_description,
        onlyAlertOnce: true,
        importance: Importance.max,
        priority: Priority.max,
      ),
    ),
    payload: jsonEncode({
      "type": NotificationActionType.openPermissionsSettings.index,
    }),
  );
}

void _updateLocation(final Position position) async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating Location History; Restoring...",
  );

  final locationHistory = await LocationHistory.restore();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating Location History; Adding position.",
  );

  locationHistory.add(position);

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating Location History; Saving...",
  );

  await locationHistory.save();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Updating Location History; Done!",
  );
}

Future<void> runBackgroundTask({
  final LocationPointService? locationData,
  final bool force = false,
}) async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Checking Airplane mode",
  );

  final status = await AirplaneModeChecker.checkAirplaneMode();

  if (status == AirplaneModeStatus.on) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task",
      "----> Airplane mode is on. Skipping headless task.",
    );
    return;
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Restoring settings.",
  );

  final settings = await SettingsService.restore();

  final locale = Locale(settings.localeName);
  final l10n = await AppLocalizations.delegate.load(locale);

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Checking permission.",
  );

  final hasPermission = await hasGrantedAlwaysLocationPermission();

  if (!hasPermission) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task",
      "Permission not granted. Headless task will not run. Showing notification.",
    );

    _showPermissionMissingNotification(l10n: l10n);

    return;
  }

  final location = locationData ?? await getLocationData();

  try {
    _updateLocation(location.asPosition());
  } catch (error) {
    FlutterLogs.logError(
      LOG_TAG,
      "Headless Task",
      "Error while updating location history: $error",
    );
  }

  if (!force) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task",
      "Checking battery saver.",
    );
    final isDeviceBatterySaverEnabled = await isBatterySaveModeEnabled();

    final shouldRunBasedOnBatterySaver =
        settings.useRealtimeUpdates || !isDeviceBatterySaverEnabled;
    final shouldRunBasedOnLastRun = settings.lastHeadlessRun == null ||
        DateTime.now().difference(settings.lastHeadlessRun!).abs() >
            BATTERY_SAVER_ENABLED_MINIMUM_TIME_BETWEEN_HEADLESS_RUNS;

    if (!shouldRunBasedOnBatterySaver && !shouldRunBasedOnLastRun) {
      // We don't want to run the headless task too often when the battery saver is enabled.
      FlutterLogs.logInfo(
        LOG_TAG,
        "Headless Task",
        "Battery saver mode is enabled and the last headless run was too recent. Skipping headless task.",
      );
      return;
    }
  } else {
    FlutterLogs.logInfo(LOG_TAG, "Headless Task", "Execution is being forced.");
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
  await updateLocation(location);
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
  await checkViewAlarmsFromBackground(
    location,
    l10n: l10n,
  );
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
