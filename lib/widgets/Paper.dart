import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:locus/constants/spacing.dart';

class Paper extends StatelessWidget {
  final Widget child;
  final double roundness;
  final BoxConstraints? constraints;

  const Paper({
    required this.child,
    double? roundness,
    this.constraints,
    Key? key,
  })  : roundness = roundness ?? MEDIUM_SPACE,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MEDIUM_SPACE),
      constraints: constraints,
      width: double.infinity,
      decoration: BoxDecoration(
        color: platformThemeData(
          context,
          material: (data) => data.dialogBackgroundColor,
          cupertino: (data) => data.barBackgroundColor,
        ),
        borderRadius: BorderRadius.circular(roundness),
      ),
      child: child,
    );
  }
}
