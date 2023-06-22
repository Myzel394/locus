import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';

import '../services/location_point_service.dart';
import '../utils/theme.dart';

const TIMEOUT_DURATION = Duration(seconds: 30);

class LocationsLoadingScreen extends StatefulWidget {
  final List<LocationPointService> locations;
  final void Function() onTimeout;

  const LocationsLoadingScreen({
    required this.locations,
    required this.onTimeout,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsLoadingScreen> createState() => _LocationsLoadingScreenState();
}

class _LocationsLoadingScreenState extends State<LocationsLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: TIMEOUT_DURATION);
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        curve: const Interval(
          0.48,
          0.52,
          curve: Curves.linear,
        ),
        parent: _controller,
      ),
    );
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LocationsLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            l10n.loadingLocationsTitle(widget.locations.length),
            style: getSubTitleTextStyle(context),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.locations.length,
              itemBuilder: (context, index) {
                final location = widget.locations[index];

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
        FadeTransition(
          opacity: _opacityAnimation,
          child: TweenAnimationBuilder<double>(
            duration: TIMEOUT_DURATION,
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 1,
              end: 0,
            ),
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value),
          ),
        ),
      ],
    );
  }
}
