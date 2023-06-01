// This transition is intended to match the default for MIUI
import 'package:flutter/material.dart';

class _OpenFromRightPageTransition extends StatelessWidget {
  const _OpenFromRightPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  // The new page slides upwards just a little as its clip
  // rectangle exposes the page from bottom to top.
  static final Tween<Offset> _primaryTranslationTween = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  );

  // The old page slides upwards a little as the new page appears.
  static final Tween<Offset> _secondaryTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.2, 0.0),
  );

  // The scrim obscures the old page by becoming increasingly opaque.
  static final Tween<double> _scrimOpacityTween = Tween<double>(
    begin: 0.0,
    end: 0.4,
  );

  // Used by all of the transition animations.
  static const Curve _transitionCurve = Curves.easeOutExpo;

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;

        final CurvedAnimation primaryAnimation = CurvedAnimation(
          parent: animation,
          curve: _transitionCurve,
          reverseCurve: _transitionCurve.flipped,
        );

        final Animation<double> opacityAnimation =
            _scrimOpacityTween.animate(primaryAnimation);
        final Animation<Offset> primaryTranslationAnimation =
            _primaryTranslationTween.animate(primaryAnimation);

        final Animation<Offset> secondaryTranslationAnimation =
            _secondaryTranslationTween.animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: _transitionCurve,
            reverseCurve: _transitionCurve.flipped,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Container(
              color: Colors.black.withOpacity(opacityAnimation.value),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: secondaryAnimation,
            child: FractionalTranslation(
              translation: primaryTranslationAnimation.value,
              child: child,
            ),
            builder: (BuildContext context, Widget? child) {
              return FractionalTranslation(
                translation: secondaryTranslationAnimation.value,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

class OpenFromRightPageTransitionsBuilder extends PageTransitionsBuilder {
  const OpenFromRightPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _OpenFromRightPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}
