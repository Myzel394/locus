import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:apple_maps_flutter/apple_maps_flutter.dart" as AppleMaps;
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/ImportTaskSheet.dart';
import 'package:locus/screens/SettingsScreen.dart';
import 'package:locus/screens/SharesOverviewScreen.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ActiveSharesSheet.dart';
import 'package:locus/screens/locations_overview_screen_widgets/OutOfBoundMarker.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ShareLocationSheet.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ViewLocationPopup.dart';
import 'package:locus/screens/locations_overview_screen_widgets/view_location_fetcher.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/helpers.dart';
import 'package:locus/utils/location.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/utils/show_message.dart';
import 'package:locus/widgets/FABOpenContainer.dart';
import 'package:locus/widgets/LocusFlutterMap.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
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
import 'ViewDetailScreen.dart';
import 'locations_overview_screen_widgets/ViewDetailsSheet.dart';
import 'locations_overview_screen_widgets/constants.dart';

// After this threshold, locations will not be merged together anymore
const LOCATION_DETAILS_ZOOM_THRESHOLD = 17;

enum LocationStatus {
  stale,
  active,
  fetching,
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
  late final ViewLocationFetcher _fetchers;
  MapController? flutterMapController;
  PopupController? flutterMapPopupController;
  AppleMaps.AppleMapController? appleMapController;

  late final AnimationController rotationController;
  late Animation<double> rotationAnimation;

  bool showFAB = true;
  bool isNorth = true;

  bool showDetailedLocations = false;
  bool disableShowDetailedLocations = false;

  Stream<Position>? _positionStream;

  // Dummy stream to trigger updates to out of bound markers
  StreamController<void> mapEventStream = StreamController<void>.broadcast();

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

  Map<TaskView, List<LocationPointService>> _cachedMergedLocations = {};

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
        configureBackgroundFetch();

        final taskService = context.read<TaskService>();
        final viewService = context.read<ViewService>();
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

        viewService.addListener(_handleViewServiceChange);
      });

    _handleViewAlarmChecker();
    _handleNotifications();

    final settings = context.read<SettingsService>();
    if (settings.getMapProvider() == MapProvider.openStreetMap) {
      flutterMapController = MapController();
      flutterMapController!.mapEventStream.listen((event) {
        if (event is MapEventRotate) {
          rotationController.animateTo(
            ((event.targetRotation % 360) / 360),
            duration: Duration.zero,
          );

          setState(() {
            isNorth = (event.targetRotation % 360).abs() < 1;
          });
        }

        if (event is MapEventWithMove ||
            event is MapEventDoubleTapZoom ||
            event is MapEventScrollWheelZoom) {
          mapEventStream.add(null);

          setState(() {
            showDetailedLocations =
                event.zoom >= LOCATION_DETAILS_ZOOM_THRESHOLD;
          });
        }
      });

      flutterMapPopupController = PopupController();
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
    mapEventStream.close();

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

  void _handleViewServiceChange() {
    final viewService = context.read<ViewService>();
    final newView = viewService.views.last;

    _fetchers.addView(newView);
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

  List<LocationPointService> mergeLocationsIfRequired(
    final TaskView view,
  ) {
    final locations = _fetchers.locations[view] ?? [];

    if (showDetailedLocations && !disableShowDetailedLocations) {
      return locations;
    }

    if (_cachedMergedLocations.containsKey(selectedView)) {
      return _cachedMergedLocations[selectedView]!;
    }

    final mergedLocations = mergeLocations(
      locations,
      distanceThreshold: LOCATION_MERGE_DISTANCE_THRESHOLD,
    );

    _cachedMergedLocations[view] = mergedLocations;

    return mergedLocations;
  }

  void _createLocationFetcher() {
    final viewService = context.read<ViewService>();

    _fetchers = ViewLocationFetcher(viewService.views)..fetchLocations();
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
          notificationIcon:
              const AndroidResource(name: "ic_quick_actions_share_now"),
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
        onCameraMove: (movement) {
          mapEventStream.add(null);

          setState(() {
            showDetailedLocations =
                movement.zoom >= LOCATION_DETAILS_ZOOM_THRESHOLD;
          });
        },
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
              (view) => mergeLocationsIfRequired(view)
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
        polylines: Set<AppleMaps.Polyline>.from(
          _fetchers.locations.entries
              .where((entry) =>
                  selectedViewID == null || entry.key.id == selectedViewID)
              .map(
            (entry) {
              final view = entry.key;

              return AppleMaps.Polyline(
                polylineId: AppleMaps.PolylineId(view.id),
                color: entry.key.color.withOpacity(0.9),
                width: 10,
                jointType: AppleMaps.JointType.round,
                polylineCap: AppleMaps.Cap.roundCap,
                consumeTapEvents: true,
                onTap: () {
                  setState(() {
                    showFAB = false;
                    selectedViewID = view.id;
                  });
                },
                points: mergeLocationsIfRequired(entry.key)
                    .reversed
                    .map(
                      (location) => AppleMaps.LatLng(
                        location.latitude,
                        location.longitude,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      );
    }

    return LocusFlutterMap(
      mapController: flutterMapController,
      children: [
        CircleLayer(
          circles: viewService.views.reversed
              .where(
                  (view) => selectedViewID == null || view.id == selectedViewID)
              .map(
                (view) => mergeLocationsIfRequired(view)
                    .mapIndexed(
                      (index, location) => CircleMarker(
                        radius: location.accuracy,
                        useRadiusInMeter: true,
                        point: LatLng(location.latitude, location.longitude),
                        borderStrokeWidth: 1,
                        color: view.color.withOpacity(.1),
                        borderColor: view.color,
                      ),
                    )
                    .toList(),
              )
              .expand((element) => element)
              .toList(),
        ),
        PolylineLayer(
          polylines: List<Polyline>.from(
            _fetchers.locations.entries
                .where((entry) =>
                    selectedViewID == null || entry.key.id == selectedViewID)
                .map(
              (entry) {
                final view = entry.key;
                final locations = mergeLocationsIfRequired(entry.key);

                return Polyline(
                  color: view.color.withOpacity(0.9),
                  strokeWidth: 10,
                  strokeJoin: StrokeJoin.round,
                  gradientColors: locations.length <=
                          LOCATION_POLYLINE_OPAQUE_AMOUNT_THRESHOLD
                      ? null
                      : List<Color>.generate(
                              9, (index) => view.color.withOpacity(0.9)) +
                          [view.color.withOpacity(.3)],
                  points: locations.reversed
                      .map(
                        (location) =>
                            LatLng(location.latitude, location.longitude),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ),
        _buildUserMarkerLayer(),
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            markerTapBehavior: MarkerTapBehavior.togglePopupAndHideRest(),
            popupController: flutterMapPopupController,
            popupDisplayOptions: PopupDisplayOptions(
              builder: (context, marker) {
                final view = viewService.views.firstWhere(
                  (view) => Key(view.id) == marker.key,
                );

                return ViewLocationPopup(
                  view: view,
                  location: marker.point,
                  onShowDetails: () {
                    flutterMapPopupController!.togglePopup(marker);
                    setState(() {
                      showFAB = false;
                      selectedViewID = view.id;
                    });
                  },
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

  Widget buildOutOfBoundsMarkers() {
    return Stack(
      children: _fetchers.views
          .where((view) =>
              (_fetchers.locations[view]?.isNotEmpty ?? false) &&
              (selectedViewID == null || selectedViewID == view.id))
          .map(
            (view) => OutOfBoundMarker(
              lastViewLocation: _fetchers.locations[view]!.last,
              onTap: () {
                showViewLocations(view);
              },
              view: view,
              updateStream: mapEventStream.stream,
              appleMapController: appleMapController,
              flutterMapController: flutterMapController,
            ),
          )
          .toList(),
    );
  }

  void showViewLocations(final TaskView view,
      {final bool jumpToLatestLocation = true}) async {
    setState(() {
      showFAB = false;
      selectedViewID = view.id;
    });

    if (!jumpToLatestLocation) {
      return;
    }

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
    const margin = 10.0;
    const dimension = 50.0;
    const diff = FAB_SIZE - dimension;

    final l10n = AppLocalizations.of(context);
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
            AnimatedScale(
              scale: showDetailedLocations ? 1 : 0,
              duration:
                  showDetailedLocations ? 1200.milliseconds : 100.milliseconds,
              curve: showDetailedLocations ? Curves.elasticOut : Curves.easeIn,
              child: Tooltip(
                message: disableShowDetailedLocations
                    ? l10n.locationsOverview_mapAction_detailedLocations_show
                    : l10n.locationsOverview_mapAction_detailedLocations_hide,
                preferBelow: false,
                margin: const EdgeInsets.only(bottom: margin),
                child: SizedBox.square(
                  dimension: dimension,
                  child: Center(
                    child: Paper(
                      width: null,
                      borderRadius: BorderRadius.circular(HUGE_SPACE),
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        color: shades[400],
                        icon: Icon(disableShowDetailedLocations
                            ? MdiIcons.mapMarkerMultipleOutline
                            : MdiIcons.mapMarkerMultiple),
                        onPressed: () {
                          setState(() {
                            disableShowDetailedLocations =
                                !disableShowDetailedLocations;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: SMALL_SPACE),
            Tooltip(
              message: l10n.locationsOverview_mapAction_alignNorth,
              preferBelow: false,
              margin: const EdgeInsets.only(bottom: margin),
              child: SizedBox.square(
                dimension: dimension,
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
            ),
            const SizedBox(height: SMALL_SPACE),
            Tooltip(
              message: l10n.locationsOverview_mapAction_goToCurrentPosition,
              preferBelow: false,
              margin: const EdgeInsets.only(bottom: margin),
              child: SizedBox.square(
                dimension: dimension,
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
                      onPressed: () =>
                          goToCurrentPosition(askPermissions: true),
                      child: const Icon(Icons.my_location),
                    ),
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
            locations: _fetchers.locations[selectedView],
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
