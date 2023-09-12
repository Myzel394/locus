import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/utils/location/get-fallback-location.dart';
import 'package:locus/widgets/LocusFlutterMap.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:locus/widgets/MapBanner.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const INITIAL_RADIUS = 50.0;

class LocationRadiusSelectorMap extends StatefulWidget {
  final MapController? flutterMapController;
  final apple_maps.AppleMapController? appleMapController;
  final LatLng? center;
  final double? radius;
  final void Function(LatLng, double)? onLocationSelected;

  const LocationRadiusSelectorMap({
    super.key,
    this.flutterMapController,
    this.appleMapController,
    this.onLocationSelected,
    this.center,
    this.radius,
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

    setState(() {
      radius = newRadius;
    });

    previousScale = scaleUpdateDetails.scale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onScaleUpdate: isInScaleMode ? updateZoom : null,
      onTap: isInScaleMode
          ? () {
              Vibration.vibrate(duration: 50);

              setState(() {
                isInScaleMode = false;
              });
            }
          : null,
      child: Expanded(
        flex: 10,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Stack(
                children: <Widget>[
                  IgnorePointer(
                    ignoring: isInScaleMode,
                    child: LocusFlutterMap(
                      mapController: widget.flutterMapController!,
                      options: MapOptions(
                        onLongPress: (_, __) {
                          Vibration.vibrate(duration: 100);

                          setState(() {
                            isInScaleMode = true;
                          });
                        },
                        center: getFallbackLocation(context),
                        zoom: FALLBACK_LOCATION_ZOOM_LEVEL,
                        onTap: (tapPosition, location) {
                          location = LatLng(
                            location.latitude,
                            location.longitude,
                          );

                          if (radius == null) {
                            setState(() {
                              radius = INITIAL_RADIUS;
                              center = location;
                            });
                          }

                          widget.onLocationSelected
                              ?.call(location, radius ?? INITIAL_RADIUS);
                        },
                        maxZoom: 18,
                      ),
                      children: [
                        if (isInScaleMode)
                          Shimmer.fromColors(
                            baseColor: Colors.red,
                            highlightColor: Colors.red.withOpacity(.2),
                            child: getFlutterMapCircleLayer(),
                          )
                        else
                          getFlutterMapCircleLayer(),
                        CurrentLocationLayer(
                          followOnLocationUpdate: FollowOnLocationUpdate.always,
                        )
                      ],
                    ),
                  ),
                  if (isInScaleMode)
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
                  if (widget.center != null && widget.radius != null)
                    Positioned(
                      bottom: LARGE_SPACE,
                      left: 0,
                      right: 0,
                      child: Text(
                        widget.radius! > 10000
                            ? l10n
                                .location_addAlarm_radiusBased_radius_kilometers(
                                    widget.radius! / 1000)
                            : l10n.location_addAlarm_radiusBased_radius_meters(
                                widget.radius!.round()),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
