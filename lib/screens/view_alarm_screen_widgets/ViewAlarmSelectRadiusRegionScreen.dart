import 'dart:math' as math;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as AppleMaps;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/RadiusRegionMetaDataSheet.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/helper_sheet.dart';
import 'package:locus/utils/permission.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RequestNotificationPermissionMixin.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

import '../../widgets/MapBanner.dart';

class ViewAlarmSelectRadiusRegionScreen extends StatefulWidget {
  const ViewAlarmSelectRadiusRegionScreen({
    super.key,
  });

  @override
  State<ViewAlarmSelectRadiusRegionScreen> createState() => _ViewAlarmSelectRadiusRegionScreenState();
}

class _ViewAlarmSelectRadiusRegionScreenState extends State<ViewAlarmSelectRadiusRegionScreen>
    with RequestNotificationPermissionMixin {
  MapController? flutterMapController;
  AppleMaps.AppleMapController? appleMapController;
  LatLng? alarmCenter;
  bool isInScaleMode = false;
  double radius = 100;
  double previousScale = 1;

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
                    child: Text(l10n.location_addAlarm_radiusBased_help_tapDescription),
                  ),
                ],
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Row(
                children: <Widget>[
                  const Icon(Icons.pinch_rounded),
                  const SizedBox(width: MEDIUM_SPACE),
                  Flexible(
                    child: Text(l10n.location_addAlarm_radiusBased_help_pinchDescription),
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

    Geolocator.getLastKnownPosition().then((location) {
      if (location == null) {
        return;
      }

      flutterMapController?.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
      appleMapController?.moveCamera(
        AppleMaps.CameraUpdate.newLatLng(
          AppleMaps.LatLng(location.latitude, location.longitude),
        ),
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
      appleMapController?.moveCamera(
        AppleMaps.CameraUpdate.newLatLng(
          AppleMaps.LatLng(location.latitude, location.longitude),
        ),
      );
    });
  }

  @override
  void dispose() {
    flutterMapController?.dispose();

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

    final hasGrantedNotificationAccess = await showNotificationPermissionDialog();

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
      return AppleMaps.AppleMap(
        initialCameraPosition: const AppleMaps.CameraPosition(
          target: AppleMaps.LatLng(40, 20),
          zoom: 13,
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
            AppleMaps.Circle(
              circleId: AppleMaps.CircleId('alarm-${radius.round()}'),
              center: AppleMaps.LatLng(
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

    return FlutterMap(
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
        center: LatLng(40, 20),
        zoom: 13,
        onTap: (tapPosition, location) {
          setState(() {
            alarmCenter = location;
          });
        },
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: "app.myzel394.locus",
        ),
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
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () async {
              final hasGrantedLocation = await requestBasicLocationPermission();

              if (hasGrantedLocation) {
                goToCurrentPosition();
              }
            },
          ),
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
              backgroundColor: isInScaleMode ? null : getCupertinoAppBarColorForMapScreen(context),
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
                      child: buildMap(),
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
