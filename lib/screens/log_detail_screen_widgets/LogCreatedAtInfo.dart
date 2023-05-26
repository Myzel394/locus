import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/themes.dart';

import '../../constants/spacing.dart';
import '../../models/log.dart';

class LogCreatedInfo extends StatelessWidget {
  final Log log;

  const LogCreatedInfo({
    required this.log,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: <Widget>[
        PlatformWidget(
          material: (_, __) => Icon(
            Icons.access_time_filled_rounded,
            size: Theme.of(context).textTheme.bodySmall!.fontSize,
            color: Theme.of(context).textTheme.bodySmall!.color,
          ),
          cupertino: (_, __) => Icon(
            CupertinoIcons.time,
            size: CUPERTINO_SUBTITLE_FONT_SIZE,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(width: TINY_SPACE),
        Text(l10n.logs_createdAt(log.createdAt)),
      ],
    );
  }
}
