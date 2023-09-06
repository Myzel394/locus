import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/screens/task_detail_screen_widgets/SendViewByBluetooth.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/widgets/SingularElementDialog.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/file.dart';
import '../../utils/theme.dart';

class ShareLocationButton extends StatefulWidget {
  final Task task;

  const ShareLocationButton({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<ShareLocationButton> createState() => _ShareLocationButtonState();
}

class _ShareLocationButtonState extends State<ShareLocationButton> {
  bool isLoading = false;

  Future<File> _createTempViewKeyFile() async {
    return createTempFile(
      const Utf8Encoder()
          .convert(await widget.task.cryptography.generateViewKeyContent()),
      name: "viewkey.locus.json",
    );
  }

  void openShareLocationDialog() async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsService>();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Share Location",
      "Showing selection dialog.",
    );

    final shouldShare = await showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text(l10n.shareLocation_title),
        content: Text(l10n.shareLocation_description),
        material: (_, __) => MaterialAlertDialogData(
          icon: const Icon(Icons.share_location_rounded),
        ),
        actions: createCancellableDialogActions(context, [
          PlatformDialogAction(
            child: Text(l10n.shareLocation_actions_createQRCode),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.qr_code),
            ),
            onPressed: () => Navigator.of(context).pop("qr"),
          ),
          PlatformDialogAction(
            child: Text(l10n.shareLocation_actions_shareFile),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.share_rounded),
            ),
            onPressed: () => Navigator.of(context).pop("share"),
          ),
          if (Platform.isAndroid && isGMSFlavor)
            PlatformDialogAction(
              material: (_, __) => MaterialDialogActionData(
                icon: const Icon(Icons.bluetooth_audio_rounded),
              ),
              onPressed: () => Navigator.of(context).pop("bluetooth"),
              child: Text(l10n.shareLocation_actions_shareBluetooth),
            ),
          PlatformDialogAction(
            child: Text(l10n.shareLocation_actions_shareLink),
            cupertino: (_, __) => CupertinoDialogActionData(
              isDefaultAction: true,
            ),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.link_rounded),
            ),
            onPressed: () => Navigator.of(context).pop("link"),
          ),
        ]),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    FlutterLogs.logInfo(
      LOG_TAG,
      "Share Location",
      "Selected value=$shouldShare.",
    );

    try {
      switch (shouldShare) {
        case "qr":
          final url = await widget.task.publisher
              .generateLink(settings.getServerHost());

          if (!mounted) {
            return;
          }

          await showSingularElementDialog(
            context: context,
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.from(
                [
                  Text(
                    l10n.shareLocation_scanToImport(widget.task.name),
                    style: getTitle2TextStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  isMaterial(context)
                      ? const SizedBox(height: LARGE_SPACE)
                      : null,
                  QrImageView(
                    data: url,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    gapless: false,
                    backgroundColor: Colors.white,
                  ),
                ].where((element) => element != null),
              ),
            ),
          );
          break;
        case "share":
          final file = XFile((await _createTempViewKeyFile()).path);

          await Share.shareXFiles(
            [file],
            text: "Locus view key",
            subject: l10n.shareLocation_actions_shareFile_text,
          );
          break;
        case "link":
          final url = await widget.task.publisher
              .generateLink(settings.getServerHost());

          await Share.share(
            url,
            subject: l10n.shareLocation_actions_shareLink_text,
          );
          break;
        case "bluetooth":
          final data = await widget.task.cryptography.generateViewKeyContent();

          if (mounted) {
            await showPlatformModalSheet(
              context: context,
              material: MaterialModalSheetData(
                isScrollControlled: true,
                isDismissible: true,
                backgroundColor: Colors.transparent,
              ),
              builder: (_) => SendViewByBluetooth(
                data: data,
              ),
            );
          }
          break;
      }
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Share Location",
        "Error while sharing location: $error",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isCupertino(context)) {
      return CupertinoButton(
        onPressed: isLoading ? null : openShareLocationDialog,
        child: Text(l10n.shareLocation_title),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MEDIUM_SPACE),
          ),
        ),
        onPressed: isLoading ? null : openShareLocationDialog,
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Column(
            children: [
              const Icon(Icons.share_location_rounded, size: 42),
              const SizedBox(height: MEDIUM_SPACE),
              Text(l10n.shareLocation_title),
            ],
          ),
        ),
      );
    }
  }
}
