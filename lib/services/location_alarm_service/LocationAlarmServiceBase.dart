import 'package:locus/services/location_point_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'enums.dart';

abstract class LocationAlarmServiceBase {
  final String id;

  LocationAlarmType get IDENTIFIER;

  String createNotificationTitle(
      final AppLocalizations l10n, final String viewName);

  Map<String, dynamic> toJSON();

  // Checks if the alarm should be triggered
  // This function will be called each time the background fetch is updated and there are new locations
  LocationAlarmTriggerType check(
    final LocationPointService previousLocation,
    final LocationPointService nextLocation, {
    final LocationPointService userLocation,
  });

  String getStorageKey() => "location_alarm_service:$IDENTIFIER:$id";

  const LocationAlarmServiceBase(this.id);
}
