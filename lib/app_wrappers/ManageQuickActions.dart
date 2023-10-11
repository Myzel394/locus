import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/screens/ShortcutScreen.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';

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

class ManageQuickActions extends StatefulWidget {
  const ManageQuickActions({super.key});

  @override
  State<ManageQuickActions> createState() => _ManageQuickActionsState();
}

class _ManageQuickActionsState extends State<ManageQuickActions> {
  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();

    if (settings.userHasSeenWelcomeScreen) {
      _registerActions();
    } else {
      _removeActions();
    }
  }

  void _registerActions() {
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(
      LOG_TAG,
      "Quick Actions",
      "Initializing quick actions...",
    );

    actions.initialize((type) async {
      FlutterLogs.logInfo(
          LOG_TAG, "Quick Actions", "Quick action $type triggered.");

      if (isCupertino(context)) {
        showCupertinoModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              ShortcutScreen(
                type: ShortcutType.values.firstWhere(
                      (element) => element.name == type,
                ),
              ),
        );
      } else {
        Navigator.push(
          context,
          NativePageRoute(
            context: context,
            builder: (_) =>
                ShortcutScreen(
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

    FlutterLogs.logInfo(
      LOG_TAG,
      "Quick Actions",
      "Quick actions initialized successfully!",
    );
  }

  void _removeActions() {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Quick Actions",
      "Removing quick actions...",
    );

    actions.clearShortcutItems();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Quick Actions",
      "Quick actions removed successfully!",
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
