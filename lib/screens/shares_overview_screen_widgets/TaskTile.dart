import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/constants/values.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:provider/provider.dart';

import '../../models/log.dart';
import '../../services/log_service.dart';
import '../../utils/task.dart';
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

class _TaskTileState extends State<TaskTile> with TaskLinkGenerationMixin {
  TaskLinkPublishProgress? linkProgress;
  bool isLoading = false;

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

                      final logService = context.read<LogService>();

                      try {
                        if (value) {
                          await widget.task.startExecutionImmediately();
                          taskService.update(widget.task);
                          await taskService.save();

                          await logService.addLog(
                            Log.taskStatusChanged(
                              initiator: LogInitiator.user,
                              taskId: widget.task.id,
                              taskName: widget.task.name,
                              active: true,
                            ),
                          );
                          final nextEndDate = widget.task.nextEndDate();

                          widget.task.publishCurrentPosition();

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
                              content: Text(l10n
                                  .taskAction_started_runsUntil(nextEndDate)),
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
                          final nextStartDate =
                              await widget.task.startScheduleTomorrow();

                          taskService.update(widget.task);
                          await taskService.save();

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
                              content: Text(l10n.taskAction_stopped_startsAgain(
                                  nextStartDate)),
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
                      } catch (error) {
                        FlutterLogs.logError(
                          LOG_TAG,
                          "Task Tile",
                          "Error while starting/stopping task: $error",
                        );
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
              leading: const Icon(Icons.link_rounded),
              trailing: const SizedBox.shrink(),
              title: Text(l10n.taskAction_generateLink),
            ),
            onPressed: () => shareTask(widget.task),
          )
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          NativePageRoute(
            context: context,
            builder: (context) => TaskDetailScreen(
              task: widget.task,
            ),
          ),
        );
      },
    );
  }
}
