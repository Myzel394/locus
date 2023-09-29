import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:uuid/uuid.dart';

import 'LocationAlarmServiceBase.dart';
import 'enums.dart';

const uuid = Uuid();

class GeoLocationAlarm extends LocationAlarmServiceBase {
  final String zoneName;
  final LatLng center;

  // Radius in meters
  final double radius;
  final LocationRadiusBasedTriggerType type;

  const GeoLocationAlarm({
    required this.center,
    required this.radius,
    required this.type,
    required this.zoneName,
    required String id,
  }) : super(id);

  @override
  LocationAlarmType get IDENTIFIER => LocationAlarmType.geo;

  factory GeoLocationAlarm.fromJSON(
    final Map<String, dynamic> data,
  ) =>
      GeoLocationAlarm(
        center: LatLng.fromJson(data["center"]),
        radius: data["radius"],
        type: LocationRadiusBasedTriggerType.values[data["alarmType"]],
        zoneName: data["zoneName"],
        id: data["id"],
      );

  factory GeoLocationAlarm.create({
    required final LatLng center,
    required final double radius,
    required final LocationRadiusBasedTriggerType type,
    required final String zoneName,
  }) =>
      GeoLocationAlarm(
        center: center,
        radius: radius,
        type: type,
        zoneName: zoneName,
        id: uuid.v4(),
      );

  @override
  Map<String, dynamic> toJSON() {
    return {
      "_IDENTIFIER": IDENTIFIER.name,
      "center": center.toJson(),
      "radius": radius,
      "zoneName": zoneName,
      "alarmType": type.index,
      "id": id,
    };
  }

  @override
  String createNotificationTitle(final l10n, final viewName) {
    switch (type) {
      case LocationRadiusBasedTriggerType.whenEnter:
        return l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(
          viewName,
          zoneName,
        );
      case LocationRadiusBasedTriggerType.whenLeave:
        return l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenLeave(
          viewName,
          zoneName,
        );
    }
  }

  // Checks if a given location was inside. If not, it must be outside
  LocationAlarmTriggerType _wasInside(final LocationPointService location) {
    final fullDistance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      center.latitude,
      center.longitude,
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
    final previousLocation,
    final nextLocation, {
    final LocationPointService? userLocation,
  }) {
    final previousInside = _wasInside(previousLocation);
    final nextInside = _wasInside(nextLocation);

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
}
