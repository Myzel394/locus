import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/models/log.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogIcon.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';

import 'log_detail_screen_widgets/LogCreatedAtInfo.dart';

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
    final Map<LogType, String> typeLocalizationMap = getTypeLocalizationMap(context);

    return PlatformScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 800,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Hero(
                          tag: "${log.id}:paper",
                          child: Material(
                            color: Colors.transparent,
                            child: Paper(
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(MEDIUM_SPACE),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Hero(
                              tag: "${log.id}:icon",
                              child: LogIcon(log: log, size: 60),
                            ),
                            Hero(
                              tag: "${log.id}:title",
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  log.getTitle(context),
                                  style: getTitle2TextStyle(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: MEDIUM_SPACE),
                            Hero(
                              tag: "${log.id}:info",
                              child: Material(
                                color: Colors.transparent,
                                child: LogCreatedInfo(log: log),
                              ),
                            ),
                            TextButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
