import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/constants/spacing.dart';
import 'package:locus/models/log.dart';
import 'package:locus/screens/LocationPointsDetailsScreen.dart';
import 'package:locus/screens/task_detail_screen_widgets/ShareLocationButton.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/log_service.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/DetailInformationBox.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/SimpleAddressFetcher.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:provider/provider.dart';

import '../../widgets/PlatformListTile.dart';
import '../../widgets/TimerWidgetSheet.dart';

class Details extends StatefulWidget {
  final Task task;

  const Details({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late final RelayController _relaysController;
  final timersController = TimerController();

  @override
  void initState() {
    super.initState();

    _relaysController = RelayController(
      relays: widget.task.relays,
    );
    timersController.addAll(widget.task.timers);
    widget.task.addListener(updateUI);
  }

  @override
  void dispose() {
    _relaysController.dispose();
    widget.task.removeListener(updateUI);

    super.dispose();
  }

  void updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskService = context.watch<TaskService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Wrap(
            runSpacing: LARGE_SPACE,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Center(
                child: ShareLocationButton(
                  task: widget.task,
                ),
              ),
              DetailInformationBox(
                title: l10n.nostrRelaysLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.from(
                        widget.task.relays.map(
                          (relay) => PlatformListTile(
                            title: Text(
                              relay,
                            ),
                            trailing: const SizedBox.shrink(),
                          ),
                        ),
                      ) +
                      [
                        PlatformTextButton(
                          material: (_, __) => MaterialTextButtonData(
                            icon: Icon(context.platformIcons.edit),
                          ),
                          child: Text(l10n.editRelays),
                          onPressed: () async {
                            await showPlatformModalSheet(
                              context: context,
                              material: MaterialModalSheetData(
                                isScrollControlled: true,
                                isDismissible: true,
                                backgroundColor: Colors.transparent,
                              ),
                              builder: (context) => RelaySelectSheet(
                                controller: _relaysController,
                              ),
                            );

                            await widget.task
                                .update(relays: _relaysController.relays);
                            taskService.update(widget.task);
                            await taskService.save();
                          },
                        ),
                      ],
                ),
              ),
              DetailInformationBox(
                title: l10n.taskDetails_taskStatus,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: (() async {
                    final status = await widget.task.getExecutionStatus();

                    if (status == null) {
                      return Map<String, dynamic>.from({});
                    }

                    return status;
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final isRunning = snapshot.hasData &&
                          snapshot.data?["startedAt"] != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (isRunning)
                            Text(
                              l10n.taskAction_started_description(
                                snapshot.data!["startedAt"],
                              ),
                              style: getBodyTextTextStyle(context),
                            )
                          else
                            Text(
                              l10n.taskAction_notRunning_title,
                              style: getBodyTextTextStyle(context),
                            ),
                          const SizedBox(height: MEDIUM_SPACE),
                          Row(
                            children: <Widget>[
                              if (isRunning)
                                PlatformTextButton(
                                  child: Text(l10n.taskAction_stop),
                                  material: (_, __) => MaterialTextButtonData(
                                    icon: const Icon(Icons.stop_rounded),
                                  ),
                                  onPressed: () async {
                                    final logService =
                                        context.read<LogService>();
                                    await widget.task
                                        .stopExecutionImmediately();

                                    taskService.update(widget.task);
                                    await taskService.save();

                                    await logService.addLog(
                                      Log.taskStatusChanged(
                                        initiator: LogInitiator.system,
                                        taskId: widget.task.id,
                                        taskName: widget.task.name,
                                        active: false,
                                      ),
                                    );
                                  },
                                )
                              else
                                PlatformTextButton(
                                  child: Text(l10n.taskAction_start),
                                  material: (_, __) => MaterialTextButtonData(
                                    icon: const Icon(Icons.play_arrow_rounded),
                                  ),
                                  onPressed: () async {
                                    final logService =
                                        context.read<LogService>();
                                    await widget.task
                                        .startExecutionImmediately();

                                    taskService.update(widget.task);
                                    await taskService.save();

                                    await logService.addLog(
                                      Log.taskStatusChanged(
                                        initiator: LogInitiator.system,
                                        taskId: widget.task.id,
                                        taskName: widget.task.name,
                                        active: true,
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(width: MEDIUM_SPACE),
                              FutureBuilder<Map<String, dynamic>>(
                                future: (() async {
                                  final status =
                                      await widget.task.getScheduleStatus();

                                  if (status == null) {
                                    return Map<String, dynamic>.from({});
                                  }

                                  return status;
                                })(),
                                builder: (context, scheduleSnapshot) {
                                  if (scheduleSnapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (scheduleSnapshot.hasData &&
                                        (scheduleSnapshot.data?.isNotEmpty ??
                                            false)) {
                                      return PlatformTextButton(
                                        child:
                                            Text(l10n.taskAction_stopSchedule),
                                        material: (_, __) =>
                                            MaterialTextButtonData(
                                          icon: const Icon(Icons.stop_outlined),
                                        ),
                                        onPressed: () async {
                                          await widget.task.stopSchedule();

                                          taskService.update(widget.task);

                                          if (!mounted) {
                                            return;
                                          }

                                          await showPlatformDialog(
                                            context: context,
                                            builder: (context) =>
                                                PlatformAlertDialog(
                                              title: Text(l10n
                                                  .taskAction_stopSchedule_title),
                                              content: Text(l10n
                                                  .taskAction_stopSchedule_description),
                                              actions: <Widget>[
                                                PlatformDialogAction(
                                                  child: Text(
                                                      l10n.closeNeutralAction),
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
                                        child:
                                            Text(l10n.taskAction_startSchedule),
                                        material: (_, __) =>
                                            MaterialTextButtonData(
                                          icon: const Icon(
                                              Icons.schedule_rounded),
                                        ),
                                        onPressed: () async {
                                          final startDate =
                                              await widget.task.startSchedule();

                                          taskService.update(widget.task);

                                          if (!mounted) {
                                            return;
                                          }

                                          if (startDate == null) {
                                            await showPlatformDialog(
                                              context: context,
                                              builder: (context) =>
                                                  PlatformAlertDialog(
                                                title: Text(l10n
                                                    .taskAction_startSchedule_notScheduled_title),
                                                content: Text(l10n
                                                    .taskAction_startSchedule_notScheduled_description),
                                                actions: <Widget>[
                                                  PlatformDialogAction(
                                                    child: Text(l10n
                                                        .closeNeutralAction),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            await showPlatformDialog(
                                              context: context,
                                              builder: (context) =>
                                                  PlatformAlertDialog(
                                                title: Text(l10n
                                                    .taskAction_startSchedule_title),
                                                content: Text(
                                                  l10n.taskAction_startSchedule_description(
                                                    startDate,
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  PlatformDialogAction(
                                                    child: Text(l10n
                                                        .closeNeutralAction),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    }
                                  }

                                  return PlatformCircularProgressIndicator(
                                    material: (_, __) =>
                                        MaterialProgressIndicatorData(
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
                title: l10n.detailsTimersLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (timersController.timers.isEmpty)
                      Text(
                        l10n.taskDetails_noTimers,
                        textAlign: TextAlign.start,
                        style: getBodyTextTextStyle(context),
                      )
                    else
                      TimerWidget(
                        timers: timersController.timers,
                        allowEdit: false,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PlatformTextButton(
                        material: (_, __) => MaterialTextButtonData(
                          icon: Icon(context.platformIcons.edit),
                        ),
                        child: Text(l10n.editTimers),
                        onPressed: () async {
                          final logService = context.read<LogService>();

                          final timers = await showPlatformModalSheet(
                            context: context,
                            material: MaterialModalSheetData(
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              isDismissible: true,
                            ),
                            builder: (_) => TimerWidgetSheet(
                              allowEmpty: true,
                              controller: timersController,
                            ),
                          );

                          if (timers == null) {
                            return;
                          }

                          await widget.task.stopExecutionImmediately();
                          await widget.task.stopSchedule();
                          await widget.task
                              .update(timers: timersController.timers);
                          taskService.update(widget.task);
                          await taskService.save();
                          await widget.task.startSchedule();
                          await taskService.checkup(logService);
                          await widget.task.update();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: PlatformTextButton(
                  child: Text(l10n.taskDetails_deleteTask),
                  material: (_, __) => MaterialTextButtonData(
                    icon: Icon(context.platformIcons.delete),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  cupertino: (_, __) => CupertinoTextButtonData(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    final logService = context.read<LogService>();

                    final confirmed = await showPlatformDialog(
                      context: context,
                      builder: (context) => PlatformAlertDialog(
                        title: Text(l10n.taskDetails_deleteTask),
                        content: Text(l10n.taskDetails_deleteTask_confirm),
                        material: (_, __) => MaterialAlertDialogData(
                          icon: Icon(context.platformIcons.delete),
                        ),
                        actions: createCancellableDialogActions(
                          context,
                          [
                            PlatformDialogAction(
                              child: Text(l10n.deleteLabel),
                              onPressed: () => Navigator.of(context).pop(true),
                              material: (_, __) => MaterialDialogActionData(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                icon: const Icon(Icons.delete_forever_rounded),
                              ),
                              cupertino: (_, __) => CupertinoDialogActionData(
                                isDestructiveAction: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (confirmed == true) {
                      await widget.task.stopExecutionImmediately();
                      taskService.remove(widget.task);
                      await taskService.save();

                      await logService.addLog(
                        Log.deleteTask(
                          initiator: LogInitiator.user,
                          taskName: widget.task.name,
                        ),
                      );

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
