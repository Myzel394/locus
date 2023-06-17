import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/MapBanner.dart';

import '../constants/spacing.dart';

class LocationStillFetchingBanner extends StatelessWidget {
  const LocationStillFetchingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MapBanner(
      child: Row(
        children: <Widget>[
          PlatformCircularProgressIndicator(),
          const SizedBox(width: SMALL_SPACE),
          Flexible(
            child: Text(
              l10n.locationIsStillFetching,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
