import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/SettingsService/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmergencySetupScreen extends StatefulWidget {
  const EmergencySetupScreen({super.key});

  @override
  State<EmergencySetupScreen> createState() => _EmergencySetupScreenState();
}

class _EmergencySetupScreenState extends State<EmergencySetupScreen> {
  bool showHint = true;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();

    settings.addListener(rebuild);
  }

  @override
  void dispose() {
    final settings = context.read<SettingsService>();

    settings.removeListener(rebuild);

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.emergencySetup_title),
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: showHint
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.warning_sharp,
                    color: Colors.yellow,
                    size: 120,
                  ),
                  const SizedBox(height: LARGE_SPACE),
                  Text(l10n.emergencySetup_hint),
                  const SizedBox(height: LARGE_SPACE),
                  PlatformTextButton(
                    onPressed: () {
                      setState(() {
                        showHint = false;
                      });
                    },
                    child: Text(l10n.emergencySetup_hint_understoodLabel),
                  )
                ],
              )
            : SizedBox.shrink(),
      )),
    );
  }
}
