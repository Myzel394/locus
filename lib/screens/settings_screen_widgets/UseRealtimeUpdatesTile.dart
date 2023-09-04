import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UseRealtimeUpdatesTile extends AbstractSettingsTile {
  const UseRealtimeUpdatesTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();

    return SettingsTile.switchTile(
      initialValue: settings.useRealtimeUpdates,
      onToggle: (newValue) async {
        if (!newValue) {
          final confirm = await showPlatformDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => PlatformAlertDialog(
              title: Text(
                  l10n.settingsScreen_settings_useRealtimeUpdates_dialog_title),
              material: (_, __) => MaterialAlertDialogData(
                icon: settings.isMIUI()
                    ? const Icon(CupertinoIcons.exclamationmark_triangle_fill)
                    : const Icon(Icons.warning_rounded),
              ),
              content: Text(
                l10n.settingsScreen_settings_useRealtimeUpdates_dialog_message,
              ),
              actions: createCancellableDialogActions(
                context,
                [
                  PlatformDialogAction(
                    child: Text(l10n
                        .settingsScreen_settings_useRealtimeUpdates_dialog_confirm),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  )
                ],
              ),
            ),
          );

          if (!context.mounted || confirm != true) {
            return;
          }
        }

        settings.setUseRealtimeUpdates(newValue);
        settings.save();
      },
      title: Text(
        l10n.settingsScreen_settings_useRealtimeUpdates_label,
      ),
      description: Text(
        l10n.settingsScreen_settings_useRealtimeUpdates_description,
      ),
    );
  }
}
