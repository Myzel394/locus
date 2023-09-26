import 'dart:math';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:locus/widgets/LocusFlutterMap.dart';
import 'package:locus/widgets/MapBanner.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

const INITIAL_RADIUS = 50.0;

class LocationRadiusSelectorMap extends StatefulWidget {
  final MapController? flutterMapController;
  final apple_maps.AppleMapController? appleMapController;
  final void Function(apple_maps.AppleMapController controller)?
      onAppleMapCreated;
  final LatLng? center;
  final double? radius;
  final void Function(LatLng)? onLocationChange;
  final void Function(double)? onRadiusChange;
  final bool enableRealTimeRadiusUpdate;
  final List<Widget> children;

  const LocationRadiusSelectorMap({
    super.key,
    this.flutterMapController,
    this.appleMapController,
    this.onLocationChange,
    this.onRadiusChange,
    this.onAppleMapCreated,
    this.center,
    this.radius,
    this.enableRealTimeRadiusUpdate = false,
    this.children = const [],
  });

  @override
  State<LocationRadiusSelectorMap> createState() =>
      _LocationRadiusSelectorMapState();
}

class _LocationRadiusSelectorMapState extends State<LocationRadiusSelectorMap> {
  LatLng? center;
  double? radius;

  bool isInScaleMode = false;

  double previousScale = 1;

  @override
  void initState() {
    super.initState();

    radius = widget.radius?.toDouble();
    center = widget.center;
  }

  @override
  void didUpdateWidget(covariant LocationRadiusSelectorMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    radius = widget.radius;
    center = widget.center;
  }

  Widget getFlutterMapCircleLayer() => CircleLayer(
        circles: [
          if (center != null && radius != null)
            CircleMarker(
              point: center!,
              radius: radius!,
              useRadiusInMeter: true,
              color: Colors.red.withOpacity(.3),
              borderStrokeWidth: 5,
              borderColor: Colors.red,
            ),
        ],
      );

  void updateZoom(final ScaleUpdateDetails scaleUpdateDetails) async {
    final mapZoom = await (() async {
      if (widget.appleMapController != null) {
        return widget.appleMapController!.getZoomLevel();
      } else if (widget.flutterMapController != null) {
        return widget.flutterMapController!.zoom;
      } else {
        return 0.0;
      }
    })() as double;
    final difference = scaleUpdateDetails.scale - previousScale;
    final multiplier = pow(2, 18 - mapZoom) * .2;

    final newRadius = max<double>(
      50,
      // Radius can only be changed if a center is set;
      // meaning it will always be defined here
      difference > 0 ? radius! + multiplier : radius! - multiplier,
    );

    if (widget.enableRealTimeRadiusUpdate) {
      widget.onRadiusChange?.call(newRadius);
    } else {
      setState(() {
        radius = newRadius;
      });
    }

    previousScale = scaleUpdateDetails.scale;
  }

  void leaveScaleMode() {
    Vibration.vibrate(duration: 50);

    setState(() {
      isInScaleMode = false;
    });

    if (!widget.enableRealTimeRadiusUpdate) {
      widget.onRadiusChange?.call(radius!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onScaleUpdate: isInScaleMode ? updateZoom : null,
      onTap: isInScaleMode ? leaveScaleMode : null,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              ignoring: isInScaleMode,
              child: LocusFlutterMap(
                flutterMapController: widget.flutterMapController,
                appleMapController: widget.appleMapController,
                initialZoom: 13.0,
                onAppleMapCreated: widget.onAppleMapCreated,
                onTap: (location) {
                  location = LatLng(
                    location.latitude,
                    location.longitude,
                  );

                  widget.onLocationChange?.call(location);

                  if (radius == null) {
                    setState(() {
                      radius = INITIAL_RADIUS;
                      center = location;
                    });

                    widget.onRadiusChange?.call(INITIAL_RADIUS);
                  }
                },
                onLongPress: (location) {
                  Vibration.vibrate(duration: 100);

                  setState(() {
                    isInScaleMode = true;
                  });
                },
                flutterChildren: [
                  if (isInScaleMode)
                    Shimmer.fromColors(
                      baseColor: Colors.red,
                      highlightColor: Colors.red.withOpacity(.2),
                      child: getFlutterMapCircleLayer(),
                    )
                  else
                    getFlutterMapCircleLayer(),
                  CurrentLocationLayer(
                    followOnLocationUpdate: FollowOnLocationUpdate.once,
                  )
                ],
                appleMapCircles: {
                  if (center != null && radius != null)
                    if (isInScaleMode)
                      apple_maps.Circle(
                        circleId: apple_maps.CircleId('radius-$radius-scale'),
                        center: toAppleMapsCoordinates(center!),
                        radius: radius!,
                        fillColor: Colors.orangeAccent.withOpacity(.35),
                        strokeColor: Colors.orangeAccent,
                        strokeWidth: 2,
                      )
                    else
                      apple_maps.Circle(
                        circleId: apple_maps.CircleId('radius-$radius'),
                        center: toAppleMapsCoordinates(center!),
                        radius: radius!,
                        fillColor: Colors.red.withOpacity(.25),
                        strokeColor: Colors.red,
                        strokeWidth: 2,
                      )
                },
              ),
            ),
          ),
          // If the map is deactivated via the `IgnorePointer`
          // widget, we need some other widget to handle taps
          // For this, we use an empty `Container`
          if (isInScaleMode) ...[
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            MapBanner(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.pinch_rounded),
                  const SizedBox(width: MEDIUM_SPACE),
                  Flexible(
                    child: Text(
                      l10n.location_addAlarm_radiusBased_isInScaleMode,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.center != null && radius != null)
            Positioned(
              bottom: LARGE_SPACE,
              left: 0,
              right: 0,
              child: Text(
                radius! > 10000
                    ? l10n.location_addAlarm_radiusBased_radius_kilometers(
                        double.parse(
                          (radius! / 1000).toStringAsFixed(1),
                        ),
                      )
                    : l10n.location_addAlarm_radiusBased_radius_meters(
                        radius!.round()),
                textAlign: TextAlign.center,
              ),
            ),
          ...widget.children,
        ],
      ),
    );
  }
}
