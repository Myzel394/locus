import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' hide PlatformListTile;
import 'package:locus/services/task_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/PlatformDialogActionButton.dart';
import '../../widgets/PlatformListTile.dart';
import '../../widgets/PlatformPopup.dart';
import '../TaskDetailScreen.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final bool disabled;

  const TaskTile({
    required this.task,
    this.disabled = false,
    Key? key,
  }) : super(key: key);

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  TaskLinkPublishProgress? linkProgress;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackBar;
  bool isLoading = false;

  Map<TaskLinkPublishProgress?, String> getProgressTextMap() {
    final l10n = AppLocalizations.of(context);

    return {
      TaskLinkPublishProgress.encrypting: l10n.taskAction_generateLink_process_encrypting,
      TaskLinkPublishProgress.publishing: l10n.taskAction_generateLink_process_publishing,
      TaskLinkPublishProgress.creatingURI: l10n.taskAction_generateLink_process_creatingURI,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskService = context.watch<TaskService>();

    return PlatformListTile(
      title: Text(widget.task.name),
      leading: FutureBuilder<bool>(
        future: widget.task.isRunning(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PlatformSwitch(
              value: snapshot.data!,
              onChanged: widget.disabled || isLoading
                  ? null
                  : (value) async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        if (value) {
                          await widget.task.startExecutionImmediately();
                          final nextEndDate = widget.task.nextEndDate();

                          widget.task.publishCurrentLocationNow();

                          if (!mounted) {
                            return;
                          }

                          if (nextEndDate == null) {
                            return;
                          }

                          showPlatformDialog(
                            context: context,
                            builder: (_) => PlatformAlertDialog(
                              title: Text(l10n.taskAction_started_title),
                              content: Text(l10n.taskAction_started_runsUntil(nextEndDate)),
                              actions: <Widget>[
                                PlatformDialogActionButton(
                                  child: Text(l10n.closeNeutralAction),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            ),
                          );
                        } else {
                          await widget.task.stopExecutionImmediately();
                          final nextStartDate = await widget.task.startScheduleTomorrow();

                          if (!mounted) {
                            return;
                          }

                          if (nextStartDate == null) {
                            return;
                          }

                          showPlatformDialog(
                            context: context,
                            builder: (_) => PlatformAlertDialog(
                              title: Text(l10n.taskAction_stopped_title),
                              content: Text(l10n.taskAction_stopped_startsAgain(nextStartDate)),
                              actions: <Widget>[
                                PlatformDialogActionButton(
                                  child: Text(l10n.closeNeutralAction),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            ),
                          );
                        }

                        taskService.update(widget.task);
                      } catch (_) {
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
            );
          }

          return const SizedBox();
        },
      ),
      trailing: PlatformPopup<String>(
        type: PlatformPopupType.tap,
        items: [
          PlatformPopupMenuItem<String>(
              label: PlatformListTile(
                leading: Icon(Icons.link_rounded),
                trailing: SizedBox.shrink(),
                title: Text(l10n.taskAction_generateLink),
              ),
              onPressed: () async {
                final url = await widget.task.generateLink(
                  onProgress: (progress) {
                    if (snackBar != null) {
                      try {
                        snackBar!.close();
                      } catch (e) {}
                    }

                    if (progress != TaskLinkPublishProgress.done && Platform.isAndroid) {
                      final scaffold = ScaffoldMessenger.of(context);

                      snackBar = scaffold.showSnackBar(
                        SnackBar(
                          content: Text(getProgressTextMap()[progress] ?? ""),
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
                  subject: l10n.taskAction_generateLink_shareTextSubject,
                );

                if (!mounted) {
                  return;
                }

                if (isMaterial(context)) {
                  final scaffold = ScaffoldMessenger.of(context);

                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(l10n.linkCopiedToClipboard),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              })
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
