import 'dart:async';

import 'package:flutter/material.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/location_history_service/index.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:provider/provider.dart';

/// Makes sure that the [LocationHistory] is updated with the current location
/// from the [CurrentLocationService].
class LocationHistoryUpdater extends StatefulWidget {
  const LocationHistoryUpdater({super.key});

  @override
  State<LocationHistoryUpdater> createState() => _LocationHistoryUpdaterState();
}

class _LocationHistoryUpdaterState extends State<LocationHistoryUpdater> {
  late final CurrentLocationService _currentLocation;
  late final StreamSubscription _subscription;
  late final LocationHistory _locationHistory;

  @override
  void initState() {
    super.initState();

    _currentLocation = context.read<CurrentLocationService>();
    _subscription = _currentLocation.stream.listen((position) async {
      final location = await LocationPointService.fromPosition(position);

      _locationHistory.add(location);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
