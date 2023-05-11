import 'package:animations/animations.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/init_quick_actions.dart';
import 'package:locus/screens/SettingsScreen.dart';
import 'package:locus/screens/main_screen_widgets/ImportTask.dart';
import 'package:locus/screens/main_screen_widgets/TaskTile.dart';
import 'package:locus/screens/main_screen_widgets/ViewTile.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/widgets/ChipCaption.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

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
  int activeTab = 0;

  double get windowHeight =>
      MediaQuery.of(context).size.height - kToolbarHeight;

  // If the ListView covers more than 75% of the screen, then actions get a whole screen of space.
  // Otherwise fill up the remaining space.
  bool getShouldUseScreenHeight(final BuildContext context) {
    // Initial app screen, no tasks have been created yet. Use the full screen.
    if (listViewKey.currentContext == null) {
      return true;
    }

    final listViewHeight = listViewKey.currentContext?.size?.height ?? 0;
    return listViewHeight >= windowHeight * 0.5;
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
      initQuickActions(context);
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

  PlatformAppBar getAppBar() {
    final l10n = AppLocalizations.of(context);

    return PlatformAppBar(
      title: Text(l10n.appName),
      trailingActions: [
        PlatformPopupMenuButton(
          itemBuilder: (context) => [
            PlatformPopupMenuItem(child: Text("Settings"), value: "settings"),
          ],
          onSelected: (value) {
            switch (value) {
              case "settings":
                if (isCupertino(context)) {
                  showCupertinoModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SettingsScreen(themeContext: context),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen(themeContext: context),
                    ),
                  );
                }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskService = context.watch<TaskService>();
    final viewService = context.watch<ViewService>();

    final showEmptyScreen =
        taskService.tasks.isEmpty && viewService.views.isEmpty;

    if (showEmptyScreen) {
      return PlatformScaffold(
        appBar: getAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: windowHeight,
                  child: const Center(
                    child: CreateTask(),
                  ),
                ),
                SizedBox(
                  height: windowHeight,
                  child: const Center(
                    child: ImportTask(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PlatformScaffold(
      material: (_, __) => MaterialScaffoldData(
        floatingActionButton: OpenContainer(
          transitionDuration: const Duration(milliseconds: 500),
          transitionType: ContainerTransitionType.fade,
          openBuilder: (_, action) => CreateTaskScreen(
            onCreated: () {
              Navigator.pop(context);
            },
          ),
          closedBuilder: (context, action) => SizedBox(
            height: FAB_DIMENSION,
            width: FAB_DIMENSION,
            child: Center(
              child: Icon(
                Icons.add,
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
        )
            .animate()
            .scale(duration: 500.ms, delay: 1.seconds, curve: Curves.bounceOut),
      ),
      // Settings bottomNavBar via cupertino data class does not work
      bottomNavBar: isCupertino(context)
          ? PlatformNavBar(
              itemChanged: (index) {
                setState(() {
                  activeTab = index;
                });
              },
              currentIndex: activeTab,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home),
                  label: l10n.mainScreen_overview,
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.location_fill),
                  label: l10n.mainScreen_createTask,
                ),
              ],
            )
          : null,
      appBar: activeTab == 0 ? getAppBar() : null,
      body: activeTab == 0
          ? SafeArea(
              child: SingleChildScrollView(
                child: Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(
                        height: windowHeight - kToolbarHeight,
                        child: Wrap(
                          runSpacing: LARGE_SPACE,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: <Widget>[
                            if (taskService.tasks.isNotEmpty)
                              PlatformWidget(
                                material: (context, __) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: MEDIUM_SPACE),
                                      child: ChipCaption(
                                        l10n.mainScreen_tasksSection,
                                        icon: Icons.task_rounded,
                                      ),
                                    ).animate().fadeIn(duration: 1.seconds),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.only(
                                          top: MEDIUM_SPACE),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: taskService.tasks.length,
                                      itemBuilder: (context, index) {
                                        final task = taskService.tasks[index];

                                        return TaskTile(
                                          task: task,
                                        )
                                            .animate()
                                            .then(delay: 100.ms * index)
                                            .slide(
                                              duration: 1.seconds,
                                              curve: Curves.easeOut,
                                              begin: Offset(0, 0.2),
                                            )
                                            .fadeIn(
                                              delay: 100.ms,
                                              duration: 1.seconds,
                                              curve: Curves.easeOut,
                                            );
                                      },
                                    ),
                                  ],
                                ),
                                cupertino: (context, __) =>
                                    CupertinoListSection(
                                  header: Text(
                                    l10n.mainScreen_tasksSection,
                                  ),
                                  children: taskService.tasks
                                      .map(
                                        (task) => TaskTile(
                                          task: task,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            if (viewService.views.isNotEmpty)
                              PlatformWidget(
                                material: (context, __) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: MEDIUM_SPACE),
                                      child: ChipCaption(
                                        l10n.mainScreen_viewsSection,
                                        icon: context.platformIcons.eyeSolid,
                                      ),
                                    ).animate().fadeIn(duration: 1.seconds),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.only(
                                          top: MEDIUM_SPACE),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: viewService.views.length,
                                      itemBuilder: (context, index) => ViewTile(
                                        view: viewService.views[index],
                                      )
                                          .animate()
                                          .then(delay: 100.ms * index)
                                          .slide(
                                            duration: 1.seconds,
                                            curve: Curves.easeOut,
                                            begin: const Offset(0, 0.2),
                                          )
                                          .fadeIn(
                                            delay: 100.ms,
                                            duration: 1.seconds,
                                            curve: Curves.easeOut,
                                          ),
                                    ),
                                  ],
                                ),
                                cupertino: (context, __) =>
                                    CupertinoListSection(
                                  header: Text(l10n.mainScreen_viewsSection),
                                  children: viewService.views
                                      .map(
                                        (view) => ViewTile(
                                          view: view,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: windowHeight,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MEDIUM_SPACE,
                            vertical: HUGE_SPACE,
                          ),
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
            )
          : activeTab == 1
              ? CreateTaskScreen(
                  onCreated: () {
                    if (isCupertino(context)) {
                      setState(() {
                        activeTab = 0;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                )
              : null,
    );
  }
}
