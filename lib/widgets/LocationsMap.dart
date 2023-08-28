import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:latlong2/latlong.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/permission.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/utils/location/index.dart';
import 'package:provider/provider.dart';

import '../constants/values.dart';
import '../services/location_point_service.dart';
import 'LocusFlutterMap.dart';

apple_maps.LatLng toAppleMapsCoordinates(final LatLng coordinates) =>
    apple_maps.LatLng(coordinates.latitude, coordinates.longitude);

class LocationsMapController extends ChangeNotifier {
  // A controller for `LocationsMap`
  // Basically a wrapper for `FlutterOSMPlugin` and `AppleMaps`
  // Used to control the map from outside of the widget
  final List<LocationPointService> _locations;

  // To inform our wrappers to update the map, we use a stream.
  // This emits event to which our wrappers listen to.
  final StreamController<Map<String, dynamic>> _eventEmitter =
      StreamController.broadcast();

  LocationsMapController({
    List<LocationPointService>? locations,
  }) : _locations = locations ?? [];

  static DateTime normalizeDateTime(final DateTime dateTime) => DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
      );

  Stream<Map<String, dynamic>> get eventListener => _eventEmitter.stream;

  bool get useAppleMaps => Platform.isIOS;

  UnmodifiableListView<LocationPointService> get locations =>
      UnmodifiableListView(_locations);

  @override
  void dispose() {
    _eventEmitter.close();

    super.dispose();
  }

  void add(LocationPointService location) {
    _locations.add(location);
    notifyListeners();
  }

  void addAll(Iterable<LocationPointService> locations) {
    _locations.addAll(locations);
    notifyListeners();
  }

  void clear() {
    _locations.clear();
    notifyListeners();
  }

  void remove(LocationPointService location) {
    _locations.remove(location);
    notifyListeners();
  }

  void sort() {
    // Sort descending
    _locations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // Groups the locations by hour and returns a map of the hour and the number of locations in that hour.
  Map<DateTime, List<LocationPointService>> getLocationsPerHour() =>
      _locations.fold(
        {},
        (final Map<DateTime, List<LocationPointService>> value, element) {
          final date = normalizeDateTime(element.createdAt);

          if (value.containsKey(date)) {
            value[date]!.add(element);
          } else {
            value[date] = [element];
          }

          return value;
        },
      );

  void goTo(final LocationPointService location) {
    _eventEmitter.add({
      "type": "goTo",
      "location": location,
    });
  }

  void goToUserLocation() {
    _eventEmitter.add({
      "type": "goToUserLocation",
    });
  }
}

class LocationsMapCircle {
  final String id;
  final LatLng center;
  final double radius;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;

  const LocationsMapCircle({
    required this.id,
    required this.center,
    required this.radius,
    required this.color,
    final Color? strokeColor,
    this.strokeWidth = 5.0,
  }) : strokeColor = strokeColor ?? color;

  apple_maps.Circle get asAppleMaps => apple_maps.Circle(
        circleId: apple_maps.CircleId(center.toString()),
        center: toAppleMapsCoordinates(center),
        radius: radius,
        fillColor: color,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth.round(),
      );

  CircleMarker get asFlutterMap => CircleMarker(
        point: center,
        color: color,
        borderColor: strokeColor,
        borderStrokeWidth: strokeWidth,
        useRadiusInMeter: true,
        radius: radius,
      );
}

class LocationsMap extends StatefulWidget {
  final LocationsMapController controller;
  final double initialZoomLevel;
  final bool initWithUserPosition;

  final List<LocationsMapCircle> circles;
  final bool showCircles;

  const LocationsMap({
    required this.controller,
    this.initialZoomLevel = 16,
    this.initWithUserPosition = false,
    this.circles = const [],
    this.showCircles = true,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsMap> createState() => _LocationsMapState();
}

class _LocationsMapState extends State<LocationsMap> {
  late final StreamSubscription _controllerSubscription;
  Stream<Position>? _positionStream;

  apple_maps.AppleMapController? appleMapsController;
  MapController? flutterMapController;

  static toAppleCoordinate(final LatLng latLng) =>
      apple_maps.LatLng(latLng.latitude, latLng.longitude);

  bool get shouldUseAppleMaps {
    final settings = context.read<SettingsService>();

    return settings.getMapProvider() == MapProvider.apple;
  }

  String get snippetText {
    final location = widget.controller.locations.last;

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
  void initState() {
    super.initState();

    _controllerSubscription =
        widget.controller.eventListener.listen(eventEmitterListener);

    if (widget.initWithUserPosition) {
      fetchUserPosition();
    }

    if (!shouldUseAppleMaps) {
      flutterMapController = MapController();
    }
  }

  LatLng getInitialPosition() {
    if (widget.controller.locations.isNotEmpty) {
      return LatLng(
        widget.controller.locations.last.latitude,
        widget.controller.locations.last.longitude,
      );
    }

    return LatLng(40, 20);
  }

  @override
  dispose() {
    _controllerSubscription.cancel();
    _positionStream?.drain();

    if (flutterMapController != null) {
      flutterMapController!.dispose();
    }

    super.dispose();
  }

  void eventEmitterListener(final Map<String, dynamic> data) async {
    switch (data["type"]) {
      case "goTo":
        final location = data["location"] as LocationPointService;

        moveToPosition(
          LatLng(
            location.latitude,
            location.longitude,
          ),
        );
        break;
      case "goToUserLocation":
        await fetchUserPosition();
        break;
    }
  }

  void moveToPosition(final LatLng latLng) async {
    if (shouldUseAppleMaps) {
      appleMapsController!.animateCamera(
        apple_maps.CameraUpdate.newCameraPosition(
          apple_maps.CameraPosition(
            target: toAppleCoordinate(latLng),
            zoom: await appleMapsController!.getZoomLevel() ?? 13,
          ),
        ),
      );
    } else {
      flutterMapController!.move(latLng, flutterMapController!.zoom);
    }
  }

  Future<void> fetchUserPosition() async {
    if (!(await hasGrantedLocationPermission())) {
      return;
    }

    _positionStream = getLastAndCurrentPosition()
      ..listen((position) {
        moveToPosition(LatLng(
          position.latitude,
          position.longitude,
        ));
      });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    switch (settings.getMapProvider()) {
      case MapProvider.apple:
        return apple_maps.AppleMap(
          initialCameraPosition: apple_maps.CameraPosition(
            target: toAppleCoordinate(getInitialPosition()),
            zoom: widget.initialZoomLevel,
          ),
          onMapCreated: (controller) {
            appleMapsController = controller;
          },
          myLocationEnabled: true,
          annotations: widget.controller.locations.isNotEmpty
              ? {
                  apple_maps.Annotation(
                    annotationId: apple_maps.AnnotationId(
                      "annotation_${widget.controller.locations.last.latitude}:${widget.controller.locations.last.longitude}",
                    ),
                    position: apple_maps.LatLng(
                      widget.controller.locations.last.latitude,
                      widget.controller.locations.last.longitude,
                    ),
                    infoWindow: apple_maps.InfoWindow(
                      title: "Last location",
                      snippet: snippetText,
                    ),
                  ),
                }
              : {},
          circles: {
            ...(widget.showCircles
                ? widget.circles.map((circle) => circle.asAppleMaps)
                : {}),
            ...widget.controller.locations.map(
              (location) => apple_maps.Circle(
                circleId: apple_maps.CircleId(
                  "circle_${location.latitude}:${location.longitude}",
                ),
                center: apple_maps.LatLng(
                  location.latitude,
                  location.longitude,
                ),
                fillColor: Colors.blue.withOpacity(0.2),
                strokeColor: Colors.blue,
                strokeWidth: location.accuracy < 10 ? 1 : 3,
                radius: location.accuracy,
              ),
            ),
          },
          polylines: {
            apple_maps.Polyline(
              polylineId: apple_maps.PolylineId("polyline"),
              color: Colors.blue.withOpacity(0.9),
              width: 10,
              jointType: apple_maps.JointType.round,
              polylineCap: apple_maps.Cap.roundCap,
              consumeTapEvents: true,
              points: List<apple_maps.LatLng>.from(
                widget.controller.locations.reversed.map(
                  (location) =>
                      apple_maps.LatLng(location.latitude, location.longitude),
                ),
              ),
            )
          },
        );
      case MapProvider.openStreetMap:
        return LocusFlutterMap(
          options: MapOptions(
            center: getInitialPosition(),
            zoom: widget.initialZoomLevel,
            maxZoom: 18,
          ),
          mapController: flutterMapController,
          children: [
            if (widget.circles.isNotEmpty)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: widget.showCircles ? 1 : 0,
                child: CircleLayer(
                  circles: widget.circles
                      .map((circle) => circle.asFlutterMap)
                      .toList(),
                ),
              ),
            CircleLayer(
              circles: widget.controller.locations
                  .map(
                    (location) => CircleMarker(
                      point: LatLng(
                        location.latitude,
                        location.longitude,
                      ),
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: location.accuracy < 10 ? 1 : 3,
                      radius: location.accuracy,
                      useRadiusInMeter: true,
                    ),
                  )
                  .toList(),
            ),
            if (widget.controller.locations.isNotEmpty) ...[
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  markers: [
                    Marker(
                      point: LatLng(
                        widget.controller.locations.last.latitude,
                        widget.controller.locations.last.longitude,
                      ),
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (context, marker) => Paper(
                      width: null,
                      child: Text(snippetText),
                    ),
                  ),
                ),
              ),
              PolylineLayer(polylines: [
                Polyline(
                  color: Colors.blue.withOpacity(0.9),
                  strokeWidth: 10,
                  strokeJoin: StrokeJoin.round,
                  gradientColors: widget.controller.locations.length <=
                          LOCATION_POLYLINE_OPAQUE_AMOUNT_THRESHOLD
                      ? null
                      : List<Color>.generate(
                              9, (index) => Colors.blue.withOpacity(0.9)) +
                          [Colors.blue.withOpacity(0.3)],
                  points: List<LatLng>.from(
                    widget.controller.locations.reversed.map(
                      (location) =>
                          LatLng(location.latitude, location.longitude),
                    ),
                  ),
                )
              ]),
            ],
          ],
        );
    }
  }
}
