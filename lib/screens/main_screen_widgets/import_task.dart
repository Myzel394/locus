import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

class ImportTask extends StatefulWidget {
  const ImportTask({Key? key}) : super(key: key);

  @override
  State<ImportTask> createState() => _ImportTaskState();
}

class _ImportTaskState extends State<ImportTask> with TickerProviderStateMixin {
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
    final topColor3 = HSLColor.fromColor(topColor).withLightness(0.3).toColor();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        VisibilityDetector(
          key: Key("import-task-lottie"),
          onVisibilityChanged: (info) {
            if (info.visibleFraction == 0) {
              _controller.reset();
            } else if (info.visibleFraction == 1) {
              _controller.forward();
            }
          },
          child: Lottie.asset("assets/lotties/url-link.json",
              frameRate: FrameRate.max,
              width: 250,
              controller: _controller,
              delegates: LottieDelegates(values: [
                ValueDelegate.strokeColor(
                  const ["linkTop 3", "Shape 1", "Stroke 1"],
                  value: topColor,
                ),
                ValueDelegate.strokeColor(
                  const ["linkTop 2", "Shape 1", "Stroke 1"],
                  value: topColor2,
                ),
                ValueDelegate.strokeColor(
                  const ["linkTop", "Shape 1", "Stroke 1"],
                  value: topColor3,
                ),
                // `linkBottom 2` coming before `linkBottom 3` is correct (lottie file is probably wrong)
                ValueDelegate.strokeColor(
                  const ["linkBottom 2", "Shape 1", "Stroke 1"],
                  value: topColor,
                ),
                ValueDelegate.strokeColor(
                  const ["linkBottom 3", "Shape 1", "Stroke 1"],
                  value: topColor2,
                ),
                ValueDelegate.strokeColor(
                  const ["linkBottom", "Shape 1", "Stroke 1"],
                  value: topColor3,
                ),
              ]), onLoaded: (composition) {
            _controller.duration = composition.duration;
          }),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          "Import a task",
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: SMALL_SPACE),
        Text(
          "Import a task from a link you have received",
          style: getCaptionTextStyle(context),
        ),
        const SizedBox(height: LARGE_SPACE),
        PlatformElevatedButton(
          child: Text("Import Task"),
          material: (_, __) => MaterialElevatedButtonData(
            icon: Icon(Icons.file_download_outlined),
          ),
        )
      ],
    );
  }
}
