import 'dart:io';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:locus/services/task_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../TaskDetailScreen.dart';

final Map<TaskLinkPublishProgress?, String> TASK_LINK_PROGRESS_TEXT_MAP = {
  null: "Preparing...",
  TaskLinkPublishProgress.startsSoon: "Preparing...",
  TaskLinkPublishProgress.encrypting: "Encrypting data...",
  TaskLinkPublishProgress.publishing: "Publishing encrypted data...",
  TaskLinkPublishProgress.creatingURI: "Creating link...",
  TaskLinkPublishProgress.done: "Done",
};

class TaskTile extends StatefulWidget {
  final Task task;

  const TaskTile({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  TaskLinkPublishProgress? linkProgress;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackBar;

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return PlatformListTile(
      title: Text(widget.task.name),
      subtitle: Text(widget.task.frequency.toString()),
      leading: FutureBuilder<bool>(
        future: widget.task.isRunning(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PlatformSwitch(
              value: snapshot.data!,
              onChanged: (value) async {
                if (value) {
                  await widget.task.startExecutionImmediately();
                  final nextEndDate = widget.task.nextEndDate();

                  if (!mounted) {
                    return;
                  }

                  if (nextEndDate == null) {
                    return;
                  }

                  await showPlatformDialog(
                    context: context,
                    builder: (_) => PlatformAlertDialog(
                      title: Text("Task started"),
                      content: Text(
                        "The task has been started and will run until ${DateFormat('MMMM d, HH:mm').format(nextEndDate)}",
                      ),
                      actions: <Widget>[
                        PlatformDialogActionButton(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                  );
                } else {
                  await widget.task.stopExecutionImmediately();
                  final nextStartDate =
                      await widget.task.startScheduleTomorrow();

                  if (!mounted) {
                    return;
                  }

                  if (nextStartDate == null) {
                    return;
                  }

                  await showPlatformDialog(
                    context: context,
                    builder: (_) => PlatformAlertDialog(
                      title: Text("Task stopped"),
                      content: Text(
                        "The task has been stopped and will run again on ${DateFormat('MMMM d, HH:mm').format(nextStartDate)}",
                      ),
                      actions: <Widget>[
                        PlatformDialogActionButton(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                  );
                }

                taskService.update(widget.task);
              },
            );
          }

          return const SizedBox();
        },
      ),
      trailing: PlatformPopupMenuButton(
        onSelected: (value) async {
          final url = await widget.task.generateLink(
            onProgress: (progress) {
              if (snackBar != null) {
                try {
                  snackBar!.close();
                } catch (e) {}
              }

              if (progress != TaskLinkPublishProgress.done &&
                  Platform.isAndroid) {
                final scaffold = ScaffoldMessenger.of(context);

                snackBar = scaffold.showSnackBar(
                  SnackBar(
                    content: Text(TASK_LINK_PROGRESS_TEXT_MAP[progress]!),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.indigoAccent,
                  ),
                );
              }
            },
          );

          await Clipboard.setData(ClipboardData(text: url));
          await Share.share(
            url,
            subject: "Here's my Locus link to see my location",
          );

          if (Platform.isAndroid) {
            final scaffold = ScaffoldMessenger.of(context);

            scaffold.showSnackBar(
              SnackBar(
                content: const Text("Link copied to clipboard"),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        itemBuilder: (context) => [
          const PlatformPopupMenuItem(
            child: PlatformListTile(
              leading: Icon(Icons.link_rounded),
              title: Text("Generate link"),
            ),
            value: 0,
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: widget.task,
            ),
          ),
        );
      },
    );
  }
}
