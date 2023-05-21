import 'dart:io';

import 'package:animations/animations.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/init_quick_actions.dart';
import 'package:locus/screens/main_screen_widgets/ImportTask.dart';
import 'package:locus/screens/main_screen_widgets/TaskTile.dart';
import 'package:locus/screens/main_screen_widgets/ViewTile.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/widgets/AppHint.dart';
import 'package:locus/widgets/ChipCaption.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:provider/provider.dart';

import '../constants/values.dart';
import '../services/location_point_service.dart';
import '../utils/platform.dart';
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
  final _hintTypeFuture = getHintTypeForMainScreen();
  bool shouldUseScreenHeight = false;
  bool listViewShouldFillUp = false;
  double listViewHeight = 0;
  int activeTab = 0;
  bool showHint = true;
  Stream<Position>? _positionStream;

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

  void initBackground() async {
    BackgroundFetch.start();
  }

  LocationSettings getLocationSettings() {
    final l10n = AppLocalizations.of(context);

    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER,
        intervalDuration: LOCATION_INTERVAL,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: l10n.backgroundLocationFetch_text,
          notificationTitle: l10n.backgroundLocationFetch_title,
        ),
      );
    } else if (isPlatformApple()) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: LOCATION_FETCH_TIME_LIMIT,
        distanceFilter: BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER,
        activityType: ActivityType.other,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: true,
      );
    }

    return const LocationSettings(
      distanceFilter: BACKGROUND_LOCATION_UPDATES_MINIMUM_DISTANCE_FILTER,
      timeLimit: LOCATION_FETCH_TIME_LIMIT,
      accuracy: LocationAccuracy.best,
    );
  }

  _initLiveLocationUpdate() {
    if (_positionStream != null) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: getLocationSettings(),
    );

    _positionStream!.listen((position) async {
      final taskService = context.read<TaskService>();
      final runningTasks = await taskService.getRunningTasks().toList();

      if (runningTasks.isEmpty) {
        return;
      }

      final locationData =
          await LocationPointService.createUsingCurrentLocation(position);

      for (final task in runningTasks) {
        await task.publishCurrentLocationNow(
          locationData.copyWithDifferentId(),
        );
      }
    });
  }

  _removeLiveLocationUpdate() {
    _positionStream?.drain();
    _positionStream = null;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initQuickActions(context);
    });

    final taskService = context.read<TaskService>();

    taskService.addListener(updateView);
    taskService.checkup();

    initBackground();
  }

  @override
  void dispose() {
    final taskService = context.read<TaskService>();
    taskService.removeListener(updateView);

    _removeLiveLocationUpdate();

    super.dispose();
  }

  void updateView() async {
    final taskService = context.read<TaskService>();
    final height = listViewKey.currentContext?.size?.height ?? 0;

    setState(() {
      shouldUseScreenHeight = getShouldUseScreenHeight(context);
      listViewShouldFillUp = getListViewShouldFillUp(context);
      listViewHeight = height;
    });

    final runningTasks = await taskService.getRunningTasks().toList();

    if (runningTasks.isNotEmpty) {
      _initLiveLocationUpdate();
    } else {
      _removeLiveLocationUpdate();
    }
  }

  PlatformAppBar getAppBar() {
    final l10n = AppLocalizations.of(context);

    return PlatformAppBar(
      title: Text(l10n.appName),
      trailingActions: [
        PlatformPopup<String>(
          type: PlatformPopupType.tap,
          items: [
            PlatformPopupMenuItem(
              label: Text(l10n.settingsScreen_title),
              onPressed: () {
                showSettings(context);
              },
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskService = context.watch<TaskService>();
    final viewService = context.watch<ViewService>();
    final settings = context.watch<SettingsService>();

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
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FutureBuilder<HintType?>(
                      future: _hintTypeFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            settings.getShowHints() &&
                            showHint) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: LARGE_SPACE,
                              horizontal: MEDIUM_SPACE,
                            ),
                            child: AppHint(
                              hintType: snapshot.data!,
                              onDismiss: () {
                                setState(() {
                                  showHint = false;
                                });
                              },
                            ),
                          );
                        }

                        return SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
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
                              cupertino: (context, __) => CupertinoListSection(
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
                              cupertino: (context, __) => CupertinoListSection(
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
