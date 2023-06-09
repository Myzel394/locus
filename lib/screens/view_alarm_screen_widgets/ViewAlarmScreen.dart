import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmSelectRadiusRegionScreen.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

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
    final RadiusBasedRegionLocationAlarm? alarm = await Navigator.of(context).push(
      MaterialPageRoute(
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
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.view.alarms.length + 1,
                    itemBuilder: (context, index) {
                      if (index == widget.view.alarms.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: LARGE_SPACE),
                          child: PlatformElevatedButton(
                            onPressed: _addNewAlarm,
                            material: (_, __) => MaterialElevatedButtonData(
                              icon: const Icon(Icons.add),
                            ),
                            child: Text(l10n.location_manageAlarms_addNewAlarm_actionLabel),
                          ),
                        );
                      }

                      final RadiusBasedRegionLocationAlarm alarm =
                          widget.view.alarms[index] as RadiusBasedRegionLocationAlarm;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlatformListTile(
                            title: Text(alarm.zoneName),
                            leading: alarm.getIcon(context),
                            trailing: PlatformIconButton(
                              icon: Icon(context.platformIcons.delete),
                              onPressed: () async {
                                final viewService = context.read<ViewService>();

                                widget.view.removeAlarm(alarm);
                                await viewService.update(widget.view);
                              },
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(LARGE_SPACE),
                            child: SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: IgnorePointer(
                                ignoring: true,
                                child: FlutterMap(
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
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
