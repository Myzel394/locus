import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/constants/themes.dart';
import 'package:locus/screens/MainScreen.dart';
import 'package:locus/screens/PermissionsScreen.dart';
import 'package:locus/services/manager_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'constants/spacing.dart';

const storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final hasLocationAlwaysGranted = await Permission.locationAlways.isGranted;
  final taskService = await TaskService.restore();

  runApp(
    ChangeNotifierProvider(
      create: (_) => taskService,
      child: MyApp(
        hasLocationAlwaysGranted: hasLocationAlwaysGranted,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasLocationAlwaysGranted;

  const MyApp({
    required this.hasLocationAlwaysGranted,
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) =>
          PlatformApp(
        title: 'Locus',
        material: (_, __) => MaterialAppData(
          theme: lightColorScheme != null
              ? LIGHT_THEME_MATERIAL.copyWith(
                  colorScheme: lightColorScheme,
                  scaffoldBackgroundColor:
                      lightColorScheme.background.withAlpha(200),
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
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                    ),
                  ),
                  scaffoldBackgroundColor:
                      darkColorScheme.background.withAlpha(200),
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
