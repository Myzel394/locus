import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/constants/app.dart';
import 'package:locus/screens/welcome_screen_widgets/TransferReceiverScreen.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';
import '../../widgets/ModalSheet.dart';
import '../../widgets/PlatformListTile.dart';

class ImportSheet extends StatefulWidget {
  final void Function(
      TaskService taskService,
      ViewService viewService,
      SettingsService settings,
      ) onImport;

  const ImportSheet({
    required this.onImport,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<ImportSheet> {
  String errorMessage = "";

  void importRawData(final String rawData) async {
    final l10n = AppLocalizations.of(context);

    final shouldImport = await showPlatformDialog(
      context: context,
      builder: (context) =>
          PlatformAlertDialog(
            material: (context, __) =>
                MaterialAlertDialogData(
                  icon: PlatformFlavorWidget(
                    material: (context, _) => const Icon(Icons.warning_rounded),
                    cupertino: (context, _) =>
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill),
                  ),
                ),
            title: Text(l10n.settingsScreen_import_confirmation_title),
            content: Text(l10n.settingsScreen_import_confirmation_description),
            actions: createCancellableDialogActions(
              context,
              [
                PlatformDialogAction(
                  material: (context, _) =>
                      MaterialDialogActionData(
                        icon: const Icon(Icons.download_rounded),
                      ),
                  child: Text(l10n.settingsScreen_import_confirmation_confirm),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
    );

    if (shouldImport != true || !mounted) {
      return;
    }

    try {
      final data = jsonDecode(rawData);
      final tasks = TaskService(
        tasks: List<Task>.from(
          data["data"]["tasks"].map((task) => Task.fromJSON(task)),
        ).toList(),
      );
      final views = ViewService(
        views: List<TaskView>.from(
          data["data"]["views"].map((view) => TaskView.fromJSON(view)),
        ).toList(),
      );
      final settings = SettingsService.fromJSON(data["data"]["settings"]);

      widget.onImport(tasks, views, settings);
    } catch (_) {
      setState(() {
        errorMessage = l10n.unknownError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.settingsScreen_settings_importExport_importLabel,
            style: getTitle2TextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          if (errorMessage.isNotEmpty) ...[
            Text(
              errorMessage,
              style: TextStyle(
                color: getErrorColor(context),
              ),
            ),
            const SizedBox(height: MEDIUM_SPACE),
          ],
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              PlatformListTile(
                leading: const Icon(Icons.file_download),
                title: Text(l10n.settingsScreen_import_file),
                onTap: () async {
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ["json"],
                      dialogTitle: l10n.settingsScreen_import_pickerTitle,
                      withData: true,
                    );

                    if (result == null || result.files.isEmpty) {
                      return;
                    }

                    final content = String.fromCharCodes(
                        List<int>.from(result.files[0].bytes!));

                    importRawData(content);
                  } catch (_) {
                    setState(() {
                      errorMessage = l10n.unknownError;
                    });
                  }
                },
              ),
              Platform.isAndroid && isGMSFlavor
                  ? PlatformListTile(
                leading: PlatformWidget(
                  material: (_, __) =>
                  const Icon(Icons.phonelink_setup_rounded),
                  cupertino: (_, __) =>
                  const Icon(CupertinoIcons.device_phone_portrait),
                ),
                title: Text(l10n.settingsScreen_import_transfer),
                onTap: () {
                  Navigator.push(
                    context,
                    NativePageRoute(
                      context: context,
                      builder: (context) =>
                          TransferReceiverScreen(
                              onContentReceived: importRawData),
                    ),
                  );
                },
              )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
