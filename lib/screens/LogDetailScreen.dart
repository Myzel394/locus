import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/models/log.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogIcon.dart';
import 'package:locus/utils/theme.dart';

const double _kSubtitleFontSize = 12.0;

class LogDetailScreen extends StatelessWidget {
  final Log log;

  const LogDetailScreen({
    required this.log,
    Key? key,
  }) : super(key: key);

  Map<LogType, String> getTypeLocalizationMap(context) {
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

    return PlatformScaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Hero(
                tag: "icon",
                child: LogIcon(log: log, size: 120),
              ),
              const SizedBox(width: MEDIUM_SPACE),
              Hero(
                tag: "title",
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    log.getTitle(context),
                    style: getTitleTextStyle(context),
                  ),
                ),
              ),
              const SizedBox(width: SMALL_SPACE),
              const SizedBox(width: 2.0),
              Text(l10n.logs_createdAt(log.createdAt)),
              TextButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
