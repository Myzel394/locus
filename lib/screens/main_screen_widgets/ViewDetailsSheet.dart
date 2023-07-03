import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:locus/screens/ViewDetailScreen.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/utils/location.dart';
import 'package:locus/utils/permission.dart';
import 'package:locus/widgets/RequestLocationPermissionMixin.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../constants/spacing.dart';
import '../../utils/icon.dart';
import '../../utils/theme.dart';
import '../../widgets/AddressFetcher.dart';
import '../../widgets/BentoGridElement.dart';
import '../../widgets/Paper.dart';

class ViewDetailsSheet extends StatefulWidget {
  final TaskView? view;
  final LocationPointService? lastLocation;
  final void Function(LatLng position) onGoToPosition;

  const ViewDetailsSheet({
    required this.onGoToPosition,
    this.view,
    this.lastLocation,
    super.key,
  });

  @override
  State<ViewDetailsSheet> createState() => _ViewDetailsSheetState();
}

class _ViewDetailsSheetState extends State<ViewDetailsSheet> {
  final containerKey = GlobalKey();
  final DraggableScrollableController controller =
      DraggableScrollableController();

  TaskView? oldView;
  LocationPointService? oldLastLocation;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      // User should not be able to close the sheet when a view is selected.
      // Dynamically changing the snap sizes doesn't seem to work.
      // Instead we will simply reopen the sheet if the user tries to close it.
      if (controller.size == 0.0 && widget.view != null) {
        controller.animateTo(
          0.22,
          duration: const Duration(milliseconds: 750),
          curve: Curves.bounceOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ViewDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.view != widget.view) {
      oldView = oldWidget.view;
      oldLastLocation = oldWidget.lastLocation;

      if (widget.view == null) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      } else {
        controller.animateTo(
          0.22,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final view = widget.view ?? oldView;
    final lastLocation = widget.lastLocation ?? oldLastLocation;

    return DraggableScrollableSheet(
      controller: controller,
      minChildSize: 0.0,
      initialChildSize: 0.0,
      snapAnimationDuration: const Duration(milliseconds: 100),
      snap: true,
      snapSizes: const [
        0.0,
        0.15,
        0.22,
        1,
      ],
      builder: (context, scrollController) => Paper(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(MEDIUM_SPACE),
          bottomRight: Radius.zero,
          bottomLeft: Radius.zero,
          topLeft: Radius.circular(MEDIUM_SPACE),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: MEDIUM_SPACE),
              if (view != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.circle_rounded,
                      size: 20,
                      color: view.color,
                    ),
                    const SizedBox(width: SMALL_SPACE),
                    Text(view.name),
                  ],
                ),
              const SizedBox(height: LARGE_SPACE),
              if (lastLocation != null) ...[
                AddressFetcher(
                  latitude: lastLocation.latitude,
                  longitude: lastLocation.longitude,
                  builder: (address) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: address,
                          style: getBodyTextTextStyle(context),
                        ),
                        TextSpan(
                          text: " (${lastLocation.formatRawAddress()})",
                          style: getCaptionTextStyle(context),
                        ),
                      ],
                    ),
                  ),
                  rawLocationBuilder: (isLoading) => Row(
                    children: <Widget>[
                      if (isLoading) ...[
                        PlatformCircularProgressIndicator(),
                        const SizedBox(width: SMALL_SPACE),
                      ],
                      Text(
                        widget.lastLocation!.formatRawAddress(),
                        style: getBodyTextTextStyle(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MEDIUM_SPACE),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: MEDIUM_SPACE,
                  crossAxisSpacing: MEDIUM_SPACE,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    LastLocationBentoElement(
                      view: view!,
                      lastLocation: lastLocation,
                    ),
                    DistanceBentoElement(
                      lastLocation: lastLocation,
                      onTap: () {
                        controller.animateTo(
                          0.22,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.fastLinearToSlowEaseIn,
                        );

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
                      description:
                          l10n.locations_values_batteryState_description,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
        if (isCupertino(context)) {
          Navigator.of(context).push(
            MaterialWithModalsPageRoute(
              builder: (context) => ViewDetailScreen(
                view: widget.view,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            NativePageRoute(
              context: context,
              builder: (context) => ViewDetailScreen(
                view: widget.view,
              ),
            ),
          );
        }
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
