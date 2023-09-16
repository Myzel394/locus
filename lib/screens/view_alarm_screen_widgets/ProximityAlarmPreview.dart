import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/locations_overview_screen_widgets/LocationFetchers.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/location_alarm_service/ProximityLocationAlarm.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/location/get-fallback-location.dart';
import 'package:locus/utils/map.dart';
import 'package:locus/widgets/LocusFlutterMap.dart';
import 'package:provider/provider.dart';

class ProximityAlarmPreview extends StatelessWidget {
  final TaskView view;
  final ProximityLocationAlarm alarm;
  final VoidCallback onDelete;

  const ProximityAlarmPreview({
    required this.view,
    required this.alarm,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locationFetchers = context.watch<LocationFetchers>();
    final lastLocation =
        locationFetchers.getLocations(view).lastOrNull?.asLatLng();
    final currentPosition =
        context.watch<CurrentLocationService>().currentPosition;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PlatformListTile(
          title: Text(
            alarm.radius > 10000
                ? l10n.location_addAlarm_radiusBased_radius_kilometers(
                    double.parse(
                      (alarm.radius / 1000).toStringAsFixed(1),
                    ),
                  )
                : l10n.location_addAlarm_radiusBased_radius_meters(
                    alarm.radius.round()),
          ),
          leading: alarm.getIcon(context),
          trailing: PlatformIconButton(
            icon: Icon(context.platformIcons.delete),
            onPressed: onDelete,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(LARGE_SPACE),
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: IgnorePointer(
              ignoring: true,
              child: LocusFlutterMap(
                options: MapOptions(
                  center: currentPosition == null
                      ? getFallbackLocation(context)
                      : LatLng(
                          currentPosition.latitude,
                          currentPosition.longitude,
                        ),
                  maxZoom: 18,
                  // create zoom based of radius
                  zoom: getZoomLevelForRadius(alarm.radius),
                ),
                children: [
                  CircleLayer(
                    circles: [
                      if (lastLocation != null)
                        CircleMarker(
                          point: lastLocation,
                          radius: 5,
                          color: Colors.blue,
                        ),
                      CircleMarker(
                        point: currentPosition == null
                            ? getFallbackLocation(context)
                            : LatLng(
                                currentPosition.latitude,
                                currentPosition.longitude,
                              ),
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
  }
}
