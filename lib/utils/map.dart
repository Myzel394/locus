import 'dart:math';

double getZoomLevelForRadius(final double radiusInMeters) =>
    18 - log(radiusInMeters / 35) / log(2);
