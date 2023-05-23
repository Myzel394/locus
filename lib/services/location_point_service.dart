import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../utils/cryptography.dart';

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
    this.batteryState,
  })  : altitude = altitude == 0.0 ? null : altitude,
        speed = speed == 0.0 ? null : speed,
        speedAccuracy = speedAccuracy == 0.0 ? null : speedAccuracy,
        heading = heading == 0.0 ? null : heading,
        headingAccuracy = headingAccuracy == 0.0 ? null : headingAccuracy,
        batteryLevel = batteryLevel == 0.0 ? null : batteryLevel;

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
      batteryState: BatteryState.values.firstWhere(
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

  static Future<LocationPointService> createUsingCurrentLocation([
    final Position? position,
  ]) async {
    final locationData = position ??
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(minutes: 5),
        );
    double? batteryLevel;
    BatteryState? batteryState;

    try {
      final battery = Battery();

      batteryLevel = (await battery.batteryLevel) / 100;
      batteryState = await battery.batteryState;
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
      latitude: locationData.latitude,
      longitude: locationData.longitude,
      altitude: locationData.altitude,
      accuracy: locationData.accuracy,
      speed: locationData.speed,
      speedAccuracy: locationData.speedAccuracy,
      heading: locationData.heading,
      batteryLevel: batteryLevel,
      batteryState: batteryState,
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
}
