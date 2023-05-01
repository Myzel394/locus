import 'dart:convert';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/import_task_sheet_widgets/ImportSelection.dart';
import 'package:locus/screens/import_task_sheet_widgets/ImportSuccess.dart';
import 'package:locus/screens/import_task_sheet_widgets/NameForm.dart';
import 'package:locus/screens/import_task_sheet_widgets/ScanQRCode.dart';
import 'package:locus/screens/import_task_sheet_widgets/URLForm.dart';
import 'package:locus/screens/import_task_sheet_widgets/ViewImportOverview.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../services/task_service.dart';
import '../widgets/ModalSheet.dart';

enum ImportScreen {
  ask,
  importFile,
  askURL,
  askName,
  scanQR,
  present,
  error,
  done,
}

class ImportTaskSheet extends StatefulWidget {
  const ImportTaskSheet({Key? key}) : super(key: key);

  @override
  State<ImportTaskSheet> createState() => _ImportTaskSheetState();
}

class _ImportTaskSheetState extends State<ImportTaskSheet>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  ImportScreen _screen = ImportScreen.ask;
  String? errorMessage;
  TaskView? _taskView;
  bool isLoading = false;

  void reset() {
    _nameController.clear();
    _urlController.clear();

    setState(() {
      _screen = ImportScreen.ask;
      errorMessage = null;
      _taskView = null;
      isLoading = false;
    });
  }

  Future<void> importView() async {
    final viewService = context.read<ViewService>();

    viewService.add(_taskView!);
    await viewService.save();

    setState(() {
      _screen = ImportScreen.done;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();

    super.dispose();
  }

  void _importFile() async {
    final taskService = context.read<TaskService>();
    final viewService = context.read<ViewService>();

    FilePickerResult? result;

    setState(() {
      errorMessage = null;
      isLoading = true;
      _screen = ImportScreen.importFile;
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
          setState(() {
            this.errorMessage = errorMessage;
          });

          return;
        } else {
          setState(() {
            _taskView = taskView;
            _screen = ImportScreen.present;
          });
        }
      }
    } catch (_) {} finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _importURL() async {
    final url = _urlController.text;
    final taskService = context.read<TaskService>();
    final viewService = context.read<ViewService>();

    try {
      setState(() {
        isLoading = true;
        _screen = ImportScreen.askURL;
      });

      final parameters = TaskView.parseLink(url);
      final taskView = await TaskView.fetchFromNostr(parameters);
      final errorMessage = await taskView.validate(
        taskService: taskService,
        viewService: viewService,
      );

      if (errorMessage == null) {
        setState(() {
          _taskView = taskView;
          _screen = ImportScreen.present;
        });
      } else {
        setState(() {
          this.errorMessage = errorMessage;
          _screen = ImportScreen.error;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = "An error occurred while fetching the task.";
        _screen = ImportScreen.error;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // QR Scanner needs full width and height
        if (_screen == ImportScreen.scanQR)
          ScanQRCode(
            onAbort: reset,
            onURLDetected: (url) {
              // Detected vibration
              Vibration.vibrate(
                duration: 100,
                amplitude: 128,
              );

              _urlController.text = url;

              _importURL();
            },
          )
        else
          ModalSheet(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Column(
                children: <Widget>[
                  if (_screen == ImportScreen.ask)
                    ImportSelection(
                      onSelect: (type) {
                        switch (type) {
                          case ImportSelectionType.file:
                            _importFile();
                            break;
                          case ImportSelectionType.url:
                            setState(() {
                              _screen = ImportScreen.askURL;
                            });
                            break;
                          case ImportSelectionType.qr:
                            setState(() {
                              _screen = ImportScreen.scanQR;
                            });
                            break;
                        }
                      },
                    )
                  else
                    if (_screen == ImportScreen.askURL)
                      URLForm(
                        isFetching: isLoading,
                        controller: _urlController,
                        onImport: _importURL,
                      )
                    else
                      if (_screen == ImportScreen.askName)
                        NameForm(
                          controller: _nameController,
                          onSubmitted: () {
                            _taskView!.update(name: _nameController.text);

                            importView();
                          },
                        )
                      else
                        if (_screen == ImportScreen.importFile)
                          Column(
                            children: <Widget>[
                              Text(
                                "Importing task...",
                                style: getSubTitleTextStyle(context),
                              ),
                              const SizedBox(height: SMALL_SPACE),
                              if (isLoading)
                                const CircularProgressIndicator()
                              else
                                if (errorMessage != null)
                                  Text(
                                    errorMessage!,
                                    style: getBodyTextTextStyle(context)
                                        .copyWith(color: Colors.red),
                                  ),
                            ],
                          )
                        else
                          if (_screen == ImportScreen.present)
                            ViewImportOverview(
                              view: _taskView!,
                              onImport: () {
                                setState(() {
                                  _screen = ImportScreen.askName;
                                });
                              },
                            )
                          else
                            if (_screen == ImportScreen.done)
                              ImportSuccess(
                                onClose: () {
                                  if (!mounted) {
                                    return;
                                  }

                                  Navigator.of(context).pop(_taskView!);
                                },
                              )
                            else
                              if (_screen == ImportScreen.error)
                                Column(
                                  children: <Widget>[
                                    Icon(context.platformIcons.error,
                                        size: 64, color: Colors.red),
                                    const SizedBox(height: MEDIUM_SPACE),
                                    Text(
                                      "An error occurred while importing the task",
                                      style: getSubTitleTextStyle(context),
                                    ),
                                    const SizedBox(height: SMALL_SPACE),
                                    Text(
                                      errorMessage!,
                                      style: getBodyTextTextStyle(context)
                                          .copyWith(color: Colors.red),
                                    ),
                                    const SizedBox(height: LARGE_SPACE),
                                    PlatformElevatedButton(
                                      padding: const EdgeInsets.all(
                                          MEDIUM_SPACE),
                                      onPressed: reset,
                                      material: (_, __) =>
                                          MaterialElevatedButtonData(
                                            icon: const Icon(
                                                Icons.arrow_back_rounded),
                                          ),
                                      child: const Text("Go back"),
                                    ),
                                  ],
                                ),
                  const SizedBox(height: LARGE_SPACE),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
