import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';

class InitializationScreen extends StatelessWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(context.platformIcons.location, size: 80),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              l10n.appName,
              style: getTitleTextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              l10n.initialization_description,
              style: getCaptionTextStyle(context),
            ),
            const SizedBox(height: LARGE_SPACE),
            Wrap(
              direction: Axis.vertical,
              spacing: SMALL_SPACE,
              children: <Widget>[
                Wrap(
                  direction: Axis.horizontal,
                  spacing: MEDIUM_SPACE,
                  children: <Widget>[
                    Icon(context.platformIcons.person),
                    Text(
                      l10n.initialization_explanation_endToEndEncrypted,
                      style: theme.textTheme.bodyText1,
                    ),
                  ],
                ),
                Wrap(
                  direction: Axis.horizontal,
                  spacing: MEDIUM_SPACE,
                  children: <Widget>[
                    Icon(context.platformIcons.share),
                    Text(
                      l10n.initialization_explanation_decentralized,
                      style: theme.textTheme.bodyText1,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: LARGE_SPACE),
            PlatformElevatedButton(
                child: Text(
                  l10n.initialization_continue,
                  style: theme.textTheme.button,
                ),
                // Navigate to "/createKeys
                onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
