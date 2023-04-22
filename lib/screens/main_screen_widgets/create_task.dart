import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
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
    final topColor = Theme.of(context).colorScheme.primary;
    final topColor2 = HSLColor.fromColor(topColor).withLightness(0.5).toColor();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        VisibilityDetector(
          key: Key("create-task-lottie"),
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
                value: topColor2,
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 2", "Group 5", "Stroke 1"],
                value: topColor2,
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 4", "Group 3", "Stroke 1"],
                value: topColor,
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 5", "Group 2", "Stroke 1"],
                value: topColor,
              ),
              ValueDelegate.strokeColor(
                const ["list Outlines 6", "Group 1", "Stroke 1"],
                value: topColor,
              ),
            ]),
            onLoaded: (composition) {
              _controller.duration = composition.duration;
            },
          ),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          "No tasks yet",
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: SMALL_SPACE),
        Text(
          "Create a task to get started",
          style: getCaptionTextStyle(context),
        ),
        const SizedBox(height: LARGE_SPACE),
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
    );
  }
}
