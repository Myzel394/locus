import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';

class Paper extends StatelessWidget {
  final Widget child;
  final BoxConstraints? constraints;
  final BoxDecoration decoration;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius borderRadius;

  Paper({
    required this.child,
    BorderRadius? borderRadius,
    BoxDecoration? decoration,
    this.height,
    this.width = double.infinity,
    this.padding = const EdgeInsets.all(MEDIUM_SPACE),
    this.constraints,
    Key? key,
  })  : borderRadius = borderRadius ?? BorderRadius.circular(MEDIUM_SPACE),
        decoration = decoration ?? const BoxDecoration(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      constraints: constraints,
      width: width,
      height: height,
      decoration: decoration.copyWith(
        color: platformThemeData(
          context,
          material: (data) => data.dialogBackgroundColor,
          cupertino: (data) => data.barBackgroundColor,
        ),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
