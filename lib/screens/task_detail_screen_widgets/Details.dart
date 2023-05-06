import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/api/get-address.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/task_detail_screen_widgets/ShareLocationButton.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/DetailInformationBox.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:provider/provider.dart';

class Details extends StatefulWidget {
  final Iterable<LocationPointService> locations;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          onPressed: widget.onGoBack,
          child: Text(l10n.goBack),
        ),
        Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Wrap(
            runSpacing: LARGE_SPACE,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              DetailInformationBox(
                title: l10n.taskDetails_lastKnownLocation,
                child: widget.locations.isEmpty
                    ? Text(l10n.taskDetails_noLocations)
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
                            message: l10n.taskDetails_mostRecentLocationExplanation,
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
                title: l10n.taskDetails_locationDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l10n.taskDetails_savedLocations(widget.locations.length),
                      style: getBodyTextTextStyle(context),
                      textAlign: TextAlign.start,
                    ),
                  ],
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
                      final isRunning = snapshot.hasData && snapshot.data?["startedAt"] != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (isRunning)
                            Text(
                              l10n.taskAction_started_description(
                                snapshot.data!["startedAt"],
                                (snapshot.data!["runFrequency"] as Duration).inMinutes,
                              ),
                            )
                          else
                            Text(l10n.taskAction_notRunning_title),
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
                                    await widget.task.stopExecutionImmediately();

                                    taskService.update(widget.task);
                                  },
                                )
                              else
                                PlatformTextButton(
                                  child: Text(l10n.taskAction_start),
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
                                    return Map<String, dynamic>.from({});
                                  }

                                  return status;
                                })(),
                                builder: (context, scheduleSnapshot) {
                                  if (scheduleSnapshot.connectionState == ConnectionState.done) {
                                    if (scheduleSnapshot.hasData) {
                                      return PlatformTextButton(
                                        child: Text(l10n.taskAction_stopSchedule),
                                        material: (_, __) => MaterialTextButtonData(
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
                                            builder: (context) => PlatformAlertDialog(
                                              title: Text(l10n.taskAction_stopSchedule_title),
                                              content: Text(l10n.taskAction_stopSchedule_description),
                                              actions: <Widget>[
                                                PlatformDialogAction(
                                                  child: Text(l10n.closeNeutralAction),
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
                                        child: Text(l10n.taskAction_startSchedule),
                                        material: (_, __) => MaterialTextButtonData(
                                          icon: const Icon(Icons.schedule_rounded),
                                        ),
                                        onPressed: () async {
                                          final startDate = await widget.task.startSchedule();

                                          taskService.update(widget.task);

                                          if (!mounted) {
                                            return;
                                          }

                                          if (startDate == null) {
                                            await showPlatformDialog(
                                              context: context,
                                              builder: (context) => PlatformAlertDialog(
                                                title: Text(l10n.taskAction_startSchedule_notScheduled_title),
                                                content: Text(l10n.taskAction_startSchedule_notScheduled_description),
                                                actions: <Widget>[
                                                  PlatformDialogAction(
                                                    child: Text(l10n.closeNeutralAction),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            await showPlatformDialog(
                                              context: context,
                                              builder: (context) => PlatformAlertDialog(
                                                title: Text(l10n.taskAction_startSchedule_title),
                                                content: Text(l10n.taskAction_startSchedule_description(startDate!)),
                                                actions: <Widget>[
                                                  PlatformDialogAction(
                                                    child: Text(l10n.closeNeutralAction),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
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
                title: l10n.detailsTimersLabel,
                child: TimerWidget(
                  timers: widget.task.timers,
                  allowEdit: false,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
              Center(
                child: ShareLocationButton(
                  task: widget.task,
                ),
              ),
              Center(
                child: PlatformTextButton(
                  child: Text(l10n.taskDetails_deleteTask),
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
                        title: Text(l10n.taskDetails_deleteTask),
                        content: Text(l10n.taskDetails_deleteTask_confirm),
                        actions: createCancellableDialogActions(context, [
                          PlatformDialogAction(
                            child: Text(l10n.deleteLabel),
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
                        ]),
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
