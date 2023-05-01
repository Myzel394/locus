import 'dart:ui';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/spacing.dart';

Future<dynamic> showSingularElementDialog({
  required final BuildContext context,
  required final Widget Function(BuildContext context) builder,
}) {
  if (isCupertino(context)) {
    // Cupertino already has a blur effect
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: LARGE_SPACE,
            horizontal: MEDIUM_SPACE,
          ),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: builder(context),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  return showDialog(
    context: context,
    barrierDismissible: true,
    // We want the `Container` to have a black color, as we can animate it
    barrierColor: Colors.transparent,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withOpacity(.5),
        child: SafeArea(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              child: builder(context),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 500.ms),
    ),
  );
}
