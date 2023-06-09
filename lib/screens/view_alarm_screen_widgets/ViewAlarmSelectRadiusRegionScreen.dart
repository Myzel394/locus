import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/RadiusRegionMetaDataSheet.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/MapBanner.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:vibration/vibration.dart';

class ViewAlarmSelectRadiusRegionScreen extends StatefulWidget {
  const ViewAlarmSelectRadiusRegionScreen({
    super.key,
  });

  @override
  State<ViewAlarmSelectRadiusRegionScreen> createState() => _ViewAlarmSelectRadiusRegionScreenState();
}

class _ViewAlarmSelectRadiusRegionScreenState extends State<ViewAlarmSelectRadiusRegionScreen> {
  final controller = MapController();
  LatLng? alarmCenter;
  bool isInScaleMode = false;
  double radius = 100;
  double previousScale = 1;

  @override
  void initState() {
    super.initState();

    Geolocator.getLastKnownPosition().then((location) {
      if (location == null) {
        return;
      }

      controller.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
    });

    Geolocator.getCurrentPosition(
      // We want to get the position as fast as possible
      desiredAccuracy: LocationAccuracy.lowest,
    ).then((location) {
      controller.move(
        LatLng(location.latitude, location.longitude),
        13,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  CircleLayer getCircleLayer() => CircleLayer(
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
    final l10n = AppLocalizations.of(context);

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
        backgroundColor: Colors.transparent,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.location_addAlarm_radiusBased_help_title,
              style: getTitleTextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Text(l10n.location_addAlarm_radiusBased_help_description),
            const SizedBox(height: MEDIUM_SPACE),
            ListTile(
              title: Text(l10n.location_addAlarm_radiusBased_help_tapDescription),
              leading: const Icon(Icons.touch_app_rounded),
            ),
            ListTile(
              title: Text(l10n.location_addAlarm_radiusBased_help_pinchDescription),
              leading: const Icon(Icons.pinch_rounded),
            ),
          ],
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
                title: Text(l10n.location_addAlarm_radiusBased_help_tapDescription),
                leading: const Icon(Icons.touch_app_rounded),
              ),
              ListTile(
                title: Text(l10n.location_addAlarm_radiusBased_help_pinchDescription),
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
            icon: Icon(context.platformIcons.help),
            onPressed: showHelp,
          ),
        ],
      ),
      body: GestureDetector(
        onScaleUpdate: isInScaleMode
            ? (details) {
                final mapZoom = controller.zoom;
                final difference = details.scale - previousScale;
                final multiplier = math.pow(2, 18 - mapZoom) * .2;

                final newRadius = math.max<double>(
                  50,
                  difference > 0 ? radius + multiplier : radius - multiplier,
                );

                setState(() {
                  radius = newRadius;
                });

                previousScale = details.scale;
              }
            : null,
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
                      child: FlutterMap(
                        mapController: controller,
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
                                child: getCircleLayer(),
                              )
                            else
                              getCircleLayer(),
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
                            child: Text(l10n.location_addAlarm_radiusBased_isInScaleMode),
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
