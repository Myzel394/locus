import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/ShortcutScreen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ShortcutType {
  createOneHour,
  shareNow,
  stopAllTasks,
}

const actions = QuickActions();

const SHORTCUT_TYPE_ICON_MAP = {
  ShortcutType.createOneHour: Icons.timelapse_rounded,
  ShortcutType.shareNow: Icons.location_on,
  ShortcutType.stopAllTasks: Icons.stop_circle_rounded,
};

void initQuickActions(final BuildContext context) {
  final l10n = AppLocalizations.of(context);

  actions.initialize((type) async {
    if (isCupertino(context)) {
      showCupertinoModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ShortcutScreen(
          type: ShortcutType.values.firstWhere(
            (element) => element.name == type,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShortcutScreen(
            type: ShortcutType.values.firstWhere(
              (element) => element.name == type,
            ),
          ),
        ),
      );
    }
  });

  actions.setShortcutItems([
    ShortcutItem(
      type: ShortcutType.createOneHour.name,
      localizedTitle: l10n.quickActions_createOneHour,
      icon: "ic_quick_actions_create_one_hour_task",
    ),
    ShortcutItem(
      type: ShortcutType.shareNow.name,
      localizedTitle: l10n.quickActions_shareNow,
      icon: "ic_quick_actions_share_now",
    ),
    ShortcutItem(
      type: ShortcutType.stopAllTasks.name,
      localizedTitle: l10n.quickActions_stopTasks,
      icon: "ic_quick_actions_stop_all_tasks",
    ),
  ]);
}
