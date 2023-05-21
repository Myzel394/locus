import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

enum ImportSelectionType {
  url,
  file,
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

    return Column(
      children: <Widget>[
        Text(
          l10n.mainScreen_importTask_title,
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: LARGE_SPACE),
        Text(
          l10n.mainScreen_importTask_description,
          style: getBodyTextTextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
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
              child: Text(l10n.mainScreen_importTask_action_importMethod_url),
            ),
            PlatformElevatedButton(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.file_open_rounded),
              ),
              onPressed: () async {
                widget.onSelect(ImportSelectionType.file);
              },
              child: Text(l10n.mainScreen_importTask_action_importMethod_file),
            ),
          ],
        ),
      ],
    );
  }
}
