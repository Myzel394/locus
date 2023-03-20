import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import 'CreateTaskScreen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(
            floatingActionButton: taskService.tasks.length == 0
                ? null
                : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateTaskScreen(),
                  ),
                );
              },
              child: Icon(context.platformIcons.add),
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
              material: (_, __) =>
                  MaterialElevatedButtonData(
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
                          await task.start();
                        } else {
                          await task.stop();
                        }

                        taskService.update();
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
