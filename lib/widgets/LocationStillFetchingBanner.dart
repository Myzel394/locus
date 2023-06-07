import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants/spacing.dart';

class LocationStillFetchingBanner extends StatelessWidget {
  const LocationStillFetchingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        color: Colors.black.withOpacity(.8),
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
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
        ),
      ),
    );
  }
}
