import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../constants/spacing.dart';
import '../../constants/themes.dart';
import '../../models/log.dart';

class LogTypeInfo extends StatelessWidget {
  final Log log;

  const LogTypeInfo({
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
      LogType.alarmCreated: l10n.logs_values_alarmCreated,
      LogType.alarmDeleted: l10n.logs_values_alarmDeleted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<LogType, String> typeLocalizationMap = getTypeLocalizationMap(context);

    return Row(
      children: <Widget>[
        PlatformWidget(
          material: (_, __) => Icon(
            Icons.info,
            size: Theme.of(context).textTheme.bodySmall!.fontSize,
            color: Theme.of(context).textTheme.bodySmall!.color,
          ),
          cupertino: (_, __) => Icon(
            CupertinoIcons.info,
            size: CUPERTINO_SUBTITLE_FONT_SIZE,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(width: TINY_SPACE),
        Text(typeLocalizationMap[log.type]!),
      ],
    );
  }
}
