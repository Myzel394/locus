import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/utils/theme.dart';
import 'package:shimmer/shimmer.dart';


enum HintType {
  quickActions,
  defaultRelays,
  appColor,
}

const storage = FlutterSecureStorage();

Future<HintType?> getHintTypeForMainScreen() async {
  // Only show hints 10% of the time
  if (Random().nextInt(10) != 0) {
    return null;
  }

  const hintTypes = HintType.values;
  final hintType = hintTypes[Random().nextInt(hintTypes.length)];

  if (await checkIfHintIsHidden(hintType)) {
    return null;
  }

  return hintType;
}

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

String _getHintKey(final HintType hintType) => "hint_type_was_shown_${hintType.name}";

Future<bool> checkIfHintIsHidden(final HintType hintType) => storage.containsKey(key: _getHintKey(hintType));

Future<void> markHintAsHidden(final HintType hintType, final bool hidden) async {
  if (hidden) {
    await storage.write(key: _getHintKey(hintType), value: "true");
  } else {
    await storage.delete(key: _getHintKey(hintType));
  }
}

void Function(BuildContext context)? getTutorialCallback(final HintType hintType) {
  switch (hintType) {
    case HintType.defaultRelays:
    case HintType.appColor:
      return showSettings;
    default:
      return null;
  }
}

class AppHint extends StatelessWidget {
  final HintType hintType;
  final VoidCallback? onDismiss;

  const AppHint({
    required this.hintType,
    this.onDismiss,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);
    final callback = getTutorialCallback(hintType);

    return Shimmer.fromColors(
      baseColor: shades[0]!,
      highlightColor: Colors.white,
      period: const Duration(seconds: 4),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: .1,
              child: Icon(
                HINT_TYPE_ICON_MAP_MATERIAL[hintType],
                color: Theme.of(context).colorScheme.secondary,
                size: 180,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            decoration: BoxDecoration(
              color: HSLColor.fromColor(shades[0]!).withSaturation(1).toColor().withOpacity(.1),
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
                  size: 60,
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
                            material: (_, __) => MaterialTextButtonData(
                              icon: const Icon(Icons.cancel),
                            ),
                            onPressed: () {
                              onDismiss?.call();
                              markHintAsHidden(hintType, true);
                            },
                          ),
                          callback == null
                              ? const SizedBox.shrink()
                              : PlatformTextButton(
                                  child: Text(l10n.appHint_showMeLabel),
                                  material: (_, __) => MaterialTextButtonData(
                                    icon: const Icon(Icons.arrow_circle_right_rounded),
                                  ),
                                  onPressed: () {
                                    callback(context);
                                    markHintAsHidden(hintType, true);
                                  },
                                ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
