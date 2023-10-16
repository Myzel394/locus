import 'package:flutter/material.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/settings_service/SettingsMapLocation.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:provider/provider.dart';

class InitCurrentLocationFromSettings extends StatefulWidget {
  const InitCurrentLocationFromSettings({super.key});

  @override
  State<InitCurrentLocationFromSettings> createState() =>
      _InitCurrentLocationFromSettingsState();
}

class _InitCurrentLocationFromSettingsState
    extends State<InitCurrentLocationFromSettings> {
  late final CurrentLocationService _currentLocation;

  @override
  void initState() {
    super.initState();

    _currentLocation = context.read<CurrentLocationService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      final lastLocation = settings.getLastMapLocation();

      if (lastLocation != null) {
        _setLocation(lastLocation);
      }
    });
  }

  void _setLocation(final SettingsLastMapLocation rawLocation) {
    final position = rawLocation.asPosition();

    _currentLocation.updateCurrentPosition(position);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
