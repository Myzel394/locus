import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:uuid/uuid.dart';

import 'LocationAlarmServiceBase.dart';
import 'enums.dart';

const uuid = Uuid();

enum RadiusBasedRegionLocationAlarmType {
  whenEnter,
  whenLeave,
}

class RadiusBasedRegionLocationAlarm extends LocationAlarmServiceBase {
  final String zoneName;
  final LatLng center;

  // Radius in meters
  final double radius;
  final RadiusBasedRegionLocationAlarmType type;

  const RadiusBasedRegionLocationAlarm({
    required this.center,
    required this.radius,
    required this.type,
    required this.zoneName,
    required String id,
  }) : super(id);

  @override
  LocationAlarmType get IDENTIFIER => LocationAlarmType.radiusBasedRegion;

  factory RadiusBasedRegionLocationAlarm.fromJSON(
          final Map<String, dynamic> data) =>
      RadiusBasedRegionLocationAlarm(
        center: LatLng.fromJson(data["center"]),
        radius: data["radius"],
        type: RadiusBasedRegionLocationAlarmType.values[data["alarmType"]],
        zoneName: data["zoneName"],
        id: data["id"],
      );

  factory RadiusBasedRegionLocationAlarm.create({
    required final LatLng center,
    required final double radius,
    required final RadiusBasedRegionLocationAlarmType type,
    required final String zoneName,
  }) =>
      RadiusBasedRegionLocationAlarm(
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
      case RadiusBasedRegionLocationAlarmType.whenEnter:
        return l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(
            viewName, zoneName);
      case RadiusBasedRegionLocationAlarmType.whenLeave:
        return l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenLeave(
            viewName, zoneName);
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
      case RadiusBasedRegionLocationAlarmType.whenEnter:
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
      case RadiusBasedRegionLocationAlarmType.whenLeave:
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

  Icon getIcon(final BuildContext context) {
    switch (type) {
      case RadiusBasedRegionLocationAlarmType.whenEnter:
        return const Icon(Icons.arrow_circle_right_rounded);
      case RadiusBasedRegionLocationAlarmType.whenLeave:
        return const Icon(Icons.arrow_circle_left_rounded);
    }
  }
}
