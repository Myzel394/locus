import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/api/nostr-fetch.dart';
import 'package:locus/services/view_service.dart';
import 'package:nostr/nostr.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/location_point_service.dart';
import '../../../services/task_service.dart';
import '../../../utils/permission.dart';

class LocationFetcher extends ChangeNotifier {
  final Iterable<TaskView> views;
  final Map<TaskView, List<LocationPointService>> _locations = {};

  Map<TaskView, List<LocationPointService>> get locations => _locations;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  LocationFetcher(this.views);

  void fetchLocations() {
    _setIsLoading(true);

    for (final view in views) {
      view.getLocations(
        onLocationFetched: (location) {
          _locations[view] = List<LocationPointService>.from(
            [..._locations[view] ?? [], location],
          );
        },
        onEnd: () {
          _locations[view] = _locations[view]!
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          _setIsLoading(_locations.keys.length == views.length);
        },
      );
    }
  }

  void _setIsLoading(final bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}

class LocationsOverviewScreen extends StatefulWidget {
  const LocationsOverviewScreen({super.key});

  @override
  State<LocationsOverviewScreen> createState() =>
      _LocationsOverviewScreenState();
}

class _LocationsOverviewScreenState extends State<LocationsOverviewScreen> {
  late final LocationFetcher _fetchers;
  final MapController flutterMapController = MapController();

  @override
  void initState() {
    super.initState();

    _createLocationFetcher();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      goToCurrentPosition();

      _fetchers.addListener(_rebuild);
    });
  }

  @override
  dispose() {
    flutterMapController.dispose();
    _fetchers.dispose();
    super.dispose();
  }

  void _createLocationFetcher() {
    final viewService = context.read<ViewService>();

    _fetchers = LocationFetcher(viewService.views)..fetchLocations();
  }

  void _rebuild() {
    setState(() {});
  }

  void goToCurrentPosition() async {
    if (!(await hasGrantedLocationPermission())) {
      return;
    }

    Geolocator.getLastKnownPosition().then((location) {
      if (location == null) {
        return;
      }

      flutterMapController?.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
    });

    Geolocator.getCurrentPosition(
      // We want to get the position as fast as possible
      desiredAccuracy: LocationAccuracy.lowest,
    ).then((location) {
      flutterMapController?.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
    });
  }

  Widget buildMap() {
    final viewService = context.read<ViewService>();

    print(_fetchers.locations);

    return FlutterMap(
      mapController: flutterMapController,
      options: MapOptions(
        center: LatLng(40, 20),
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: "app.myzel394.locus",
        ),
        CircleLayer(
          circles: viewService.views
              .map(
                (view) => (_fetchers.locations[view] ?? [])
                    .map(
                      (location) => CircleMarker(
                        radius: location.accuracy,
                        useRadiusInMeter: true,
                        point: LatLng(location.latitude, location.longitude),
                        color: Colors.blue,
                        borderColor: Colors.black,
                      ),
                    )
                    .toList(),
              )
              .toList()
              .expand((element) => element)
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text('Locations'),
      ),
      body: buildMap(),
    );
  }
}
