import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/app_update_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ShowUpdateDialog extends StatefulWidget {
  const ShowUpdateDialog({super.key});

  @override
  State<ShowUpdateDialog> createState() => _ShowUpdateDialogState();
}

class _ShowUpdateDialogState extends State<ShowUpdateDialog> {
  late final AppUpdateService _appUpdateService;

  @override
  void initState() {
    super.initState();

    _appUpdateService = context.read<AppUpdateService>();
  }

  void _showDialogIfRequired() async {
    final l10n = AppLocalizations.of(context);

    if (_appUpdateService.shouldShowDialogue() &&
        !_appUpdateService.hasShownDialogue &&
        mounted) {
      await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        material: MaterialDialogData(
          barrierColor: Colors.black,
        ),
        builder: (context) => PlatformAlertDialog(
          title: Text(l10n.updateAvailable_android_title),
          content: Text(l10n.updateAvailable_android_description),
          actions: [
            PlatformDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              material: (context, _) => MaterialDialogActionData(
                  icon: const Icon(Icons.watch_later_rounded)),
              child: Text(l10n.updateAvailable_android_remindLater),
            ),
            PlatformDialogAction(
              onPressed: () {
                _appUpdateService.doNotShowDialogueAgain();

                Navigator.of(context).pop();
              },
              material: (context, _) =>
                  MaterialDialogActionData(icon: const Icon(Icons.block)),
              child: Text(l10n.updateAvailable_android_ignore),
            ),
            PlatformDialogAction(
              onPressed: _appUpdateService.openStoreForUpdate,
              material: (context, _) =>
                  MaterialDialogActionData(icon: const Icon(Icons.download)),
              child: Text(l10n.updateAvailable_android_download),
            ),
          ],
        ),
      );

      _appUpdateService.setHasShownDialogue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
