import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' hide PlatformListTile;
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/main_screen_widgets/TaskTileDetailsScreen.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/widgets/MaybeMaterial.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/log.dart';
import '../../services/location_point_service.dart';
import '../../services/log_service.dart';
import '../../widgets/Paper.dart';
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
  bool? _isTaskRunning;

  Map<TaskLinkPublishProgress?, String> getProgressTextMap() {
    final l10n = AppLocalizations.of(context);

    return {
      TaskLinkPublishProgress.encrypting: l10n.taskAction_generateLink_process_encrypting,
      TaskLinkPublishProgress.publishing: l10n.taskAction_generateLink_process_publishing,
      TaskLinkPublishProgress.creatingURI: l10n.taskAction_generateLink_process_creatingURI,
    };
  }

  @override
  void initState() {
    super.initState();

    checkTaskStatus();
  }

  void checkTaskStatus() async {
    // We manually set the value because a `FutureBuilder` rerenders the builder when the user comes back from the
    // animation.

    _isTaskRunning = await widget.task.isRunning();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskService = context.watch<TaskService>();

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Hero(
            tag: "${widget.task.id}:paper",
            child: Paper(
              child: Container(),
            ),
          ),
        ),
        PlatformListTile(
          title: Hero(
            tag: "${widget.task.id}:title",
            child: MaybeMaterial(
              color: Colors.transparent,
              child: Text(widget.task.name),
            ),
          ),
          leading: Hero(
            tag: "${widget.task.id}:switch",
            child: _isTaskRunning == null
                ? SizedBox.shrink()
                : MaybeMaterial(
                    color: Colors.transparent,
                    child: PlatformSwitch(
                      value: _isTaskRunning!,
                      onChanged: widget.disabled || isLoading
                          ? null
                          : (value) async {
                              setState(() {
                                isLoading = true;
                              });

                              final logService = context.read<LogService>();

                              try {
                                if (value) {
                                  await widget.task.startExecutionImmediately();
                                  await logService.addLog(
                                    Log.taskStatusChanged(
                                      initiator: LogInitiator.user,
                                      taskId: widget.task.id,
                                      taskName: widget.task.name,
                                      active: true,
                                    ),
                                  );
                                  final nextEndDate = widget.task.nextEndDate();
                                  final locationData = await LocationPointService.createUsingCurrentLocation();

                                  widget.task.publishCurrentLocationNow(locationData);

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
                                  await logService.addLog(
                                    Log.taskStatusChanged(
                                      initiator: LogInitiator.user,
                                      taskId: widget.task.id,
                                      taskName: widget.task.name,
                                      active: false,
                                    ),
                                  );
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
                    ),
                  ),
          ),
          trailing: PlatformIconButton(
            icon: Icon(Icons.more_horiz),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black.withOpacity(0.5),
                  barrierDismissible: true,
                  fullscreenDialog: true,
                  pageBuilder: (context, _, __) => TaskTileDetailsScreen(task: widget.task),
                ),
              );
            },
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
        ),
      ],
    );
  }
}
