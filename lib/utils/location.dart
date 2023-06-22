import 'package:flutter_logs/flutter_logs.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/values.dart';

enum LocationMethod {
  best,
  worst,
  androidLocationManagerBest,
  androidLocationManagerWorst,
}

const TIMEOUT_DURATION = Duration(minutes: 1);

Future<Position?> _getLocationUsingMethod(final LocationMethod method) async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Get Location",
    "Getting location using method: $method",
  );

  try {
    switch (method) {
      case LocationMethod.best:
        final result = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: false,
          timeLimit: TIMEOUT_DURATION,
        );
        return result;
      case LocationMethod.worst:
        final result = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.lowest,
          forceAndroidLocationManager: false,
          timeLimit: TIMEOUT_DURATION,
        );
        return result;
      case LocationMethod.androidLocationManagerBest:
        final result = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: true,
          timeLimit: TIMEOUT_DURATION,
        );
        return result;
      case LocationMethod.androidLocationManagerWorst:
        final result = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          forceAndroidLocationManager: true,
          timeLimit: TIMEOUT_DURATION,
        );
        return result;
    }
  } catch (error) {
    FlutterLogs.logError(
      LOG_TAG,
      "Get Location",
      "Error getting location using method $method: $error",
    );
    return null;
  }
}

Future<Position> getCurrentPosition({
  final void Function(LocationMethod)? onMethodCheck,
}) async {
  for (final method in LocationMethod.values) {
    onMethodCheck?.call(method);

    final position = await _getLocationUsingMethod(method);
    if (position != null) {
      return position;
    }
  }

  throw Exception("Could not get location");
}
