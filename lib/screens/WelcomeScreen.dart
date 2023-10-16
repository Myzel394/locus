import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/LocationsOverviewScreen.dart';
import 'package:locus/screens/welcome_screen_widgets/SimpleContinuePage.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../utils/theme.dart';

const storage = FlutterSecureStorage();

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _nextScreen(final int page) {
    _controller.animateToPage(
      page,
      duration: 500.ms,
      curve: Curves.easeOutExpo,
    );
  }

  void _onDone() {
    final settings = context.read<SettingsService>();

    settings.setHasSeenWelcomeScreen();

    Navigator.pushAndRemoveUntil(
      context,
      NativePageRoute(
        context: context,
        builder: (context) => const LocationsOverviewScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: PageView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              SimpleContinuePage(
                title: l10n.welcomeScreen_title,
                description: l10n.welcomeScreen_description,
                continueLabel: l10n.welcomeScreen_getStarted,
                header: SvgPicture.asset(
                  "assets/logo.svg",
                  width: 150,
                  height: 150,
                ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: FADE_IN_DURATION,
                    ),
                onContinue: () {
                  _nextScreen(1);
                },
              ),
              SimpleContinuePage(
                title: l10n.welcomeScreen_explanation_title,
                description: l10n.welcomeScreen_explanation_description,
                continueLabel: l10n.welcomeScreen_startLabel,
                header: Lottie.asset(
                  "assets/lotties/lock.json",
                  delegates: LottieDelegates(
                    values: [
                      // wave
                      ValueDelegate.strokeColor(
                        const ["Formebene 1", "Ellipse 1", "Kontur 1"],
                        value: shades[0],
                      ),
                      // Lock
                      ValueDelegate.color(
                        const ["unlock Konturen", "Gruppe 1", "Fläche 1"],
                        value: shades[0],
                      ),
                      // Background
                      ValueDelegate.color(
                        const ["unlock Konturen", "Kreis", "Fläche 1"],
                        value:
                            getIsDarkMode(context) ? shades[900] : shades[200],
                      ),
                    ],
                  ),
                ),
                onContinue: _onDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
