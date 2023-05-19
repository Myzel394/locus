import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

final FADE_IN_DURATION = 500.ms;

class SimpleContinuePage extends StatelessWidget {
  final String title;
  final String description;
  final String continueLabel;
  final void Function() onContinue;
  final Widget header;
  final bool initialAnimations;

  const SimpleContinuePage({
    required this.title,
    required this.description,
    required this.continueLabel,
    required this.onContinue,
    required this.header,
    this.initialAnimations = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: getTitleTextStyle(context),
              )
                  .animate()
                  .then(delay: 200.ms)
                  .fadeIn(duration: FADE_IN_DURATION)
                  .slide(begin: const Offset(0, 0.5), duration: FADE_IN_DURATION),
              header,
              Text(
                description,
                style: getBodyTextTextStyle(context),
              )
                  .animate()
                  .then(delay: 500.ms)
                  .fadeIn(duration: FADE_IN_DURATION)
                  .slide(begin: const Offset(0, 0.5), duration: FADE_IN_DURATION),
            ],
          ),
        ),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: onContinue,
          child: Text(continueLabel),
        ).animate().then(delay: 800.ms).slide(
              begin: const Offset(0, 1),
              end: const Offset(0, 0),
              duration: FADE_IN_DURATION,
            ),
      ],
    );
  }
}
