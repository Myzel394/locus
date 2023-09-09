import 'dart:math' as math;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/screens/locations_overview_screen_widgets/constants.dart';
import 'package:locus/screens/view_alarm_screen_widgets/RadiusRegionMetaDataSheet.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/helper_sheet.dart';
import 'package:locus/utils/location/get-fallback-location.dart';
import 'package:locus/utils/location/index.dart';
import 'package:locus/utils/permissions/has-granted.dart';
import 'package:locus/utils/permissions/request.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/GoToMyLocationMapAction.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:locus/widgets/MapActionsContainer.dart';
import 'package:locus/widgets/RequestNotificationPermissionMixin.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

import '../../widgets/LocusFlutterMap.dart';
import '../../widgets/MapBanner.dart';

class ViewAlarmSelectRadiusRegionScreen extends StatefulWidget {
  const ViewAlarmSelectRadiusRegionScreen({
    super.key,
  });

  @override
  State<ViewAlarmSelectRadiusRegionScreen> createState() =>
      _ViewAlarmSelectRadiusRegionScreenState();
}

class _ViewAlarmSelectRadiusRegionScreenState
    extends State<ViewAlarmSelectRadiusRegionScreen>
    with RequestNotificationPermissionMixin {
  MapController? flutterMapController;
  apple_maps.AppleMapController? appleMapController;
  LatLng? alarmCenter;
  bool isInScaleMode = false;
  double radius = 100;
  double previousScale = 1;
  Stream<Position>? _positionStream;

  bool isGoingToCurrentPosition = false;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();
    if (settings.mapProvider == MapProvider.openStreetMap) {
      flutterMapController = MapController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      goToCurrentPosition();

      final settings = context.read<SettingsService>();

      if (!settings.hasSeenHelperSheet(HelperSheet.radiusBasedAlarms)) {
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) {
          return;
        }

        showHelp();
      }
    });
  }

  void showHelp() {
    final l10n = AppLocalizations.of(context);

    showHelperSheet(
      context: context,
      builder: (context) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.location_addAlarm_radiusBased_help_description),
              const SizedBox(height: MEDIUM_SPACE),
              Row(
                children: <Widget>[
                  const Icon(Icons.touch_app_rounded),
                  const SizedBox(width: MEDIUM_SPACE),
                  Flexible(
                    child: Text(
                        l10n.location_addAlarm_radiusBased_help_tapDescription),
                  ),
                ],
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Row(
                children: <Widget>[
                  const Icon(Icons.pinch_rounded),
                  const SizedBox(width: MEDIUM_SPACE),
                  Flexible(
                    child: Text(
                        l10n
                            .location_addAlarm_radiusBased_help_pinchDescription),
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
      ..listen((position) {
        setState(() {
          isGoingToCurrentPosition = false;
        });

        flutterMapController?.move(
          LatLng(position.latitude, position.longitude),
          13,
        );
        appleMapController?.moveCamera(
          apple_maps.CameraUpdate.newLatLng(
            apple_maps.LatLng(position.latitude, position.longitude),
          ),
        );
      });
  }

  @override
  void dispose() {
    flutterMapController?.dispose();
    _positionStream?.drain();

    super.dispose();
  }

  CircleLayer getFlutterMapCircleLayer() =>
      CircleLayer(
        circles: [
          CircleMarker(
            point: alarmCenter!,
            radius: radius,
            useRadiusInMeter: true,
            color: Colors.red.withOpacity(.3),
            borderStrokeWidth: 5,
            borderColor: Colors.red,
          ),
        ],
      );

  Future<void> _selectRegion() async {
    final RadiusBasedRegionLocationAlarm? alarm = await showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        backgroundColor: Colors.transparent,
        isDismissible: true,
        isScrollControlled: true,
      ),
      builder: (_) =>
          RadiusRegionMetaDataSheet(
            center: alarmCenter!,
            radius: radius,
          ),
    );

    final hasGrantedNotificationAccess =
    await showNotificationPermissionDialog();

    if (!hasGrantedNotificationAccess) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (alarm != null) {
      Navigator.pop(context, alarm);
    }
  }

  void updateZoom(final ScaleUpdateDetails scaleUpdateDetails) async {
    final mapZoom = await (() async {
      if (appleMapController != null) {
        return appleMapController!.getZoomLevel();
      } else if (flutterMapController != null) {
        return flutterMapController!.zoom;
      } else {
        return 0.0;
      }
    })() as double;
    final difference = scaleUpdateDetails.scale - previousScale;
    final multiplier = math.pow(2, 18 - mapZoom) * .2;

    final newRadius = math.max<double>(
      50,
      difference > 0 ? radius + multiplier : radius - multiplier,
    );

    setState(() {
      radius = newRadius;
    });

    previousScale = scaleUpdateDetails.scale;
  }

  Widget buildMap() {
    final settings = context.read<SettingsService>();

    if (settings.mapProvider == MapProvider.apple) {
      return apple_maps.AppleMap(
        initialCameraPosition: apple_maps.CameraPosition(
          target: toAppleMapsCoordinates(getFallbackLocation(context)),
          zoom: FALLBACK_LOCATION_ZOOM_LEVEL,
        ),
        onMapCreated: (controller) {
          appleMapController = controller;
        },
        onLongPress: (_) {
          if (alarmCenter == null) {
            return;
          }

          Vibration.vibrate(duration: 100);

          setState(() {
            isInScaleMode = true;
          });
        },
        myLocationEnabled: true,
        onTap: (tapPosition) {
          setState(() {
            alarmCenter = LatLng(
              tapPosition.latitude,
              tapPosition.longitude,
            );
          });
        },
        circles: {
          if (alarmCenter != null)
            apple_maps.Circle(
              circleId: apple_maps.CircleId('alarm-${radius.round()}'),
              center: apple_maps.LatLng(
                alarmCenter!.latitude,
                alarmCenter!.longitude,
              ),
              radius: radius,
              fillColor: Colors.red.withOpacity(.3),
              strokeWidth: 5,
              consumeTapEvents: false,
            ),
        },
      );
    }

    return LocusFlutterMap(
      mapController: flutterMapController,
      options: MapOptions(
        onLongPress: (_, __) {
          if (alarmCenter == null) {
            return;
          }

          Vibration.vibrate(duration: 100);

          setState(() {
            isInScaleMode = true;
          });
        },
        center: getFallbackLocation(context),
        zoom: FALLBACK_LOCATION_ZOOM_LEVEL,
        onTap: (tapPosition, location) {
          setState(() {
            alarmCenter = location;
          });
        },
        maxZoom: 18,
      ),
      children: [
        if (alarmCenter != null)
          if (isInScaleMode)
            Shimmer.fromColors(
              baseColor: Colors.red,
              highlightColor: Colors.red.withOpacity(.2),
              child: getFlutterMapCircleLayer(),
            )
          else
            getFlutterMapCircleLayer(),
      ],
    );
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

    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(
            resizeToAvoidBottomInset: false,
          ),
      appBar: PlatformAppBar(
        title: Text(l10n.location_addAlarm_radiusBased_title),
        trailingActions: [
          PlatformIconButton(
            cupertino: (_, __) =>
                CupertinoIconButtonData(
                  padding: EdgeInsets.zero,
                ),
            icon: Icon(context.platformIcons.help),
            onPressed: showHelp,
          ),
        ],
        cupertino: (_, __) =>
            CupertinoNavigationBarData(
              backgroundColor: isInScaleMode
                  ? null
                  : getCupertinoAppBarColorForMapScreen(context),
            ),
      ),
      body: GestureDetector(
        onScaleUpdate: isInScaleMode ? updateZoom : null,
        onTap: isInScaleMode
            ? () {
          Vibration.vibrate(duration: 50);
          setState(() {
            isInScaleMode = false;
          });
        }
            : null,
        // We need a `Stack` to disable the map, but also need to show a container to detect the long press again
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 10,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: isInScaleMode,
                      child: Stack(
                        children: <Widget>[
                          buildMap(),
                          buildMapActions(),
                        ],
                      ),
                    ),
                  ),
                  if (isInScaleMode) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                    MapBanner(
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.pinch_rounded),
                          const SizedBox(width: MEDIUM_SPACE),
                          Flexible(
                            child: Text(
                              l10n.location_addAlarm_radiusBased_isInScaleMode,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: Icon(context.platformIcons.checkMark),
                onPressed: alarmCenter == null ? null : _selectRegion,
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
      ),
    );
  }
}
