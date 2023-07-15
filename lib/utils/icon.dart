import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

IconData getIconDataForBatteryLevel(
  final BuildContext context,
  final double? level,
) {
  if (isCupertino(context)) {
    if (level == null) {
      return CupertinoIcons.battery_full;
    }

    if (level > 0.9) {
      return CupertinoIcons.battery_100;
    } else if (level > 0.25) {
      return CupertinoIcons.battery_25;
    } else {
      return CupertinoIcons.battery_0;
    }
  }

  if (level == null) {
    return Icons.battery_unknown_rounded;
  }

  if (level == 1) {
    return Icons.battery_full;
  } else if (level >= .83) {
    return Icons.battery_6_bar_rounded;
  } else if (level >= .67) {
    return Icons.battery_5_bar_rounded;
  } else if (level >= .5) {
    return Icons.battery_4_bar_rounded;
  } else if (level >= .33) {
    return Icons.battery_3_bar_rounded;
  } else if (level >= .17) {
    return Icons.battery_2_bar_rounded;
  } else if (level >= .05) {
    return Icons.battery_1_bar_rounded;
  } else {
    return Icons.battery_0_bar_rounded;
  }
}
