import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/ImportTaskSheet.dart';
import 'package:locus/screens/SettingsScreen.dart';
import 'package:locus/screens/SharesOverviewScreen.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ActiveSharesSheet.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ShareLocationSheet.dart';
import 'package:locus/screens/shares_overview_screen_widgets/UpdateAvailableBanner.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/location.dart';
import 'package:locus/utils/show_message.dart';
import 'package:locus/widgets/FABOpenContainer.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  final MapController flutterMapController = MapController();

  late final AnimationController rotationController;
  late Animation<double> rotationAnimation;

  bool showFAB = true;

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

    flutterMapController.mapEventStream.listen((event) {
      if (event is MapEventRotate) {
        print((event.targetRotation % 360) / 360);

        rotationController.animateTo(
          ((event.targetRotation % 360) / 360),
          duration: Duration.zero,
        );
      }
    });

    rotationController =
        AnimationController(vsync: this, duration: Duration.zero);
    rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(rotationController);
  }

  @override
  dispose() {
    flutterMapController.dispose();
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
        flutterMapController.move(
          LatLng(position.latitude, position.longitude),
          flutterMapController.zoom,
        );
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
      flutterMapController?.move(
        LatLng(lastPosition!.latitude, lastPosition!.longitude),
        13,
      );
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
    final viewService = context.read<ViewService>();

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

  void showViewLocations(final TaskView view) async {
    setState(() {
      showFAB = false;
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
    final viewService = context.watch<ViewService>();

    if (viewService.views.isEmpty) {
      return const SizedBox.shrink();
    }

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

    return Positioned(
      // Add half the difference to center the button
      right: FAB_MARGIN + diff / 2,
      bottom: FAB_SIZE + FAB_MARGIN + SMALL_SPACE,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 50,
            child: Center(
              child: Paper(
                width: null,
                borderRadius: BorderRadius.circular(HUGE_SPACE),
                padding: EdgeInsets.zero,
                child: PlatformIconButton(
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
                  onPressed: () => goToCurrentPosition(askPermissions: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: SMALL_SPACE),
          SizedBox.square(
            dimension: 50,
            child: Center(
              child: Paper(
                width: null,
                borderRadius: BorderRadius.circular(HUGE_SPACE),
                padding: EdgeInsets.zero,
                child: PlatformIconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () => goToCurrentPosition(askPermissions: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
          buildBar(),
          buildMapActions(),
          ViewDetailsSheet(
            view: selectedView,
            lastLocation: lastLocation,
            onGoToPosition: (position) {
              flutterMapController.move(position, flutterMapController.zoom);
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
          ),
        ],
      ),
    );
  }
}
