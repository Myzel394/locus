import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:locus/utils/theme.dart';

import "package:latlong2/latlong.dart";

class LocusFlutterMap extends StatelessWidget {
  final List<Widget> children;
  final List<Widget> nonRotatedChildren;
  final MapOptions? options;
  final MapController? mapController;

  const LocusFlutterMap({
    super.key,
    this.options,
    this.children = const [],
    this.nonRotatedChildren = const [],
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = getIsDarkMode(context);

    final tileLayer = TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: "app.myzel394.locus",
    );

    return FlutterMap(
      options: options ??
          MapOptions(
            maxZoom: 18,
            minZoom: 2,
            center: LatLng(40, 20),
            zoom: 13.0,
          ),
      nonRotatedChildren: nonRotatedChildren,
      mapController: mapController,
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
        ...children,
      ],
    );
  }
}
