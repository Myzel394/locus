import 'dart:convert';
import 'dart:io';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/task_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/file.dart';
import '../../utils/theme.dart';
import '../../widgets/ModalSheet.dart';

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

  Future<File> _createTempViewKeyFile() {
    return createTempFile(
      const Utf8Encoder().convert(widget.task.generateViewKeyContent()),
      name: "viewkey.locus.json",
    );
  }

  void openShareLocationDialog() async {
    final shouldShare = await showPlatformDialog(
      context: context,
      builder: (context) =>
          PlatformAlertDialog(
            title: Text("Share location"),
            content: Text(
              "Would you like to share your location from this task? This will allow other users to see your location. A view key file will be generated which allows anyone to view your location. Makes sure to keep this file safe and only share it with people you trust.",
            ),
            actions: createCancellableDialogActions(context, [
              PlatformDialogAction(
                child: Text("Save file"),
                material: (_, __) =>
                    MaterialDialogActionData(
                      icon: const Icon(Icons.save_alt_rounded),
                    ),
                onPressed: () => Navigator.of(context).pop("save"),
              ),
              PlatformDialogAction(
                child: Text("Create QR Code"),
                material: (_, __) =>
                    MaterialDialogActionData(
                      icon: const Icon(Icons.qr_code),
                    ),
                onPressed: () => Navigator.of(context).pop("qr"),
              ),
              PlatformDialogAction(
                child: Text("Share file"),
                material: (_, __) =>
                    MaterialDialogActionData(
                      icon: const Icon(Icons.share_rounded),
                    ),
                onPressed: () => Navigator.of(context).pop("share"),
              ),
              PlatformDialogAction(
                child: Text("Share link"),
                cupertino: (_, __) =>
                    CupertinoDialogActionData(
                      isDefaultAction: true,
                    ),
                material: (_, __) =>
                    MaterialDialogActionData(
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

    try {
      switch (shouldShare) {
        case "save":
          if (!(await Permission.storage.isGranted)) {
            await Permission.storage.request();
          }

          await FileSaver.instance.saveFile(
            name: "viewkey.json",
            bytes:
            const Utf8Encoder().convert(widget.task.generateViewKeyContent()),
          );
          break;
        case "qr":
          final url = await widget.task.generateLink();

          await showPlatformModalSheet(
            context: context,
            material: MaterialModalSheetData(
              backgroundColor: Colors.transparent,
              isDismissible: true,
            ),
            cupertino: CupertinoModalSheetData(
              barrierDismissible: true,
            ),
            builder: (context) =>
                ModalSheet(
                  child: Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            "Scan this QR Code to import task ${widget.task
                                .name}",
                            style: getTitle2TextStyle(context),
                            textAlign: TextAlign.center,
                          ),
                          QrImage(
                            data: url,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            gapless: false,
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          );

          break;
        case "share":
          final file = XFile((await _createTempViewKeyFile()).path);

          await Share.shareXFiles(
            [file],
            text: "Locus view key",
            subject: "Here's my Locus View Key to see my location",
          );
          break;
        case "link":
          final url = await widget.task.generateLink();

          await Share.share(
            url,
            subject: "Here's my Locus link to see my location",
          );
      }
    } catch (_) {} finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformElevatedButton(
      child: Text("Share location"),
      material: (_, __) =>
          MaterialElevatedButtonData(
            icon: Icon(Icons.share_location_rounded),
          ),
      onPressed: isLoading ? null : openShareLocationDialog,
    );
  }
}
