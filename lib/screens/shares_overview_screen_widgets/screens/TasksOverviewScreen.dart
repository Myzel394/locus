import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/widgets/AppHint.dart';
import 'package:locus/widgets/ChipCaption.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../TaskTile.dart';
import '../ViewTile.dart';
import '../values.dart';

class TasksOverviewScreen extends StatefulWidget {
  const TasksOverviewScreen({Key? key}) : super(key: key);

  @override
  State<TasksOverviewScreen> createState() => _TasksOverviewScreenState();
}

class _TasksOverviewScreenState extends State<TasksOverviewScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _hintTypeFuture = getHintTypeForMainScreen();
  bool showHint = true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final l10n = AppLocalizations.of(context);
    final taskService = context.watch<TaskService>();
    final viewService = context.watch<ViewService>();
    final settings = context.watch<SettingsService>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: Platform.isAndroid
            ? const EdgeInsets.only(bottom: FAB_DIMENSION)
            : EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FutureBuilder<HintType?>(
              future: _hintTypeFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && settings.getShowHints() && showHint) {
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

                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Wrap(
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
                            l10n.sharesOverviewScreen_tasksSection,
                            icon: Icons.task_rounded,
                          ),
                        ).animate().fadeIn(duration: 1.seconds),
                        ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: MEDIUM_SPACE),
                          physics: const NeverScrollableScrollPhysics(),
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
                                  begin: const Offset(0, 0.2),
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
                        l10n.sharesOverviewScreen_tasksSection,
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
                            l10n.sharesOverviewScreen_viewsSection,
                            icon: context.platformIcons.eyeSolid,
                          ),
                        ).animate().fadeIn(duration: 1.seconds),
                        ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: MEDIUM_SPACE),
                          physics: const NeverScrollableScrollPhysics(),
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
                      header: Text(l10n.sharesOverviewScreen_viewsSection),
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
          ],
        ),
      ),
    );
  }
}
