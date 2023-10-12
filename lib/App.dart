import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/colors.dart';
import 'package:locus/screens/BiometricsRequiredStartupScreen.dart';
import 'package:locus/screens/LocationsOverviewScreen.dart';
import 'package:locus/screens/WelcomeScreen.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/utils/color.dart';
import 'package:locus/widgets/DismissKeyboard.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'app_wrappers/CheckViewAlarmsLive.dart';
import 'app_wrappers/HandleNotifications.dart';
import 'app_wrappers/InitCurrentLocationFromSettings.dart';
import 'app_wrappers/ManageQuickActions.dart';
import 'app_wrappers/PublishTaskPositionsOnUpdate.dart';
import 'app_wrappers/RegisterBackgroundListeners.dart';
import 'app_wrappers/ShowUpdateDialog.dart';
import 'app_wrappers/UniLinksHandler.dart';
import 'app_wrappers/UpdateLastLocationToSettings.dart';
import 'app_wrappers/UpdateLocaleToSettings.dart';
import 'app_wrappers/UpdateLocationHistory.dart';
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
  const App({
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
                Expanded(
          child: PlatformApp(
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
                if (settings.getAndroidTheme() == AndroidTheme.miui) {
                  return DARK_THEME_MATERIAL_MIUI.copyWith(
                    colorScheme: settings.primaryColor == null
                        ? null
                        : createColorScheme(
                            const ColorScheme.dark(),
                            settings.primaryColor!,
                            Brightness.dark,
                          ),
                    primaryColor: settings.primaryColor,
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            settings.primaryColor ?? MIUI_PRIMARY_COLOR,
                        foregroundColor: Colors.white,
                        splashFactory: NoSplash.splashFactory,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }

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
            builder: (context, child) => Stack(
              children: [
                const UpdateLocationHistory(),
                const UniLinksHandler(),
                const UpdateLastLocationToSettings(),
                const RegisterBackgroundListeners(),
                const UpdateLocaleToSettings(),
                const HandleNotifications(),
                const CheckViewAlarmsLive(),
                const ManageQuickActions(),
                const InitCurrentLocationFromSettings(),
                const ShowUpdateDialog(),
                const PublishTaskPositionsOnUpdate(),
                if (child != null) child,
              ],
            ),
            onGenerateRoute: (routeSettings) {
              final screen = (() {
                if (settings.getRequireBiometricAuthenticationOnStart()) {
                  return const BiometricsRequiredStartupScreen();
                }

                if (!settings.userHasSeenWelcomeScreen) {
                  return const WelcomeScreen();
                }

                return const LocationsOverviewScreen();
              })();

              if (isCupertino(context)) {
                return MaterialWithModalsPageRoute(
                  builder: (_) => screen,
                  settings: routeSettings,
                );
              }

              return NativePageRoute(
                builder: (_) => screen,
                context: context,
              );
            },
          ),
        ),
      ),
    );
  }
}
