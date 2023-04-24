import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../services/location_point_service.dart';
import '../utils/theme.dart';

class LocationsLoadingScreen extends StatelessWidget {
  final List<LocationPointService> locations;

  const LocationsLoadingScreen({
    required this.locations,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            "Loading locations: ${locations.length}",
            style: getTitleTextStyle(context),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];

                return Text(
                  "${location.latitude}, ${location.longitude}",
                  style: getBodyTextTextStyle(context),
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Lottie.asset(
            "assets/lotties/search.json",
            frameRate: FrameRate.max,
            delegates: LottieDelegates(
              values: [
                ...List.generate(
                  // Starts at 8, ends at 8
                  18 - 8,
                  (index) => ValueDelegate.strokeColor(
                    ["Shape Layer ${index + 8}", "Ellipse 1", "Stroke 1"],
                    value: shades[800],
                  ),
                ),
                ValueDelegate.strokeColor(
                  const ["Shape Layer 1", "Ellipse 1", "Stroke 1"],
                  value: shades[500],
                ),
                ValueDelegate.strokeColor(
                  const ["Shape Layer 1", "Ellipse 2", "Stroke 1"],
                  value: shades[500],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 800.ms),
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 20),
          curve: Curves.easeInOut,
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ),
          builder: (context, value, _) => LinearProgressIndicator(value: value),
        ).animate().fadeIn(duration: 2.seconds, delay: 10.seconds),
      ],
    );
  }
}
