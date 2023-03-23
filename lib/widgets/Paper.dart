import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:locus/constants/spacing.dart';

class Paper extends StatelessWidget {
  final Widget child;

  const Paper({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MEDIUM_SPACE),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .dialogBackgroundColor,
        borderRadius: BorderRadius.circular(
          MEDIUM_SPACE,
        ),
      ),
      child: child,
    );
  }
}
