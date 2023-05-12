import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum HintType {
  quickActions,
  defaultRelays,
  appColor,
}

const storage = FlutterSecureStorage();

final Map<HintType, IconData> HINT_TYPE_ICON_MAP_MATERIAL = {
  HintType.quickActions: Icons.grid_view_rounded,
  HintType.defaultRelays: Icons.dns_rounded,
  HintType.appColor: Icons.color_lens_rounded,
};
final Map<HintType, IconData> HINT_TYPE_ICON_MAP_CUPERTINO = {
  HintType.quickActions: CupertinoIcons.circle_grid_3x3_fill,
  HintType.defaultRelays: Icons.dns_rounded,
  HintType.appColor: CupertinoIcons.color_filter,
};

Map<HintType, String> getHintTypeTitleMap(final BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return {
    HintType.quickActions: l10n.appHint_quickActions_title,
    HintType.defaultRelays: l10n.appHint_defaultRelays_title,
    HintType.appColor: l10n.appHint_appColor_title,
  };
}

Map<HintType, String> getHintDescriptionMap(final BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return {
    HintType.quickActions: l10n.appHint_quickActions_description,
    HintType.defaultRelays: l10n.appHint_defaultRelays_description,
    HintType.appColor: l10n.appHint_appColor_description,
  };
}

String _getHintKey(final HintType hintType) =>
    "hint_type_was_shown_${hintType.name}";

Future<bool> checkIfHintIsHidden(final HintType hintType) =>
    storage.containsKey(key: _getHintKey(hintType));

Future<void> markHintAsHidden(
    final HintType hintType, final bool hidden) async {
  if (hidden) {
    await storage.write(key: _getHintKey(hintType), value: "true");
  } else {
    await storage.delete(key: _getHintKey(hintType));
  }
}

class AppHint extends StatelessWidget {
  final HintType hintType;

  const AppHint({
    required this.hintType,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Container(
      padding: const EdgeInsets.all(MEDIUM_SPACE),
      decoration: BoxDecoration(
        color: HSLColor.fromColor(shades[0]!)
            .withSaturation(1)
            .toColor()
            .withOpacity(.1),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            HINT_TYPE_ICON_MAP_MATERIAL[hintType],
            color: Theme.of(context).colorScheme.secondary,
            size: 30,
          ),
          const SizedBox(width: MEDIUM_SPACE),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  getHintTypeTitleMap(context)[hintType]!,
                  style: getSubTitleTextStyle(context).copyWith(
                    color: shades[0],
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: SMALL_SPACE),
                Text(
                  getHintDescriptionMap(context)[hintType]!,
                  style: getBodyTextTextStyle(context).copyWith(
                    color: shades[0],
                  ),
                ),
                Row(
                  children: <Widget>[
                    PlatformTextButton(
                      child: Text(l10n.dismissLabel),
                      onPressed: () => markHintAsHidden(hintType, true),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
