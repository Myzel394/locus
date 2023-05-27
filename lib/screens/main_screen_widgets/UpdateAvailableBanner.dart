import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/values.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../services/app_update_service.dart';

class UpdateAvailableBanner extends StatelessWidget {
  const UpdateAvailableBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appUpdateService = context.watch<AppUpdateService>();

    if (Platform.isAndroid) {
      return InkWell(
        onTap: appUpdateService.openStoreForUpdate,
        child: ColoredBox(
          color: platformThemeData(
            context,
            material: (data) => Colors.green,
            cupertino: (data) => CupertinoColors.systemGreen.resolveFrom(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.updateAvailable_android,
                ),
                const SizedBox(height: SMALL_SPACE),
                TextButton(
                  onPressed: appUpdateService.doNotShowBannerAgain,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.doNotShowAgainLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
