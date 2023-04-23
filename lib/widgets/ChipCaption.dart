import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';

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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.onPrimary.withAlpha(100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE, vertical: SMALL_SPACE),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
        color: backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: primaryColor,
          ),
          const SizedBox(width: SMALL_SPACE),
          Text(
            caption,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
