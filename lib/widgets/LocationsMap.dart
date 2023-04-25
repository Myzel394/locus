import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as AppleMaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:intl/intl.dart';

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

  String get snippetText {
    final location = widget.locations.last;

    final batteryInfo = location.batteryLevel == null
        ? ""
        : "Battery at ${(location.batteryLevel! * 100).ceil()}%";
    final dateInfo =
        "Date: ${DateFormat.yMd().add_jm().format(location.createdAt)}";
    final speedInfo = location.speed == null
        ? ""
        : "Moving at ${(location.speed!.abs() * 3.6).ceil()} km/h";

    return [
      batteryInfo,
      dateInfo,
      speedInfo,
    ].where((element) => element.isNotEmpty).join("\n");
  }

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
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      annotations: {
        AppleMaps.Annotation(
          annotationId: AppleMaps.AnnotationId(
            "annotation_${widget.locations.last.latitude}:${widget.locations.last.longitude}",
          ),
          position: AppleMaps.LatLng(
            widget.locations.last.latitude,
            widget.locations.last.longitude,
          ),
          infoWindow: AppleMaps.InfoWindow(
            title: "Last known location",
            snippet: snippetText,
          ),
        ),
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
    return OSMFlutter(
      controller: _controller,
      initZoom: 15,
      trackMyPosition: true,
      androidHotReloadSupport: kDebugMode,
      onMapIsReady: (controller) {
        drawPoints();
      },
      onGeoPointClicked: (point) {
        print(point);
      },
    );
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
