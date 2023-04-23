import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/api/get-address.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/file.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/DetailInformationBox.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class Details extends StatefulWidget {
  final UnmodifiableListView<LocationPointService> locations;
  final Task task;
  final void Function() onGoBack;

  const Details({
    required this.locations,
    required this.task,
    required this.onGoBack,
    Key? key,
  }) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late final RelayController _relaysController;

  @override
  void initState() {
    super.initState();

    _relaysController = RelayController(
      relays: widget.task.relays,
    );
  }

  @override
  void dispose() {
    _relaysController.dispose();
    super.dispose();
  }

  Future<File> _createTempViewKeyFile() {
    return createTempFile(
      const Utf8Encoder().convert(widget.task.generateViewKeyContent()),
      name: "viewkey.locus.json",
    );
  }

  void openShareLocationDialog() async {
    final shouldShare = await showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text("Share location"),
        content: Text(
          "Would you like to share your location from this task? This will allow other users to see your location. A view key file will be generated which allows anyone to view your location. Makes sure to keep this file safe and only share it with people you trust.",
        ),
        actions: <Widget>[
          PlatformDialogAction(
            child: Text("Cancel"),
            cupertino: (_, __) => CupertinoDialogActionData(
              isDestructiveAction: true,
            ),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.cancel_outlined),
            ),
            onPressed: () => Navigator.of(context).pop(""),
          ),
          PlatformDialogAction(
            child: Text("Save file"),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.save_alt_rounded),
            ),
            onPressed: () => Navigator.of(context).pop("save"),
          ),
          PlatformDialogAction(
            child: Text("Share file"),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.share_rounded),
            ),
            onPressed: () => Navigator.of(context).pop("share"),
          ),
          PlatformDialogAction(
            child: Text("Share link"),
            cupertino: (_, __) => CupertinoDialogActionData(
              isDefaultAction: true,
            ),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.link_rounded),
            ),
            onPressed: () => Navigator.of(context).pop("link"),
          ),
        ],
      ),
    );

    switch (shouldShare) {
      case "save":
        if (!(await Permission.storage.isGranted)) {
          await Permission.storage.request();
        }

        await FileSaver.instance.saveFile(
          name: "viewkey.json",
          bytes: const Utf8Encoder().convert(widget.task.generateViewKeyContent()),
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
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PlatformTextButton(
          material: (_, __) => MaterialTextButtonData(
            style: ButtonStyle(
              // Not rounded, but square
              shape: MaterialStateProperty.all(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.all(MEDIUM_SPACE),
              ),
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
          child: Text("Go back"),
          onPressed: widget.onGoBack,
        ),
        Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Wrap(
            runSpacing: LARGE_SPACE,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              DetailInformationBox(
                title: "Last known location",
                child: widget.locations.isEmpty
                    ? Text("No location available")
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FutureBuilder<String>(
                            future: getAddress(
                              widget.locations.last.latitude,
                              widget.locations.last.longitude,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: snapshot.data!,
                                        style: getBodyTextTextStyle(context),
                                      ),
                                      TextSpan(
                                        text:
                                            " (${widget.locations.last.latitude}, ${widget.locations.last.longitude})",
                                        style: getCaptionTextStyle(context),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      "${widget.locations.last.latitude}, ${widget.locations.last.longitude}",
                                      style: getBodyTextTextStyle(context),
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                  const SizedBox(width: SMALL_SPACE),
                                  SizedBox.square(
                                    dimension: getIconSizeForBodyText(context),
                                    child: PlatformCircularProgressIndicator(
                                      material: (_, __) => MaterialProgressIndicatorData(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: MEDIUM_SPACE),
                          Tooltip(
                            message: "Most recent location point",
                            textAlign: TextAlign.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  context.platformIcons.time,
                                  size: getIconSizeForBodyText(context),
                                ),
                                const SizedBox(width: TINY_SPACE),
                                Text(
                                  widget.locations.last.createdAt.toString(),
                                  style: getBodyTextTextStyle(context),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              DetailInformationBox(
                title: "Location details",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "${widget.locations.length} location points saved",
                      style: getBodyTextTextStyle(context),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
              DetailInformationBox(
                title: "Nostr Relays",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                        for (final relay in widget.task.relays)
                          ListTile(
                            title: Text(
                              relay,
                            ),
                          ),
                      ] +
                      [
                        PlatformTextButton(
                          material: (_, __) => MaterialTextButtonData(
                            icon: Icon(context.platformIcons.edit),
                          ),
                          child: Text("Edit relays"),
                          onPressed: () async {
                            await showPlatformModalSheet(
                              context: context,
                              material: MaterialModalSheetData(
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                isDismissible: true,
                              ),
                              builder: (context) => RelaySelectSheet(
                                controller: _relaysController,
                              ),
                            );

                            widget.task.update(relays: _relaysController.relays);
                            taskService.update(widget.task);
                          },
                        ),
                      ],
                ),
              ),
              DetailInformationBox(
                title: "Task status",
                child: FutureBuilder<Map<String, dynamic>>(
                  future: (() async {
                    final status = await widget.task.getExecutionStatus();

                    if (status == null) {
                      return {} as Map<String, dynamic>;
                    }

                    return status;
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (snapshot.hasData)
                            Text(
                              "Task started at ${snapshot.data!["startedAt"]} with a frequency of ${snapshot.data!["runFrequency"]}.",
                            )
                          else
                            Text("Task is not running."),
                          const SizedBox(height: MEDIUM_SPACE),
                          Row(
                            children: <Widget>[
                              if (snapshot.hasData)
                                PlatformTextButton(
                                  child: Text("Stop task"),
                                  material: (_, __) => MaterialTextButtonData(
                                    icon: const Icon(Icons.stop_rounded),
                                  ),
                                  onPressed: () async {
                                    await widget.task.stopExecutionImmediately();

                                    taskService.update(widget.task);
                                  },
                                )
                              else
                                PlatformTextButton(
                                  child: Text("Start task"),
                                  material: (_, __) => MaterialTextButtonData(
                                    icon: const Icon(Icons.play_arrow_rounded),
                                  ),
                                  onPressed: () async {
                                    await widget.task.startExecutionImmediately();

                                    taskService.update(widget.task);
                                  },
                                ),
                              const SizedBox(width: MEDIUM_SPACE),
                              FutureBuilder<Map<String, dynamic>>(
                                future: (() async {
                                  final status = await widget.task.getScheduleStatus();

                                  if (status == null) {
                                    return {} as Map<String, dynamic>;
                                  }

                                  return status;
                                })(),
                                builder: (context, scheduleSnapshot) {
                                  if (scheduleSnapshot.connectionState == ConnectionState.done) {
                                    if (scheduleSnapshot.hasData) {
                                      return PlatformTextButton(
                                        child: Text("Stop scheduling"),
                                        material: (_, __) => MaterialTextButtonData(
                                          icon: const Icon(Icons.stop_outlined),
                                        ),
                                        onPressed: () async {
                                          await widget.task.stopSchedule();

                                          taskService.update(widget.task);

                                          await showPlatformDialog(
                                            context: context,
                                            builder: (context) => PlatformAlertDialog(
                                              title: Text("Task unscheduled"),
                                              content: Text(
                                                "The task has been unscheduled. It will no longer be executed automatically. To start it again, you can either schedule it again or start it manually",
                                              ),
                                              actions: <Widget>[
                                                PlatformDialogAction(
                                                  child: Text("OK"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    } else {
                                      return PlatformTextButton(
                                        child: Text("Start scheduling"),
                                        material: (_, __) => MaterialTextButtonData(
                                          icon: const Icon(Icons.schedule_rounded),
                                        ),
                                        onPressed: () async {
                                          final startDate = await widget.task.startSchedule();

                                          taskService.update(widget.task);

                                          if (startDate == null) {
                                            await showPlatformDialog(
                                              context: context,
                                              builder: (context) => PlatformAlertDialog(
                                                title: Text("Task not scheduled"),
                                                content: Text(
                                                  "The task has not been started because there is no schedule set for the future.",
                                                ),
                                                actions: <Widget>[
                                                  PlatformDialogAction(
                                                    child: Text("OK"),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          await showPlatformDialog(
                                            context: context,
                                            builder: (context) => PlatformAlertDialog(
                                              title: Text("Task scheduled"),
                                              content: Text(
                                                "The task has been scheduled to start at ${DateFormat('MMMM d, HH:mm').format(startDate!)}.",
                                              ),
                                              actions: <Widget>[
                                                PlatformDialogAction(
                                                  child: Text("OK"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  }

                                  return PlatformCircularProgressIndicator(
                                    material: (_, __) => MaterialProgressIndicatorData(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      );
                    }

                    return Center(
                      child: PlatformCircularProgressIndicator(),
                    );
                  },
                ),
              ),
              DetailInformationBox(
                title: "Timers",
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 500,
                  ),
                  child: TimerWidget(
                    timers: widget.task.timers,
                    allowEdit: false,
                  ),
                ),
              ),
              Center(
                child: PlatformElevatedButton(
                  child: Text("Share location"),
                  material: (_, __) => MaterialElevatedButtonData(
                    icon: Icon(Icons.share_location_rounded),
                  ),
                  onPressed: openShareLocationDialog,
                ),
              ),
              Center(
                child: PlatformTextButton(
                  child: Text("Delete task"),
                  material: (_, __) => MaterialTextButtonData(
                    icon: Icon(context.platformIcons.delete),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).errorColor,
                    ),
                  ),
                  cupertino: (_, __) => CupertinoTextButtonData(
                    color: Theme.of(context).errorColor,
                  ),
                  onPressed: () async {
                    final confirmed = await showPlatformDialog(
                      context: context,
                      builder: (context) => PlatformAlertDialog(
                        title: Text("Delete task"),
                        content: Text(
                          "Are you sure you want to delete this task? This means that no more locations will be saved for this task. Existing locations will not be deleted. This action cannot be undone.",
                        ),
                        actions: <Widget>[
                          PlatformDialogAction(
                            child: Text("Cancel"),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          PlatformDialogAction(
                            child: Text("Delete"),
                            onPressed: () => Navigator.of(context).pop(true),
                            material: (_, __) => MaterialDialogActionData(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).errorColor,
                              ),
                            ),
                            cupertino: (_, __) => CupertinoDialogActionData(
                              isDestructiveAction: true,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await widget.task.stopExecutionImmediately();
                      taskService.remove(widget.task);
                      await taskService.save();

                      if (!mounted) {
                        return;
                      }

                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
