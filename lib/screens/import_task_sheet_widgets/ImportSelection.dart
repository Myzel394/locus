import 'dart:convert';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/view_service.dart';
import 'package:provider/provider.dart';

import '../../constants/spacing.dart';
import '../../services/task_service.dart';
import '../../utils/theme.dart';

class ImportSelection extends StatefulWidget {
  final void Function() onGoToURL;
  final void Function(TaskView) onTaskImported;
  final void Function(String) onTaskError;

  const ImportSelection({
    required this.onGoToURL,
    required this.onTaskImported,
    required this.onTaskError,
    Key? key,}) : super(key: key);

  @override
  State<ImportSelection> createState() => _ImportSelectionState();
}

class _ImportSelectionState extends State<ImportSelection> {
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final taskService = context.read<TaskService>();
    final viewService = context.read<ViewService>();

    return Column(
      children: <Widget>[
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
        Row(
          children: <Widget>[
            Expanded(
              child: PlatformElevatedButton(
                padding: const EdgeInsets.all(MEDIUM_SPACE),
                onPressed: () {
                  widget.onGoToURL();
                },
                material: (_, __) =>
                    MaterialElevatedButtonData(
                      icon: const Icon(Icons.link_rounded),
                    ),
                child: const Text("Import URL"),
              ),
            ),
            const SizedBox(width: MEDIUM_SPACE),
            Expanded(
              child: PlatformElevatedButton(
                padding: const EdgeInsets.all(MEDIUM_SPACE),
                material: (_, __) =>
                    MaterialElevatedButtonData(
                      icon: const Icon(Icons.file_open_rounded),
                    ),
                onPressed: () async {
                  FilePickerResult? result;

                  setState(() {
                    errorMessage = null;
                  });

                  try {
                    result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ["json"],
                      dialogTitle: "Select a viewkey file",
                      withData: true,
                    );
                  } catch (_) {
                    setState(() {
                      errorMessage = "An error occurred while importing the task.";
                    });
                  }

                  try {
                    if (result != null) {
                      final rawData = const Utf8Decoder().convert(result.files[0].bytes!);
                      final data = jsonDecode(rawData);

                      final taskView = TaskView(
                        relays: List<String>.from(data["relays"]),
                        nostrPublicKey: data["nostrPublicKey"],
                        signPublicKey: data["signPublicKey"],
                        viewPrivateKey: data["viewPrivateKey"],
                      );

                      final errorMessage = await taskView.validate(
                        taskService: taskService,
                        viewService: viewService,
                      );

                      if (errorMessage != null) {
                        widget.onTaskError(errorMessage);
                        return;
                      } else {
                        widget.onTaskImported(taskView);
                      }
                    }
                  } catch (_) {
                    setState(() {
                      errorMessage = "This does not seem to be a valid viewkey file.";
                    });
                  }
                },
                child: const Text("Import file"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
