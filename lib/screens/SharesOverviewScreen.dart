import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/shares_overview_screen_widgets/screens/EmptyScreen.dart';
import 'package:locus/screens/shares_overview_screen_widgets/screens/TasksOverviewScreen.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import 'CreateTaskScreen.dart';
import 'shares_overview_screen_widgets/values.dart';

class SharesOverviewScreen extends StatefulWidget {
  const SharesOverviewScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SharesOverviewScreen> createState() => _SharesOverviewScreenState();
}

class _SharesOverviewScreenState extends State<SharesOverviewScreen> {
  final listViewKey = GlobalKey();
  late final TaskService taskService;
  int activeTab = 0;

  PlatformAppBar? getAppBar() {
    final l10n = AppLocalizations.of(context);

    return PlatformAppBar(
      title: Text(l10n.sharesOverviewScreen_title),
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
        body: const EmptyScreen(),
      );
    }

    return PlatformScaffold(
      material: (_, __) => MaterialScaffoldData(
          floatingActionButton: OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (_, action) => CreateTaskScreen(
          onCreated: () {
            Navigator.pop(context);
          },
        ),
        closedBuilder: (context, action) => InkWell(
          onTap: action,
          child: SizedBox(
            height: FAB_DIMENSION,
            width: FAB_DIMENSION,
            child: Center(
              child: Icon(
                settings.isMIUI() || isCupertino(context)
                    ? CupertinoIcons.plus
                    : Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: settings.isMIUI() ? 34 : 38,
              ),
            ),
          ),
        ),
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        openColor: Colors.transparent,
        closedColor: getIsDarkMode(context)
            ? HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                .withLightness(.15)
                .withSaturation(1)
                .toColor()
            : Theme.of(context).colorScheme.primary,
      ).animate().scale(
              duration: 500.ms, delay: 1.seconds, curve: Curves.bounceOut)),
      cupertino: (_, __) => CupertinoPageScaffoldData(
        backgroundColor: getIsDarkMode(context)
            ? null
            : CupertinoColors.tertiarySystemGroupedBackground
                .resolveFrom(context),
      ),
      appBar: getAppBar(),
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
                  icon: const Icon(CupertinoIcons.list_bullet),
                  label: l10n.sharesOverviewScreen_tasks,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.location_fill),
                  label: l10n.sharesOverviewScreen_createTask,
                ),
              ],
            )
          : null,
      body: activeTab == 0
          ? const TasksOverviewScreen()
          : CreateTaskScreen(
              onCreated: () {
                setState(() {
                  activeTab = 0;
                });
              },
            ),
    );
  }
}
