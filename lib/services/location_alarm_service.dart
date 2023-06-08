import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'location_point_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class LocationAlarmServiceBase {
  String get IDENTIFIER;

  String createNotificationTitle(final AppLocalizations l10n, final String viewName);

  Map<String, dynamic> toJSON();

  // Checks if the alarm should be triggered
  // This function will be called each time the background fetch is updated and there are new locations
  bool check(final LocationPointService previousLocation, final LocationPointService nextLocation);
}

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

  RadiusBasedRegionLocationAlarm({
    required this.center,
    required this.radius,
    required this.type,
    required this.zoneName,
  });

  String get IDENTIFIER => "radius_based_region";

  factory RadiusBasedRegionLocationAlarm.fromJSON(final Map<String, dynamic> data) => RadiusBasedRegionLocationAlarm(
        center: LatLng(data["center"]["latitude"], data["center"]["longitude"]),
        radius: data["radius"],
        type: RadiusBasedRegionLocationAlarmType.values[data["alarmType"]],
        zoneName: data["zoneName"],
      );

  @override
  Map<String, dynamic> toJSON() {
    return {
      "type": IDENTIFIER,
      "center": center.toJson(),
      "radius": radius,
      "zoneName": zoneName,
      "alarmType": type.index,
    };
  }

  @override
  String createNotificationTitle(final l10n, final viewName) {
    switch (type) {
      case RadiusBasedRegionLocationAlarmType.whenEnter:
        return l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenEnter(viewName, zoneName);
      case RadiusBasedRegionLocationAlarmType.whenLeave:
        return l10n.locationAlarm_radiusBasedRegion_notificationTitle_whenLeave(viewName, zoneName);
    }
  }

  // Checks if a given location was inside. If not, it must be outside
  bool _wasInside(final LocationPointService location) {
    final distance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      center.latitude,
      center.longitude,
    );

    return distance <= radius;
  }

  @override
  bool check(final previousLocation, final nextLocation) {
    switch (type) {
      case RadiusBasedRegionLocationAlarmType.whenEnter:
        return !_wasInside(previousLocation) && _wasInside(nextLocation);
      case RadiusBasedRegionLocationAlarmType.whenLeave:
        return _wasInside(previousLocation) && !_wasInside(nextLocation);
    }
  }
}
