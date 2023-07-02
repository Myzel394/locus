import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:locus/api/nostr-fetch.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/icon.dart';
import 'package:locus/utils/location.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/BentoGridElement.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nostr/nostr.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../services/location_point_service.dart';
import '../../../services/task_service.dart';
import '../../../utils/permission.dart';
import '../../../widgets/AddressFetcher.dart';
import '../ViewDetailsSheet.dart';

class LocationFetcher extends ChangeNotifier {
  final Iterable<TaskView> views;
  final Map<TaskView, List<LocationPointService>> _locations = {};
  final List<VoidCallback> _getLocationsUnsubscribers = [];

  bool _mounted = true;

  Map<TaskView, List<LocationPointService>> get locations => _locations;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  LocationFetcher(this.views);

  bool get hasMultipleLocationViews => _locations.keys.length > 1;

  // If _fetchLast24Hours fails (no location fetched), we want to get the last location
  void _fetchLastLocation(final TaskView view) {
    _getLocationsUnsubscribers.add(
      view.getLocations(
        onLocationFetched: (location) {
          if (!_mounted) {
            return;
          }

          _locations[view] = [location];
        },
        onEnd: () {
          if (!_mounted) {
            return;
          }

          _setIsLoading(_locations.keys.length == views.length);
        },
      ),
    );
  }

  void _fetchLast24Hours() {
    _getLocationsUnsubscribers.addAll(
      views.map(
        (view) => view.getLocations(
          from: DateTime.now().subtract(const Duration(days: 1)),
          onLocationFetched: (location) {
            if (!_mounted) {
              return;
            }

            _locations[view] = List<LocationPointService>.from(
              [..._locations[view] ?? [], location],
            );
          },
          onEnd: () {
            if (!_mounted) {
              return;
            }

            if (_locations.containsKey(view)) {
              _locations[view] = _locations[view]!
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

              _setIsLoading(_locations.keys.length == views.length);
            } else {
              // No locations found in the last 24 hours
              _fetchLastLocation(view);
            }
          },
        ),
      ),
    );
  }

  void fetchLocations() {
    _setIsLoading(true);

    _fetchLast24Hours();
  }

  void _setIsLoading(final bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final unsubscribe in _getLocationsUnsubscribers) {
      unsubscribe();
    }

    _mounted = false;
    super.dispose();
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
  Stream<Position>? _positionStream;

  // Null = all views
  String? selectedViewID;

  TaskView? get selectedView {
    if (selectedViewID == null) {
      return null;
    }

    return context.read<ViewService>().getViewById(selectedViewID!);
  }

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
    _positionStream?.drain();

    super.dispose();
  }

  void _createLocationFetcher() {
    final viewService = context.read<ViewService>();

    _fetchers = LocationFetcher(viewService.views)..fetchLocations();
  }

  void _rebuild() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void goToCurrentPosition([final bool askPermissions = false]) async {
    if (askPermissions) {
      final hasGrantedPermissions = await requestBasicLocationPermission();

      if (!hasGrantedPermissions) {
        return;
      }
    }

    if (!(await hasGrantedLocationPermission())) {
      return;
    }

    _positionStream = getLastAndCurrentPosition()
      ..listen((position) {
        flutterMapController?.move(
          LatLng(position.latitude, position.longitude),
          13,
        );
      });
  }

  Widget buildMap() {
    final viewService = context.read<ViewService>();

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
              .where(
                  (view) => selectedViewID == null || view.id == selectedViewID)
              .map(
                (view) => (_fetchers.locations[view] ?? [])
                    .map(
                      (location) => CircleMarker(
                        radius: location.accuracy,
                        useRadiusInMeter: true,
                        point: LatLng(location.latitude, location.longitude),
                        color: view.color.withOpacity(.2),
                        borderColor: view.color,
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

  void showViewLocations(final TaskView view) async {
    setState(() {
      selectedViewID = view.id;
    });

    final latestLocation = _fetchers.locations[view]?.last;

    if (latestLocation == null) {
      return;
    }

    flutterMapController.move(
      LatLng(latestLocation.latitude, latestLocation.longitude),
      flutterMapController.zoom,
    );
  }

  Widget buildViewTile(
    final TaskView? view, {
    final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  }) {
    final l10n = AppLocalizations.of(context);

    if (view == null) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.location_on_rounded, size: 20),
          const SizedBox(width: SMALL_SPACE),
          Text(l10n.locationsOverview_viewSelection_all),
        ],
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.circle_rounded,
          size: 20,
          color: view.color,
        ),
        const SizedBox(width: SMALL_SPACE),
        Text(view.name),
      ],
    );
  }

  Widget buildBar() {
    final l10n = AppLocalizations.of(context);
    final viewService = context.watch<ViewService>();

    return Positioned(
      left: MEDIUM_SPACE,
      right: MEDIUM_SPACE,
      top: SMALL_SPACE,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (viewService.views.length > 1)
                Expanded(
                  flex: 4,
                  child: Paper(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MEDIUM_SPACE,
                      vertical: SMALL_SPACE,
                    ),
                    child: DropdownButton<String?>(
                      isDense: true,
                      value: selectedViewID,
                      onChanged: (selection) {
                        if (selection == null) {
                          setState(() {
                            selectedViewID = null;
                          });
                          return;
                        }

                        final view = viewService.views.firstWhere(
                          (view) => view.id == selection,
                        );

                        showViewLocations(view);
                      },
                      underline: Container(),
                      alignment: Alignment.center,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: buildViewTile(null),
                        ),
                        for (final view in viewService.views) ...[
                          DropdownMenuItem(
                            value: view.id,
                            child: buildViewTile(view),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              Flexible(
                child: SizedBox.square(
                  dimension: 50,
                  child: Center(
                    child: Paper(
                      width: null,
                      borderRadius: BorderRadius.circular(HUGE_SPACE),
                      padding: EdgeInsets.zero,
                      child: PlatformIconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: () => goToCurrentPosition(true),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LocationPointService? get lastLocation {
    if (selectedView == null) {
      return null;
    }

    if (_fetchers.locations[selectedView!] == null) {
      return null;
    }

    if (_fetchers.locations[selectedView!]!.isEmpty) {
      return null;
    }

    return _fetchers.locations[selectedView!]!.last;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewService = context.watch<ViewService>();

    return PlatformScaffold(
      body: Stack(
        children: <Widget>[
          buildMap(),
          buildBar(),
          ViewDetailsSheet(
            view: selectedView,
            lastLocation: lastLocation,
          )
        ],
      ),
    );
  }
}
