import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

class BentoGridElement extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const BentoGridElement({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  Color getBackgroundColor(final BuildContext context) {
    final settings = context.read<SettingsService>();

    if (settings.primaryColor != null) {
      return settings.primaryColor!.withOpacity(.2);
    }

    return platformThemeData(
      context,
      material: (data) => data.colorScheme.secondaryContainer,
      cupertino: (data) => data.primaryColor,
    );
  }

  Color getTitleColor(final BuildContext context) {
    final settings = context.read<SettingsService>();

    if (settings.primaryColor != null) {
      return settings.primaryColor!;
    }

    return platformThemeData(
      context,
      material: (data) => data.textTheme.bodyLarge!.color!,
      cupertino: (data) => data.textTheme.navTitleTextStyle.color!,
    );
  }

  Color getDescriptionColor(final BuildContext context) {
    final settings = context.read<SettingsService>();

    if (settings.primaryColor != null) {
      return settings.primaryColor!.withOpacity(.8);
    }

    return platformThemeData(
      context,
      material: (data) => data.colorScheme.onSecondaryContainer,
      cupertino: (data) => data.textTheme.tabLabelTextStyle.color!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: LARGE_SPACE,
            cornerSmoothing: 1,
          ),
        ),
        color: getBackgroundColor(context),
      ),
      padding: const EdgeInsets.all(MEDIUM_SPACE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: getTitleColor(context),
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: getDescriptionColor(context),
                size: 16,
              ),
              const SizedBox(width: TINY_SPACE),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    color: getDescriptionColor(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
