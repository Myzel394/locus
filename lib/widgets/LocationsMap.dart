import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as AppleMaps;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
// Provided by the flutter_map package
import 'package:latlong2/latlong.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/widgets/Paper.dart';
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

  void sort() {
    // Sort descending
    _locations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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

class LocationsMap extends StatefulWidget {
  final LocationsMapController controller;
  final double initialZoomLevel;
  final bool initWithUserPosition;

  LocationsMap({
    required this.controller,
    this.initialZoomLevel = 16,
    this.initWithUserPosition = false,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationsMap> createState() => _LocationsMapState();
}

class _LocationsMapState extends State<LocationsMap> {
  late final StreamSubscription _controllerSubscription;

  AppleMaps.AppleMapController? appleMapsController;
  MapController? flutterMapController;

  static toAppleCoordinate(final LatLng latLng) =>
      AppleMaps.LatLng(latLng.latitude, latLng.longitude);

  bool get shouldUseAppleMaps {
    final settings = context.watch<SettingsService>();

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
  }

  LatLng getInitialPosition() {
    if (widget.controller.locations.isNotEmpty) {
      return LatLng(
        widget.controller.locations.last.latitude,
        widget.controller.locations.last.longitude,
      );
    }

    return LatLng(0, 0);
  }

  @override
  dispose() {
    _controllerSubscription.cancel();

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
    }
  }

  void moveToPosition(final LatLng latLng) async {
    if (shouldUseAppleMaps) {
      appleMapsController!.moveCamera(
        AppleMaps.CameraUpdate.newCameraPosition(
          AppleMaps.CameraPosition(
            target: toAppleCoordinate(latLng),
          ),
        ),
      );
    } else {
      flutterMapController!.move(latLng, flutterMapController!.zoom);
    }
  }

  Future<void> fetchUserPosition() async {
    final locationData = await Geolocator.getCurrentPosition(
      // We want to get the position as fast as possible
      desiredAccuracy: LocationAccuracy.lowest,
    );

    moveToPosition(LatLng(
      locationData.latitude,
      locationData.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    switch (settings.getMapProvider()) {
      case MapProvider.apple:
        return AppleMaps.AppleMap(
          initialCameraPosition: AppleMaps.CameraPosition(
            target: toAppleCoordinate(getInitialPosition()),
            zoom: widget.initialZoomLevel,
          ),
          onMapCreated: (controller) {
            appleMapsController = controller;
          },
          myLocationEnabled: true,
          annotations: widget.controller.locations.isNotEmpty
              ? {
                  AppleMaps.Annotation(
                    annotationId: AppleMaps.AnnotationId(
                      "annotation_${widget.controller.locations.last.latitude}:${widget.controller.locations.last.longitude}",
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
      case MapProvider.openStreetMap:
        return FlutterMap(
          options: MapOptions(
            center: getInitialPosition(),
            zoom: widget.initialZoomLevel,
            maxZoom: 18,
          ),
          mapController: flutterMapController,
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: "app.myzel394.locus",
              tileProvider: FMTC.instance('mapStore').getTileProvider(),
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
            if (widget.controller.locations.isNotEmpty)
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
          ],
        );
    }
  }
}
