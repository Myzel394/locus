import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/manager_service/helpers.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Checks view alarms while the app is in use
class CheckViewAlarmsLive extends StatefulWidget {
  const CheckViewAlarmsLive({super.key});

  @override
  State<CheckViewAlarmsLive> createState() => _CheckViewAlarmsLiveState();
}

class _CheckViewAlarmsLiveState extends State<CheckViewAlarmsLive> {
  late final StreamSubscription<Position> _subscription;

  @override
  void initState() {
    super.initState();

    final currentLocation = context.read<CurrentLocationService>();
    _subscription = currentLocation.stream.listen((position) async {
      final l10n = AppLocalizations.of(context);
      final viewService = context.read<ViewService>();
      final userLocation = await LocationPointService.fromPosition(position);

      if (!mounted) {
        return;
      }

      checkViewAlarms(
        l10n: l10n,
        viewService: viewService,
        userLocation: userLocation,
      );
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
