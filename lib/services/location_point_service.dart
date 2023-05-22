import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<String> toEncryptedMessage({
    required final RSAPublicKey viewPublicKey,
    required final ECPrivateKey signPrivateKey,
    required final ECPublicKey signPublicKey,
  }) async {
    final rawMessage = jsonEncode(toJSON());
    final rawMessageBytes = Uint8List.fromList(utf8.encode(rawMessage));
    final signedMessage = CryptoUtils.ecSign(signPrivateKey, rawMessageBytes);
    final signedMessageBase64 = CryptoUtils.ecSignatureToBase64(signedMessage);

    final content = {
      "message": rawMessage,
      "signature": signedMessageBase64,
    };
    final rawContent = jsonEncode(content);

    return CryptoUtils.rsaEncrypt(rawContent, viewPublicKey);
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
    final String cipherMessage,
    final RSAPrivateKey viewPrivateKey,
    final ECPublicKey signPublicKey,
  ) async {
    final rawContent = CryptoUtils.rsaDecrypt(cipherMessage, viewPrivateKey);

    final content = jsonDecode(rawContent);
    final message = content["message"];
    final signatureBase64 = content["signature"];
    final signature = CryptoUtils.ecSignatureFromBase64(signatureBase64);
    final messageBytes = Uint8List.fromList(utf8.encode(message));

    final isSignatureValid = CryptoUtils.ecVerify(signPublicKey, messageBytes, signature);

    if (!isSignatureValid) {
      throw Exception("Invalid signature");
    }

    return LocationPointService.fromJSON(jsonDecode(message));
  }
}
