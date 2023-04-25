import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as AppleMaps;
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

import '../services/location_point_service.dart';

class LocationsMapAppleMaps extends StatefulWidget {
  final List<LocationPointService> locations;

  const LocationsMapAppleMaps({
    required this.locations,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsMapAppleMaps> createState() => _LocationsMapAppleMapsState();
}

class _LocationsMapAppleMapsState extends State<LocationsMapAppleMaps> {
  late final AppleMaps.AppleMapController _controller;

  @override
  Widget build(BuildContext context) {
    return AppleMaps.AppleMap(
      initialCameraPosition: AppleMaps.CameraPosition(
        target: AppleMaps.LatLng(
          widget.locations.last.latitude,
          widget.locations.last.longitude,
        ),
        zoom: 16,
      ),
      onMapCreated: (controller) {
        _controller = controller;
      },
      circles: widget.locations
          .map(
            (location) => AppleMaps.Circle(
              circleId: AppleMaps.CircleId(
                "circle_${location.latitude}:${location.longitude}",
              ),
              center: AppleMaps.LatLng(
                location.latitude,
                location.longitude,
              ),
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: location.accuracy < 10 ? 1 : 3,
              radius: location.accuracy,
            ),
          )
          .toSet(),
    );
  }
}

class LocationsMapOSM extends StatefulWidget {
  final List<LocationPointService> locations;

  const LocationsMapOSM({
    required this.locations,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsMapOSM> createState() => _LocationsMapOSMState();
}

class _LocationsMapOSMState extends State<LocationsMapOSM> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();

    _controller = MapController(
      initMapWithUserPosition: true,
    );
  }

  @override
  void didUpdateWidget(covariant LocationsMapOSM oldWidget) {
    super.didUpdateWidget(oldWidget);

    drawPoints();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void drawPoints() {
    _controller.removeAllCircle();

    for (final location in widget.locations) {
      _controller.drawCircle(
        CircleOSM(
          key: "circle_${location.latitude}:${location.longitude}",
          centerPoint: GeoPoint(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
          radius: location.accuracy,
          color: Colors.blue,
          strokeWidth: location.accuracy < 10 ? 1 : 3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class LocationsMap extends StatelessWidget {
  final List<LocationPointService> locations;

  const LocationsMap({
    required this.locations,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return LocationsMapAppleMaps(
        locations: locations,
      );
    }
    return LocationsMapOSM(
      locations: locations,
    );
  }
}
