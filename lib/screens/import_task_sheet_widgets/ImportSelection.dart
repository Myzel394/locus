import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/view_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../constants/spacing.dart';
import '../../services/task_service.dart';
import '../../utils/theme.dart';

enum ImportSelectionType {
  url,
  file,
  qr,
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
    return Column(
      children: <Widget>[
        Text(
          "Import a task",
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: LARGE_SPACE),
        Text(
          "How would you like to import?",
          style: getBodyTextTextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        if (errorMessage != null) ...[
          Text(
            errorMessage!,
            style: getBodyTextTextStyle(context).copyWith(color: Colors.red),
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
              child: const Text("Import URL"),
            ),
            PlatformElevatedButton(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.file_open_rounded),
              ),
              onPressed: () async {
                widget.onSelect(ImportSelectionType.file);
              },
              child: const Text("Import file"),
            ),
            PlatformElevatedButton(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
              onPressed: () {
                widget.onSelect(ImportSelectionType.qr);
              },
              child: Text("Scan QR code"),
            ),
          ],
        ),
      ],
    );
  }
}
