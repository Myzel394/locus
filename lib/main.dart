import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/themes.dart';
import 'package:locus/screens/InitializationScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return PlatformApp(
        title: 'Locus',
        material: (_, __) => MaterialAppData(
              theme: LIGHT_THEME_MATERIAL,
              darkTheme: DARK_THEME_MATERIAL,
              themeMode: ThemeMode.system,
            ),
        cupertino: (_, __) => CupertinoAppData(
              theme: LIGHT_THEME_CUPERTINO,
            ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          "/": (context) => const InitializationScreen(),
        });
  }
}
