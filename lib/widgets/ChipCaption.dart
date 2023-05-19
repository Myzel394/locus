import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';

class ChipCaption extends StatelessWidget {
  final String caption;
  final IconData icon;

  const ChipCaption(
    this.caption, {
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: MEDIUM_SPACE, vertical: SMALL_SPACE),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
        color: shades[0]!.withOpacity(.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: shades[0],
          ),
          const SizedBox(width: SMALL_SPACE),
          Text(
            caption,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: shades[0],
            ),
          ),
        ],
      ),
    );
  }
}
