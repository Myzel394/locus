import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/timers.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:locus/widgets/ModalSheetContent.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:locus/widgets/WarningText.dart';
import 'package:locus/widgets/WeekdaySelection.dart';

class TimerWidgetSheet extends StatefulWidget {
  final TimerController controller;
  final bool allowEmpty;

  const TimerWidgetSheet({
    required this.controller,
    this.allowEmpty = false,
    Key? key,
  }) : super(key: key);

  @override
  State<TimerWidgetSheet> createState() => _TimerWidgetSheetState();
}

class _TimerWidgetSheetState extends State<TimerWidgetSheet> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(rebuild);
  }

  void rebuild() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(rebuild);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 1,
      expand: false,
      builder: (context, controller) => ModalSheet(
        child: SingleChildScrollView(
          controller: controller,
          child: ModalSheetContent(
            title: l10n.detailsTimersLabel,
            submitLabel: l10n.closePositiveSheetAction,
            onSubmit: (widget.controller.timers.isEmpty && !widget.allowEmpty)
                ? null
                : () {
                    Navigator.of(context).pop(widget.controller.timers);
                  },
            children: [
              if (widget.controller.timers.isNotEmpty) ...[
                TimerWidget(
                  controller: widget.controller,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                const SizedBox(height: SMALL_SPACE),
                if (findNextStartDate(widget.controller.timers) == null)
                  Text(l10n.timer_executionStartsImmediately)
                else
                  Text(l10n.timer_nextExecution(
                      findNextStartDate(widget.controller.timers)!)),
                if (widget.controller.timers
                    .any((timer) => timer.isInfinite())) ...[
                  const SizedBox(height: SMALL_SPACE),
                  WarningText(l10n.timer_runsInfiniteMessage),
                ],
              ],
              const SizedBox(height: MEDIUM_SPACE),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  PlatformTextButton(
                    child: Text(l10n.timer_addWeekday),
                    material: (_, __) => MaterialTextButtonData(
                      icon: const Icon(Icons.date_range_rounded),
                    ),
                    onPressed: () async {
                      final data = await showPlatformDialog(
                        context: context,
                        builder: (_) => const WeekdaySelection(),
                      );

                      if (!mounted) {
                        return;
                      }

                      if (data != null) {
                        widget.controller.add(
                          WeekdayTimer(
                            day: data["weekday"] as int,
                            startTime: data["startTime"] as TimeOfDay,
                            endTime: data["endTime"] as TimeOfDay,
                          ),
                        );
                      }
                    },
                  ),
                  PlatformTextButton(
                    child: Text(l10n.timer_addDuration),
                    material: (_, __) => MaterialTextButtonData(
                      icon: const Icon(Icons.timelapse_rounded),
                    ),
                    onPressed: () async {
                      Duration? duration;

                      if (isCupertino(context)) {
                        await showCupertinoModalPopup(
                          context: context,
                          builder: (context) => Container(
                            height: 300,
                            padding: const EdgeInsets.only(top: 6.0),
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            color: CupertinoColors.systemBackground
                                .resolveFrom(context),
                            child: SafeArea(
                              top: false,
                              child: CupertinoTimerPicker(
                                initialTimerDuration: Duration.zero,
                                minuteInterval: 5,
                                onTimerDurationChanged: (value) {
                                  duration = value;
                                },
                                mode: CupertinoTimerPickerMode.hm,
                              ),
                            ),
                          ),
                        );
                      } else {
                        duration = await showDurationPicker(
                          context: context,
                          initialTime: Duration.zero,
                          snapToMins: 15.0,
                        );
                      }

                      if (duration != null && duration!.inSeconds > 0) {
                        widget.controller.add(
                          DurationTimer(
                            duration: duration!,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
