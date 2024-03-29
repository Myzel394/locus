import 'dart:async';

import 'package:flutter/material.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/location_history_service/index.dart';
import 'package:provider/provider.dart';

/// Makes sure that the [LocationHistory] is updated with the current location
/// from the [CurrentLocationService].
class UpdateLocationHistory extends StatefulWidget {
  const UpdateLocationHistory({super.key});

  @override
  State<UpdateLocationHistory> createState() => _UpdateLocationHistoryState();
}

class _UpdateLocationHistoryState extends State<UpdateLocationHistory> {
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    final currentLocation = context.read<CurrentLocationService>();
    final locationHistory = context.read<LocationHistory>();
    _subscription = currentLocation.stream.listen(locationHistory.add);
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
