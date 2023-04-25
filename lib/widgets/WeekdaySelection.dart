import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/extensions/date.dart';
import 'package:locus/utils/theme.dart';

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
    return PlatformAlertDialog(
      title: Text("Select Date and Time"),
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
              child: PlatformDropdownButton<int>(
                value: weekday,
                style: TextStyle(
                  backgroundColor: Colors.blue,
                ),
                onChanged: widget.lockWeekday
                    ? null
                    : ((value) {
                        setState(() {
                          weekday = value as int;
                        });
                      }),
                underline: Container(),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem(
                    child: Text("Monday"),
                    value: DateTime.monday,
                  ),
                  DropdownMenuItem(
                    child: Text("Tuesday"),
                    value: DateTime.tuesday,
                  ),
                  DropdownMenuItem(
                    child: Text("Wednesday"),
                    value: DateTime.wednesday,
                  ),
                  DropdownMenuItem(
                    child: Text("Thursday"),
                    value: DateTime.thursday,
                  ),
                  DropdownMenuItem(
                    child: Text("Friday"),
                    value: DateTime.friday,
                  ),
                  DropdownMenuItem(
                    child: Text("Saturday"),
                    value: DateTime.saturday,
                  ),
                  DropdownMenuItem(
                    child: Text("Sunday"),
                    value: DateTime.sunday,
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
                  final time = await showPlatformTimePicker(
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
              "Start time must be before end time",
              style: getErrorTextStyle(context),
            ),
          ]
        ],
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        PlatformDialogAction(
          child: Text("Add"),
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
        )
      ],
    );
  }
}
