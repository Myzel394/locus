import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class SettingsLastMapLocation {
  final double latitude;
  final double longitude;
  final double accuracy;

  const SettingsLastMapLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  factory SettingsLastMapLocation.fromJSON(final Map<String, dynamic> data) =>
      SettingsLastMapLocation(
        latitude: data['latitude'] as double,
        longitude: data['longitude'] as double,
        accuracy: data['accuracy'] as double,
      );

  Map<String, dynamic> toJSON() =>
      {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };

  LatLng toLatLng() => LatLng(latitude, longitude);

  Position asPosition() =>
      Position(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        timestamp: DateTime.now(),
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}
