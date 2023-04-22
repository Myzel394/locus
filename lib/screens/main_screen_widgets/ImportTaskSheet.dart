import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/main_screen_widgets/URLImporter.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:openpgp/openpgp.dart';
import 'package:provider/provider.dart';

import '../../widgets/ModalSheet.dart';

enum ImportScreen {
  ask,
  url,
  fetching,
  present,
  error,
  done,
}

class ImportTaskSheet extends StatefulWidget {
  const ImportTaskSheet({Key? key}) : super(key: key);

  @override
  State<ImportTaskSheet> createState() => _ImportTaskSheetState();
}

class _ImportTaskSheetState extends State<ImportTaskSheet> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late final AnimationController _lottieController;
  ImportScreen _screen = ImportScreen.ask;
  TaskView? _taskView;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this)
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          await Future.delayed(const Duration(seconds: 3));

          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _lottieController.dispose();

    super.dispose();
  }

  Future<String> getFingerprintFromKey(final String key) async {
    final metadata = await OpenPGP.getPublicKeyMetadata(key);

    return metadata.fingerprint;
  }

  Future<String?> validateTaskView(final TaskView view) async {
    final taskService = context.read<TaskService>();

    if (view.relays.isEmpty) {
      return "No relays are present in the task.";
    }

    try {
      await OpenPGP.getPublicKeyMetadata(view.signPublicKey);
      await OpenPGP.getPrivateKeyMetadata(view.viewPrivateKey);
    } catch (error) {
      return "Invalid keys provided.";
    }

    final sameTask = taskService.tasks.firstWhereOrNull((element) =>
        element.signPGPPublicKey == view.signPublicKey ||
        element.nostrPublicKey == view.nostrPublicKey ||
        element.viewPGPPrivateKey == view.viewPrivateKey);

    if (sameTask != null) {
      return "This is a task from you (name: ${sameTask.name}).";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ModalSheet(
          child: Column(
            children: <Widget>[
              Text(
                "Import a task",
                style: getSubTitleTextStyle(context),
              ),
              const SizedBox(height: LARGE_SPACE),
              if (_screen == ImportScreen.ask)
                Column(
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
                              setState(() {
                                errorMessage = null;
                                _screen = ImportScreen.url;
                              });
                            },
                            material: (_, __) => MaterialElevatedButtonData(
                              icon: const Icon(Icons.link_rounded),
                            ),
                            child: Text("Import URL"),
                          ),
                        ),
                        const SizedBox(width: MEDIUM_SPACE),
                        Expanded(
                          child: PlatformElevatedButton(
                            padding: const EdgeInsets.all(MEDIUM_SPACE),
                            material: (_, __) => MaterialElevatedButtonData(
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

                                  final errorMessage = await validateTaskView(taskView);

                                  if (errorMessage != null) {
                                    setState(() {
                                      this.errorMessage = errorMessage;
                                      _screen = ImportScreen.error;
                                    });
                                    return;
                                  } else {
                                    setState(() {
                                      this.errorMessage = null;
                                      _screen = ImportScreen.present;
                                      _taskView = taskView;
                                    });
                                  }
                                }
                              } catch (_) {
                                setState(() {
                                  errorMessage = "This does not seem to be a valid viewkey file.";
                                });
                              }
                            },
                            child: Text("Import file"),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else if (_screen == ImportScreen.url || _screen == ImportScreen.fetching)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Enter the URL of your task",
                      style: getBodyTextTextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    URLImporter(
                      controller: _urlController,
                      enabled: _screen == ImportScreen.url,
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    if (_screen == ImportScreen.fetching) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: MEDIUM_SPACE),
                    ],
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: getBodyTextTextStyle(context).copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: MEDIUM_SPACE),
                    ],
                    PlatformElevatedButton(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      onPressed: _screen == ImportScreen.url
                          ? () async {
                              try {
                                setState(() {
                                  _screen = ImportScreen.fetching;
                                  this.errorMessage = null;
                                });

                                final parameters = TaskView.parseLink(_urlController.text);
                                final taskView = await TaskView.fetchFromNostr(parameters);
                                final errorMessage = await validateTaskView(taskView);

                                if (errorMessage != null) {
                                  setState(() {
                                    this.errorMessage = errorMessage;
                                    _screen = ImportScreen.error;
                                  });
                                  return;
                                } else {
                                  setState(() {
                                    _screen = ImportScreen.present;
                                    _taskView = taskView;
                                  });
                                }
                              } catch (_) {
                                setState(() {
                                  errorMessage = "An error occurred while importing the task";
                                  _screen = ImportScreen.url;
                                });

                                final scaffold = ScaffoldMessenger.of(context);

                                scaffold.showSnackBar(
                                  SnackBar(
                                    content: Text("An error occurred while importing the task"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                      material: (_, __) => MaterialElevatedButtonData(
                        icon: const Icon(Icons.link_rounded),
                      ),
                      child: Text("Import URL"),
                    ),
                  ],
                )
              else if (_screen == ImportScreen.present)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Do you want to import this task?",
                      style: getBodyTextTextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        ListTile(
                          title: Text(_taskView!.relays.join(", ")),
                          subtitle: const Text("Relays"),
                          leading: const Icon(Icons.dns_rounded),
                        ),
                        ListTile(
                          title: Text(_taskView!.nostrPublicKey),
                          subtitle: const Text("Public Nostr Key"),
                          leading: const Icon(Icons.key),
                        ),
                        ListTile(
                          title: FutureBuilder<String>(
                              future: getFingerprintFromKey(_taskView!.signPublicKey),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(snapshot.data!);
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                              }),
                          subtitle: const Text("Public Sign Key"),
                          leading: const Icon(Icons.edit),
                        )
                      ],
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    PlatformElevatedButton(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      onPressed: () {
                        setState(() {
                          _screen = ImportScreen.done;
                        });
                      },
                      material: (_, __) => MaterialElevatedButtonData(
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                      child: Text("Import"),
                    ),
                  ],
                )
              else if (_screen == ImportScreen.done)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Lottie.asset(
                      "assets/lotties/success.json",
                      frameRate: FrameRate.max,
                      controller: _lottieController,
                      onLoaded: (composition) {
                        _lottieController
                          ..duration = composition.duration
                          ..forward();
                      },
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(
                      "Task imported successfully!",
                      textAlign: TextAlign.center,
                      style: getSubTitleTextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    PlatformElevatedButton(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      onPressed: () {
                        Navigator.of(context).pop(_taskView);
                      },
                      material: (_, __) => MaterialElevatedButtonData(
                        icon: const Icon(Icons.check_rounded),
                      ),
                      child: Text("Done"),
                    ),
                  ],
                )
              else if (_screen == ImportScreen.error)
                Column(
                  children: <Widget>[
                    Icon(context.platformIcons.error, size: 64, color: Colors.red),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(
                      "An error occurred while importing the task",
                      style: getSubTitleTextStyle(context),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    Text(
                      errorMessage!,
                      style: getBodyTextTextStyle(context).copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: LARGE_SPACE),
                    PlatformElevatedButton(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                          _screen = ImportScreen.ask;
                        });
                      },
                      material: (_, __) => MaterialElevatedButtonData(
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      child: Text("Go back"),
                    ),
                  ],
                ),
              const SizedBox(height: LARGE_SPACE),
            ],
          ),
        ),
      ],
    );
  }
}
