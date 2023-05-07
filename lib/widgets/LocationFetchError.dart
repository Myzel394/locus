import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';

import '../utils/theme.dart';

class LocationFetchError extends StatelessWidget {
  const LocationFetchError({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Text(
            l10n.locationFetchError,
            style: getBodyTextTextStyle(context).copyWith(
              color: getErrorColor(context),
            ),
          ),
        ),
      ),
    );
  }
}
