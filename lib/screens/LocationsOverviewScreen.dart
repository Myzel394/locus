import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import "package:apple_maps_flutter/apple_maps_flutter.dart" as AppleMaps;
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/ImportTaskSheet.dart';
import 'package:locus/screens/SettingsScreen.dart';
import 'package:locus/screens/SharesOverviewScreen.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ActiveSharesSheet.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ShareLocationSheet.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/helpers.dart';
import 'package:locus/utils/location.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/utils/show_message.dart';
import 'package:locus/widgets/FABOpenContainer.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:uni_links/uni_links.dart';

import '../constants/notifications.dart';
import '../constants/values.dart';
import '../init_quick_actions.dart';
import '../main.dart';
import '../services/app_update_service.dart';
import '../services/location_point_service.dart';
import '../services/log_service.dart';
import '../services/manager_service.dart';
import '../services/settings_service.dart';
import '../utils/PageRoute.dart';
import '../utils/color.dart';
import '../utils/permission.dart';
import '../utils/platform.dart';
import '../utils/theme.dart';
import '../widgets/OpenInMaps.dart';
import 'ViewDetailScreen.dart';
import 'locations_overview_screen_widgets/ViewDetailsSheet.dart';

enum LocationStatus {
  stale,
  active,
  fetching,
}

// Based of https://m3.material.io/components/floating-action-button/specs
const FAB_SIZE = 56.0;
const FAB_MARGIN = 16.0;

const OUT_OF_BOUND_MARKER_X_PADDING = 5;
const OUT_OF_BOUND_MARKER_Y_PADDING = FAB_SIZE + FAB_MARGIN;
const OUT_OF_BOUND_MARKER_SIZE = 60;

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
        limit: 1,
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

            _locations[view] = _locations[view]!
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

            _setIsLoading(_locations.keys.length == views.length);
          },
          onEmptyEnd: () {
            _fetchLastLocation(view);
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

class _LocationsOverviewScreenState extends State<LocationsOverviewScreen>
    with
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
  late final LocationFetcher _fetchers;
  MapController? flutterMapController;
  AppleMaps.AppleMapController? appleMapController;

  late final AnimationController rotationController;
  late Animation<double> rotationAnimation;

  bool showFAB = true;
  bool isNorth = true;

  Stream<Position>? _positionStream;

  // Since we already listen to the latest position, we will pass it
  // manually to `current_location_layer` to avoid it also registering
  // extra listeners.
  final StreamController<LocationMarkerPosition?>
      _currentLocationPositionStream =
      StreamController<LocationMarkerPosition?>.broadcast();

  Position? lastPosition;
  StreamSubscription<String?>? _uniLinksStream;
  Timer? _viewsAlarmCheckerTimer;
  LocationStatus locationStatus = LocationStatus.stale;

  // Null = all views
  String? selectedViewID;

  bool _hasGoneToInitialPosition = false;

  TaskView? get selectedView {
    if (selectedViewID == null) {
      return null;
    }

    return context.read<ViewService>().getViewById(selectedViewID!);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _createLocationFetcher();

    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) async {
        _setLocationFromSettings();

        final taskService = context.read<TaskService>();
        final logService = context.read<LogService>();
        final appUpdateService = context.read<AppUpdateService>();
        _fetchers.addListener(_rebuild);
        appUpdateService.addListener(_rebuild);

        initQuickActions(context);
        _initUniLinks();
        _updateLocaleToSettings();
        _showUpdateDialogIfRequired();

        taskService.checkup(logService);

        hasGrantedLocationPermission().then((hasGranted) {
          if (hasGranted) {
            _initLiveLocationUpdate();
          }
        });
      });

    BackgroundFetch.start();
    _handleViewAlarmChecker();
    _handleNotifications();

    final settings = context.read<SettingsService>();
    if (settings.getMapProvider() == MapProvider.openStreetMap) {
      flutterMapController = MapController();
      flutterMapController!.mapEventStream.listen((event) {
        setState(() {});

        if (event is MapEventRotate) {
          rotationController.animateTo(
            ((event.targetRotation % 360) / 360),
            duration: Duration.zero,
          );

          setState(() {
            isNorth = (event.targetRotation % 360).abs() < 1;
          });
        }
      });
    }

    rotationController =
        AnimationController(vsync: this, duration: Duration.zero);
    rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(rotationController);
  }

  @override
  dispose() {
    flutterMapController?.dispose();
    _fetchers.dispose();
    _positionStream?.drain();

    _viewsAlarmCheckerTimer?.cancel();
    _uniLinksStream?.cancel();
    _positionStream?.drain();

    _removeLiveLocationUpdate();

    WidgetsBinding.instance.removeObserver(this);

    final appUpdateService = context.read<AppUpdateService>();
    appUpdateService.removeListener(_rebuild);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      goToCurrentPosition(showErrorMessage: false);
    }
  }

  void _setLocationFromSettings() async {
    final settings = context.read<SettingsService>();
    final position = settings.getLastMapLocation();

    if (position == null) {
      return;
    }

    setState(() {
      locationStatus = LocationStatus.stale;
    });

    _currentLocationPositionStream.add(
      LocationMarkerPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      ),
    );
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

  LocationSettings _getLocationSettings() {
    final l10n = AppLocalizations.of(context);

    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER,
        intervalDuration: LOCATION_INTERVAL,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: l10n.backgroundLocationFetch_text,
          notificationTitle: l10n.backgroundLocationFetch_title,
        ),
      );
    } else if (isPlatformApple()) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: LOCATION_FETCH_TIME_LIMIT,
        distanceFilter: BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER,
        activityType: ActivityType.other,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: true,
      );
    }

    return const LocationSettings(
      distanceFilter: BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER,
      timeLimit: LOCATION_FETCH_TIME_LIMIT,
      accuracy: LocationAccuracy.best,
    );
  }

  void _updateLocationToSettings(final Position position) async {
    final settings = context.read<SettingsService>();

    settings.setLastMapLocation(
      SettingsLastMapLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      ),
    );
    await settings.save();
  }

  void _initLiveLocationUpdate() {
    if (_positionStream != null) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _getLocationSettings(),
    );

    _positionStream!.listen((position) async {
      _currentLocationPositionStream.add(
        LocationMarkerPosition(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        ),
      );

      _updateLocationToSettings(position);

      if (!_hasGoneToInitialPosition) {
        if (flutterMapController != null) {
          flutterMapController!.move(
            LatLng(position.latitude, position.longitude),
            flutterMapController!.zoom,
          );
        }

        // Print statement is required to work
        print(appleMapController);
        if (appleMapController != null) {
          if (_hasGoneToInitialPosition) {
            appleMapController!.animateCamera(
              AppleMaps.CameraUpdate.newLatLng(
                AppleMaps.LatLng(position.latitude, position.longitude),
              ),
            );
          } else {
            appleMapController!.moveCamera(
              AppleMaps.CameraUpdate.newLatLng(
                AppleMaps.LatLng(position.latitude, position.longitude),
              ),
            );
          }
        }
        _hasGoneToInitialPosition = true;
      }

      setState(() {
        lastPosition = position;
        locationStatus = LocationStatus.active;
      });

      final taskService = context.read<TaskService>();
      final runningTasks = await taskService.getRunningTasks().toList();

      if (runningTasks.isEmpty) {
        return;
      }

      final locationData = await LocationPointService.fromPosition(position);

      for (final task in runningTasks) {
        await task.publishLocation(
          locationData.copyWithDifferentId(),
        );
      }
    });
  }

  void _removeLiveLocationUpdate() {
    _positionStream?.drain();
    _positionStream = null;
  }

  Future<void> _importUniLink(final String url) => showPlatformModalSheet(
        context: context,
        material: MaterialModalSheetData(
          isScrollControlled: true,
          isDismissible: true,
          backgroundColor: Colors.transparent,
        ),
        builder: (context) => ImportTaskSheet(initialURL: url),
      );

  Future<void> _initUniLinks() async {
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(LOG_TAG, "Uni Links", "Initiating uni links...");

    _uniLinksStream = linkStream.listen((final String? link) {
      if (link != null) {
        _importUniLink(link);
      }
    });

    try {
      // Only fired when the app was in background
      final initialLink = await getInitialLink();

      if (initialLink != null) {
        await _importUniLink(initialLink);
      }
    } on PlatformException catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Uni Links",
        "Error initializing uni links: $error",
      );

      showPlatformDialog(
        context: context,
        builder: (_) => PlatformAlertDialog(
          title: Text(l10n.uniLinksOpenError),
          content: Text(error.message ?? l10n.unknownError),
          actions: [
            PlatformDialogAction(
              child: Text(l10n.closeNeutralAction),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void _handleViewAlarmChecker() {
    _viewsAlarmCheckerTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        final viewService = context.read<ViewService>();
        final l10n = AppLocalizations.of(context);

        if (viewService.viewsWithAlarms.isEmpty) {
          return;
        }

        checkViewAlarms(
          l10n: l10n,
          views: viewService.viewsWithAlarms,
          viewService: viewService,
        );
      },
    );
  }

  void _handleNotifications() {
    selectedNotificationsStream.stream.listen((notification) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Notification",
        "Notification received: ${notification.payload}",
      );

      try {
        final data = jsonDecode(notification.payload ?? "{}");
        final type = NotificationActionType.values[data["type"]];

        switch (type) {
          case NotificationActionType.openTaskView:
            final viewService = context.read<ViewService>();

            Navigator.of(context).push(
              NativePageRoute(
                context: context,
                builder: (_) => ViewDetailScreen(
                  view: viewService.getViewById(data["taskViewID"]),
                ),
              ),
            );
            break;
        }
      } catch (error) {
        FlutterLogs.logErrorTrace(
          LOG_TAG,
          "Notification",
          "Error handling notification.",
          error as Error,
        );
      }
    });
  }

  void _updateLocaleToSettings() {
    final settingsService = context.read<SettingsService>();

    settingsService.localeName = AppLocalizations.of(context).localeName;
    settingsService.save();
  }

  void _showUpdateDialogIfRequired() async {
    final l10n = AppLocalizations.of(context);
    final appUpdateService = context.read<AppUpdateService>();

    if (appUpdateService.shouldShowDialogue() &&
        !appUpdateService.hasShownDialogue &&
        mounted) {
      await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        material: MaterialDialogData(
          barrierColor: Colors.black,
        ),
        builder: (context) => PlatformAlertDialog(
          title: Text(l10n.updateAvailable_android_title),
          content: Text(l10n.updateAvailable_android_description),
          actions: [
            PlatformDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              material: (context, _) => MaterialDialogActionData(
                  icon: const Icon(Icons.watch_later_rounded)),
              child: Text(l10n.updateAvailable_android_remindLater),
            ),
            PlatformDialogAction(
              onPressed: () {
                appUpdateService.doNotShowDialogueAgain();

                Navigator.of(context).pop();
              },
              material: (context, _) =>
                  MaterialDialogActionData(icon: const Icon(Icons.block)),
              child: Text(l10n.updateAvailable_android_ignore),
            ),
            PlatformDialogAction(
              onPressed: appUpdateService.openStoreForUpdate,
              material: (context, _) =>
                  MaterialDialogActionData(icon: const Icon(Icons.download)),
              child: Text(l10n.updateAvailable_android_download),
            ),
          ],
        ),
      );

      appUpdateService.setHasShownDialogue();
    }
  }

  void goToCurrentPosition({
    final bool askPermissions = false,
    final bool showErrorMessage = true,
  }) async {
    final previousValue = locationStatus;

    setState(() {
      locationStatus = LocationStatus.fetching;
    });

    if (askPermissions) {
      final hasGrantedPermissions = await requestBasicLocationPermission();

      if (!hasGrantedPermissions) {
        setState(() {
          locationStatus = previousValue;
        });
        return;
      }
    }

    if (!(await hasGrantedLocationPermission())) {
      setState(() {
        locationStatus = previousValue;
      });
      return;
    }

    _initLiveLocationUpdate();

    if (lastPosition != null) {
      if (flutterMapController != null) {
        flutterMapController?.move(
          LatLng(lastPosition!.latitude, lastPosition!.longitude),
          13,
        );
      }

      if (appleMapController != null) {
        appleMapController?.animateCamera(
          AppleMaps.CameraUpdate.newCameraPosition(
            AppleMaps.CameraPosition(
              target: AppleMaps.LatLng(
                  lastPosition!.latitude, lastPosition!.longitude),
              zoom: 13,
            ),
          ),
        );
      }
    }

    FlutterLogs.logInfo(
      LOG_TAG,
      "LocationOverviewScreen",
      "Getting current position...",
    );

    try {
      final latestPosition = await getCurrentPosition();

      _currentLocationPositionStream.add(
        LocationMarkerPosition(
          latitude: latestPosition.latitude,
          longitude: latestPosition.longitude,
          accuracy: latestPosition.accuracy,
        ),
      );

      setState(() {
        lastPosition = latestPosition;
        locationStatus = LocationStatus.active;
      });
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "LocationOverviewScreen",
        "Error getting current position: $error",
      );

      setState(() {
        locationStatus = previousValue;
      });

      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);

      showMessage(
        context,
        l10n.unknownError,
        type: MessageType.error,
      );
      return;
    }
  }

  Widget _buildUserMarkerLayer() {
    final settings = context.read<SettingsService>();
    final color = {
      LocationStatus.active: settings.primaryColor ??
          platformThemeData(
            context,
            material: (data) => data.colorScheme.primary,
            cupertino: (data) => data.primaryColor,
          ),
      LocationStatus.fetching: Colors.orange,
      LocationStatus.stale: Colors.grey,
    }[locationStatus]!;

    return CurrentLocationLayer(
      positionStream: _currentLocationPositionStream.stream,
      followOnLocationUpdate: FollowOnLocationUpdate.always,
      style: LocationMarkerStyle(
        marker: DefaultLocationMarker(
          color: color,
        ),
        accuracyCircleColor: color.withOpacity(0.2),
        headingSectorColor: color,
      ),
    );
  }

  Widget buildMap() {
    final settings = context.read<SettingsService>();
    final viewService = context.read<ViewService>();

    if (settings.getMapProvider() == MapProvider.apple) {
      return AppleMaps.AppleMap(
        initialCameraPosition: const AppleMaps.CameraPosition(
          target: AppleMaps.LatLng(40, 20),
          zoom: 13.0,
        ),
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        compassEnabled: true,
        onMapCreated: (controller) {
          appleMapController = controller;

          if (lastPosition != null) {
            appleMapController?.moveCamera(
              AppleMaps.CameraUpdate.newCameraPosition(
                AppleMaps.CameraPosition(
                  target: AppleMaps.LatLng(
                    lastPosition!.latitude,
                    lastPosition!.longitude,
                  ),
                  zoom: 13,
                ),
              ),
            );

            _hasGoneToInitialPosition = true;
          }
        },
        circles: viewService.views
            .where(
                (view) => selectedViewID == null || view.id == selectedViewID)
            .map(
              (view) => (_fetchers.locations[view] ?? [])
                  .map(
                    (location) => AppleMaps.Circle(
                        circleId: AppleMaps.CircleId(location.id),
                        center: AppleMaps.LatLng(
                          location.latitude,
                          location.longitude,
                        ),
                        radius: location.accuracy,
                        fillColor: view.color.withOpacity(0.2),
                        strokeColor: view.color,
                        strokeWidth: location.accuracy < 10 ? 1 : 3),
                  )
                  .toList(),
            )
            .expand((element) => element)
            .toSet(),
      );
    }

    return FlutterMap(
      mapController: flutterMapController,
      options: MapOptions(
        maxZoom: 18,
        minZoom: 2,
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
                        borderStrokeWidth: location.accuracy < 10 ? 1 : 3,
                        color: view.color.withOpacity(.1),
                        borderColor: view.color,
                      ),
                    )
                    .toList(),
              )
              .expand((element) => element)
              .toList(),
        ),
        _buildUserMarkerLayer(),
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            markerTapBehavior: MarkerTapBehavior.togglePopupAndHideRest(),
            popupDisplayOptions: PopupDisplayOptions(
              builder: (context, marker) {
                final l10n = AppLocalizations.of(context);
                final view = viewService.views.firstWhere(
                  (view) => Key(view.id) == marker.key,
                );

                return Paper(
                  width: null,
                  child: Padding(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                        PlatformTextButton(
                          child: Text(l10n.openInMaps),
                          onPressed: () {
                            showPlatformModalSheet(
                              context: context,
                              material: MaterialModalSheetData(
                                backgroundColor: Colors.transparent,
                              ),
                              builder: (context) => OpenInMaps(
                                destination: Coords(
                                  marker.point.latitude,
                                  marker.point.longitude,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            markers: viewService.views
                .where((view) =>
                    (selectedViewID == null || view.id == selectedViewID) &&
                    _fetchers.locations[view]?.last != null)
                .map((view) {
              final latestLocation = _fetchers.locations[view]!.last;

              return Marker(
                key: Key(view.id),
                point: LatLng(
                  latestLocation.latitude,
                  latestLocation.longitude,
                ),
                anchorPos: AnchorPos.align(AnchorAlign.top),
                builder: (context) => Icon(
                  Icons.location_on,
                  size: 40,
                  color: view.color,
                  shadows: const [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOutOfBoundMarker(final TaskView view) {
    final lastLocation = _fetchers.locations[view]!.last;

    final bounds = flutterMapController!.bounds;
    final size = MediaQuery.of(context).size;

    // Add some padding to the bounds
    final availableWidth = size.width - OUT_OF_BOUND_MARKER_X_PADDING * 2;
    final availableHeight = size.height - OUT_OF_BOUND_MARKER_Y_PADDING * 2;
    final xAvailablePercentage = availableWidth / size.width;
    final yAvailablePercentage = availableHeight / size.height;
    final xPercentage =
        ((lastLocation.longitude - bounds!.west) / (bounds.east - bounds.west))
            .clamp(1 - xAvailablePercentage, xAvailablePercentage);
    final yPercentage =
        ((lastLocation.latitude - bounds.north) / (bounds.south - bounds.north))
            .clamp(1 - yAvailablePercentage, yAvailablePercentage);

    // Calculate the rotation between marker and last location
    final markerLongitude =
        bounds.west + xPercentage * (bounds.east - bounds.west);
    final markerLatitude =
        bounds.north + yPercentage * (bounds.south - bounds.north);

    final diffLongitude = lastLocation.longitude - markerLongitude;
    final diffLatitude = lastLocation.latitude - markerLatitude;

    final rotation = atan2(diffLongitude, diffLatitude) + pi;

    final totalDiff = Geolocator.distanceBetween(
      lastLocation.latitude,
      lastLocation.longitude,
      markerLatitude,
      markerLongitude,
    );

    final bottomRightMapActionsHeight = size.width - (FAB_SIZE + FAB_MARGIN);
    final width =
        size.width - OUT_OF_BOUND_MARKER_X_PADDING - OUT_OF_BOUND_MARKER_SIZE;
    final height = xPercentage * size.width > bottomRightMapActionsHeight
        ? size.height - (FAB_SIZE + FAB_MARGIN) * 2
        : size.height - OUT_OF_BOUND_MARKER_Y_PADDING;

    return Positioned(
      // Subtract `OUT_OF_BOUND_MARKER_SIZE` to make sure the marker doesn't
      // overlap with the bounds
      left: xPercentage * width,
      top: yPercentage * height,
      child: Opacity(
        opacity: (1000000 / totalDiff).clamp(0.2, 1),
        child: Transform.rotate(
          angle: rotation,
          child: GestureDetector(
            onTap: () {
              showViewLocations(view);
            },
            child: Stack(
              children: [
                SimpleShadow(
                  opacity: .4,
                  sigma: 2,
                  color: Colors.black,
                  // Calculate offset based of rotation, shadow should always show down
                  offset: Offset(
                    sin(rotation) * 4,
                    cos(rotation) * 4,
                  ),
                  child: SizedBox.square(
                    dimension: OUT_OF_BOUND_MARKER_SIZE.toDouble(),
                    child: SvgPicture.asset(
                      "assets/location-out-of-bounds-marker.svg",
                      width: OUT_OF_BOUND_MARKER_SIZE.toDouble(),
                      height: OUT_OF_BOUND_MARKER_SIZE.toDouble(),
                      colorFilter: ColorFilter.mode(
                        getSheetColor(context),
                        BlendMode.srcATop,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: OUT_OF_BOUND_MARKER_SIZE / 2 - 40 / 2,
                  top: 3,
                  child: Icon(
                    Icons.circle_rounded,
                    size: 40,
                    color: view.color,
                  ),
                ),
                Positioned(
                  left: OUT_OF_BOUND_MARKER_SIZE / 2 - 30 / 2,
                  top: 7.5,
                  child: Transform.rotate(
                    angle: -rotation,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 30,
                      color: getSheetColor(context),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _isLocationOutOfBound(final Position location) async {
    final settings = context.read<SettingsService>();

    if (settings.getMapProvider() == MapProvider.openStreetMap) {
      final bounds = flutterMapController!.bounds;

      if (bounds == null) {
        return false;
      }

      return location.longitude < bounds.west ||
          location.longitude > bounds.east ||
          location.latitude < bounds.south ||
          location.latitude > bounds.north;
    } else {
      final bounds = await appleMapController!.getVisibleRegion();

      return location.longitude < bounds.southwest.longitude ||
          location.longitude > bounds.northeast.longitude ||
          location.latitude < bounds.southwest.latitude ||
          location.latitude > bounds.northeast.latitude;
    }
  }

  // Returns a stream of views whose last location is out of bounds
  Stream<TaskView> _getOutOfBoundsViews() async* {
    if (_fetchers.isLoading && false) {
      return;
    }

    for (final view in _fetchers.views) {
      if (_fetchers.locations[view]?.isEmpty ?? true) {
        continue;
      }

      final lastLocation = _fetchers.locations[view]!.last;

      if (await _isLocationOutOfBound(lastLocation.asPosition())) {
        yield view;
      }
    }
  }

  Widget buildOutOfBoundsMarkers() {
    return FutureBuilder<List<TaskView>>(
      future: _getOutOfBoundsViews().toList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Stack(
            children: snapshot.data!.map(_buildOutOfBoundMarker).toList(),
          );
        }

        return const SizedBox();
      },
    );
  }

  void showViewLocations(final TaskView view) async {
    setState(() {
      showFAB = false;
      selectedViewID = view.id;
    });

    final latestLocation = _fetchers.locations[view]?.last;

    if (latestLocation == null) {
      return;
    }

    if (flutterMapController != null) {
      flutterMapController!.move(
        LatLng(latestLocation.latitude, latestLocation.longitude),
        flutterMapController!.zoom,
      );
    }
    if (appleMapController != null) {
      appleMapController!.animateCamera(
        AppleMaps.CameraUpdate.newCameraPosition(
          AppleMaps.CameraPosition(
            target: AppleMaps.LatLng(
              latestLocation.latitude,
              latestLocation.longitude,
            ),
            zoom: (await appleMapController!.getZoomLevel()) ?? 13.0,
          ),
        ),
      );
    }
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

  Widget buildViewsSelection() {
    final settings = context.watch<SettingsService>();
    final viewService = context.watch<ViewService>();
    final l10n = AppLocalizations.of(context);

    if (viewService.views.isEmpty) {
      return const SizedBox.shrink();
    }

    if (settings.getMapProvider() == MapProvider.apple) {
      return Positioned(
        top: 100.0,
        right: 5.0,
        child: Center(
          child: SizedBox.square(
            dimension: 35.0,
            child: CupertinoButton(
              color: Colors.white,
              padding: EdgeInsets.zero,
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  barrierDismissible: true,
                  builder: (cupertino) => CupertinoActionSheet(
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(l10n.cancelLabel),
                    ),
                    actions: [
                          CupertinoActionSheetAction(
                            child: buildViewTile(
                              null,
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                selectedViewID = null;
                              });
                            },
                          )
                        ] +
                        viewService.views
                            .map(
                              (view) => CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showViewLocations(view);
                                },
                                child: buildViewTile(
                                  view,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                );
              },
              child: selectedViewID == null
                  ? Icon(
                      Icons.location_on_rounded,
                      color: settings.getPrimaryColor(context),
                    )
                  : Icon(
                      Icons.circle_rounded,
                      color: selectedView!.color,
                    ),
            ),
          ),
        ),
      );
    } else {
      return Positioned(
        left: MEDIUM_SPACE,
        right: MEDIUM_SPACE,
        top: settings.getMapProvider() == MapProvider.apple
            ? LARGE_SPACE
            : SMALL_SPACE,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Paper(
              padding: const EdgeInsets.symmetric(
                horizontal: MEDIUM_SPACE,
                vertical: SMALL_SPACE,
              ),
              child: PlatformWidget(
                material: (context, _) => DropdownButton<String?>(
                  isDense: true,
                  value: selectedViewID,
                  onChanged: (selection) {
                    if (selection == null) {
                      setState(() {
                        showFAB = true;
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
                cupertino: (context, _) => CupertinoButton(
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      barrierDismissible: true,
                      builder: (cupertino) => CupertinoActionSheet(
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(l10n.cancelLabel),
                        ),
                        actions: [
                              CupertinoActionSheetAction(
                                child: buildViewTile(
                                  null,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    selectedViewID = null;
                                  });
                                },
                              )
                            ] +
                            viewService.views
                                .map(
                                  (view) => CupertinoActionSheetAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showViewLocations(view);
                                    },
                                    child: buildViewTile(
                                      view,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                  child: buildViewTile(selectedView),
                ),
              ),
            ),
          ),
        ),
      );
    }
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

  void importLocation() {
    showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
      ),
      builder: (context) => const ImportTaskSheet(),
    );
  }

  void createNewQuickLocationShare() async {
    final l10n = AppLocalizations.of(context);

    final task = await showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
      ),
      builder: (context) => const ShareLocationSheet(),
    );

    if (task == null || !mounted) {
      return;
    }

    final settings = context.read<SettingsService>();
    final link = await (task as Task).generateLink(settings.getServerHost());

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) {
      return;
    }

    showMessage(
      context,
      l10n.linkCopiedToClipboard,
      type: MessageType.success,
    );
  }

  Widget buildMapActions() {
    const dimension = 50;
    const diff = FAB_SIZE - dimension;

    final settings = context.watch<SettingsService>();
    final shades = getPrimaryColorShades(context);

    if (settings.getMapProvider() == MapProvider.openStreetMap) {
      return Positioned(
        // Add half the difference to center the button
        right: FAB_MARGIN + diff / 2,
        bottom: FAB_SIZE +
            FAB_MARGIN +
            (isCupertino(context) ? LARGE_SPACE : SMALL_SPACE),
        child: Column(
          children: [
            SizedBox.square(
              dimension: 50,
              child: Center(
                child: PlatformWidget(
                  material: (context, _) => Paper(
                    width: null,
                    borderRadius: BorderRadius.circular(HUGE_SPACE),
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      color: isNorth ? shades[200] : shades[400],
                      icon: AnimatedBuilder(
                        animation: rotationAnimation,
                        builder: (context, child) => Transform.rotate(
                          angle: rotationAnimation.value,
                          child: child,
                        ),
                        child: PlatformFlavorWidget(
                          material: (context, _) => Transform.rotate(
                            angle: -pi / 4,
                            child: const Icon(MdiIcons.compass),
                          ),
                          cupertino: (context, _) =>
                              const Icon(CupertinoIcons.location_north_fill),
                        ),
                      ),
                      onPressed: () {
                        if (flutterMapController != null) {
                          flutterMapController!.rotate(0);
                        }
                      },
                    ),
                  ),
                  cupertino: (context, _) => CupertinoButton(
                    color: isNorth ? shades[200] : shades[400],
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(HUGE_SPACE),
                    onPressed: () {
                      if (flutterMapController != null) {
                        flutterMapController!.rotate(0);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: rotationAnimation,
                      builder: (context, child) => Transform.rotate(
                        angle: rotationAnimation.value,
                        child: child,
                      ),
                      child: const Icon(CupertinoIcons.location_north_fill),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: SMALL_SPACE),
            SizedBox.square(
              dimension: 50,
              child: Center(
                child: PlatformWidget(
                  material: (context, _) => Paper(
                    width: null,
                    borderRadius: BorderRadius.circular(HUGE_SPACE),
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      color: shades[400],
                      icon: const Icon(Icons.my_location),
                      onPressed: () =>
                          goToCurrentPosition(askPermissions: true),
                    ),
                  ),
                  cupertino: (context, _) => CupertinoButton(
                    color: shades[400],
                    padding: EdgeInsets.zero,
                    onPressed: () => goToCurrentPosition(askPermissions: true),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      material: (context, __) {
        final theme = Theme.of(context);

        final foreground = (() {
          if (settings.primaryColor != null) {
            final color = createMaterialColor(settings.primaryColor!);
            return getIsDarkMode(context) ? color.shade50 : color.shade900;
          }

          return theme.colorScheme.onPrimaryContainer;
        })();
        final background = (() {
          if (settings.primaryColor != null) {
            final color = createMaterialColor(settings.primaryColor!);
            return getIsDarkMode(context) ? color.shade900 : color.shade50;
          }

          return theme.colorScheme.primaryContainer;
        })();

        return MaterialScaffoldData(
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: AnimatedScale(
            scale: showFAB ? 1 : 0,
            duration: showFAB
                ? const Duration(milliseconds: 900)
                : const Duration(milliseconds: 200),
            curve: showFAB ? Curves.elasticOut : Curves.easeIn,
            alignment: const Alignment(0.8, 0.9),
            child: ExpandableFab(
              overlayStyle: ExpandableFabOverlayStyle(
                color: Colors.black.withOpacity(0.4),
              ),
              foregroundColor: foreground,
              backgroundColor: background,
              expandedFabSize: ExpandableFabSize.regular,
              distance: HUGE_SPACE,
              closeButtonStyle: ExpandableFabCloseButtonStyle(
                backgroundColor: background,
                foregroundColor: foreground,
              ),
              type: ExpandableFabType.up,
              children: [
                FloatingActionButton.extended(
                  onPressed: createNewQuickLocationShare,
                  icon: const Icon(Icons.share_location_rounded),
                  label: Text(l10n.shareLocation_title),
                  backgroundColor: background,
                  foregroundColor: foreground,
                ),
                FloatingActionButton.extended(
                  onPressed: importLocation,
                  icon: const Icon(Icons.download_rounded),
                  label:
                      Text(l10n.sharesOverviewScreen_importTask_action_import),
                  backgroundColor: background,
                  foregroundColor: foreground,
                ),
                FABOpenContainer(
                  label: l10n.sharesOverviewScreen_title,
                  icon: Icons.list_rounded,
                  onTap: (context, _) => const SharesOverviewScreen(),
                ),
                FABOpenContainer(
                  label: l10n.settingsScreen_title,
                  icon: context.platformIcons.settings,
                  onTap: (context, _) => const SettingsScreen(),
                )
              ],
            ),
          ),
        );
      },
      body: Stack(
        children: <Widget>[
          buildMap(),
          buildOutOfBoundsMarkers(),
          buildViewsSelection(),
          buildMapActions(),
          ViewDetailsSheet(
            view: selectedView,
            lastLocation: lastLocation,
            onGoToPosition: (position) {
              if (flutterMapController != null) {
                flutterMapController!
                    .move(position, flutterMapController!.zoom);
              }

              if (appleMapController != null) {
                appleMapController!.moveCamera(
                  AppleMaps.CameraUpdate.newLatLng(
                    AppleMaps.LatLng(
                      position.latitude,
                      position.longitude,
                    ),
                  ),
                );
              }
            },
          ),
          ActiveSharesSheet(
            visible: selectedViewID == null,
            triggerThreshold: 0.12,
            onThresholdReached: () {
              setState(() {
                showFAB = false;
              });
            },
            onThresholdPassed: () {
              setState(() {
                showFAB = true;
              });
            },
            onShareLocation: () {
              setState(() {
                showFAB = true;
                selectedViewID = null;
              });

              createNewQuickLocationShare();
            },
            onOpenActionSheet: () {
              showCupertinoModalPopup(
                context: context,
                barrierDismissible: true,
                builder: (cupertino) => CupertinoActionSheet(
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancelLabel),
                  ),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: withPopNavigation(createNewQuickLocationShare)(
                          context),
                      child: CupertinoListTile(
                        leading: const Icon(Icons.share_location_rounded),
                        title: Text(l10n.shareLocation_title),
                      ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: withPopNavigation(importLocation)(context),
                      child: CupertinoListTile(
                        leading:
                            const Icon(CupertinoIcons.square_arrow_down_fill),
                        title: Text(
                            l10n.sharesOverviewScreen_importTask_action_import),
                      ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialWithModalsPageRoute(
                            builder: (context) => const SharesOverviewScreen(),
                          ),
                        );
                      },
                      child: CupertinoListTile(
                        leading: const Icon(CupertinoIcons.list_bullet),
                        title: Text(l10n.sharesOverviewScreen_title),
                      ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);

                        showSettings(context);
                      },
                      child: CupertinoListTile(
                        leading: Icon(context.platformIcons.settings),
                        title: Text(l10n.settingsScreen_title),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
