import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:intl/intl.dart';
import 'package:locus/screens/TaskDetailScreen.dart';
import 'package:locus/services/task_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/date.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/utils/task.dart';

import '../../widgets/PlatformListTile.dart';
import '../../widgets/PlatformPopup.dart';

class TaskTile extends StatefulWidget {
  final Task task;

  const TaskTile({
    required this.task,
    super.key,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with TaskLinkGenerationMixin {
  bool isLoading = false;

  void generateLink() async {
    setState(() {
      isLoading = true;
    });

    try {
      await shareTask(widget.task);
    } catch (_) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatStartDate(DateTime startDate) {
    if (startDate.isSameDay(DateTime.now())) {
      return DateFormat.Hm().format(startDate);
    } else {
      return DateFormat.yMd().add_Hm().format(startDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformListTile(
      title: Text(widget.task.name),
      subtitle: widget.task.timers.length == 1 &&
              widget.task.timers[0] is DurationTimer &&
              (widget.task.timers[0] as DurationTimer).startDate != null
          ? Text(
              formatStartDate(
                (widget.task.timers[0] as DurationTimer).startDate!,
              ),
            )
          : null,
      trailing: isLoading
          ? const CircularProgressIndicator()
          : PlatformPopup(
              items: [
                PlatformPopupMenuItem(
                  label: PlatformListTile(
                    leading: const Icon(Icons.link_rounded),
                    title: Text(l10n.taskAction_generateLink),
                  ),
                  onPressed: generateLink,
                ),
              ],
            ),
      leading: FutureBuilder<bool>(
        future: widget.task.isRunning(),
        builder: (context, snapshot) => PlatformSwitch(
          value: snapshot.data ?? false,
          onChanged: snapshot.hasData
              ? (newValue) {
                  if (newValue) {
                    widget.task.startExecutionImmediately();
                  } else {
                    widget.task.stopExecutionImmediately();
                  }
                }
              : null,
        ),
      ),
      onTap: () {
        pushRoute(
          context,
          (context) => TaskDetailScreen(
            task: widget.task,
          ),
        );
      },
    );
  }
}
