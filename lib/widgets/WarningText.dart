import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/spacing.dart';
import '../utils/theme.dart';

class WarningText extends StatelessWidget {
  final String text;

  const WarningText(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color =
        isCupertino(context) ? CupertinoColors.systemYellow : Colors.yellow;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isDarkMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          PlatformWidget(
            material: (_, __) => Icon(
              Icons.warning_rounded,
              color: color,
            ),
            cupertino: (_, __) => Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: color,
            ),
          ),
          const SizedBox(width: TINY_SPACE),
          Flexible(
            child: Text(
              text,
              style: getCaptionTextStyle(context).copyWith(
                color: color,
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(SMALL_SPACE),
        ),
        padding: const EdgeInsets.all(SMALL_SPACE),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            PlatformWidget(
              material: (_, __) => Icon(
                Icons.warning_rounded,
                color: Colors.white,
              ),
              cupertino: (_, __) => Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: TINY_SPACE),
            Flexible(
              child: Text(
                text,
                style: getCaptionTextStyle(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
