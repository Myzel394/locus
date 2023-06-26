import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/screens/MainScreen.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../utils/PageRoute.dart';

class BiometricsRequiredStartupScreen extends StatefulWidget {
  const BiometricsRequiredStartupScreen({super.key});

  @override
  State<BiometricsRequiredStartupScreen> createState() =>
      _BiometricsRequiredStartupScreenState();
}

class _BiometricsRequiredStartupScreenState
    extends State<BiometricsRequiredStartupScreen> {
  void authenticate() async {
    final l10n = AppLocalizations.of(context);

    final auth = LocalAuthentication();

    try {
      final isValid = await auth.authenticate(
        localizedReason: l10n.biometricsAuthentication_description,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!isValid) {
        return;
      }

      if (!mounted) {
        return;
      }

      const screen = MainScreen();
      Navigator.of(context).pushAndRemoveUntil(
        isCupertino(context)
            ? MaterialWithModalsPageRoute(
                builder: (_) => screen,
              )
            : NativePageRoute(
                builder: (_) => screen,
                context: context,
              ),
        (route) => false,
      );
    } catch (error) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "BiometricsRequiredStartupScreen",
        "Authentication failed: $error",
      );
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.biometricsAuthentication_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                PlatformFlavorWidget(
                  material: (_, __) => const Icon(
                    Icons.lock,
                    size: 120,
                  ),
                  cupertino: (_, __) => const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    size: 120,
                  ),
                ),
                const SizedBox(height: MEDIUM_SPACE),
                Text(
                  l10n.biometricsAuthentication_description,
                  style: getBodyTextTextStyle(context),
                ),
                const SizedBox(height: HUGE_SPACE),
                PlatformElevatedButton(
                  onPressed: authenticate,
                  child: Text(l10n.biometricsAuthentication_action),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
