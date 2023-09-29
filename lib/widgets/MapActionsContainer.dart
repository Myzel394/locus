import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/locations_overview_screen_widgets/constants.dart';

const MAP_ACTION_SIZE = 50.0;
const diff = FAB_SIZE - MAP_ACTION_SIZE;

class MapActionsContainer extends StatelessWidget {
  final List<Widget> children;

  const MapActionsContainer({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Add half the difference to center the button
      right: FAB_MARGIN + diff / 2,
      bottom: FAB_SIZE +
          FAB_MARGIN +
          (isCupertino(context) ? LARGE_SPACE : SMALL_SPACE),
      child: Column(
        children: children,
      ),
    );
  }
}
