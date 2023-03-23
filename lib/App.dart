import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/MainScreen.dart';
import 'package:locus/screens/PermissionsScreen.dart';

import 'constants/spacing.dart';
import 'constants/themes.dart';

class App extends StatelessWidget {
  final bool hasLocationAlwaysGranted;

  const App({
    required this.hasLocationAlwaysGranted,
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) => PlatformApp(
        title: 'Locus',
        material: (_, __) => MaterialAppData(
          theme: lightColorScheme != null
              ? LIGHT_THEME_MATERIAL.copyWith(
                  colorScheme: lightColorScheme,
                  scaffoldBackgroundColor: lightColorScheme.background.withAlpha(200),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                    ),
                  ),
                )
              : LIGHT_THEME_MATERIAL,
          darkTheme: darkColorScheme != null
              ? DARK_THEME_MATERIAL.copyWith(
                  colorScheme: darkColorScheme,
                  scaffoldBackgroundColor: darkColorScheme.background.withAlpha(200),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                    ),
                  ),
                )
              : DARK_THEME_MATERIAL,
          themeMode: ThemeMode.system,
        ),
        cupertino: (_, __) => CupertinoAppData(
          theme: LIGHT_THEME_CUPERTINO,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: (() {
          if (!hasLocationAlwaysGranted) {
            return const PermissionsScreen();
          }

          return const MainScreen();
        })(),
      ),
    );
  }
}
