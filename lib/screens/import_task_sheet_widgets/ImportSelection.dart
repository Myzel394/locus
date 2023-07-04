import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/app.dart';

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
        Wrap(
          spacing: MEDIUM_SPACE,
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            PlatformElevatedButton(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              onPressed: () {
                widget.onSelect(ImportSelectionType.url);
              },
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.link_rounded),
              ),
              child: Text(
                  l10n.sharesOverviewScreen_importTask_action_importMethod_url),
            ),
            PlatformElevatedButton(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.file_open_rounded),
              ),
              onPressed: () async {
                widget.onSelect(ImportSelectionType.file);
              },
              child: Text(l10n
                  .sharesOverviewScreen_importTask_action_importMethod_file),
            ),
            if (Platform.isAndroid && isGMSFlavor)
              PlatformElevatedButton(
                padding: const EdgeInsets.all(MEDIUM_SPACE),
                material: (_, __) => MaterialElevatedButtonData(
                  icon: const Icon(Icons.bluetooth_audio_rounded),
                ),
                onPressed: () async {
                  widget.onSelect(ImportSelectionType.bluetooth);
                },
                child: Text(l10n
                    .sharesOverviewScreen_importTask_action_importMethod_bluetooth),
              )
          ],
        ),
      ],
    );
  }
}
