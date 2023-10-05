import "package:apple_maps_flutter/apple_maps_flutter.dart" as apple_maps;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/location/get-fallback-location.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:provider/provider.dart';

class LocusFlutterMap extends StatelessWidget {
  final List<Widget> flutterChildren;
  final List<Widget> nonRotatedChildren;
  final MapOptions? flutterMapOptions;
  final double? initialZoom;
  final MapController? flutterMapController;
  final apple_maps.AppleMapController? appleMapController;
  final Set<apple_maps.Circle> appleMapCircles;
  final void Function(apple_maps.AppleMapController)? onAppleMapCreated;

  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;

  const LocusFlutterMap({
    super.key,
    this.flutterMapOptions,
    this.flutterChildren = const [],
    this.nonRotatedChildren = const [],
    this.appleMapCircles = const {},
    this.initialZoom,
    this.flutterMapController,
    this.appleMapController,
    this.onTap,
    this.onLongPress,
    this.onAppleMapCreated,
  });

  LatLng getInitialPosition(final BuildContext context) {
    final currentLocation = context.read<CurrentLocationService>();

    return currentLocation.currentPosition == null
        ? getFallbackLocation(context)
        : LatLng(
      currentLocation.currentPosition!.latitude,
      currentLocation.currentPosition!.longitude,
    );
  }

  double getInitialZoom(final BuildContext context) {
    if (initialZoom != null) {
      return initialZoom!;
    }

    final currentLocation = context.read<CurrentLocationService>();

    return currentLocation.currentPosition == null
        ? FALLBACK_LOCATION_ZOOM_LEVEL
        : 13.0;
  }

  Widget buildFlutterMaps(final BuildContext context) {
    final isDarkMode = getIsDarkMode(context);

    final tileLayer = TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: "app.myzel394.locus",
    );

    return FlutterMap(
      options: flutterMapOptions ??
          MapOptions(
            maxZoom: 18,
            minZoom: 2,
            center: getInitialPosition(context),
            zoom: getInitialZoom(context),
            onTap: (_, location) => onTap?.call(location),
            onLongPress: (_, location) => onTap?.call(location),
          ),
      nonRotatedChildren: nonRotatedChildren,
      mapController: flutterMapController,
      children: [
        if (isDarkMode)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.difference,
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFFFF8800),
                BlendMode.hue,
              ),
              child: tileLayer,
            ),
          )
        else
          tileLayer,
        ...flutterChildren,
      ],
    );
  }

  Widget buildAppleMaps(final BuildContext context) {
    return apple_maps.AppleMap(
      initialCameraPosition: apple_maps.CameraPosition(
        target: toAppleMapsCoordinates(getInitialPosition(context)),
        zoom: getInitialZoom(context),
      ),
      compassEnabled: true,
      onTap: (location) =>
          onTap?.call(LatLng(
            location.latitude,
            location.longitude,
          )),
      onLongPress: (location) =>
          onLongPress?.call(LatLng(
            location.latitude,
            location.longitude,
          )),
      onMapCreated: onAppleMapCreated,
      circles: appleMapCircles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    if (settings.getMapProvider() == MapProvider.apple) {
      return buildAppleMaps(context);
    }

    return buildFlutterMaps(context);
  }
}
