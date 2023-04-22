import 'package:animations/animations.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/main_screen_widgets/ImportTask.dart';
import 'package:locus/screens/main_screen_widgets/TaskTile.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:provider/provider.dart';

import '../utils/theme.dart';
import 'CreateTaskScreen.dart';
import 'main_screen_widgets/CreateTask.dart';

const FAB_DIMENSION = 56.0;

class MainScreen extends StatefulWidget {
  const MainScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final listViewKey = GlobalKey();
  late final TaskService taskService;
  bool shouldUseScreenHeight = false;
  bool listViewShouldFillUp = false;
  double listViewHeight = 0;

  double get windowHeight =>
      MediaQuery
          .of(context)
          .size
          .height - kToolbarHeight;

  // If the ListView covers more than 75% of the screen, then actions get a whole screen of space.
  // Otherwise fill up the remaining space.
  bool getShouldUseScreenHeight(final BuildContext context) {
    // Initial app screen, no tasks have been created yet. Use the full screen.
    if (listViewKey.currentContext == null) {
      return true;
    }

    final listViewHeight = listViewKey.currentContext?.size?.height ?? 0;
    return listViewHeight > windowHeight * 0.6;
  }

  // Checks if the ListView should fill up the remaining space. This means that the listView is smaller than the
  // remaining height.
  bool getListViewShouldFillUp(final BuildContext context) {
    final listViewHeight = listViewKey.currentContext?.size?.height ?? 0;

    return listViewHeight < windowHeight;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateView();
    });

    final taskService = context.read<TaskService>();

    taskService.addListener(updateView);
  }

  @override
  void dispose() {
    taskService.removeListener(updateView);

    super.dispose();
  }

  void updateView() {
    final height = listViewKey.currentContext?.size?.height ?? 0;

    setState(() {
      shouldUseScreenHeight = getShouldUseScreenHeight(context);
      listViewShouldFillUp = getListViewShouldFillUp(context);
      listViewHeight = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(
            floatingActionButton: taskService.tasks.isEmpty
                ? null
                : OpenContainer(
              transitionDuration: const Duration(milliseconds: 500),
              transitionType: ContainerTransitionType.fade,
              openBuilder: (context, action) => const CreateTaskScreen(),
              closedBuilder: (context, action) =>
                  SizedBox(
                    height: FAB_DIMENSION,
                    width: FAB_DIMENSION,
                    child: Center(
                      child: Icon(
                        context.platformIcons.add,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onPrimary,
                      ),
                    ),
                  ),
              closedElevation: 6.0,
              closedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(FAB_DIMENSION / 2),
                ),
              ),
              openColor: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              closedColor: Theme
                  .of(context)
                  .colorScheme
                  .primary,
            ),
          ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: taskService.tasks.isEmpty
              ? Column(
            children: <Widget>[
              SizedBox(
                height: windowHeight,
                child: Center(
                  child: CreateTask(),
                ),
              ),
              SizedBox(
                height: windowHeight,
                child: Center(
                  child: ImportTask(),
                ),
              ),
            ],
          )
              : Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
                  height: (() {
                    if (shouldUseScreenHeight) {
                      if (listViewShouldFillUp) {
                        return windowHeight;
                      }
                    }

                    return null;
                  })(),
                  child: Container(
                    key: listViewKey,
                    child: Padding(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "TASKS",
                            style: getTitleTextStyle(context),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(top: MEDIUM_SPACE),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: taskService.tasks.length,
                            itemBuilder: (context, index) {
                              final task = taskService.tasks[index];

                              return TaskTile(
                                task: task,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  height: shouldUseScreenHeight ? windowHeight : windowHeight - listViewHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE, vertical: LARGE_SPACE),
                    child: Center(
                      child: Paper(
                        child: ImportTask(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
