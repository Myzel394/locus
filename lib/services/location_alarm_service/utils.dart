import 'package:flutter/material.dart';

import 'enums.dart';

Icon getIconForLocationRadiusBasedTrigger(
  final BuildContext context,
  final LocationRadiusBasedTriggerType type,
) {
  switch (type) {
    case LocationRadiusBasedTriggerType.whenEnter:
      return const Icon(Icons.arrow_circle_right_rounded);
    case LocationRadiusBasedTriggerType.whenLeave:
      return const Icon(Icons.arrow_circle_left_rounded);
  }
}
