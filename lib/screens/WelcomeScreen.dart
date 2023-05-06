import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: PageView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(l10n.welcomeScreen_title,
                    style: getTitleTextStyle(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
}
