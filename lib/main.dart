import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/constants/themes.dart';
import 'package:locus/screens/InitializationSreen.dart';
import 'package:locus/screens/MainScreen.dart';
import 'package:locus/screens/WelcomeScreen.dart';
import 'package:locus/services/manager_service.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final pgpPublicKey = await storage.read(key: "PGP_PUBLIC_KEY");
  final pgpPrivateKey = await storage.read(key: "PGP_PRIVATE_KEY");
  final nostrPrivateKey = await storage.read(key: "NOSTR_PRIVATE_KEY");
  final relays = (await storage.read(key: "RELAYS") ?? "").split(",");

  runApp(MyApp(
    pgpPublicKey: pgpPublicKey,
    pgpPrivateKey: pgpPrivateKey,
    nostrPrivateKey: nostrPrivateKey,
    relays: relays,
  ));
}

class MyApp extends StatelessWidget {
  final String? pgpPublicKey;
  final String? pgpPrivateKey;
  final String? nostrPrivateKey;
  final List<String> relays;

  const MyApp({
    required this.pgpPublicKey,
    required this.pgpPrivateKey,
    required this.nostrPrivateKey,
    required this.relays,
    super.key,
  });

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
        "/": (context) => const WelcomeScreen(),
        "/initialize": (context) => const InitializationScreen(),
        "/home": (context) => MainScreen(
              pgpPublicKey: pgpPublicKey!,
              pgpPrivateKey: pgpPrivateKey!,
              nostrPrivateKey: nostrPrivateKey!,
              relays: relays,
            ),
      },
      initialRoute: pgpPublicKey != null ? "/home" : "/initialize",
    );
  }
}
