import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/notifications.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/manager_service/helpers.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/device/index.dart';
import 'package:locus/utils/permissions/has-granted.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

Future<void> runBackgroundTask({
  final LocationPointService? locationData,
  final bool force = false,
}) async {
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

  if (!force) {
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
  } else {
    FlutterLogs.logInfo(LOG_TAG, "Headless Task", "Execution is being forced.");
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task",
    "Executing headless task now.",
  );

  final location = locationData ?? await getLocationData();

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
