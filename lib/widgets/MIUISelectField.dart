import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/SettingsCaretIcon.dart';

class MIUISelectField extends StatelessWidget {
  final String label;
  final String actionText;
  final VoidCallback onPressed;

  final Widget? icon;

  const MIUISelectField({
    required this.label,
    required this.actionText,
    required this.onPressed,
    this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(SMALL_SPACE),
        ),
      ),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MEDIUM_SPACE,
          horizontal: TINY_SPACE,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: SMALL_SPACE),
                    child: icon,
                  ),
                Text(
                  label,
                  style: getSubTitleTextStyle(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  actionText,
                  textAlign: TextAlign.end,
                  style: getBodyTextTextStyle(context).copyWith(
                    color: getCaptionTextStyle(context).color,
                  ),
                ),
                const SizedBox(width: 8),
                const SettingsCaretIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
