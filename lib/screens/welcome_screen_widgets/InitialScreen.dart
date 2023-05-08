import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

final FADE_IN_DURATION = 500.ms;

class InitialScreen extends StatelessWidget {
  final void Function() onContinue;

  const InitialScreen({
    required this.onContinue,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                "assets/logo.svg",
                width: 150,
                height: 150,
              ).animate().scale(
                    begin: Offset(0, 0),
                    end: Offset(1, 1),
                    duration: FADE_IN_DURATION,
                  ),
              const SizedBox(height: HUGE_SPACE),
              Text(
                l10n.welcomeScreen_title,
                style: getTitleTextStyle(context),
              )
                  .animate()
                  .then(delay: 200.ms)
                  .fadeIn(duration: FADE_IN_DURATION)
                  .slide(begin: Offset(0, 0.5), duration: FADE_IN_DURATION),
              const SizedBox(height: SMALL_SPACE),
              Text(
                l10n.welcomeScreen_description,
                style: getBodyTextTextStyle(context),
              )
                  .animate()
                  .then(delay: 500.ms)
                  .fadeIn(duration: FADE_IN_DURATION)
                  .slide(begin: Offset(0, 0.5), duration: FADE_IN_DURATION),
            ],
          ),
        ),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: onContinue,
          child: Text(l10n.welcomeScreen_getStarted),
        ).animate().then(delay: 800.ms).slide(
              begin: Offset(0, 1),
              end: Offset(0, 0),
              duration: FADE_IN_DURATION,
            ),
      ],
    );
  }
}
