import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../constants/spacing.dart';
import 'Paper.dart';
import 'PlatformFlavorWidget.dart';

class MapCompass extends StatefulWidget {
  final double dimension;
  final VoidCallback onAlignNorth;
  final MapController mapController;

  const MapCompass({
    super.key,
    this.dimension = 50.0,
    required this.onAlignNorth,
    required this.mapController,
  });

  @override
  State<MapCompass> createState() => _MapCompassState();
}

class _MapCompassState extends State<MapCompass> with TickerProviderStateMixin {
  late final AnimationController rotationController;
  late Animation<double> rotationAnimation;

  late final StreamSubscription<MapEvent> _mapEventSubscription;

  @override
  void initState() {
    super.initState();

    rotationController =
        AnimationController(vsync: this, duration: Duration.zero);
    rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(rotationController);

    _mapEventSubscription =
        widget.mapController.mapEventStream.listen(updateRotation);
  }

  @override
  void dispose() {
    _mapEventSubscription.cancel();

    super.dispose();
  }

  void updateRotation(final MapEvent event) {
    if (event is MapEventRotate) {
      rotationController.animateTo(
        ((event.targetRotation % 360) / 360),
        duration: Duration.zero,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Tooltip(
      message: l10n.mapAction_alignNorth,
      preferBelow: false,
      child: SizedBox.square(
        dimension: widget.dimension,
        child: Center(
          child: AnimatedBuilder(
            animation: rotationAnimation,
            builder: (context, _) {
              final degrees = rotationAnimation.value * 180 / pi;
              final isNorth = (degrees % 360).abs() < 1;

              return PlatformWidget(
                material: (context, _) => Paper(
                  width: null,
                  borderRadius: BorderRadius.circular(HUGE_SPACE),
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    color: isNorth ? shades[200] : shades[400],
                    icon: Transform.rotate(
                      angle: rotationAnimation.value,
                      child: PlatformFlavorWidget(
                        material: (context, _) => Transform.rotate(
                          angle: -pi / 4,
                          child: const Icon(MdiIcons.compass),
                        ),
                        cupertino: (context, _) =>
                            const Icon(CupertinoIcons.location_north_fill),
                      ),
                    ),
                    onPressed: widget.onAlignNorth,
                  ),
                ),
                cupertino: (context, _) => CupertinoButton(
                  color: isNorth ? shades[200] : shades[400],
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(HUGE_SPACE),
                  onPressed: widget.onAlignNorth,
                  child: AnimatedBuilder(
                    animation: rotationAnimation,
                    builder: (context, child) => Transform.rotate(
                      angle: rotationAnimation.value,
                      child: child,
                    ),
                    child: const Icon(CupertinoIcons.location_north_fill),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
