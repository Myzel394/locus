import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/MainScreen.dart';
import 'package:locus/screens/WelcomeScreen.dart';
import 'package:locus/widgets/DismissKeyboard.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'constants/spacing.dart';
import 'constants/themes.dart';

class App extends StatelessWidget {
  final bool hasLocationAlwaysGranted;
  final bool isIgnoringBatteryOptimizations;

  const App({
    required this.hasLocationAlwaysGranted,
    required this.isIgnoringBatteryOptimizations,
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: DynamicColorBuilder(
        builder:
            (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) =>
                PlatformApp(
          title: 'Locus',
          material: (_, __) => MaterialAppData(
            theme: lightColorScheme != null
                ? LIGHT_THEME_MATERIAL.copyWith(
                    colorScheme: lightColorScheme,
                    scaffoldBackgroundColor:
                        HSLColor.fromColor(lightColorScheme.background)
                            .withSaturation(0.1)
                            .withLightness(0.92)
                            .toColor(),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                      ),
                    ),
                    dialogBackgroundColor: lightColorScheme.background,
                  )
                : LIGHT_THEME_MATERIAL,
            darkTheme: darkColorScheme != null
                ? DARK_THEME_MATERIAL.copyWith(
                    colorScheme: darkColorScheme,
                    scaffoldBackgroundColor:
                        HSLColor.fromColor(darkColorScheme.background)
                            .withLightness(0.08)
                            .toColor(),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                      ),
                    ),
                    dialogBackgroundColor: darkColorScheme.background,
                  )
                : DARK_THEME_MATERIAL,
            themeMode: ThemeMode.system,
          ),
          cupertino: (_, __) => CupertinoAppData(
            theme: LIGHT_THEME_CUPERTINO,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (settings) {
            final screen =
                hasLocationAlwaysGranted && isIgnoringBatteryOptimizations
                    ? const MainScreen()
                    : WelcomeScreen(
                        hasLocationAlwaysGranted: hasLocationAlwaysGranted,
                        isIgnoringBatteryOptimizations:
                            isIgnoringBatteryOptimizations,
                      );

            return MaterialWithModalsPageRoute(
              builder: (context) => screen,
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}
