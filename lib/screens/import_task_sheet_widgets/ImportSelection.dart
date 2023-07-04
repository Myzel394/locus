import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:locus/widgets/SettingsCaretIcon.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';
import '../../widgets/ModalSheetContent.dart';

enum ImportSelectionType {
  url,
  file,
  bluetooth,
}

class ImportSelection extends StatefulWidget {
  final void Function(ImportSelectionType) onSelect;

  const ImportSelection({
    required this.onSelect,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportSelection> createState() => _ImportSelectionState();
}

class _ImportSelectionState extends State<ImportSelection> {
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheetContent(
      icon: Icons.file_download_rounded,
      title: l10n.sharesOverviewScreen_importTask_title,
      description: l10n.sharesOverviewScreen_importTask_description,
      children: [
        if (errorMessage != null) ...[
          Text(
            errorMessage!,
            style: getBodyTextTextStyle(context)
                .copyWith(color: getErrorColor(context)),
          ),
          const SizedBox(height: MEDIUM_SPACE),
        ],
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              PlatformListTile(
                title: Text(
                  l10n.sharesOverviewScreen_importTask_action_importMethod_url,
                ),
                leading: PlatformFlavorWidget(
                  material: (_, __) => const Icon(Icons.link_rounded),
                  cupertino: (_, __) => const Icon(CupertinoIcons.link),
                ),
                trailing: PlatformFlavorWidget(
                  material: (_, __) => const Icon(Icons.chevron_right_rounded),
                  cupertino: (_, __) =>
                      const Icon(CupertinoIcons.right_chevron),
                ),
                onTap: () {
                  widget.onSelect(ImportSelectionType.url);
                },
              ),
              PlatformListTile(
                title: Text(
                  l10n.sharesOverviewScreen_importTask_action_importMethod_file,
                ),
                leading: PlatformFlavorWidget(
                  material: (_, __) => const Icon(Icons.file_open_rounded),
                  cupertino: (_, __) => const Icon(CupertinoIcons.doc),
                ),
                trailing: PlatformFlavorWidget(
                  material: (_, __) => const Icon(Icons.chevron_right_rounded),
                  cupertino: (_, __) =>
                      const Icon(CupertinoIcons.right_chevron),
                ),
                onTap: () {
                  widget.onSelect(ImportSelectionType.file);
                },
              ),
              if (Platform.isAndroid && isGMSFlavor)
                PlatformListTile(
                  title: Text(
                    l10n.sharesOverviewScreen_importTask_action_importMethod_bluetooth,
                  ),
                  leading: const Icon(Icons.bluetooth_audio_rounded),
                  trailing: PlatformFlavorWidget(
                    material: (_, __) =>
                        const Icon(Icons.chevron_right_rounded),
                    cupertino: (_, __) =>
                        const Icon(CupertinoIcons.right_chevron),
                  ),
                  onTap: () {
                    widget.onSelect(ImportSelectionType.bluetooth);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
