import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/locations_overview_screen_widgets/LocationFetchers.dart';
import 'package:locus/services/location_alarm_service/index.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/map.dart';
import 'package:locus/widgets/LocusFlutterMap.dart';
import 'package:provider/provider.dart';

class GeoLocationAlarmPreview extends StatelessWidget {
  final TaskView view;
  final GeoLocationAlarm alarm;
  final VoidCallback onDelete;

  const GeoLocationAlarmPreview({
    super.key,
    required this.view,
    required this.alarm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final locationFetchers = context.watch<LocationFetchers>();
    final lastLocation =
    locationFetchers
        .getLocations(view)
        .lastOrNull
        ?.asLatLng();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PlatformListTile(
          title: Text(alarm.zoneName),
          leading: getIconForLocationRadiusBasedTrigger(context, alarm.type),
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
                  center: alarm.center,
                  maxZoom: 18,
                  // create zoom based of radius
                  zoom: getZoomLevelForRadius(alarm.radius),
                ),
                children: [
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: alarm.center,
                        useRadiusInMeter: true,
                        color: Colors.red.withOpacity(0.3),
                        borderStrokeWidth: 5,
                        borderColor: Colors.red,
                        radius: alarm.radius,
                      ),
                      if (lastLocation != null) ...[
                        CircleMarker(
                          point: lastLocation,
                          useRadiusInMeter: false,
                          color: Colors.white,
                          radius: 7,
                        ),
                        CircleMarker(
                          point: lastLocation,
                          useRadiusInMeter: false,
                          color: Colors.cyan,
                          radius: 5,
                        ),
                      ],
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
