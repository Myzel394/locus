import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/GeoLocationAlarmPreview.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ProximityAlarmPreview.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmSelectRadiusBasedScreen.dart';
import 'package:locus/services/location_alarm_service/LocationAlarmServiceBase.dart';
import 'package:locus/services/location_alarm_service/ProximityLocationAlarm.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/services/location_alarm_service/index.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/log_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:locus/widgets/ModalSheetContent.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../../models/log.dart';
import '../../utils/PageRoute.dart';
import '../../widgets/LocusFlutterMap.dart';
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
    final l10n = AppLocalizations.of(context);

    final alarmType = await showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
      ),
      builder: (context) => ModalSheet(
        child: ModalSheetContent(
          icon: Icons.alarm_rounded,
          title: l10n.location_addAlarm_selectType_title,
          description: l10n.location_addAlarm_selectType_description,
          children: [
            PlatformListTile(
              title: Text(l10n.location_addAlarm_geo_title),
              subtitle: Text(l10n.location_addAlarm_geo_description),
              leading: const Icon(Icons.circle),
              onTap: () {
                Navigator.of(context).pop(
                  LocationAlarmType.geo,
                );
              },
            ),
            PlatformListTile(
              title: Text(l10n.location_addAlarm_proximity_title),
              subtitle: Text(l10n.location_addAlarm_proximity_description),
              leading: const Icon(Icons.location_searching_rounded),
              onTap: () {
                Navigator.of(context).pop(
                  LocationAlarmType.proximity,
                );
              },
            ),
          ],
        ),
      ),
    );

    if (!mounted || alarmType == null) {
      return;
    }

    final logService = context.read<LogService>();
    final viewService = context.read<ViewService>();
    final LocationAlarmServiceBase? alarm = (await (() {
      if (isCupertino(context)) {
        return showCupertinoModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => ViewAlarmSelectRadiusBasedScreen(
            type: alarmType,
          ),
        );
      }

      return Navigator.of(context).push(
        NativePageRoute(
          context: context,
          builder: (context) => ViewAlarmSelectRadiusBasedScreen(
            type: alarmType,
          ),
        ),
      );
    })()) as LocationAlarmServiceBase?;

    if (!mounted) {
      return;
    }

    if (alarm == null) {
      return;
    }

    widget.view.addAlarm(alarm);
    await viewService.update(widget.view);

    await logService.addLog(
      Log.createAlarm(
        initiator: LogInitiator.user,
        id: alarm.id,
        alarmType: LocationAlarmType.geo,
        viewID: widget.view.id,
        viewName: widget.view.name,
      ),
    );
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

  Widget buildMap(final GeoLocationAlarm alarm) {
    // Apple Maps doesn't seem to be working with multiple maps
    // see https://github.com/LuisThein/apple_maps_flutter/issues/44
    /*
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
   */

    return LocusFlutterMap(
      options: MapOptions(
        center: alarm.center,
        maxZoom: 18,
        // create zoom based of radius
        zoom: 18 - log(alarm.radius / 35) / log(2),
      ),
      children: [
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

  VoidCallback _deleteAlarm(final LocationAlarmServiceBase alarm) {
    return () async {
      final l10n = AppLocalizations.of(context);
      final shouldDelete = await showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlertDialog(
          material: (context, __) => MaterialAlertDialogData(
            icon: const Icon(Icons.delete_forever_rounded),
          ),
          title: Text(l10n.location_removeAlarm_title),
          content: Text(l10n.location_removeAlarm_description),
          actions: createCancellableDialogActions(
            context,
            [
              PlatformDialogAction(
                material: (context, _) => MaterialDialogActionData(
                  icon: const Icon(Icons.delete_forever_rounded),
                ),
                child: Text(l10n.location_removeAlarm_confirm),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );

      if (!mounted || shouldDelete != true) {
        return;
      }

      final viewService = context.read<ViewService>();
      final logService = context.read<LogService>();

      widget.view.removeAlarm(alarm);
      await viewService.update(widget.view);

      await logService.addLog(
        Log.deleteAlarm(
          initiator: LogInitiator.user,
          viewID: widget.view.id,
          viewName: widget.view.name,
        ),
      );
    };
  }

  Widget getList() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.view.alarms.length,
            itemBuilder: (context, index) {
              final alarm = widget.view.alarms[index];
              final handleDelete = _deleteAlarm(alarm);

              final child = (() {
                switch (alarm.IDENTIFIER) {
                  case LocationAlarmType.geo:
                    return GeoLocationAlarmPreview(
                      view: widget.view,
                      alarm: alarm as GeoLocationAlarm,
                      onDelete: handleDelete,
                    );
                  case LocationAlarmType.proximity:
                    return ProximityAlarmPreview(
                      view: widget.view,
                      alarm: alarm as ProximityLocationAlarm,
                      onDelete: handleDelete,
                    );
                }
              })();

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: MEDIUM_SPACE,
                ),
                child: child,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MEDIUM_SPACE),
            child: PlatformElevatedButton(
              onPressed: _addNewAlarm,
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.add),
              ),
              child: Text(l10n.location_manageAlarms_addNewAlarm_actionLabel),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MEDIUM_SPACE),
            child: Text(l10n.location_manageAlarms_lastCheck_description(
                widget.view.lastAlarmCheck)),
          ),
        ],
      ),
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
            child: widget.view.alarms.isEmpty ? getEmptyState() : getList(),
          ),
        ),
      ),
    );
  }
}
