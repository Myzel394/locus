import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/constants/values.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/location_point_service.dart';

import 'task.dart';

@pragma('vm:entry-point')
void runBackgroundLocatorTask(final LocationDto location) async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Locator",
    "Running background locator",
  );

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Locator",
    "Parsing location...",
  );
  LocationPointService? locationData;

  try {
    locationData = await LocationPointService.fromLocationDto(location);
    FlutterLogs.logInfo(
      LOG_TAG,
      "Background Locator",
      "Parsing location... Done!",
    );
  } catch (error) {
    FlutterLogs.logError(
      LOG_TAG,
      "Background Locator",
      "Error while parsing location: $error",
    );
    FlutterLogs.logInfo(
      LOG_TAG,
      "Background Locator",
      "Will try continuing without location data.",
    );
  }

  await runBackgroundTask(
    locationData: locationData,
  );

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Locator",
    "Running background locator... Done!",
  );
}

Future<void> configureBackgroundLocator() {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Locator",
    "Initializing background locator.",
  );

  return BackgroundLocator.initialize();
}

Future<void> registerBackgroundLocator(final BuildContext context) {
  final l10n = AppLocalizations.of(context);

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Locator",
    "Registering background locator.",
  );

  return BackgroundLocator.registerLocationUpdate(
    runBackgroundLocatorTask,
    autoStop: false,
    androidSettings: AndroidSettings(
      accuracy: LocationAccuracy.HIGH,
      distanceFilter:
          BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER.toDouble(),
      client: isGMSFlavor ? LocationClient.google : LocationClient.android,
      androidNotificationSettings: AndroidNotificationSettings(
        notificationTitle: l10n.backgroundLocator_title,
        notificationMsg: l10n.backgroundLocator_text,
        notificationBigMsg: l10n.backgroundLocator_text,
        notificationChannelName: l10n.backgroundLocator_channelName,
        notificationIcon: "ic_quick_actions_share_now",
      ),
    ),
    iosSettings: IOSSettings(
      distanceFilter:
          BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER.toDouble(),
      accuracy: LocationAccuracy.HIGH,
      showsBackgroundLocationIndicator: true,
      stopWithTerminate: false,
    ),
  );
}

Future<void> removeBackgroundLocator() {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Locator",
    "Removing background locator.",
  );

  return BackgroundLocator.unRegisterLocationUpdate();
}
