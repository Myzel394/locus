import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/date.dart';
import 'package:locus/utils/navigation.dart';
import 'package:latlong2/latlong.dart';

import 'package:locus/utils/location/index.dart';
import 'package:locus/utils/permissions/has-granted.dart';
import 'package:locus/utils/permissions/request.dart';
import 'package:locus/widgets/OpenInMaps.dart';
import 'package:map_launcher/map_launcher.dart';
import '../../constants/spacing.dart';
import '../../services/location_point_service.dart';
import '../../utils/icon.dart';
import '../../utils/theme.dart';
import '../../widgets/BentoGridElement.dart';
import '../../widgets/LocusFlutterMap.dart';
import '../../widgets/RequestLocationPermissionMixin.dart';
import '../ViewDetailsScreen.dart';

class ViewDetails extends StatefulWidget {
  final TaskView? view;
  final LocationPointService? location;
  final void Function(LocationPointService position) onGoToPosition;

  const ViewDetails({
    required this.view,
    required this.location,
    required this.onGoToPosition,
    super.key,
  });

  @override
  State<ViewDetails> createState() => _ViewDetailsState();
}

class _ViewDetailsState extends State<ViewDetails> {
  TaskView? oldView;
  LocationPointService? oldLastLocation;

  @override
  void didUpdateWidget(covariant ViewDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    oldView = oldWidget.view;
    oldLastLocation = oldWidget.location;
  }

  Widget buildHeadingMap(final LocationPointService lastLocation,) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LARGE_SPACE),
      child: SizedBox(
        height: 200,
        child: LocusFlutterMap(
          options: MapOptions(
            center: LatLng(
              lastLocation.latitude,
              lastLocation.longitude,
            ),
            zoom: 13,
          ),
          children: [
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    lastLocation.latitude,
                    lastLocation.longitude,
                  ),
                  builder: (context) =>
                      Transform.rotate(
                        angle: lastLocation.heading!,
                        child: Icon(
                          CupertinoIcons.location_north_fill,
                          color: getPrimaryColorShades(context)[0],
                          size: 30,
                        ),
                      ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final view = (widget.view ?? oldView)!;
    final lastLocation = (widget.location ?? oldLastLocation)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: MEDIUM_SPACE,
          crossAxisSpacing: MEDIUM_SPACE,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            LastLocationBentoElement(
              view: view,
              lastLocation: lastLocation,
            ),
            DistanceBentoElement(
              lastLocation: lastLocation,
            ),
            BentoGridElement(
              title: lastLocation.altitude == null
                  ? l10n.unknownValue
                  : l10n.locations_values_altitude_m(
                lastLocation.altitude!.round(),
              ),
              icon: platformThemeData(
                context,
                material: (_) => Icons.height_rounded,
                cupertino: (_) => CupertinoIcons.arrow_up,
              ),
              type: BentoType.tertiary,
              description: l10n.locations_values_altitude_description,
            ),
            BentoGridElement(
              title: lastLocation.speed == null
                  ? l10n.unknownValue
                  : l10n.locations_values_speed_kmh(
                (lastLocation.speed! * 3.6).round(),
              ),
              icon: platformThemeData(
                context,
                material: (_) => Icons.speed,
                cupertino: (_) => CupertinoIcons.speedometer,
              ),
              type: BentoType.tertiary,
              description: l10n.locations_values_speed_description,
            ),
            BentoGridElement(
              title: lastLocation.batteryLevel == null
                  ? l10n.unknownValue
                  : l10n.locations_values_battery_value(
                (lastLocation.batteryLevel! * 100).round(),
              ),
              icon: getIconDataForBatteryLevel(
                context,
                lastLocation.batteryLevel,
              ),
              description: l10n.locations_values_battery_description,
              type: BentoType.tertiary,
            ),
            BentoGridElement(
              title: lastLocation.batteryState == null
                  ? l10n.unknownValue
                  : l10n.locations_values_batteryState_value(
                lastLocation.batteryState!.name,
              ),
              icon: Icons.cable_rounded,
              type: BentoType.tertiary,
              description: l10n.locations_values_batteryState_description,
            ),
          ],
        ),
        if (lastLocation.heading != null) ...[
          const SizedBox(height: MEDIUM_SPACE),
          buildHeadingMap(lastLocation),
        ],
      ],
    );
  }
}

class DistanceBentoElement extends StatefulWidget {
  final LocationPointService lastLocation;

  const DistanceBentoElement({
    required this.lastLocation,
    super.key,
  });

  @override
  State<DistanceBentoElement> createState() => _DistanceBentoElementState();
}

class _DistanceBentoElementState extends State<DistanceBentoElement>
    with RequestLocationPermissionMixin {
  Stream<Position>? _positionStream;
  bool hasGrantedPermission = false;
  Position? currentPosition;

  void fetchCurrentPosition() async {
    _positionStream = getLastAndCurrentPosition(updateLocation: true)
      ..listen((position) {
        if (!mounted) {
          return;
        }

        setState(() {
          currentPosition = position;
        });
      });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await hasGrantedLocationPermission()) {
        fetchCurrentPosition();

        setState(() {
          hasGrantedPermission = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.drain();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BentoGridElement(
      onTap: () {
        showPlatformModalSheet(
          context: context,
          material: MaterialModalSheetData(),
          builder: (context) =>
              OpenInMaps(
                destination: widget.lastLocation.asCoords(),
              ),
        );
      },
      title: (() {
        if (!hasGrantedPermission) {
          return l10n.locations_values_distance_permissionRequired;
        }

        if (currentPosition == null) {
          return l10n.loading;
        }

        final distanceInMeters = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          widget.lastLocation.latitude,
          widget.lastLocation.longitude,
        );

        if (distanceInMeters < 10) {
          return l10n.locations_values_distance_nearby;
        }

        if (distanceInMeters < 1000) {
          return l10n.locations_values_distance_m(
            distanceInMeters.toStringAsFixed(0).toString(),
          );
        }

        return l10n.locations_values_distance_km(
          (distanceInMeters / 1000).toStringAsFixed(0),
        );
      })(),
      type: hasGrantedPermission && currentPosition != null
          ? BentoType.secondary
          : BentoType.disabled,
      icon: platformThemeData(
        context,
        material: (_) => Icons.map,
        cupertino: (_) => CupertinoIcons.map,
      ),
      description: l10n.locations_values_distance_description,
    );
  }
}

// We use a custom element for this, because it will be updated
// in a specific interval and so we reduce the amount of
// elements that need to be updated
class LastLocationBentoElement extends StatefulWidget {
  final TaskView view;
  final LocationPointService lastLocation;

  const LastLocationBentoElement({
    required this.view,
    required this.lastLocation,
    super.key,
  });

  @override
  State<LastLocationBentoElement> createState() =>
      _LastLocationBentoElementState();
}

class _LastLocationBentoElementState extends State<LastLocationBentoElement> {
  late final Timer _timer;
  bool showAbsolute = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BentoGridElement(
      onTap: () {
        setState(() {
          showAbsolute = !showAbsolute;
        });
      },
      title: showAbsolute
          ? formatDateTimeHumanReadable(widget.lastLocation.createdAt)
          : GetTimeAgo.parse(
        DateTime.now().subtract(
          DateTime.now().difference(widget.lastLocation.createdAt),
        ),
      ),
      icon: Icons.location_on_rounded,
      description: l10n.locations_values_lastLocation_description,
    );
  }
}
