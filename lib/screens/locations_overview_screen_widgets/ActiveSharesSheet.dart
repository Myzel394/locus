import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/utils/location/index.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import './TaskTile.dart';
import '../../constants/spacing.dart';
import '../../utils/theme.dart';
import '../../widgets/ModalSheet.dart';

const MIN_SIZE = 0.1;

class ActiveSharesSheet extends StatefulWidget {
  final double triggerThreshold;
  final VoidCallback onThresholdReached;
  final VoidCallback onThresholdPassed;
  final bool visible;
  final VoidCallback onShareLocation;
  final VoidCallback onOpenActionSheet;

  const ActiveSharesSheet({
    required this.visible,
    required this.triggerThreshold,
    required this.onThresholdReached,
    required this.onThresholdPassed,
    required this.onShareLocation,
    required this.onOpenActionSheet,
    super.key,
  });

  @override
  State<ActiveSharesSheet> createState() => _ActiveSharesSheetState();
}

class _ActiveSharesSheetState extends State<ActiveSharesSheet>
    with TickerProviderStateMixin {
  final wrapperKey = GlobalKey();
  final textKey = GlobalKey();
  final sheetController = DraggableScrollableController();
  late final AnimationController offsetController;
  late Animation<double> offsetProgress;

  bool isInitializing = true;
  bool isLocationPointerVisible = false;

  bool isUpdatingLocation = false;
  bool isTogglingTasks = false;

  bool _hasCalledThreshold = false;
  bool _hasCalledPassed = false;

  double _xOffset = 0;

  @override
  void initState() {
    super.initState();

    offsetController =
        AnimationController(vsync: this, duration: Duration.zero);
    // Dummy animation so first render can occur without any problems
    offsetProgress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(offsetController);

    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final wrapperWidth = wrapperKey.currentContext!.size!.width;
      final textWidth = textKey.currentContext!.size!.width;
      _xOffset = (wrapperWidth - textWidth) / 2;

      offsetProgress = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          curve: Curves.linearToEaseOut,
          parent: offsetController,
        ),
      );

      isInitializing = false;
    });

    sheetController.addListener(() {
      final progress = (sheetController.size - MIN_SIZE) / (1 - MIN_SIZE);

      offsetController.animateTo(
        progress,
        duration: Duration.zero,
      );

      final isThresholdReached = progress >= widget.triggerThreshold;

      if (isThresholdReached && !_hasCalledThreshold) {
        _hasCalledThreshold = true;
        widget.onThresholdReached();
      } else if (!isThresholdReached) {
        _hasCalledThreshold = false;
      }

      if (!isThresholdReached && !_hasCalledPassed) {
        _hasCalledPassed = true;
        widget.onThresholdPassed();
      } else if (isThresholdReached) {
        _hasCalledPassed = false;
      }
    });

    final taskService = context.read<TaskService>();
    taskService.addListener(rebuild);
  }

  @override
  void dispose() {
    sheetController.dispose();
    offsetController.dispose();

    final taskService = context.read<TaskService>();
    taskService.removeListener(rebuild);

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ActiveSharesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        sheetController.animateTo(
          MIN_SIZE,
          duration: const Duration(milliseconds: 500),
          curve: Curves.linearToEaseOut,
        );
      } else {
        sheetController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void rebuild() {
    setState(() {});
  }

  Iterable<Task> get quickShareTasks {
    final taskService = context.read<TaskService>();

    return taskService.tasks
        .where((task) => task.deleteAfterRun && task.timers.length <= 1);
  }

  Future<bool> getAreSomeTasksRunning() async {
    final tasksRunning =
        await Future.wait(quickShareTasks.map((task) => task.isRunning()));

    return tasksRunning.any((isRunning) => isRunning);
  }

  void updateLocation() async {
    setState(() {
      isUpdatingLocation = true;
    });

    FlutterLogs.logInfo(
      LOG_TAG,
      "ActiveSharesSheet",
      "Updating location for ${quickShareTasks.length} tasks",
    );

    try {
      final position = await getCurrentPosition();
      final locationData = await LocationPointService.fromPosition(position);

      await Future.wait(
        quickShareTasks.map(
          (task) => task.publishLocation(
            locationData.copyWithDifferentId(),
          ),
        ),
      );

      FlutterLogs.logInfo(
        LOG_TAG,
        "ActiveSharesSheet",
        "Updated location for ${quickShareTasks.length} tasks successfully!",
      );
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "ActiveSharesSheet",
        "Error while updating location for ${quickShareTasks.length} tasks: $error",
      );
    } finally {
      setState(() {
        isUpdatingLocation = false;
      });
    }
  }

  void toggleTasks(final bool start) async {
    final taskService = context.read<TaskService>();

    setState(() {
      isTogglingTasks = true;
    });

    FlutterLogs.logInfo(
      LOG_TAG,
      "ActiveSharesSheet",
      "Toggling ${quickShareTasks.length} tasks",
    );

    try {
      if (start) {
        for (final task in quickShareTasks) {
          task.startExecutionImmediately();
        }
      } else {
        for (final task in quickShareTasks) {
          task.stopExecutionImmediately();
        }
      }

      await taskService.save();

      FlutterLogs.logInfo(
        LOG_TAG,
        "ActiveSharesSheet",
        "Toggled ${quickShareTasks.length} tasks successfully!",
      );
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "ActiveSharesSheet",
        "Error while toggling ${quickShareTasks.length} tasks: $error",
      );
    } finally {
      setState(() {
        isTogglingTasks = false;
      });
    }
  }

  Widget buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height -
          kToolbarHeight -
          MediaQuery.of(context).viewPadding.top,
      child: Column(
        key: wrapperKey,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTitle(),
          Column(
            children: [
              SizedBox(
                width: 200,
                child: VisibilityDetector(
                  key: const Key("location-pointer"),
                  onVisibilityChanged: (visibilityInfo) {
                    setState(() {
                      isLocationPointerVisible =
                          visibilityInfo.visibleFraction > 0.0;
                    });
                  },
                  child: Lottie.asset(
                    "assets/lotties/location-pointer.json",
                    key: Key(isLocationPointerVisible.toString()),
                    frameRate: FrameRate.max,
                    repeat: false,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(
                          const ["Path 3306", "Path 3305", "Fill 1"],
                          value: shades[0],
                        ),
                        ValueDelegate.color(
                          const ["Path 3305", "Path 3305", "Fill 1"],
                          value: shades[0],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.sharesOverviewScreen_createTask_tasksEmpty,
                style: getTitle2TextStyle(context),
              ),
              const SizedBox(height: SMALL_SPACE),
              Text(
                l10n.sharesOverviewScreen_createTask_description,
                style: getCaptionTextStyle(context),
              ),
            ],
          ),
          PlatformElevatedButton(
            material: (_, __) => MaterialElevatedButtonData(
              icon: const Icon(Icons.share_location_rounded),
            ),
            onPressed: () {
              sheetController.animateTo(
                MIN_SIZE,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeIn,
              );
              widget.onShareLocation();
            },
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            child: Text(l10n.shareLocation_title),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTasksStatusButton(final bool someTasksRunning) {
    final l10n = AppLocalizations.of(context);

    return ElevatedButton(
      onPressed: isTogglingTasks ? null : () => toggleTasks(!someTasksRunning),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MEDIUM_SPACE),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Column(
          children: (() {
            if (isTogglingTasks) {
              return <Widget>[
                PlatformCircularProgressIndicator(),
                const SizedBox(height: MEDIUM_SPACE),
                Text(
                  l10n.tasks_action_stopAll,
                  textAlign: TextAlign.center,
                ),
              ];
            }

            if (someTasksRunning) {
              return <Widget>[
                PlatformFlavorWidget(
                  material: (_, __) => const Icon(
                    Icons.stop_circle_rounded,
                    size: 42,
                  ),
                  cupertino: (_, __) => const Icon(
                    CupertinoIcons.stop_circle_fill,
                    size: 42,
                  ),
                ),
                const SizedBox(height: MEDIUM_SPACE),
                Text(
                  l10n.tasks_action_stopAll,
                  textAlign: TextAlign.center,
                ),
              ];
            }

            return <Widget>[
              PlatformFlavorWidget(
                material: (_, __) => const Icon(
                  Icons.play_circle_rounded,
                  size: 42,
                ),
                cupertino: (_, __) => const Icon(
                  CupertinoIcons.play_circle_fill,
                  size: 42,
                ),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.tasks_action_startAll,
                textAlign: TextAlign.center,
              ),
            ];
          })(),
        ),
      ),
    );
  }

  Widget _buildShareLocationButton(final bool allTasksRunning) {
    final l10n = AppLocalizations.of(context);

    return ElevatedButton(
      onPressed: isUpdatingLocation || !allTasksRunning ? null : updateLocation,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MEDIUM_SPACE),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Column(
          children: [
            (() {
              if (isUpdatingLocation) {
                return PlatformCircularProgressIndicator();
              }

              if (!allTasksRunning) {
                return PlatformFlavorWidget(
                  material: (_, __) => const Icon(
                    Icons.location_disabled_rounded,
                    size: 42,
                  ),
                  cupertino: (_, __) => const Icon(
                    CupertinoIcons.location_slash_fill,
                    size: 42,
                  ),
                );
              }

              return Icon(
                context.platformIcons.location,
                size: 42,
              );
            })(),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              l10n.quickActions_shareNow,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (isCupertino(context))
          const Expanded(
            child: SizedBox.square(),
          ),
        Expanded(
          flex: 8,
          child: Center(
            child: Text(
              l10n.locationsOverview_activeShares_amount(
                quickShareTasks.length,
              ),
              key: textKey,
              style: getTitle2TextStyle(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (isCupertino(context))
          Expanded(
            child: CupertinoButton(
              onPressed: widget.onOpenActionSheet,
              child: const Icon(CupertinoIcons.ellipsis_circle_fill),
            ),
          ),
      ],
    );
  }

  Widget buildActiveSharesList() {
    return Column(
      key: wrapperKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: MEDIUM_SPACE),
        FutureBuilder<bool>(
          future: getAreSomeTasksRunning(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final isRunning = snapshot.data as bool;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(SMALL_SPACE),
                      child: _buildShareLocationButton(isRunning),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(SMALL_SPACE),
                      child: _buildToggleTasksStatusButton(isRunning),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        ListView.builder(
          itemCount: quickShareTasks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final task = quickShareTasks.elementAt(index);

            return TaskTile(task: task);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isInitializing ? 0 : 1,
      child: PlatformWidget(
        material: (context, _) => AnimatedBuilder(
          animation: offsetProgress,
          builder: (context, child) => Transform.translate(
            offset: Offset(-_xOffset * (1 - offsetProgress.value), 0),
            child: child,
          ),
          child: DraggableScrollableSheet(
            snap: true,
            snapSizes: const [MIN_SIZE, 1],
            minChildSize: 0.0,
            initialChildSize: MIN_SIZE,
            controller: sheetController,
            builder: (context, controller) => ModalSheet(
              miuiIsGapless: true,
              child: SingleChildScrollView(
                controller: controller,
                child: quickShareTasks.isEmpty
                    ? buildEmptyState()
                    : buildActiveSharesList(),
              ),
            ),
          ),
        ),
        cupertino: (context, _) => DraggableScrollableSheet(
          snap: true,
          snapSizes: const [MIN_SIZE, 1],
          minChildSize: 0.0,
          initialChildSize: MIN_SIZE,
          controller: sheetController,
          builder: (context, controller) => AnimatedBuilder(
            animation: offsetProgress,
            child: SingleChildScrollView(
              controller: controller,
              child: quickShareTasks.isEmpty
                  ? buildEmptyState()
                  : buildActiveSharesList(),
            ),
            builder: (context, child) => ModalSheet(
              cupertinoPadding: EdgeInsets.only(
                top: lerpDouble(
                      MEDIUM_SPACE,
                      HUGE_SPACE,
                      offsetProgress.value,
                    ) ??
                    0,
                left: MEDIUM_SPACE,
                right: MEDIUM_SPACE,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
