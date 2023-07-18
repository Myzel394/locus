import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:locus/services/view_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/navigation.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/spacing.dart';
import '../../services/location_point_service.dart';
import '../../utils/icon.dart';
import '../../utils/location.dart';
import '../../utils/permission.dart';
import '../../utils/theme.dart';
import '../../widgets/BentoGridElement.dart';
import '../../widgets/RequestLocationPermissionMixin.dart';
import '../ViewDetailScreen.dart';

class ViewDetails extends StatefulWidget {
  final TaskView? view;
  final LocationPointService? location;
  final void Function(LatLng position) onGoToPosition;

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

  Widget buildHeadingMap(
    final LocationPointService lastLocation,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LARGE_SPACE),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(
              lastLocation.latitude,
              lastLocation.longitude,
            ),
            zoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: "app.myzel394.locus",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    lastLocation.latitude,
                    lastLocation.longitude,
                  ),
                  builder: (context) => Transform.rotate(
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
              onTap: () {
                widget.onGoToPosition(
                  LatLng(
                    lastLocation.latitude,
                    lastLocation.longitude,
                  ),
                );
              },
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
  final VoidCallback onTap;

  const DistanceBentoElement({
    required this.onTap,
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
      onTap: hasGrantedPermission == false
          ? () async {
              final hasGranted = await requestBasicLocationPermission();

              if (hasGranted) {
                fetchCurrentPosition();

                setState(() {
                  hasGrantedPermission = true;
                });
              }
            }
          : widget.onTap,
      title: (() {
        if (!hasGrantedPermission) {
          return l10n.locations_values_distance_permissionRequired;
        }

        if (currentPosition == null) {
          return l10n.loading;
        }

        return l10n.locations_values_distance_km(
          (Geolocator.distanceBetween(
                    currentPosition!.latitude,
                    currentPosition!.longitude,
                    widget.lastLocation.latitude,
                    widget.lastLocation.longitude,
                  ) /
                  1000)
              .floor()
              .toString(),
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
        pushRoute(
          context,
          (context) => ViewDetailScreen(view: widget.view),
        );
      },
      title: GetTimeAgo.parse(
        DateTime.now().subtract(
          DateTime.now().difference(widget.lastLocation.createdAt),
        ),
      ),
      icon: Icons.location_on_rounded,
      description: l10n.locations_values_lastLocation_description,
    );
  }
}
