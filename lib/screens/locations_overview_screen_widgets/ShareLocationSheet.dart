import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/date.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/utils/ui-message/enums.dart';
import 'package:locus/utils/ui-message/show-message.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/ModalSheetContent.dart';
import 'package:locus/widgets/PlatformRadioTile.dart';
import 'package:provider/provider.dart';

import '../../services/task_service.dart';

enum ShareType {
  untilTurnOff,
  forHours,
}

class ShareLocationSheet extends StatefulWidget {
  const ShareLocationSheet({super.key});

  @override
  State<ShareLocationSheet> createState() => _ShareLocationSheetState();
}

class _ShareLocationSheetState extends State<ShareLocationSheet> {
  final hoursFormKey = GlobalKey<FormState>();
  final hoursController = TextEditingController(text: "1");

  ShareType type = ShareType.untilTurnOff;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    hoursController.addListener(updateUI);
  }

  @override
  void dispose() {
    hoursController.dispose();

    super.dispose();
  }

  void updateUI() {
    setState(() {});
  }

  void createNewTask([final List<TaskRuntimeTimer>? timers]) async {
    final l10n = AppLocalizations.of(context);
    final taskService = context.read<TaskService>();
    final settings = context.read<SettingsService>();

    setState(() {
      isLoading = true;
    });

    FlutterLogs.logInfo(
      LOG_TAG,
      "Quick Location Share",
      "Creating new task",
    );

    try {
      final relays = await settings.getDefaultRelaysOrRandom();
      final name = l10n.quickLocationShare_name(DateTime.now());

      final task = await Task.create(
        name,
        relays.toList(),
        timers: timers ?? [],
        deleteAfterRun: true,
      );
      taskService.add(task);
      await task.startExecutionImmediately();
      await taskService.save();

      FlutterLogs.logInfo(
        LOG_TAG,
        "Quick Location Share",
        "New task created: ${task.id}",
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(task);
      return;
    } catch (error) {
      setState(() {
        isLoading = false;
      });

      FlutterLogs.logError(
        LOG_TAG,
        "Quick Location Share",
        "Error while creating new task: $error",
      );

      showMessage(
        context,
        l10n.unknownError,
        type: MessageType.error,
      );
    }
  }

  VoidCallback createAddHoursFn(final int value) {
    return () {
      final hours = int.tryParse(hoursController.text) ?? 0;
      final newHours = max(1, hours + value);

      hoursController.text = newHours.toString();

      // Force UI update so `endDate` is updated
      setState(() {});
    };
  }

  DateTime? get endDate {
    final hours = int.tryParse(hoursController.text);

    if (hours == null) {
      return null;
    }

    final now = DateTime.now();
    final endDate = now.add(Duration(hours: hours));
    return endDate;
  }

  String formatEndDate(final DateTime date) => date.isSameDay(DateTime.now())
      ? DateFormat.Hm().format(date)
      : DateFormat.yMd().add_Hm().format(date);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: ModalSheetContent(
        icon: Icons.share_location_rounded,
        title: l10n.quickLocationShare_title,
        description: l10n.quickLocationShare_description,
        submitLabel: l10n.quickLocationShare_submit_label,
        onSubmit: isLoading
            ? null
            : () async {
                switch (type) {
                  case ShareType.untilTurnOff:
                    createNewTask();
                    break;
                  case ShareType.forHours:
                    if (hoursFormKey.currentState!.validate()) {
                      final hours = int.parse(hoursController.text);
                      final timer = DurationTimer(
                        duration: Duration(hours: hours),
                      );

                      createNewTask([timer]);
                    }
                    break;
                }
              },
        children: [
          PlatformRadioTile<ShareType>(
            title: Text(l10n.quickLocationShare_shareUntilTurnOff),
            groupValue: type,
            value: ShareType.untilTurnOff,
            onChanged: (value) {
              setState(() {
                type = value!;
              });
            },
          ),
          PlatformRadioTile<ShareType>(
            title: Text(l10n.quickLocationShare_shareForTime),
            groupValue: type,
            value: ShareType.forHours,
            onChanged: (value) {
              setState(() {
                type = value!;
              });
            },
          ),
          Form(
            key: hoursFormKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: Opacity(
                    opacity: type == ShareType.forHours ? 1 : 0.4,
                    child: Text(
                      formatEndDate(endDate!),
                      style: getCaptionTextStyle(context),
                    ),
                  ),
                ),
                Flexible(
                  child: PlatformIconButton(
                    onPressed: type == ShareType.forHours && !isLoading
                        ? createAddHoursFn(-1)
                        : null,
                    icon: Icon(context.platformIcons.removeCircledSolid),
                  ),
                ),
                Expanded(
                  child: PlatformTextFormField(
                    material: (_, __) => MaterialTextFormFieldData(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: l10n.hoursPluralization(
                          int.tryParse(hoursController.text) ?? 0,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    enabled: type == ShareType.forHours && !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.fields_errors_isEmpty;
                      }

                      if (!StringUtils.isDigit(value)) {
                        return l10n.fields_errors_notNumber;
                      }

                      if (int.parse(value) < 1) {
                        return l10n.fields_errors_greaterThan(0);
                      }

                      return null;
                    },
                  ),
                ),
                Flexible(
                  child: PlatformIconButton(
                    onPressed: type == ShareType.forHours && !isLoading
                        ? createAddHoursFn(1)
                        : null,
                    icon: Icon(context.platformIcons.addCircledSolid),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
