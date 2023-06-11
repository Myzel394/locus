import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/screens/import_task_sheet_widgets/ImportSelection.dart';
import 'package:locus/screens/import_task_sheet_widgets/ImportSuccess.dart';
import 'package:locus/screens/import_task_sheet_widgets/NameForm.dart';
import 'package:locus/screens/import_task_sheet_widgets/URLForm.dart';
import 'package:locus/screens/import_task_sheet_widgets/ViewImportOverview.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../services/task_service.dart';
import '../widgets/ModalSheet.dart';
import 'import_task_sheet_widgets/ReceiveViewByBluetooth.dart';

enum ImportScreen {
  ask,
  importFile,
  askURL,
  askName,
  bluetoothReceive,
  present,
  error,
  done,
}

class ImportTaskSheet extends StatefulWidget {
  final ImportScreen? initialScreen;

  // If set, `initialScreen` will be ignored and the URL will be imported
  final String? initialURL;

  const ImportTaskSheet({
    this.initialScreen = ImportScreen.ask,
    this.initialURL,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportTaskSheet> createState() => _ImportTaskSheetState();
}

class _ImportTaskSheetState extends State<ImportTaskSheet> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  ImportScreen _screen = ImportScreen.ask;
  String? errorMessage;
  TaskView? _taskView;
  bool isLoading = false;

  void reset() {
    if (isCupertino(context)) {
      // Action sheet has been shown, so no `ask` screen was shown
      // Instead, we pop the sheet so that the user can see the ActionSheet
      // again if they want to
      Navigator.of(context).pop();
      return;
    }

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
  void initState() {
    super.initState();

    if (widget.initialScreen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialScreen == ImportScreen.importFile) {
          _importFile();
        } else if (widget.initialURL != null) {
          _urlController.text = widget.initialURL!;
          _importURL();
        } else {
          setState(() {
            _screen = widget.initialScreen!;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();

    super.dispose();
  }

  void parseViewData(final TaskView taskView) async {
    final l10n = AppLocalizations.of(context);
    final taskService = context.read<TaskService>();
    final viewService = context.read<ViewService>();

    try {
      final errorMessage = await taskView.validate(
        l10n,
        taskService: taskService,
        viewService: viewService,
      );

      if (errorMessage != null) {
        setState(() {
          this.errorMessage = errorMessage;
          _screen = ImportScreen.error;
        });

        return;
      } else {
        setState(() {
          _taskView = taskView;
          _screen = ImportScreen.present;
        });
      }
    } catch (error) {
      FlutterLogs.logErrorTrace(
        LOG_TAG,
        "Import Task",
        "Error validating task view.",
        error as Error,
      );

      setState(() {
        errorMessage = l10n.unknownError;
        _screen = ImportScreen.error;
      });
    }
  }

  void _importFile() async {
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(
      LOG_TAG,
      "Import Task",
      "Importing task from file...",
    );

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
        dialogTitle: l10n.mainScreen_importTask_action_importMethod_file_selectFile,
        withData: true,
      );
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Import Task",
        "Error calling `.pickFiles`: $error",
      );

      setState(() {
        errorMessage = l10n.unknownError;
      });
    }

    FlutterLogs.logInfo(
      LOG_TAG,
      "Import Task",
      "File picker returned file. Parsing content...",
    );

    try {
      if (result == null) {
        reset();
      } else {
        final rawData = const Utf8Decoder().convert(result.files[0].bytes!);
        final taskView = TaskView.fromJSON(jsonDecode(rawData));

        parseViewData(taskView);
      }
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Import Task",
        "Error parsing file: $error",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _importURL() async {
    final url = _urlController.text;
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(
      LOG_TAG,
      "Import Task",
      "Importing task from URL...",
    );

    try {
      setState(() {
        isLoading = true;
        _screen = ImportScreen.askURL;
      });

      final parameters = TaskView.parseLink(url);
      final taskView = await TaskView.fetchFromNostr(l10n, parameters);

      parseViewData(taskView);
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Import Task",
        "Error fetching task from URL: $error",
      );

      setState(() {
        errorMessage = l10n.unknownError;
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
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ModalSheet(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                        case ImportSelectionType.bluetooth:
                          setState(() {
                            _screen = ImportScreen.bluetoothReceive;
                          });
                          break;
                      }
                    },
                  )
                else if (_screen == ImportScreen.askURL)
                  URLForm(
                    isFetching: isLoading,
                    controller: _urlController,
                    onImport: _importURL,
                  )
                else if (_screen == ImportScreen.askName)
                  NameForm(
                    controller: _nameController,
                    onSubmitted: () {
                      _taskView!.update(name: _nameController.text);

                      importView();
                    },
                  )
                else if (_screen == ImportScreen.importFile)
                  Column(
                    children: <Widget>[
                      Text(
                        l10n.mainScreen_importTask_action_import_isLoading,
                        style: getSubTitleTextStyle(context),
                      ),
                      const SizedBox(height: SMALL_SPACE),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: getBodyTextTextStyle(context).copyWith(color: getErrorColor(context)),
                        ),
                    ],
                  )
                else if (_screen == ImportScreen.bluetoothReceive)
                  ReceiveViewByBluetooth(
                    onImport: parseViewData,
                  )
                else if (_screen == ImportScreen.present)
                  ViewImportOverview(
                    view: _taskView!,
                    onImport: () {
                      _nameController.text = _taskView!.name;

                      setState(() {
                        _screen = ImportScreen.askName;
                      });
                    },
                  )
                else if (_screen == ImportScreen.done)
                  ImportSuccess(
                    onClose: () {
                      if (!mounted) {
                        return;
                      }

                      Navigator.of(context).pop(_taskView!);
                    },
                  )
                else if (_screen == ImportScreen.error)
                  Column(
                    children: <Widget>[
                      Icon(context.platformIcons.error, size: 64, color: getErrorColor(context)),
                      const SizedBox(height: MEDIUM_SPACE),
                      Text(
                        l10n.taskImportError,
                        style: getSubTitleTextStyle(context),
                      ),
                      const SizedBox(height: SMALL_SPACE),
                      Text(
                        errorMessage!,
                        style: getBodyTextTextStyle(context).copyWith(color: getErrorColor(context)),
                      ),
                      const SizedBox(height: LARGE_SPACE),
                      PlatformElevatedButton(
                        padding: const EdgeInsets.all(MEDIUM_SPACE),
                        onPressed: reset,
                        material: (_, __) => MaterialElevatedButtonData(
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        child: Text(l10n.goBack),
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
