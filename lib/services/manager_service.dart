import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:locus/constants/notifications.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/location.dart';

import '../models/log.dart';
import 'log_service.dart';

Future<void> updateLocation() async {
  final taskService = await TaskService.restore();
  final logService = await LogService.restore();

  await taskService.checkup(logService);
  final runningTasks = await taskService.getRunningTasks().toList();

  if (runningTasks.isEmpty) {
    return;
  }

  final position = await getCurrentPosition();
  final locationData = await LocationPointService.fromPosition(
    position,
  );

  for (final task in runningTasks) {
    await task.publishLocation(locationData.copyWithDifferentId());
  }

  await logService.addLog(
    Log.updateLocation(
      initiator: LogInitiator.system,
      latitude: locationData.latitude,
      longitude: locationData.longitude,
      accuracy: locationData.accuracy,
      tasks: List<UpdatedTaskData>.from(
        runningTasks.map(
          (task) => UpdatedTaskData(
            id: task.id,
            name: task.name,
          ),
        ),
      ),
    ),
  );
}

Future<void> checkViewAlarms({
  required final AppLocalizations l10n,
  required final Iterable<TaskView> views,
  required final ViewService viewService,
}) async {
  for (final view in views) {
    await view.checkAlarm(
      onTrigger: (alarm, location, __) async {
        if (alarm is RadiusBasedRegionLocationAlarm) {
          final flutterLocalNotificationsPlugin =
              FlutterLocalNotificationsPlugin();

          flutterLocalNotificationsPlugin.show(
            int.parse(
                "${location.createdAt.millisecond}${location.createdAt.microsecond}"),
            StringUtils.truncate(
              l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(
                view.name,
                "test",
              ),
              76,
            ),
            l10n.locationAlarm_notification_description,
            NotificationDetails(
              android: AndroidNotificationDetails(
                AndroidChannelIDs.locationAlarms.name,
                l10n.androidNotificationChannel_locationAlarms_name,
                channelDescription:
                    l10n.androidNotificationChannel_locationAlarms_description,
                importance: Importance.max,
                priority: Priority.max,
              ),
            ),
            payload: jsonEncode({
              "type": NotificationActionType.openTaskView.index,
              "taskViewID": view.id,
            }),
          );
        }
      },
      onMaybeTrigger: (alarm, _, __) async {
        if (view.lastMaybeTrigger != null &&
            view.lastMaybeTrigger!.difference(DateTime.now()).abs() <
                MAYBE_TRIGGER_MINIMUM_TIME_BETWEEN) {
          return;
        }

        if (alarm is RadiusBasedRegionLocationAlarm) {
          final flutterLocalNotificationsPlugin =
              FlutterLocalNotificationsPlugin();

          flutterLocalNotificationsPlugin.show(
            int.parse(
                "${DateTime.now().millisecond}${DateTime.now().microsecond}"),
            StringUtils.truncate(
              l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(
                view.name,
                alarm.zoneName,
              ),
              76,
            ),
            l10n.locationAlarm_notification_description,
            NotificationDetails(
              android: AndroidNotificationDetails(
                AndroidChannelIDs.locationAlarms.name,
                l10n.locationAlarm_radiusBasedRegion_notificationTitle_maybe(
                  view.name,
                  alarm.zoneName,
                ),
                channelDescription:
                    l10n.androidNotificationChannel_locationAlarms_description,
                importance: Importance.max,
                priority: Priority.max,
              ),
            ),
            payload: jsonEncode({
              "type": NotificationActionType.openTaskView.index,
              "taskViewID": view.id,
            }),
          );

          view.lastMaybeTrigger = DateTime.now();
          await viewService.update(view);
        }
      },
    );
  }
}

Future<void> _checkViewAlarms() async {
  final viewService = await ViewService.restore();
  final settings = await SettingsService.restore();
  final alarmsViews = viewService.viewsWithAlarms;
  final locale = Locale(settings.localeName);
  final l10n = await AppLocalizations.delegate.load(locale);

  if (alarmsViews.isEmpty) {
    return;
  }

  checkViewAlarms(
    l10n: l10n,
    views: alarmsViews,
    viewService: viewService,
  );
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;

  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  await runHeadlessTask();

  BackgroundFetch.finish(taskId);
}

Future<bool> isBatterySaveModeEnabled() async {
  try {
    final value = await Battery().isInBatterySaveMode;
    return value;
  } catch (_) {
    return false;
  }
}

Future<void> runHeadlessTask() async {
  final settings = await SettingsService.restore();
  final isBatterySaveEnabled = await isBatterySaveModeEnabled();

  if (isBatterySaveEnabled &&
      settings.lastHeadlessRun != null &&
      DateTime.now().difference(settings.lastHeadlessRun!).abs() <=
          BATTERY_SAVER_ENABLED_MINIMUM_TIME_BETWEEN_HEADLESS_RUNS) {
    // We don't want to run the headless task too often when the battery saver is enabled.
    return;
  }

  await updateLocation();
  await _checkViewAlarms();

  settings.lastHeadlessRun = DateTime.now();
  await settings.save();
}

void configureBackgroundFetch() {
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      requiresCharging: false,
      enableHeadless: true,
      requiredNetworkType: NetworkType.ANY,
      requiresBatteryNotLow: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
      startOnBoot: true,
      stopOnTerminate: false,
    ),
    (taskId) async {
      // We only use one taskId to update the location for all tasks,
      // so we don't need to check the taskId.
      await runHeadlessTask();

      BackgroundFetch.finish(taskId);
    },
    (taskId) {
      // Timeout, we need to finish immediately.
      BackgroundFetch.finish(taskId);
    },
  );
}
