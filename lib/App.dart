import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/MainScreen.dart';
import 'package:locus/screens/WelcomeScreen.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/color.dart';
import 'package:locus/widgets/DismissKeyboard.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'constants/themes.dart';

ColorScheme createColorScheme(
  final ColorScheme baseScheme,
  final Color primaryColor,
  final Brightness brightness,
) {
  switch (brightness) {
    case Brightness.dark:
      return baseScheme.copyWith(
        background:
            HSLColor.fromColor(primaryColor).withLightness(0.3).toColor(),
        primary: primaryColor,
        brightness: brightness,
        surface: HSLColor.fromColor(primaryColor).withLightness(0.15).toColor(),
      );
    case Brightness.light:
      return baseScheme.copyWith(
        primary: primaryColor,
        brightness: brightness,
      );
  }
}

class App extends StatelessWidget {
  final bool hasLocationAlwaysGranted;
  final bool hasNotificationGranted;
  final bool isIgnoringBatteryOptimizations;
  final bool isMIUI;

  const App({
    required this.hasLocationAlwaysGranted,
    required this.hasNotificationGranted,
    required this.isIgnoringBatteryOptimizations,
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return DismissKeyboard(
      child: DynamicColorBuilder(
        builder:
            (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) =>
                PlatformApp(
          title: 'Locus',
          material: (_, __) => MaterialAppData(
            theme: (() {
              if (lightColorScheme != null) {
                return LIGHT_THEME_MATERIAL.copyWith(
                  colorScheme: settings.primaryColor == null
                      ? lightColorScheme
                      : createColorScheme(
                          lightColorScheme,
                          settings.primaryColor!,
                          Brightness.light,
                        ),
                  primaryColor:
                      settings.primaryColor ?? lightColorScheme.primary,
                );
              }

              return LIGHT_THEME_MATERIAL.copyWith(
                colorScheme: settings.primaryColor == null
                    ? null
                    : createColorScheme(
                        lightColorScheme ??
                            ColorScheme.fromSwatch(
                              primarySwatch:
                                  createMaterialColor(settings.primaryColor!),
                            ),
                        settings.primaryColor!,
                        Brightness.light,
                      ),
                primaryColor: settings.primaryColor,
              );
            })(),
            darkTheme: (() {
              if (darkColorScheme != null) {
                return DARK_THEME_MATERIAL.copyWith(
                  colorScheme: settings.primaryColor == null
                      ? darkColorScheme
                      : createColorScheme(
                          darkColorScheme,
                          settings.primaryColor!,
                          Brightness.dark,
                        ),
                  primaryColor:
                      settings.primaryColor ?? darkColorScheme.primary,
                  scaffoldBackgroundColor: HSLColor.fromColor(
                          settings.primaryColor ?? darkColorScheme.background)
                      .withLightness(0.08)
                      .toColor(),
                  dialogBackgroundColor: settings.primaryColor == null
                      ? darkColorScheme.background
                      : HSLColor.fromColor(settings.primaryColor!)
                          .withLightness(0.15)
                          .toColor(),
                  inputDecorationTheme:
                      DARK_THEME_MATERIAL.inputDecorationTheme.copyWith(
                    fillColor: settings.primaryColor == null
                        ? null
                        : HSLColor.fromColor(settings.primaryColor!)
                            .withLightness(0.3)
                            .withSaturation(.5)
                            .toColor(),
                  ),
                );
              }

              return DARK_THEME_MATERIAL.copyWith(
                colorScheme: settings.primaryColor == null
                    ? null
                    : createColorScheme(
                        const ColorScheme.dark(),
                        settings.primaryColor!,
                        Brightness.dark,
                      ),
                primaryColor: settings.primaryColor,
                scaffoldBackgroundColor: settings.primaryColor == null
                    ? null
                    : HSLColor.fromColor(settings.primaryColor!)
                        .withLightness(0.08)
                        .toColor(),
                dialogBackgroundColor: settings.primaryColor == null
                    ? null
                    : HSLColor.fromColor(settings.primaryColor!)
                        .withLightness(0.15)
                        .toColor(),
                inputDecorationTheme:
                    DARK_THEME_MATERIAL.inputDecorationTheme.copyWith(
                  fillColor: settings.primaryColor == null
                      ? null
                      : HSLColor.fromColor(settings.primaryColor!)
                          .withLightness(0.3)
                          .withSaturation(.5)
                          .toColor(),
                ),
              );
            })(),
            themeMode: ThemeMode.system,
          ),
          cupertino: (_, __) => CupertinoAppData(
            theme: settings.primaryColor == null
                ? LIGHT_THEME_CUPERTINO
                : LIGHT_THEME_CUPERTINO.copyWith(
                    primaryColor: settings.primaryColor,
                  ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (settings) {
            final screen = hasLocationAlwaysGranted &&
                    isIgnoringBatteryOptimizations &&
                    hasNotificationGranted
                ? const MainScreen()
                : WelcomeScreen(
                    hasLocationAlwaysGranted: hasLocationAlwaysGranted,
                    hasNotificationGranted: hasNotificationGranted,
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
