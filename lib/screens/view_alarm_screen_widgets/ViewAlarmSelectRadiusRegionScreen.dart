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
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/MapBanner.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

class ViewAlarmSelectRadiusRegionScreen extends StatefulWidget {
  const ViewAlarmSelectRadiusRegionScreen({
    super.key,
  });

  @override
  State<ViewAlarmSelectRadiusRegionScreen> createState() =>
      _ViewAlarmSelectRadiusRegionScreenState();
}

class _ViewAlarmSelectRadiusRegionScreenState
    extends State<ViewAlarmSelectRadiusRegionScreen> {
  MapController? flutterMapController;
  AppleMaps.AppleMapController? appleMapController;
  LatLng? alarmCenter;
  bool isInScaleMode = false;
  double radius = 100;
  double previousScale = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsService>();

      if (!settings.helpers_hasSeen_radiusBasedAlarms) {
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) {
          return;
        }

        showHelp();

        settings.helpers_hasSeen_radiusBasedAlarms = true;
        await settings.save();
      }
    });
  }

  @override
  void dispose() {
    flutterMapController?.dispose();

    super.dispose();
  }

  CircleLayer getFlutterMapCircleLayer() => CircleLayer(
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
      builder: (_) => RadiusRegionMetaDataSheet(
        center: alarmCenter!,
        radius: radius,
      ),
    );

    if (!mounted) {
      return;
    }

    if (alarm != null) {
      Navigator.pop(context, alarm);
    }
  }

  void showHelp() {
    final l10n = AppLocalizations.of(context);

    if (isCupertino(context)) {
      showCupertinoModalBottomSheet(
        context: context,
        backgroundColor: getSheetColor(context),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(LARGE_SPACE),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.location_addAlarm_radiusBased_help_title,
                  style: getTitleTextStyle(context),
                ),
                const SizedBox(height: MEDIUM_SPACE),
                Text(
                  l10n.location_addAlarm_radiusBased_help_description,
                  style: getBodyTextTextStyle(context),
                ),
                const SizedBox(height: LARGE_SPACE),
                Row(
                  children: <Widget>[
                    const Icon(Icons.touch_app_rounded),
                    const SizedBox(width: MEDIUM_SPACE),
                    Flexible(
                      child: Text(l10n
                          .location_addAlarm_radiusBased_help_tapDescription),
                    ),
                  ],
                ),
                const SizedBox(height: SMALL_SPACE),
                Row(
                  children: <Widget>[
                    const Icon(Icons.pinch_rounded),
                    const SizedBox(width: MEDIUM_SPACE),
                    Flexible(
                      child: Text(l10n
                          .location_addAlarm_radiusBased_help_pinchDescription),
                    ),
                  ],
                ),
                const SizedBox(height: LARGE_SPACE),
                CupertinoButton.filled(
                  child: Text(l10n.closeNeutralAction),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.location_addAlarm_radiusBased_help_title),
          icon: Icon(context.platformIcons.help),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.location_addAlarm_radiusBased_help_description),
              const SizedBox(height: MEDIUM_SPACE),
              ListTile(
                title: Text(
                    l10n.location_addAlarm_radiusBased_help_tapDescription),
                leading: const Icon(Icons.touch_app_rounded),
              ),
              ListTile(
                title: Text(
                    l10n.location_addAlarm_radiusBased_help_pinchDescription),
                leading: const Icon(Icons.pinch_rounded),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.closeNeutralAction),
            ),
          ],
        ),
      );
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
              circleId: AppleMaps.CircleId('alarm'),
              center: AppleMaps.LatLng(
                alarmCenter!.latitude,
                alarmCenter!.longitude,
              ),
              radius: radius,
              fillColor: Colors.red.withOpacity(.3),
              strokeWidth: 5,
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
      material: (_, __) => MaterialScaffoldData(
        resizeToAvoidBottomInset: false,
      ),
      appBar: PlatformAppBar(
        title: Text(l10n.location_addAlarm_radiusBased_title),
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
          backgroundColor: getCupertinoAppBarColorForMapScreen(context),
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
                            child: Text(l10n
                                .location_addAlarm_radiusBased_isInScaleMode),
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
