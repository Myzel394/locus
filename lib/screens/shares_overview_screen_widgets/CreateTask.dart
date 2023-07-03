import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';
import '../CreateTaskScreen.dart';

class CreateTask extends StatefulWidget {
  const CreateTask({Key? key}) : super(key: key);

  @override
  State<CreateTask> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        VisibilityDetector(
          key: const Key("create-task-lottie"),
          onVisibilityChanged: (info) {
            if (info.visibleFraction == 0) {
              _controller.reset();
            } else if (info.visibleFraction == 1) {
              _controller.forward();
            }
          },
          child: Lottie.asset(
            "assets/lotties/task.json",
            controller: _controller,
            width: 250,
            frameRate: FrameRate.max,
            delegates: LottieDelegates(values: [
              ValueDelegate.strokeColor(
                const ["list Outlines 3", "Group 4", "Stroke 1"],
                value: shades[0],
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 2", "Group 5", "Stroke 1"],
                value: shades[0],
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 4", "Group 3", "Stroke 1"],
                value: shades[0],
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 5", "Group 2", "Stroke 1"],
                value: shades[0],
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 6", "Group 1", "Stroke 1"],
                value: shades[0],
              ),
            ]),
            onLoaded: (composition) {
              _controller.duration = composition.duration;
            },
          ),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          l10n.mainScreen_createTask_tasksEmpty,
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: SMALL_SPACE),
        Text(
          l10n.mainScreen_createTask_description,
          style: getCaptionTextStyle(context),
        ),
        const SizedBox(height: LARGE_SPACE),
        OpenContainer(
          transitionDuration: const Duration(milliseconds: 700),
          transitionType: ContainerTransitionType.fade,
          openBuilder: (context, action) => CreateTaskScreen(
            onCreated: () {
              Navigator.pop(context);
            },
          ),
          closedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(HUGE_SPACE),
            ),
          ),
          closedBuilder: (context, action) => GestureDetector(
            onTap: () {
              _controller.reverseDuration = const Duration(milliseconds: 150);
              _controller.reverse();

              action();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MEDIUM_SPACE,
                vertical: SMALL_SPACE,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.add,
                    color: getButtonTextColor(context),
                  ),
                  const SizedBox(width: SMALL_SPACE),
                  Text(
                    l10n.mainScreen_createTask_action_create,
                    style: TextStyle(
                      color: getButtonTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          openColor: Theme.of(context).scaffoldBackgroundColor,
          closedColor: getButtonBackgroundColor(context),
        ),
      ],
    );
  }
}