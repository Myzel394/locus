import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}

/// Picks a random color from the Material color palette, if design is material,
/// or from the Cupertino color palette, if design is cupertino.
Color pickRandomColor(
  final BuildContext context, {
  final bool onlyMaterial = false,
}) {
  final colors = onlyMaterial
      ? Colors.primaries
      : platformThemeData(
          context,
          material: (data) => Colors.primaries,
          cupertino: (data) => [
            CupertinoColors.systemRed,
            CupertinoColors.systemOrange,
            CupertinoColors.systemYellow,
            CupertinoColors.systemGreen,
            CupertinoColors.systemTeal,
            CupertinoColors.systemBlue,
            CupertinoColors.systemIndigo,
            CupertinoColors.systemPurple,
            CupertinoColors.systemPink,
          ],
        );

  return colors[Random().nextInt(colors.length)];
}
