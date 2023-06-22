import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/init_quick_actions.dart';
import 'package:locus/main.dart';
import 'package:locus/screens/ViewDetailScreen.dart';
import 'package:locus/screens/main_screen_widgets/screens/EmptyScreen.dart';
import 'package:locus/services/manager_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/navigation.dart';
import 'package:locus/utils/theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

import '../constants/notifications.dart';
import '../constants/values.dart';
import '../models/log.dart';
import '../services/app_update_service.dart';
import '../services/location_point_service.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../utils/PageRoute.dart';
import '../utils/platform.dart';
import 'CreateTaskScreen.dart';
import 'ImportTaskSheet.dart';
import 'LogsScreen.dart';
import 'main_screen_widgets/screens/OverviewScreen.dart';
import 'main_screen_widgets/values.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final listViewKey = GlobalKey();
  final PageController _tabController = PageController();
  late final TaskService taskService;
  int activeTab = 0;
  Stream<Position>? _positionStream;
  StreamSubscription<String?>? _uniLinksStream;
  Timer? _viewsAlarmCheckerTimer;

  void _changeTab(final int newTab) {
    setState(() {
      activeTab = newTab;
    });

    _tabController.animateToPage(
      newTab,
      duration: getTransitionDuration(context),
      curve: Curves.easeInOut,
    );
  }

  void _initBackground() async {
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
      final logService = context.read<LogService>();
      final runningTasks = await taskService.getRunningTasks().toList();

      if (runningTasks.isEmpty) {
        return;
      }

      final locationData =
      await LocationPointService.fromPosition(position);

      for (final task in runningTasks) {
        await task.publishLocation(
          locationData.copyWithDifferentId(),
        );
      }

      await logService.addLog(
        Log.updateLocation(
          initiator: LogInitiator.system,
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          accuracy: locationData.accuracy,
          tasks: List<UpdatedTaskData>.from(
            runningTasks.map(
                  (task) =>
                  UpdatedTaskData(
                    id: task.id,
                    name: task.name,
                  ),
            ),
          ),
        ),
      );
    });
  }

  _removeLiveLocationUpdate() {
    _positionStream?.drain();
    _positionStream = null;
  }

  Future<void> _importUniLink(final String url) =>
      showPlatformModalSheet(
        context: context,
        material: MaterialModalSheetData(
          isScrollControlled: true,
          isDismissible: true,
          backgroundColor: Colors.transparent,
        ),
        builder: (context) => ImportTaskSheet(initialURL: url),
      );

  Future<void> _initUniLinks() async {
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(LOG_TAG, "Uni Links", "Initiating uni links...");

    _uniLinksStream = linkStream.listen((final String? link) {
      if (link != null) {
        _importUniLink(link);
      }
    });

    try {
      // Only fired when the app was in background
      final initialLink = await getInitialLink();

      if (initialLink != null) {
        await _importUniLink(initialLink);
      }
    } on PlatformException catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Uni Links",
        "Error initializing uni links: $error",
      );

      showPlatformDialog(
        context: context,
        builder: (_) =>
            PlatformAlertDialog(
              title: Text(l10n.uniLinksOpenError),
              content: Text(error.message ?? l10n.unknownError),
              actions: [
                PlatformDialogAction(
                  child: Text(l10n.closeNeutralAction),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    final taskService = context.read<TaskService>();
    final appUpdateService = context.read<AppUpdateService>();
    taskService.addListener(updateView);
    appUpdateService.addListener(updateView);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final taskService = context.read<TaskService>();
      final logService = context.read<LogService>();

      initQuickActions(context);
      _initUniLinks();
      _updateLocaleToSettings();

      taskService.checkup(logService);
    });

    _initBackground();
    _handleViewAlarmChecker();
    _handleNotifications();
  }

  void _handleViewAlarmChecker() {
    _viewsAlarmCheckerTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) {
        final viewService = context.read<ViewService>();
        final l10n = AppLocalizations.of(context);

        if (viewService.viewsWithAlarms.isEmpty) {
          return;
        }

        checkViewAlarms(
          l10n: l10n,
          views: viewService.viewsWithAlarms,
          viewService: viewService,
        );
      },
    );
  }

  void _handleNotifications() {
    selectedNotificationsStream.stream.listen((notification) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Notification",
        "Notification received: ${notification.payload}",
      );

      try {
        final data = jsonDecode(notification.payload ?? "{}");
        final type = NotificationActionType.values[data["type"]];

        switch (type) {
          case NotificationActionType.openTaskView:
            final viewService = context.read<ViewService>();

            Navigator.of(context).push(
              NativePageRoute(
                context: context,
                builder: (_) =>
                    ViewDetailScreen(
                      view: viewService.getViewById(data["taskViewID"]),
                    ),
              ),
            );
            break;
        }
      } catch (error) {
        FlutterLogs.logErrorTrace(
          LOG_TAG,
          "Notification",
          "Error handling notification.",
          error as Error,
        );
      }
    });
  }

  void _updateLocaleToSettings() {
    final settingsService = context.read<SettingsService>();

    settingsService.localeName = AppLocalizations
        .of(context)
        .localeName;
    settingsService.save();
  }

  @override
  void dispose() {
    final taskService = context.read<TaskService>();
    final appUpdateService = context.read<AppUpdateService>();
    taskService.removeListener(updateView);
    appUpdateService.removeListener(updateView);

    _tabController.dispose();

    _viewsAlarmCheckerTimer?.cancel();
    _uniLinksStream?.cancel();

    _removeLiveLocationUpdate();

    super.dispose();
  }

  void _showUpdateDialogIfRequired() async {
    final l10n = AppLocalizations.of(context);
    final appUpdateService = context.read<AppUpdateService>();

    if (appUpdateService.shouldShowDialogue() &&
        !appUpdateService.hasShownDialogue &&
        mounted) {
      await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        material: MaterialDialogData(
          barrierColor: Colors.black,
        ),
        builder: (context) =>
            PlatformAlertDialog(
              title: Text(l10n.updateAvailable_android_title),
              content: Text(l10n.updateAvailable_android_description),
              actions: [
                PlatformDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  material: (context, _) =>
                      MaterialDialogActionData(
                          icon: const Icon(Icons.watch_later_rounded)),
                  child: Text(l10n.updateAvailable_android_remindLater),
                ),
                PlatformDialogAction(
                  onPressed: () {
                    appUpdateService.doNotShowDialogueAgain();

                    Navigator.of(context).pop();
                  },
                  material: (context, _) =>
                      MaterialDialogActionData(icon: const Icon(Icons.block)),
                  child: Text(l10n.updateAvailable_android_ignore),
                ),
                PlatformDialogAction(
                  onPressed: appUpdateService.openStoreForUpdate,
                  material: (context, _) =>
                      MaterialDialogActionData(
                          icon: const Icon(Icons.download)),
                  child: Text(l10n.updateAvailable_android_download),
                ),
              ],
            ),
      );

      appUpdateService.setHasShownDialogue();
    }
  }

  void updateView() async {
    final taskService = context.read<TaskService>();
    final runningTasks = await taskService.getRunningTasks().toList();

    if (runningTasks.isNotEmpty) {
      _initLiveLocationUpdate();
    } else {
      _removeLiveLocationUpdate();
    }

    _showUpdateDialogIfRequired();
  }

  PlatformAppBar? getAppBar([final bool hasScreens = true]) {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsService>();

    if (settings.isMIUI()) {
      final colors = getPrimaryColorShades(context);
      final primaryColor = colors[0];

      return PlatformAppBar(
        title: hasScreens
            ? Row(
          children: <Widget>[
            // We want the same width
            const SizedBox(width: 48),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      _changeTab(0);
                    },
                    child: Icon(
                      activeTab == 0
                          ? CupertinoIcons.square_list_fill
                          : CupertinoIcons.square_list,
                      color: activeTab == 0
                          ? primaryColor
                          : getBodyTextColor(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _changeTab(1);
                    },
                    child: Icon(
                      activeTab == 1
                          ? CupertinoIcons.time_solid
                          : CupertinoIcons.time,
                      color: activeTab == 1
                          ? primaryColor
                          : getBodyTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : null,
        trailingActions: <Widget>[
          IconButton(
            icon: Transform.rotate(
              angle: 0,
              child: const Icon(MdiIcons.nut),
            ),
            onPressed: () {
              showSettings(context);
            },
          ),
        ],
      );
    }

    return PlatformAppBar(
      title: Text(l10n.appName),
      trailingActions: [
        PlatformIconButton(
          cupertino: (_, __) =>
              CupertinoIconButtonData(
                padding: EdgeInsets.zero,
              ),
          icon: Icon(context.platformIcons.settings),
          onPressed: () {
            showSettings(context);
          },
        ),
      ],
    );
  }

  PlatformNavBar? getBottomNavBar() {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsService>();

    if (settings.isMIUI()) {
      return null;
    }

    return PlatformNavBar(
      material: (_, __) =>
          MaterialNavBarData(
              backgroundColor: Theme
                  .of(context)
                  .dialogBackgroundColor,
              elevation: 0,
              padding: const EdgeInsets.all(0)),
      itemChanged: _changeTab,
      currentIndex: activeTab,
      items: isCupertino(context)
          ? [
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.home),
          label: l10n.mainScreen_overview,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.list_bullet),
          label: l10n.mainScreen_logs,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.location_fill),
          label: l10n.mainScreen_createTask,
        ),
      ]
          : [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.mainScreen_overview,
          backgroundColor: Theme
              .of(context)
              .dialogBackgroundColor,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: l10n.mainScreen_logs,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final viewService = context.watch<ViewService>();
    final settings = context.watch<SettingsService>();

    final showEmptyScreen =
        taskService.tasks.isEmpty && viewService.views.isEmpty;

    if (showEmptyScreen) {
      return PlatformScaffold(
        appBar: getAppBar(false),
        body: const EmptyScreen(),
      );
    }

    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(
            floatingActionButton: activeTab == 0
                ? OpenContainer(
              transitionDuration: const Duration(milliseconds: 500),
              transitionType: ContainerTransitionType.fade,
              openBuilder: (_, action) =>
                  CreateTaskScreen(
                    onCreated: () {
                      Navigator.pop(context);
                    },
                  ),
              closedBuilder: (context, action) =>
                  SizedBox(
                    height: FAB_DIMENSION,
                    width: FAB_DIMENSION,
                    child: Center(
                      child: Icon(
                        settings.isMIUI() || isCupertino(context)
                            ? CupertinoIcons.plus
                            : Icons.add,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                        size: settings.isMIUI() ? 34 : 38,
                      ),
                    ),
                  ),
              closedElevation: 6.0,
              closedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(30),
                ),
              ),
              openColor: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              closedColor: getIsDarkMode(context)
                  ? HSLColor.fromColor(Theme
                  .of(context)
                  .colorScheme
                  .primary)
                  .withLightness(.15)
                  .withSaturation(1)
                  .toColor()
                  : Theme
                  .of(context)
                  .colorScheme
                  .primary,
            ).animate().scale(
                duration: 500.ms, delay: 1.seconds, curve: Curves.bounceOut)
                : null,
          ),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(
            backgroundColor: getIsDarkMode(context)
                ? null
                : CupertinoColors.tertiarySystemGroupedBackground
                .resolveFrom(context),
          ),
      // Settings bottomNavBar via cupertino data class does not work
      bottomNavBar: getBottomNavBar(),
      appBar: getAppBar(true),
      body: PageView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          const OverviewScreen(),
          const LogsScreen(),
          if (isCupertino(context))
            CreateTaskScreen(
              onCreated: () {
                _changeTab(0);
              },
            ),
        ],
      ),
    );
  }
}
