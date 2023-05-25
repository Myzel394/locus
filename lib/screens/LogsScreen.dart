import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:locus/constants/spacing.dart';

import '../constants/hive_keys.dart';
import '../models/log.dart';

const double _kSubtitleFontSize = 12.0;

final Map<LogType, IconData> TYPE_ICON_MAP_MATERIAL = {
  LogType.taskCreated: Icons.add,
  LogType.taskDeleted: Icons.delete,
  LogType.taskStatusChanged: Icons.change_circle_rounded,
  LogType.updatedLocation: Icons.location_on,
};

final Map<LogType, IconData> TYPE_ICON_MAP_CUPERTINO = {
  LogType.taskCreated: CupertinoIcons.add,
  LogType.taskDeleted: CupertinoIcons.delete,
  LogType.taskStatusChanged: CupertinoIcons.arrow_2_circlepath,
  LogType.updatedLocation: CupertinoIcons.location,
};

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  Map<LogType, String> getTypeLocalizationMap() {
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
    final Map<LogType, String> typeLocalizationMap = getTypeLocalizationMap();

    return PlatformScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<Log>(HIVE_KEY_LOGS).listenable(),
            builder: (context, final Box box, _) => ListView.builder(
              itemCount: box.length,
              shrinkWrap: true,
              itemBuilder: (context, final int index) {
                // Reverse
                final Log log = box.getAt(box.length - index - 1)!;
                return PlatformListTile(
                  title: Text(log.getTitle(context)),
                  subtitle: Row(
                    children: <Widget>[
                      Text(typeLocalizationMap[log.type]!),
                      const SizedBox(width: SMALL_SPACE),
                      PlatformWidget(
                        material: (_, __) =>
                            const Icon(Icons.access_time_filled_rounded),
                        cupertino: (_, __) => Icon(
                          CupertinoIcons.time,
                          size: _kSubtitleFontSize,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 2.0),
                      Text(l10n.logs_createdAt(log.createdAt)),
                    ],
                  ),
                  leading: PlatformWidget(
                    material: (_, __) {
                      if (log.type == LogType.taskStatusChanged) {
                        return Icon(
                          log.taskStatusChangeData.active
                              ? Icons.play_arrow
                              : Icons.pause,
                        );
                      }

                      return Icon(
                        TYPE_ICON_MAP_MATERIAL[log.type],
                      );
                    },
                    cupertino: (_, __) {
                      if (log.type == LogType.taskStatusChanged) {
                        return Icon(
                          log.taskStatusChangeData.active
                              ? CupertinoIcons.play
                              : CupertinoIcons.pause,
                        );
                      }

                      return Icon(
                        TYPE_ICON_MAP_CUPERTINO[log.type],
                      );
                    },
                  ),
                  trailing: log.initiator == LogInitiator.system
                      ? PlatformWidget(
                          material: (_, __) => const Icon(
                            Icons.laptop,
                          ),
                          cupertino: (_, __) => const Icon(
                            CupertinoIcons.bolt,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
