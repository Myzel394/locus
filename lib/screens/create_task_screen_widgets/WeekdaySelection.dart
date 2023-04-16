import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';

class WeekdaySelection extends StatefulWidget {
  const WeekdaySelection({Key? key}) : super(key: key);

  @override
  State<WeekdaySelection> createState() => _WeekdaySelectionState();
}

class _WeekdaySelectionState extends State<WeekdaySelection> {
  int weekday = DateTime.monday;
  TimeOfDay startTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 20, minute: 0);

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
              padding: const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE, vertical: SMALL_SPACE),
              child: PlatformDropdownButton(
                value: weekday,
                onChanged: (value) {
                  setState(() {
                    weekday = value as int;
                  });
                },
                underline: Container(),
                items: const <DropdownMenuItem>[
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
                    backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.surface),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(SMALL_SPACE)),
                    ),
                  ),
                ),
                child: Text(
                  DateFormat("HH:mm").format(DateTime(0, 0, 0, startTime.hour, startTime.minute)),
                ),
                onPressed: () async {
                  final time = await showPlatformTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
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
                    backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.surface),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(SMALL_SPACE)),
                    ),
                  ),
                ),
                child: Text(
                  DateFormat("HH:mm").format(DateTime(0, 0, 0, endTime.hour, endTime.minute)),
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
          onPressed: () => Navigator.of(context).pop({
            "weekday": weekday,
            "startTime": startTime,
            "endTime": endTime,
          }),
        )
      ],
    );
  }
}
