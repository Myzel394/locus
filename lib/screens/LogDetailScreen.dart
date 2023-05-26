import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/models/log.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogIcon.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogTypeInfo.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';

import '../constants/themes.dart';
import 'log_detail_screen_widgets/LogCreatedAtInfo.dart';

final FADE_IN_DURATION = 900.ms;
final DELAY_DURATION = 100.ms;

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
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          SafeArea(
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
                                  tag: "${log.id}:type",
                                  child: Material(
                                    color: Colors.transparent,
                                    child: LogTypeInfo(log: log),
                                  ),
                                ),
                                const SizedBox(height: SMALL_SPACE),
                                Hero(
                                  tag: "${log.id}:createdAt",
                                  child: Material(
                                    color: Colors.transparent,
                                    child: LogCreatedInfo(log: log),
                                  ),
                                ),
                                if (log.type == LogType.taskCreated) ...[
                                  const SizedBox(height: SMALL_SPACE),
                                  Row(
                                    children: <Widget>[
                                      PlatformWidget(
                                        material: (_, __) => Icon(
                                          Icons.edit,
                                          size: Theme.of(context).textTheme.bodySmall!.fontSize,
                                          color: Theme.of(context).textTheme.bodySmall!.color,
                                        ),
                                        cupertino: (_, __) => Icon(
                                          CupertinoIcons.pencil,
                                          size: CUPERTINO_SUBTITLE_FONT_SIZE,
                                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                        ),
                                      ),
                                      const SizedBox(width: TINY_SPACE),
                                      Text(
                                        l10n.logs_task_creationContext_description(
                                          log.createTaskData.creationContext.name,
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(duration: FADE_IN_DURATION, delay: DELAY_DURATION),
                                ],
                                if (log.initiator == LogInitiator.system) ...[
                                  const SizedBox(height: SMALL_SPACE),
                                  Row(
                                    children: <Widget>[
                                      Hero(
                                        tag: "${log.id}:initiator",
                                        child: PlatformWidget(
                                          material: (_, __) => Icon(
                                            Icons.laptop,
                                            size: Theme.of(context).textTheme.bodySmall!.fontSize,
                                            color: Theme.of(context).textTheme.bodySmall!.color,
                                          ),
                                          cupertino: (_, __) => Icon(
                                            CupertinoIcons.bolt,
                                            size: CUPERTINO_SUBTITLE_FONT_SIZE,
                                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: TINY_SPACE),
                                      Text(l10n.logs_system_initiator_description)
                                          .animate()
                                          .fadeIn(duration: FADE_IN_DURATION, delay: DELAY_DURATION),
                                    ],
                                  ),
                                ],
                                TextButton(
                                  child: Text(l10n.closeNeutralAction),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ).animate().fadeIn(duration: FADE_IN_DURATION, delay: DELAY_DURATION),
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
        ],
      ),
    );
  }
}
