import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Future<T> showHelperSheet<T>({
  required final BuildContext context,
  required final Widget Function(BuildContext) builder,
  required final String title,
  final HelperSheet? sheetName,
}) async {
  final l10n = AppLocalizations.of(context);
  final settings = context.read<SettingsService>();
  late final T result;

  if (isCupertino(context)) {
    result = await showCupertinoModalBottomSheet(
      context: context,
      backgroundColor: getSheetColor(context),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LARGE_SPACE),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                title,
                style: getTitle2TextStyle(context),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              builder(context),
              const SizedBox(height: LARGE_SPACE),
              CupertinoButton.filled(
                child: Text(l10n.closeNeutralAction),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
      ),
    );
  } else {
    result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        icon: Icon(context.platformIcons.help),
        content: builder(context),
        actions: [
          PlatformDialogAction(
            child: Text(l10n.closeNeutralAction),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  if (sheetName != null) {
    await settings.markHelperSheetAsSeen(sheetName);
  }

  return result;
}
