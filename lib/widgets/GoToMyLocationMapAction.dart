import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/theme.dart';

import '../constants/spacing.dart';
import 'Paper.dart';

class GoToMyLocationMapAction extends StatefulWidget {
  final double dimension;
  final double tooltipSpacing;
  final VoidCallback onGoToMyLocation;
  final bool animate;

  const GoToMyLocationMapAction({
    this.dimension = 50.0,
    this.tooltipSpacing = 10.0,
    this.animate = false,
    required this.onGoToMyLocation,
    super.key,
  });

  @override
  State<GoToMyLocationMapAction> createState() =>
      _GoToMyLocationMapActionState();
}

class _GoToMyLocationMapActionState extends State<GoToMyLocationMapAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController rotationController =
      AnimationController(vsync: this, duration: 2.seconds);

  void _updateAnimation() {
    if (widget.animate) {
      rotationController.repeat();
    } else {
      rotationController.reset();
    }
  }

  @override
  void initState() {
    super.initState();

    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant GoToMyLocationMapAction oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateAnimation();
  }

  @override
  void dispose() {
    rotationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Tooltip(
      message: l10n.mapAction_goToCurrentPosition,
      preferBelow: false,
      margin: EdgeInsets.only(bottom: widget.tooltipSpacing),
      child: SizedBox.square(
        dimension: widget.dimension,
        child: Center(
          child: PlatformWidget(
            material: (context, _) => Paper(
              width: null,
              borderRadius: BorderRadius.circular(HUGE_SPACE),
              padding: EdgeInsets.zero,
              child: IconButton(
                color: shades[400],
                icon: AnimatedBuilder(
                  animation: rotationController,
                  builder: (context, child) => Transform.rotate(
                    angle: rotationController.value * 2 * pi,
                    child: child,
                  ),
                  child: const Icon(Icons.my_location),
                ),
                onPressed: widget.onGoToMyLocation,
              ),
            ),
            cupertino: (context, _) => CupertinoButton(
              color: shades[400],
              padding: EdgeInsets.zero,
              onPressed: widget.onGoToMyLocation,
              child: AnimatedBuilder(
                animation: rotationController,
                builder: (context, child) => Transform.rotate(
                  angle: rotationController.value * 2 * pi,
                  child: child,
                ),
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
