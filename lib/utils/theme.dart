import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/colors.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:provider/provider.dart';

TextStyle getBodyTextTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodyLarge!,
      cupertino: (data) => data.textTheme.textStyle,
    );

Color getErrorColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.colorScheme.error,
      cupertino: (data) => CupertinoColors.systemRed,
    );

Color getBodyTextColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodyLarge!.color!,
      cupertino: (data) => data.textTheme.textStyle.color!,
    );

bool getIsDarkMode(final BuildContext context) =>
    MediaQuery.of(context).platformBrightness == Brightness.dark;

Color getButtonBackgroundColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) {
        if (getIsDarkMode(context)) {
          return data.colorScheme.primary.withOpacity(.2);
        } else {
          return Colors.white;
        }
      },
      cupertino: (data) => data.primaryColor,
    );

Color getButtonTextColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.colorScheme.primary,
      cupertino: (data) => data.primaryContrastingColor,
    );

TextStyle getTitleTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.headlineLarge!,
      cupertino: (data) => data.textTheme.navLargeTitleTextStyle,
    );

TextStyle getTitle2TextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.headlineSmall!,
      cupertino: (data) => data.textTheme.navTitleTextStyle,
    );

TextStyle getSubTitleTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.titleMedium!,
      cupertino: (data) => data.textTheme.navTitleTextStyle,
    );

TextStyle getCaptionTextStyle(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodySmall!,
      cupertino: (data) => data.textTheme.tabLabelTextStyle,
    );

Color getSheetColor(final BuildContext context) {
  final settings = context.read<SettingsService>();

  if (settings.isMIUI() && settings.getAndroidTheme() == AndroidTheme.miui) {
    return MIUI_DIALOG_COLOR;
  }

  return platformThemeData(
    context,
    material: (data) => getIsDarkMode(context)
        ? HSLColor.fromColor(data.scaffoldBackgroundColor.withAlpha(255))
            .withLightness(.18)
            .toColor()
        : data.scaffoldBackgroundColor,
    cupertino: (data) => data.barBackgroundColor.withOpacity(1),
  );
}

double getIconSizeForBodyText(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.bodyLarge!.fontSize ?? 16,
      cupertino: (data) => data.textTheme.textStyle.fontSize ?? 16,
    );

double getActionButtonSize(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.textTheme.titleLarge!.fontSize ?? 16,
      cupertino: (data) => data.textTheme.actionTextStyle.fontSize ?? 16,
    );

Map<int, Color> getPrimaryColorShades(final BuildContext context) {
  final settings = context.read<SettingsService>();
  final primaryColor = settings.getPrimaryColor(context);

  final colorShades = Map.fromEntries(
    List.generate(
      9,
      (index) => MapEntry(
        (index + 1) * 100,
        HSLColor.fromColor(primaryColor)
            .withLightness(1 - (index / 10))
            .toColor(),
      ),
    ),
  );

  return {
    ...colorShades,
    0: primaryColor,
  };
}

EdgeInsets getSmallButtonPadding(final BuildContext context) =>
    platformThemeData(
      context,
      material: (data) => const EdgeInsets.symmetric(
        horizontal: MEDIUM_SPACE,
        vertical: SMALL_SPACE,
      ),
      cupertino: (data) => const EdgeInsets.symmetric(
        horizontal: SMALL_SPACE,
        vertical: TINY_SPACE,
      ),
    );

List<Widget> createCancellableDialogActions(
  final BuildContext context,
  final Iterable<Widget> actions,
) {
  final l10n = AppLocalizations.of(context);

  final cancelWidget = PlatformDialogAction(
    child: Text(l10n.cancelLabel),
    material: (_, __) => MaterialDialogActionData(
      icon: const Icon(Icons.cancel_outlined),
    ),
    onPressed: () => Navigator.of(context).pop(""),
  );

  if (isCupertino(context) && actions.length > 1) {
    return [
      ...actions,
      cancelWidget,
    ];
  }

  return [
    cancelWidget,
    ...actions,
  ];
}

Color getHighlightColor(final BuildContext context) => platformThemeData(
      context,
      material: (data) => data.primaryColorLight.withOpacity(.8),
      cupertino: (_) => CupertinoColors.systemYellow,
    );

Duration getTransitionDuration(final BuildContext context) =>
    NativePageRoute(context: context, builder: (_) => const SizedBox.shrink())
        .transitionDuration;

Color getCupertinoAppBarColorForMapScreen(final BuildContext context) =>
    CupertinoTheme.of(context).barBackgroundColor.withOpacity(.5);
