import 'dart:convert';
import 'dart:ui';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/notifications.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/models/log.dart';
import 'package:locus/services/location_alarm_service/ProximityLocationAlarm.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/services/location_alarm_service/index.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/log_service.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/location/index.dart' as location;

Future<LocationPointService> getLocationData() async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Update Location",
    "Fetching position now...",
  );
  late final Position position;

  try {
    position = await location.getCurrentPosition();
  } catch (error) {
    FlutterLogs.logError(
      LOG_TAG,
      "Headless Task; Update Location",
      "Error while fetching position: $error",
    );
    throw error;
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Update Location",
    "Fetching position now... Done!",
  );

  return LocationPointService.fromPosition(
    position,
  );
}

Future<void> updateLocation(
  final LocationPointService locationData,
) async {
  final taskService = await TaskService.restore();
  final logService = await LogService.restore();

  await taskService.checkup(logService);
  final runningTasks = await taskService.getRunningTasks().toList();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Update Location",
    "Everything restored, now checking for running tasks.",
  );

  if (runningTasks.isEmpty) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task; Update Location",
      "No tasks to run available",
    );
    return;
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Update Location",
    "Publishing position to ${runningTasks.length} tasks...",
  );

  for (final task in runningTasks) {
    await task.publisher.publishOutstandingPositions();
    await task.publisher.publishLocation(locationData.copyWithDifferentId());
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Update Location",
    "Publishing position to ${runningTasks.length} tasks... Done!",
  );

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
  required final LocationPointService userLocation,
}) async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Check View Alarms",
    "Checking ${views.length} views...",
  );

  for (final view in views) {
    await view.checkAlarm(
      userLocation: userLocation,
      onTrigger: (alarm, location, __) async {
        final notifications = FlutterLocalNotificationsPlugin();
        final id = int.parse(
          "${location.createdAt.millisecond}${location.createdAt.microsecond}",
        );

        if (alarm is GeoLocationAlarm) {
          notifications.show(
            id,
            StringUtils.truncate(
              alarm.type == LocationRadiusBasedTriggerType.whenEnter
                  ? l10n
                      .locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(
                      view.name,
                      alarm.zoneName,
                    )
                  : l10n
                      .locationAlarm_radiusBasedRegion_notificationTitle_whenLeave(
                      view.name,
                      alarm.zoneName,
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
          return;
        }

        if (alarm is ProximityLocationAlarm) {
          notifications.show(
            id,
            StringUtils.truncate(
              alarm.type == LocationRadiusBasedTriggerType.whenEnter
                  ? l10n
                      .locationAlarm_proximityLocation_notificationTitle_whenEnter(
                      view.name,
                      alarm.radius.round(),
                    )
                  : l10n
                      .locationAlarm_proximityLocation_notificationTitle_whenLeave(
                      view.name,
                      alarm.radius.round(),
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
      onMaybeTrigger: (alarm, _, __) async {},
    );
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Check View Alarms",
    "Checking ${views.length} views... Done! Saving...",
  );

  await viewService.save();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Headless Task; Check View Alarms",
    "Checking ${views.length} views... Done! Saving... Done!",
  );
}

Future<void> checkViewAlarmsFromBackground(
  final LocationPointService userLocation,
) async {
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
    userLocation: userLocation,
  );
}
