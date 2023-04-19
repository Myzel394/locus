import 'package:animations/animations.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/TaskDetailScreen.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import 'CreateTaskScreen.dart';

const FAB_DIMENSION = 56.0;

class MainScreen extends StatefulWidget {
  const MainScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return PlatformScaffold(
      material: (_, __) => MaterialScaffoldData(
        floatingActionButton: taskService.tasks.isEmpty
            ? null
            : OpenContainer(
                transitionDuration: const Duration(milliseconds: 500),
                transitionType: ContainerTransitionType.fade,
                openBuilder: (context, action) => const CreateTaskScreen(),
                closedBuilder: (context, action) => SizedBox(
                  height: FAB_DIMENSION,
                  width: FAB_DIMENSION,
                  child: Center(
                    child: Icon(
                      context.platformIcons.add,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                closedElevation: 6.0,
                closedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(FAB_DIMENSION / 2),
                  ),
                ),
                openColor: Theme.of(context).scaffoldBackgroundColor,
                closedColor: Theme.of(context).colorScheme.primary,
              ),
      ),
      body: Center(
        child: taskService.tasks.length == 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "No tasks yet",
                    style: getSubTitleTextStyle(context),
                  ),
                  const SizedBox(height: SMALL_SPACE),
                  Text(
                    "Create a task to get started",
                    style: getCaptionTextStyle(context),
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  PlatformElevatedButton(
                    material: (_, __) => MaterialElevatedButtonData(
                      icon: Icon(context.platformIcons.add),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateTaskScreen(),
                        ),
                      );
                    },
                    child: Text("Create task"),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: taskService.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskService.tasks[index];

                  return ListTile(
                    title: Text(task.name),
                    subtitle: Text(task.frequency.toString()),
                    leading: FutureBuilder<bool>(
                      future: task.isRunning(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return PlatformSwitch(
                            value: snapshot.data!,
                            onChanged: (value) async {
                              if (value) {
                                await task.startExecutionImmediately();
                                final nextEndDate = task.nextEndDate();

                                if (!mounted) {
                                  return;
                                }

                                if (nextEndDate == null) {
                                  return;
                                }

                                await showPlatformDialog(
                                  context: context,
                                  builder: (_) => PlatformAlertDialog(
                                    title: Text("Task started"),
                                    content: Text(
                                      "The task has been started and will run until ${DateFormat('MMMM d, HH:mm').format(nextEndDate)}",
                                    ),
                                    actions: <Widget>[
                                      PlatformDialogActionButton(
                                        child: Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      )
                                    ],
                                  ),
                                );
                              } else {
                                await task.stopExecutionImmediately();
                                final nextStartDate = await task.startScheduleTomorrow();

                                if (!mounted) {
                                  return;
                                }

                                if (nextStartDate == null) {
                                  return;
                                }

                                await showPlatformDialog(
                                  context: context,
                                  builder: (_) => PlatformAlertDialog(
                                    title: Text("Task stopped"),
                                    content: Text(
                                      "The task has been stopped and will run again on ${DateFormat('MMMM d, HH:mm').format(nextStartDate)}",
                                    ),
                                    actions: <Widget>[
                                      PlatformDialogActionButton(
                                        child: Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      )
                                    ],
                                  ),
                                );
                              }

                              taskService.update(task);
                            },
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(
                            task: task,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
