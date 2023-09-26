import 'dart:math';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/GeoAlarmMetaDataSheet.dart';
import 'package:locus/screens/view_alarm_screen_widgets/LocationRadiusSelectorMap.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ProximityAlarmMetaDataSheet.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/location_alarm_service/LocationAlarmServiceBase.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/helper_sheet.dart';
import 'package:locus/utils/location/index.dart';
import 'package:locus/utils/permissions/has-granted.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/GoToMyLocationMapAction.dart';
import 'package:locus/widgets/MapActionsContainer.dart';
import 'package:locus/widgets/RequestNotificationPermissionMixin.dart';
import 'package:provider/provider.dart';

class ViewAlarmSelectRadiusBasedScreen extends StatefulWidget {
  final LocationAlarmType type;

  const ViewAlarmSelectRadiusBasedScreen({
    super.key,
    required this.type,
  });

  @override
  State<ViewAlarmSelectRadiusBasedScreen> createState() =>
      _ViewAlarmSelectRadiusBasedScreenState();
}

class _ViewAlarmSelectRadiusBasedScreenState
    extends State<ViewAlarmSelectRadiusBasedScreen>
    with RequestNotificationPermissionMixin {
  MapController? flutterMapController;
  apple_maps.AppleMapController? appleMapController;

  LatLng? alarmCenter;

  bool isInScaleMode = false;
  double radius = 50.0;
  double previousScale = 1;
  Stream<Position>? _positionStream;

  bool isGoingToCurrentPosition = false;

  bool _hasSetInitialPosition = false;

  late CurrentLocationService _currentLocationService;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();
    _currentLocationService = context.read<CurrentLocationService>();

    if (settings.mapProvider == MapProvider.openStreetMap) {
      flutterMapController = MapController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      goToCurrentPosition();

      _setPositionFromCurrentLocationService(updateAlarmCenter: true);
      _showHelperSheetIfRequired();
    });

    _currentLocationService.addListener(_setPositionFromCurrentLocationService);
  }

  @override
  void dispose() {
    flutterMapController?.dispose();
    _positionStream?.drain();

    _currentLocationService
        .removeListener(_setPositionFromCurrentLocationService);

    super.dispose();
  }

  void _setPositionFromCurrentLocationService({
    final updateAlarmCenter = false,
  }) {
    if (_currentLocationService.currentPosition == null) {
      return;
    }

    _animateToPosition(_currentLocationService.currentPosition!);

    if (updateAlarmCenter || widget.type == LocationAlarmType.proximity) {
      setState(() {
        alarmCenter = LatLng(
          _currentLocationService.currentPosition!.latitude,
          _currentLocationService.currentPosition!.longitude,
        );
      });
    }
  }

  void _showHelperSheetIfRequired() async {
    final settings = context.read<SettingsService>();

    if (!settings.hasSeenHelperSheet(HelperSheet.radiusBasedAlarms)) {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return;
      }

      showHelp();
    }
  }

  void _animateToPosition(final Position position) async {
    final zoom = _hasSetInitialPosition
        ? (16 - log(position.accuracy / 200) / log(2)).toDouble()
        : flutterMapController?.zoom ??
            (await appleMapController?.getZoomLevel()) ??
            16.0;

    flutterMapController?.move(
      LatLng(position.latitude, position.longitude),
      zoom,
    );
    appleMapController?.moveCamera(
      apple_maps.CameraUpdate.newLatLng(
        apple_maps.LatLng(position.latitude, position.longitude),
      ),
    );

    if (!_hasSetInitialPosition) {
      _hasSetInitialPosition = true;
      setState(() {
        alarmCenter = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void showHelp() {
    final l10n = AppLocalizations.of(context);

    showHelperSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.location_addAlarm_radiusBased_help_description),
          const SizedBox(height: MEDIUM_SPACE),
          if (widget.type == LocationAlarmType.geo) ...[
            Row(
              children: <Widget>[
                const Icon(Icons.touch_app_rounded),
                const SizedBox(width: MEDIUM_SPACE),
                Flexible(
                  child: Text(
                    l10n.location_addAlarm_geo_help_tapDescription,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: MEDIUM_SPACE),
          Row(
            children: <Widget>[
              const Icon(Icons.pinch_rounded),
              const SizedBox(width: MEDIUM_SPACE),
              Flexible(
                child: Text(
                  l10n.location_addAlarm_radiusBased_help_pinchDescription,
                ),
              ),
            ],
          ),
        ],
      ),
      title: l10n.location_addAlarm_radiusBased_help_title,
      sheetName: HelperSheet.radiusBasedAlarms,
    );
  }

  void goToCurrentPosition() async {
    if (!(await hasGrantedLocationPermission())) {
      return;
    }

    setState(() {
      isGoingToCurrentPosition = true;
    });

    _positionStream = getLastAndCurrentPosition()
      ..listen((position) async {
        final currentLocation = context.read<CurrentLocationService>();

        currentLocation.updateCurrentPosition(position);

        setState(() {
          isGoingToCurrentPosition = false;
        });

        _animateToPosition(position);
      });
  }

  Future<void> _selectRegion() async {
    LocationAlarmServiceBase? alarm;

    switch (widget.type) {
      case LocationAlarmType.geo:
        alarm = await showPlatformModalSheet(
          context: context,
          material: MaterialModalSheetData(
            backgroundColor: Colors.transparent,
            isDismissible: true,
            isScrollControlled: true,
          ),
          builder: (_) => GeoAlarmMetaDataSheet(
            center: alarmCenter!,
            radius: radius.toDouble(),
          ),
        );
        break;
      case LocationAlarmType.proximity:
        alarm = await showPlatformModalSheet(
          context: context,
          material: MaterialModalSheetData(
            backgroundColor: Colors.transparent,
            isDismissible: true,
            isScrollControlled: true,
          ),
          builder: (_) => ProximityAlarmMetaDataSheet(
            radius: radius,
          ),
        );
    }

    if (alarm == null) {
      return;
    }

    final hasGrantedNotificationAccess =
        await showNotificationPermissionDialog();

    if (!hasGrantedNotificationAccess || !mounted) {
      return;
    }

    Navigator.pop(context, alarm);
  }

  Widget buildMapActions() {
    return MapActionsContainer(
      children: <Widget>[
        GoToMyLocationMapAction(
          onGoToMyLocation: goToCurrentPosition,
          animate: isGoingToCurrentPosition,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final TYPE_TITLE_MAP = {
      LocationAlarmType.geo: l10n.location_addAlarm_geo_title,
      LocationAlarmType.proximity: l10n.location_addAlarm_proximity_title,
    };

    return PlatformScaffold(
      material: (_, __) => MaterialScaffoldData(
        resizeToAvoidBottomInset: false,
      ),
      appBar: PlatformAppBar(
        title: Text(TYPE_TITLE_MAP[widget.type]!),
        trailingActions: [
          PlatformIconButton(
            cupertino: (_, __) => CupertinoIconButtonData(
              padding: EdgeInsets.zero,
            ),
            icon: Icon(context.platformIcons.help),
            onPressed: showHelp,
          ),
        ],
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: isInScaleMode
              ? null
              : getCupertinoAppBarColorForMapScreen(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 10,
            child: LocationRadiusSelectorMap(
              center: alarmCenter,
              radius: radius,
              flutterMapController: flutterMapController,
              appleMapController: appleMapController,
              onLocationChange: (location) {
                // Proximity does not need a center
                if (widget.type == LocationAlarmType.proximity) {
                  return;
                }

                setState(() {
                  alarmCenter = location;
                });
              },
              onAppleMapCreated: (controller) {
                appleMapController = controller;
              },
              onRadiusChange: (newRadius) {
                setState(() {
                  radius = newRadius;
                });
              },
              children: [
                buildMapActions(),
              ],
            ),
          ),
          Expanded(
            child: TextButton.icon(
              icon: Icon(context.platformIcons.checkMark),
              onPressed: _selectRegion,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              label: Text(l10n.location_addAlarm_radiusBased_addLabel),
            ),
          ),
        ],
      ),
    );
  }
}
