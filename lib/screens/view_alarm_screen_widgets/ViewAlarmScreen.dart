import 'dart:math';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as AppleMaps;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmSelectRadiusRegionScreen.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import '../../widgets/PlatformFlavorWidget.dart';

class ViewAlarmScreen extends StatefulWidget {
  final TaskView view;

  const ViewAlarmScreen({
    required this.view,
    super.key,
  });

  @override
  State<ViewAlarmScreen> createState() => _ViewAlarmScreenState();
}

class _ViewAlarmScreenState extends State<ViewAlarmScreen> {
  LocationPointService? lastLocation;

  void _addNewAlarm() async {
    final viewService = context.read<ViewService>();
    final RadiusBasedRegionLocationAlarm? alarm =
        await Navigator.of(context).push(
      MaterialWithModalsPageRoute(
        builder: (context) => const ViewAlarmSelectRadiusRegionScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (alarm == null) {
      return;
    }

    widget.view.addAlarm(alarm);
    await viewService.update(widget.view);
  }

  Widget getEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        PlatformFlavorWidget(
          cupertino: (_, __) => const Icon(CupertinoIcons.alarm, size: 120),
          material: (_, __) => const Icon(Icons.alarm_rounded, size: 120),
        ),
        const SizedBox(height: LARGE_SPACE),
        Text(
          l10n.location_manageAlarms_empty_title,
          style: getTitle2TextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          l10n.location_manageAlarms_empty_description,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          onPressed: _addNewAlarm,
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.add),
          ),
          child: Text(l10n.location_manageAlarms_addNewAlarm_actionLabel),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    widget.view.addListener(updateView);

    widget.view.getLocations(
      onLocationFetched: (final location) {
        if (!mounted) {
          return;
        }

        setState(() {
          lastLocation = location;
        });
      },
      onEnd: () {},
      limit: 1,
    );
  }

  @override
  void dispose() {
    widget.view.removeListener(updateView);

    super.dispose();
  }

  updateView() {
    setState(() {});
  }

  Widget buildMap(final RadiusBasedRegionLocationAlarm alarm) {
    final settings = context.read<SettingsService>();

    // Apple Maps doesn't seem to be working with multiple maps
    // see https://github.com/LuisThein/apple_maps_flutter/issues/44
    if (settings.mapProvider == MapProvider.apple && false) {
      return AppleMaps.AppleMap(
        key: ValueKey(alarm.id),
        initialCameraPosition: AppleMaps.CameraPosition(
          target: AppleMaps.LatLng(
            alarm.center.latitude,
            alarm.center.longitude,
          ),
          zoom: 18 - log(alarm.radius / 30) / log(2),
        ),
        myLocationEnabled: true,
        circles: {
          if (lastLocation != null)
            AppleMaps.Circle(
              circleId: AppleMaps.CircleId("${alarm.id}:lastLocation"),
              center: AppleMaps.LatLng(
                lastLocation!.latitude,
                lastLocation!.longitude,
              ),
              radius: 5,
              fillColor: Colors.blue.withOpacity(0.5),
              strokeWidth: 0,
            ),
          AppleMaps.Circle(
            circleId: AppleMaps.CircleId("${alarm.id}:alarm"),
            center: AppleMaps.LatLng(
              alarm.center.latitude,
              alarm.center.longitude,
            ),
            radius: alarm.radius,
            fillColor: Colors.red.withOpacity(0.3),
            strokeWidth: 0,
          ),
        },
      );
    }

    return FlutterMap(
      options: MapOptions(
        center: alarm.center,
        maxZoom: 18,
        // create zoom based off of radius
        zoom: 18 - log(alarm.radius / 35) / log(2),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: "app.myzel394.locus",
        ),
        CircleLayer(
          circles: [
            if (lastLocation != null)
              CircleMarker(
                point: LatLng(lastLocation!.latitude, lastLocation!.longitude),
                radius: 5,
                color: Colors.blue,
              ),
            CircleMarker(
              point: alarm.center,
              useRadiusInMeter: true,
              color: Colors.red.withOpacity(0.3),
              borderStrokeWidth: 5,
              borderColor: Colors.red,
              radius: alarm.radius,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.location_manageAlarms_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE),
          child: Center(
            child: widget.view.alarms.isEmpty
                ? getEmptyState()
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: widget.view.alarms.length,
                          itemBuilder: (context, index) {
                            final RadiusBasedRegionLocationAlarm alarm =
                                widget.view.alarms[index]
                                    as RadiusBasedRegionLocationAlarm;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: MEDIUM_SPACE,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  PlatformListTile(
                                    title: Text(alarm.zoneName),
                                    leading: alarm.getIcon(context),
                                    trailing: PlatformIconButton(
                                      icon: Icon(context.platformIcons.delete),
                                      onPressed: () async {
                                        final viewService =
                                            context.read<ViewService>();

                                        widget.view.removeAlarm(alarm);
                                        await viewService.update(widget.view);
                                      },
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(LARGE_SPACE),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 200,
                                      child: IgnorePointer(
                                        ignoring: true,
                                        child: buildMap(alarm),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: MEDIUM_SPACE),
                          child: PlatformElevatedButton(
                            onPressed: _addNewAlarm,
                            material: (_, __) => MaterialElevatedButtonData(
                              icon: const Icon(Icons.add),
                            ),
                            child: Text(l10n
                                .location_manageAlarms_addNewAlarm_actionLabel),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: MEDIUM_SPACE),
                          child: Text(
                              l10n.location_manageAlarms_lastCheck_description(
                                  widget.view.lastAlarmCheck)),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
