import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

import 'package:vibration/vibration.dart';

class ViewAlarmManagerScreen extends StatefulWidget {
  const ViewAlarmManagerScreen({super.key});

  @override
  State<ViewAlarmManagerScreen> createState() => _ViewAlarmManagerScreenState();
}

class _ViewAlarmManagerScreenState extends State<ViewAlarmManagerScreen> {
  final controller = MapController();
  LatLng? alarmCenter;
  bool isInScaleMode = false;
  double radius = 100;
  double previousScale = 1;

  @override
  void initState() {
    super.initState();

    Geolocator.getLastKnownPosition().then((location) {
      if (location == null) {
        return;
      }

      controller.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
    });

    Geolocator.getCurrentPosition(
      // We want to get the position as fast as possible
      desiredAccuracy: LocationAccuracy.lowest,
    ).then((location) {
      controller.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  CircleLayer getCircleLayer() => CircleLayer(
        circles: [
          CircleMarker(
            point: alarmCenter!,
            radius: radius,
            useRadiusInMeter: true,
            color: Colors.red.withOpacity(.3),
            borderStrokeWidth: 5,
            borderColor: Colors.red,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: GestureDetector(
        onScaleUpdate: isInScaleMode
            ? (details) {
                final mapZoom = controller.zoom;
                final difference = details.scale - previousScale;
                final multiplier = math.pow(2, 18 - mapZoom) * .2;

                final newRadius = math.max<double>(
                  50,
                  difference > 0 ? radius + multiplier : radius - multiplier,
                );

                setState(() {
                  radius = newRadius;
                });

                previousScale = details.scale;
              }
            : null,
        onLongPress: isInScaleMode
            ? () {
                Vibration.vibrate(duration: 50);
                setState(() {
                  isInScaleMode = false;
                });
              }
            : null,
        // We need a `Stack` to disable the map, but also need to show a container to detect the long press again
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                ignoring: isInScaleMode,
                child: FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    onLongPress: (_, __) {
                      Vibration.vibrate(duration: 100);

                      setState(() {
                        isInScaleMode = true;
                      });
                    },
                    center: LatLng(40, 20),
                    zoom: 13,
                    onTap: (tapPosition, location) {
                      setState(() {
                        alarmCenter = location;
                      });
                    },
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: "app.myzel394.locus",
                    ),
                    if (alarmCenter != null)
                      if (isInScaleMode)
                        Shimmer.fromColors(
                          baseColor: Colors.red,
                          highlightColor: Colors.red.withOpacity(.2),
                          child: getCircleLayer(),
                        )
                      else
                        getCircleLayer(),
                  ],
                ),
              ),
            ),
            if (isInScaleMode)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
