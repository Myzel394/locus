import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/theme.dart';

import '../constants/spacing.dart';
import 'Paper.dart';


class GoToMyLocationMapAction extends StatelessWidget {
  final double dimension;
  final double tooltipSpacing;
  final VoidCallback onGoToMyLocation;

  const GoToMyLocationMapAction({
    this.dimension = 50.0,
    this.tooltipSpacing = 10.0,
    required this.onGoToMyLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Tooltip(
      message: l10n.locationsOverview_mapAction_goToCurrentPosition,
      preferBelow: false,
      margin: EdgeInsets.only(bottom: tooltipSpacing),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: PlatformWidget(
            material: (context, _) =>
                Paper(
                  width: null,
                  borderRadius: BorderRadius.circular(HUGE_SPACE),
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    color: shades[400],
                    icon: const Icon(Icons.my_location),
                    onPressed: onGoToMyLocation,
                  ),
                ),
            cupertino: (context, _) =>
                CupertinoButton(
                  color: shades[400],
                  padding: EdgeInsets.zero,
                  onPressed: onGoToMyLocation,
                  child: const Icon(Icons.my_location),
                ),
          ),
        ),
      ),
    );
  }
}
