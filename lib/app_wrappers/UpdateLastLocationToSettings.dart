import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/settings_service/SettingsMapLocation.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:provider/provider.dart';

class UpdateLastLocationToSettings extends StatefulWidget {
  const UpdateLastLocationToSettings({super.key});

  @override
  State<UpdateLastLocationToSettings> createState() =>
      _UpdateLastLocationToSettingsState();
}

class _UpdateLastLocationToSettingsState
    extends State<UpdateLastLocationToSettings> {
  late final CurrentLocationService _currentLocation;

  @override
  void initState() {
    super.initState();

    _currentLocation = context.read<CurrentLocationService>();

    _currentLocation.addListener(_handleLocationChange);
  }

  void _handleLocationChange() async {
    final settings = context.read<SettingsService>();
    final position = _currentLocation.currentPosition;

    if (position == null) {
      return;
    }

    settings.setLastMapLocation(
      SettingsLastMapLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      ),
    );
    await settings.save();
  }

  @override
  void dispose() {
    _currentLocation.removeListener(_handleLocationChange);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
