import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/extensions/date.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PlatformSelect.dart';

class WeekdaySelection extends StatefulWidget {
  final int weekday;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool lockWeekday;

  const WeekdaySelection({
    this.weekday = DateTime.monday,
    this.startTime = const TimeOfDay(hour: 8, minute: 0),
    this.endTime = const TimeOfDay(hour: 20, minute: 0),
    this.lockWeekday = false,
    Key? key,
  }) : super(key: key);

  @override
  State<WeekdaySelection> createState() => _WeekdaySelectionState();
}

class _WeekdaySelectionState extends State<WeekdaySelection> {
  late int weekday;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  bool get isValid => startTime.toDateTime().isBefore(endTime.toDateTime());

  @override
  void initState() {
    super.initState();

    weekday = widget.weekday;
    startTime = widget.startTime;
    endTime = widget.endTime;
  }

  Future<TimeOfDay?> _showTimePicker(final TimeOfDay initialTime) async {
    if (isCupertino(context)) {
      DateTime value = initialTime.toDateTime();

      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              initialDateTime: initialTime.toDateTime(),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              onDateTimeChanged: (DateTime newTime) {
                value = newTime;
              },
            ),
          ),
        ),
      );

      return TimeOfDay.fromDateTime(value);
    } else {
      return showTimePicker(
        context: context,
        initialTime: initialTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformAlertDialog(
      title: Text(l10n.weekdaySelection_selectTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(SMALL_SPACE),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: MEDIUM_SPACE, vertical: SMALL_SPACE),
              child: PlatformSelect<int>(
                value: weekday,
                onChanged: widget.lockWeekday
                    ? null
                    : ((value) {
                        setState(() {
                          weekday = value as int;
                        });
                      }),
                items: <DropdownMenuItem<int>>[
                  DropdownMenuItem(
                    value: DateTime.monday,
                    child: Text(l10n.weekdays_monday),
                  ),
                  DropdownMenuItem(
                    value: DateTime.tuesday,
                    child: Text(l10n.weekdays_tuesday),
                  ),
                  DropdownMenuItem(
                    value: DateTime.wednesday,
                    child: Text(l10n.weekdays_wednesday),
                  ),
                  DropdownMenuItem(
                    value: DateTime.thursday,
                    child: Text(l10n.weekdays_thursday),
                  ),
                  DropdownMenuItem(
                    value: DateTime.friday,
                    child: Text(l10n.weekdays_friday),
                  ),
                  DropdownMenuItem(
                    value: DateTime.saturday,
                    child: Text(l10n.weekdays_saturday),
                  ),
                  DropdownMenuItem(
                    value: DateTime.sunday,
                    child: Text(l10n.weekdays_sunday),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              PlatformTextButton(
                material: (_, __) => MaterialTextButtonData(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(MEDIUM_SPACE),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Theme.of(context).colorScheme.surface,
                    ),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SMALL_SPACE),
                      ),
                    ),
                  ),
                ),
                child: Text(
                  DateFormat("HH:mm").format(
                      DateTime(0, 0, 0, startTime.hour, startTime.minute)),
                ),
                onPressed: () async {
                  final time = await _showTimePicker(startTime);
                  if (time != null) {
                    setState(() {
                      startTime = time;
                    });
                  }
                },
              ),
              PlatformTextButton(
                material: (_, __) => MaterialTextButtonData(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(MEDIUM_SPACE),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).colorScheme.surface),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SMALL_SPACE),
                      ),
                    ),
                  ),
                ),
                child: Text(
                  DateFormat("HH:mm")
                      .format(DateTime(0, 0, 0, endTime.hour, endTime.minute)),
                ),
                onPressed: () async {
                  // TODO: Add cupertino time picker
                  final time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    setState(() {
                      endTime = time;
                    });
                  }
                },
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: SMALL_SPACE),
            Text(
              l10n.weekdaySelection_error_startTimeBeforeEndTime,
              style: TextStyle(
                color: getErrorColor(context),
              ),
            ),
          ]
        ],
      ),
      actions: createCancellableDialogActions(
        context,
        <Widget>[
          PlatformDialogAction(
            cupertino: (_, __) => CupertinoDialogActionData(
              isDefaultAction: true,
            ),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            onPressed: isValid
                ? () => Navigator.of(context).pop({
                      "weekday": weekday,
                      "startTime": startTime,
                      "endTime": endTime,
                    })
                : null,
            child: Text(l10n.addLabel),
          )
        ],
      ),
    );
  }
}
