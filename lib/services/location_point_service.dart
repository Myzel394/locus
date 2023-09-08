import 'dart:convert';

import 'package:background_locator_2/location_dto.dart';
import 'package:latlong2/latlong.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/utils/cryptography/decrypt.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class LocationPointService {
  final String id;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? speed;
  final double? speedAccuracy;
  final double? heading;
  final double? headingAccuracy;
  final double? batteryLevel;
  final BatteryState? batteryState;
  final bool isCopy;

  LocationPointService({
    required this.id,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    double? altitude,
    double? speed,
    double? speedAccuracy,
    double? heading,
    double? headingAccuracy,
    double? batteryLevel,
    this.isCopy = false,
    this.batteryState,
  })  : altitude = altitude == 0.0 ? null : altitude,
        speed = speed == 0.0 ? null : speed,
        speedAccuracy = speedAccuracy == 0.0 ? null : speedAccuracy,
        heading = heading == 0.0 ? null : heading,
        headingAccuracy = headingAccuracy == 0.0 ? null : headingAccuracy,
        batteryLevel = batteryLevel == 0.0 ? null : batteryLevel;

  String formatRawAddress() =>
      "${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}";

  factory LocationPointService.dummyFromLatLng(final LatLng latLng,
          {final double accuracy = 10.0}) =>
      LocationPointService(
        id: uuid.v4(),
        createdAt: DateTime.now(),
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        accuracy: accuracy,
      );

  static Future<LocationPointService> fromLocationDto(
    final LocationDto locationDto, [
    final bool addBatteryInfo = true,
  ]) async {
    BatteryInfo? batteryInfo;

    if (addBatteryInfo) {
      try {
        batteryInfo = await BatteryInfo.fromCurrent();
      } catch (error) {
        if (error is PlatformException) {
          // Battery level is unavailable (probably iOS simulator)
        } else {
          rethrow;
        }
      }
    }

    return LocationPointService(
      id: uuid.v4(),
      // unix time to DateTime
      createdAt: DateTime.fromMillisecondsSinceEpoch(locationDto.time.toInt()),
      accuracy: locationDto.accuracy,
      latitude: locationDto.latitude,
      longitude: locationDto.longitude,
      altitude: locationDto.altitude,
      speed: locationDto.speed,
      speedAccuracy: locationDto.speedAccuracy,
      heading: locationDto.heading,
      headingAccuracy: null,
      batteryLevel: batteryInfo?.batteryLevel,
      batteryState: batteryInfo?.batteryState,
    );
  }

  static LocationPointService fromJSON(Map<String, dynamic> json) {
    return LocationPointService(
      id: json["id"],
      createdAt: DateTime.parse(json["createdAt"]),
      latitude: json["latitude"],
      longitude: json["longitude"],
      altitude: json["altitude"],
      accuracy: json["accuracy"],
      speed: json["speed"],
      speedAccuracy: json["speedAccuracy"],
      heading: json["heading"],
      headingAccuracy: json["headingAccuracy"],
      batteryLevel: json["batteryLevel"],
      batteryState: json["batteryState"] == null
          ? null
          : BatteryState.values.firstWhere(
              (value) => value.name == json["batteryState"],
            ),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "createdAt": createdAt.toIso8601String(),
      "latitude": latitude,
      "longitude": longitude,
      "altitude": altitude,
      "accuracy": accuracy,
      "speed": speed,
      "speedAccuracy": speedAccuracy,
      "heading": heading,
      "headingAccuracy": headingAccuracy,
      "batteryLevel": batteryLevel,
      "batteryState": batteryState?.name,
    };
  }

  static Future<LocationPointService> fromPosition(
    final Position position,
  ) async {
    BatteryInfo? batteryInfo;

    try {
      batteryInfo = await BatteryInfo.fromCurrent();
    } catch (error) {
      if (error is PlatformException) {
        // Battery level is unavailable (probably iOS simulator)
      } else {
        rethrow;
      }
    }

    return LocationPointService(
      id: uuid.v4(),
      createdAt: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      heading: position.heading,
      batteryLevel: batteryInfo?.batteryLevel,
      batteryState: batteryInfo?.batteryState,
    );
  }

  /// Copies `current` with a new id - mainly used in conjunction with `createUsingCurrentLocation`
  /// in background fetch to avoid fetching the location multiple times.
  LocationPointService copyWithDifferentId() => LocationPointService(
        id: uuid.v4(),
        createdAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        accuracy: accuracy,
        speed: speed,
        speedAccuracy: speedAccuracy,
        heading: heading,
        batteryLevel: batteryLevel,
        batteryState: batteryState,
      );

  static Future<LocationPointService> fromEncrypted(
    final String cipherText,
    final SecretKey encryptionPassword,
  ) async {
    final message = await decryptUsingAES(
      cipherText,
      encryptionPassword,
    );

    return LocationPointService.fromJSON(jsonDecode(message));
  }

  Position asPosition() => Position(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude ?? 0.0,
        accuracy: accuracy,
        speed: speed ?? 0.0,
        speedAccuracy: speedAccuracy ?? 0.0,
        heading: heading ?? 0.0,
        timestamp: createdAt,
      );

  LatLng asLatLng() => LatLng(latitude, longitude);

  LocationPointService copyWith({
    final double? latitude,
    final double? longitude,
    final double? altitude,
    final double? accuracy,
    final double? speed,
    final double? speedAccuracy,
    final double? heading,
    final double? headingAccuracy,
    final double? batteryLevel,
    final BatteryState? batteryState,
  }) =>
      LocationPointService(
        id: id,
        createdAt: createdAt,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        altitude: altitude ?? this.altitude,
        accuracy: accuracy ?? this.accuracy,
        speed: speed ?? this.speed,
        speedAccuracy: speedAccuracy ?? this.speedAccuracy,
        heading: heading ?? this.heading,
        headingAccuracy: headingAccuracy ?? this.headingAccuracy,
        batteryLevel: batteryLevel ?? this.batteryLevel,
        batteryState: batteryState ?? this.batteryState,
        isCopy: true,
      );
}

class BatteryInfo {
  final double batteryLevel;
  final BatteryState batteryState;

  const BatteryInfo({
    required this.batteryLevel,
    required this.batteryState,
  });

  static Future<BatteryInfo> fromCurrent() async {
    final battery = Battery();

    return BatteryInfo(
      batteryLevel: (await battery.batteryLevel) / 100,
      batteryState: (await battery.batteryState),
    );
  }
}
