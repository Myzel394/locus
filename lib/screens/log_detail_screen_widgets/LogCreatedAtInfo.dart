import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../constants/spacing.dart';
import '../../models/log.dart';

const double _kSubtitleFontSize = 12.0;

class LogCreatedInfo extends StatelessWidget {
  final Log log;

  const LogCreatedInfo({
    required this.log,
    Key? key,
  }) : super(key: key);

  Map<LogType, String> getTypeLocalizationMap(final BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return {
      LogType.taskCreated: l10n.logs_values_taskCreated,
      LogType.taskDeleted: l10n.logs_values_taskDeleted,
      LogType.taskStatusChanged: l10n.logs_values_taskStatusChanged,
      LogType.updatedLocation: l10n.logs_values_updatedLocation,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Map<LogType, String> typeLocalizationMap =
        getTypeLocalizationMap(context);

    return Material(
      color: Colors.transparent,
      child: Row(
        children: <Widget>[
          Text(typeLocalizationMap[log.type]!),
          const SizedBox(width: SMALL_SPACE),
          PlatformWidget(
            material: (_, __) => const Icon(Icons.access_time_filled_rounded),
            cupertino: (_, __) => Icon(
              CupertinoIcons.time,
              size: _kSubtitleFontSize,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 2.0),
          Text(l10n.logs_createdAt(log.createdAt)),
        ],
      ),
    );
  }
}
