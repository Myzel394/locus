import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/services/location_point_service.dart';
import "package:latlong2/latlong.dart";
import 'package:locus/services/view_service.dart';
import 'package:simple_shadow/simple_shadow.dart';

import '../../utils/theme.dart';
import 'constants.dart';

class OutOfBoundMarker extends StatelessWidget {
  final TaskView view;
  final LocationPointService lastViewLocation;
  final VoidCallback onTap;
  final double north;
  final double south;
  final double west;
  final double east;

  const OutOfBoundMarker({
    required this.onTap,
    required this.view,
    required this.lastViewLocation,
    required this.north,
    required this.south,
    required this.west,
    required this.east,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Add some padding to the bounds
    final availableWidth = size.width - OUT_OF_BOUND_MARKER_X_PADDING * 2;
    final availableHeight = size.height - OUT_OF_BOUND_MARKER_Y_PADDING * 2;
    final xAvailablePercentage = availableWidth / size.width;
    final yAvailablePercentage = availableHeight / size.height;
    final xPercentage = ((lastViewLocation.longitude - west) / (east - west))
        .clamp(1 - xAvailablePercentage, xAvailablePercentage);
    final yPercentage = ((lastViewLocation.latitude - north) / (south - north))
        .clamp(1 - yAvailablePercentage, yAvailablePercentage);

    // Calculate the rotation between marker and last location
    final markerLongitude = west + xPercentage * (east - west);
    final markerLatitude = north + yPercentage * (south - north);

    final diffLongitude = lastViewLocation.longitude - markerLongitude;
    final diffLatitude = lastViewLocation.latitude - markerLatitude;

    final rotation = atan2(diffLongitude, diffLatitude) + pi;

    final totalDiff = Geolocator.distanceBetween(
      lastViewLocation.latitude,
      lastViewLocation.longitude,
      markerLatitude,
      markerLongitude,
    );

    final bottomRightMapActionsHeight = size.width - (FAB_SIZE + FAB_MARGIN);
    final width =
        size.width - OUT_OF_BOUND_MARKER_X_PADDING - OUT_OF_BOUND_MARKER_SIZE;
    final height = xPercentage * size.width > bottomRightMapActionsHeight
        ? size.height - (FAB_SIZE + FAB_MARGIN) * 2
        : size.height - OUT_OF_BOUND_MARKER_Y_PADDING;

    return Positioned(
      // Subtract `OUT_OF_BOUND_MARKER_SIZE` to make sure the marker doesn't
      // overlap with the bounds
      left: xPercentage * width,
      top: yPercentage * height,
      child: Opacity(
        opacity: (1000000 / totalDiff).clamp(0.2, 1),
        child: Transform.rotate(
          angle: rotation,
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                SimpleShadow(
                  opacity: .4,
                  sigma: 2,
                  color: Colors.black,
                  // Calculate offset based of rotation, shadow should always show down
                  offset: Offset(
                    sin(rotation) * 4,
                    cos(rotation) * 4,
                  ),
                  child: SizedBox.square(
                    dimension: OUT_OF_BOUND_MARKER_SIZE.toDouble(),
                    child: SvgPicture.asset(
                      "assets/location-out-of-bounds-marker.svg",
                      width: OUT_OF_BOUND_MARKER_SIZE.toDouble(),
                      height: OUT_OF_BOUND_MARKER_SIZE.toDouble(),
                      colorFilter: ColorFilter.mode(
                        getSheetColor(context),
                        BlendMode.srcATop,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: OUT_OF_BOUND_MARKER_SIZE / 2 - 40 / 2,
                  top: 3,
                  child: Icon(
                    Icons.circle_rounded,
                    size: 40,
                    color: view.color,
                  ),
                ),
                Positioned(
                  left: OUT_OF_BOUND_MARKER_SIZE / 2 - 30 / 2,
                  top: 7.5,
                  child: Transform.rotate(
                    angle: -rotation,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 30,
                      color: getSheetColor(context),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
