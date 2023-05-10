import 'dart:collection';
import 'dart:io';
import 'dart:async';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as AppleMaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:locus/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../services/location_point_service.dart';

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

  static DateTime normalizeDateTime(final DateTime dateTime) =>
      DateTime(
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

  void addAll(List<LocationPointService> locations) {
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

  // Groups the locations by hour and returns a map of the hour and the number of locations in that hour.
  Map<DateTime, List<LocationPointService>> getLocationsPerHour() =>
      locations.fold(
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
}

class LocationsMapAppleMaps extends StatefulWidget {
  final LocationsMapController controller;
  final double initialZoomLevel;

  const LocationsMapAppleMaps({
    required this.controller,
    required this.initialZoomLevel,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsMapAppleMaps> createState() => _LocationsMapAppleMapsState();
}

class _LocationsMapAppleMapsState extends State<LocationsMapAppleMaps> {
  late final StreamSubscription _controllerSubscription;
  AppleMaps.AppleMapController? _controller;
  Position? userPosition;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(rebuild);
    _controllerSubscription =
        widget.controller.eventListener.listen(eventEmitterListener);

    fetchInitialPosition();
  }

  @override
  void dispose() {
    widget.controller.removeListener(rebuild);
    _controllerSubscription.cancel();

    super.dispose();
  }

  void eventEmitterListener(final Map<String, dynamic> data) async {
    switch (data["type"]) {
      case "goTo":
        final location = data["location"] as LocationPointService;
        final zoomLevel = await _controller!.getZoomLevel();

        _controller!.animateCamera(
          AppleMaps.CameraUpdate.newCameraPosition(
            AppleMaps.CameraPosition(
              target: AppleMaps.LatLng(
                location.latitude,
                location.longitude,
              ),
              zoom: zoomLevel ?? 16,
            ),
          ),
        );
        break;
    }
  }

  Future<void> fetchInitialPosition() async {
    final locationData = await Geolocator.getCurrentPosition(
      // We want to get the position as fast as possible
      desiredAccuracy: LocationAccuracy.lowest,
      timeLimit: const Duration(seconds: 5),
    );

    setState(() {
      userPosition = locationData;
    });
  }

  void rebuild() {
    setState(() {});
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

  AppleMaps.LatLng get initialPosition {
    if (userPosition != null) {
      return AppleMaps.LatLng(
        userPosition!.latitude,
        userPosition!.longitude,
      );
    }

    if (widget.controller.locations.isEmpty) {
      return const AppleMaps.LatLng(0, 0);
    }

    return AppleMaps.LatLng(
      widget.controller.locations.last.latitude,
      widget.controller.locations.last.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppleMaps.AppleMap(
      key: Key(initialPosition.toString()),
      initialCameraPosition: AppleMaps.CameraPosition(
        target: initialPosition,
        zoom: widget.initialZoomLevel,
      ),
      onMapCreated: (controller) {
        _controller = controller;
      },
      myLocationEnabled: true,
      annotations: widget.controller.locations.isNotEmpty
          ? {
        AppleMaps.Annotation(
          annotationId: AppleMaps.AnnotationId(
            "annotation_${widget.controller.locations.last.latitude}:${widget
                .controller.locations.last.longitude}",
          ),
          position: AppleMaps.LatLng(
            widget.controller.locations.last.latitude,
            widget.controller.locations.last.longitude,
          ),
          infoWindow: AppleMaps.InfoWindow(
            title: "Last location",
            snippet: snippetText,
          ),
        ),
      }
          : {},
      circles: widget.controller.locations
          .map(
            (location) =>
            AppleMaps.Circle(
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
  final LocationsMapController controller;
  final double initialZoomLevel;

  const LocationsMapOSM({
    required this.controller,
    required this.initialZoomLevel,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsMapOSM> createState() => _LocationsMapOSMState();
}

class _LocationsMapOSMState extends State<LocationsMapOSM> {
  late final MapController _controller;
  late final StreamSubscription _controllerSubscription;

  @override
  void initState() {
    super.initState();

    _controller = MapController(
      initMapWithUserPosition: true,
    );
    widget.controller.addListener(rebuild);
    _controllerSubscription =
        widget.controller.eventListener.listen(eventEmitterListener);
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.removeListener(rebuild);
    _controllerSubscription.cancel();

    super.dispose();
  }

  void rebuild() {
    drawCircles();

    setState(() {});
  }

  void eventEmitterListener(final Map<String, dynamic> data) async {
    switch (data["type"]) {
      case "goTo":
        final location = data["location"] as LocationPointService;

        _controller.goToLocation(
          GeoPoint(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        );

        break;
    }
  }

  void drawCircles() {
    _controller.removeAllCircle();

    for (final location in widget.controller.locations) {
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
      initZoom: widget.initialZoomLevel,
      trackMyPosition: true,
      androidHotReloadSupport: kDebugMode,
      onMapIsReady: (controller) {
        drawCircles();
      },
      onGeoPointClicked: (point) {
        print(point);
      },
    );
  }
}

class LocationsMap extends StatelessWidget {
  final LocationsMapController controller;
  final double initialZoomLevel;

  const LocationsMap({
    required this.controller,
    this.initialZoomLevel = 15,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    switch (settings.getMapProvider()) {
      case MapProvider.apple:
        return LocationsMapAppleMaps(
          controller: controller,
          initialZoomLevel: initialZoomLevel,
        );
      case MapProvider.openStreetMap:
        return LocationsMapOSM(
          controller: controller,
          initialZoomLevel: initialZoomLevel,
        );
    }
  }
}
