import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/services/location_point_service.dart';

import 'LocationAlarmServiceBase.dart';

class ProximityLocationAlarm extends LocationAlarmServiceBase {
  // Radius in meters
  final double radius;
  final LocationRadiusBasedTriggerType type;

  const ProximityLocationAlarm({
    required this.radius,
    required this.type,
    required String id,
  }) : super(id);

  @override
  LocationAlarmType get IDENTIFIER => LocationAlarmType.proximity;

  factory ProximityLocationAlarm.fromJSON(
    final Map<String, dynamic> data,
  ) =>
      ProximityLocationAlarm(
        radius: data["radius"],
        type: LocationRadiusBasedTriggerType.values[data["alarmType"]],
        id: data["id"],
      );

  factory ProximityLocationAlarm.create({
    required final double radius,
    required final LocationRadiusBasedTriggerType type,
  }) =>
      ProximityLocationAlarm(
        radius: radius,
        type: type,
        id: uuid.v4(),
      );

  LocationAlarmTriggerType _wasInside(
    final LocationPointService location,
    final LocationPointService userLocation,
  ) {
    final fullDistance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      userLocation.latitude,
      userLocation.longitude,
    );

    if (fullDistance < radius && location.accuracy < radius) {
      return LocationAlarmTriggerType.yes;
    }

    if (fullDistance - location.accuracy - radius > 0) {
      return LocationAlarmTriggerType.no;
    }

    return LocationAlarmTriggerType.maybe;
  }

  @override
  LocationAlarmTriggerType check(
    LocationPointService previousLocation,
    LocationPointService nextLocation, {
    required LocationPointService userLocation,
  }) {
    final previousInside = _wasInside(previousLocation, userLocation);
    final nextInside = _wasInside(nextLocation, userLocation);

    switch (type) {
      case LocationRadiusBasedTriggerType.whenEnter:
        if (previousInside == LocationAlarmTriggerType.no &&
            nextInside == LocationAlarmTriggerType.yes) {
          return LocationAlarmTriggerType.yes;
        }

        if (previousInside == LocationAlarmTriggerType.maybe &&
            nextInside == LocationAlarmTriggerType.yes) {
          return LocationAlarmTriggerType.yes;
        }

        if (previousInside == LocationAlarmTriggerType.no &&
            nextInside == LocationAlarmTriggerType.maybe) {
          return LocationAlarmTriggerType.maybe;
        }

        if (previousInside == LocationAlarmTriggerType.maybe &&
            nextInside == LocationAlarmTriggerType.maybe) {
          return LocationAlarmTriggerType.maybe;
        }
        break;
      case LocationRadiusBasedTriggerType.whenLeave:
        if (previousInside == LocationAlarmTriggerType.yes &&
            nextInside == LocationAlarmTriggerType.no) {
          return LocationAlarmTriggerType.yes;
        }

        if (previousInside == LocationAlarmTriggerType.maybe &&
            nextInside == LocationAlarmTriggerType.no) {
          return LocationAlarmTriggerType.yes;
        }

        if (previousInside == LocationAlarmTriggerType.yes &&
            nextInside == LocationAlarmTriggerType.maybe) {
          return LocationAlarmTriggerType.maybe;
        }

        if (previousInside == LocationAlarmTriggerType.maybe &&
            nextInside == LocationAlarmTriggerType.maybe) {
          return LocationAlarmTriggerType.maybe;
        }
        break;
    }

    return LocationAlarmTriggerType.no;
  }

  @override
  String createNotificationTitle(AppLocalizations l10n, String viewName) {
    switch (type) {
      case LocationRadiusBasedTriggerType.whenEnter:
        return l10n.locationAlarm_proximityLocation_notificationTitle_whenEnter(
          viewName,
          radius.round(),
        );
      case LocationRadiusBasedTriggerType.whenLeave:
        return l10n.locationAlarm_proximityLocation_notificationTitle_whenLeave(
          viewName,
          radius.round(),
        );
    }
  }

  @override
  Map<String, dynamic> toJSON() {
    return {
      "_IDENTIFIER": IDENTIFIER.name,
      "radius": radius,
      "alarmType": type.index,
      "id": id,
    };
  }
}
