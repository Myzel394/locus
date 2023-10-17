import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:intl/intl.dart';
import 'package:locus/screens/TaskDetailScreen.dart';
import 'package:locus/screens/locations_overview_screen_widgets/TaskChangeNameDialog.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/date.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/utils/task.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();

    widget.task.addListener(rebuild);
  }

  @override
  void dispose() {
    widget.task.removeListener(rebuild);

    super.dispose();
  }

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

  void rebuild() {
    setState(() {});
  }

  void _showChangeNameDialog() async => showPlatformDialog(
        context: context,
        builder: (context) => TaskChangeNameDialog(
          initialName: widget.task.name,
          onNameChanged: (newName) {
            final taskService = context.read<TaskService>();

            widget.task.name = newName;

            taskService.save();
            taskService.update(widget.task);

            Navigator.of(context).pop();
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformListTile(
      title: Text(widget.task.name),
      subtitle: widget.task.isFiniteQuickShare &&
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
                PlatformPopupMenuItem(
                  label: PlatformListTile(
                    leading: Icon(context.platformIcons.info),
                    title: Text(l10n.taskAction_showDetails),
                  ),
                  onPressed: () {
                    pushRoute(
                      context,
                      (context) => TaskDetailScreen(
                        task: widget.task,
                      ),
                    );
                  },
                ),
                PlatformPopupMenuItem(
                  label: PlatformListTile(
                    leading: Icon(context.platformIcons.edit),
                    title: Text(l10n.taskAction_changeName),
                  ),
                  onPressed: _showChangeNameDialog,
                )
              ],
            ),
      leading: FutureBuilder<bool>(
        future: widget.task.isRunning(),
        builder: (context, snapshot) => PlatformSwitch(
          value: snapshot.data ?? false,
          onChanged: snapshot.hasData
              ? (newValue) {
                  final taskService = context.read<TaskService>();

                  if (newValue) {
                    widget.task.startExecutionImmediately();
                  } else {
                    widget.task.stopExecutionImmediately();
                  }

                  taskService.forceListenerUpdate();
                  taskService.save();
                }
              : null,
        ),
      ),
    );
  }
}
