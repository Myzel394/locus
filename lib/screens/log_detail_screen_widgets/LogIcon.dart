import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../models/log.dart';

final Map<LogType, IconData> TYPE_ICON_MAP_MATERIAL = {
  LogType.taskCreated: Icons.add,
  LogType.taskDeleted: Icons.delete,
  LogType.taskStatusChanged: Icons.change_circle_rounded,
  LogType.updatedLocation: Icons.location_on,
  LogType.alarmCreated: Icons.alarm,
  LogType.alarmDeleted: Icons.alarm_off_rounded,
};

final Map<LogType, IconData> TYPE_ICON_MAP_CUPERTINO = {
  LogType.taskCreated: CupertinoIcons.add,
  LogType.taskDeleted: CupertinoIcons.delete,
  LogType.taskStatusChanged: CupertinoIcons.arrow_2_circlepath,
  LogType.updatedLocation: CupertinoIcons.location,
  LogType.alarmCreated: CupertinoIcons.alarm,
  LogType.alarmDeleted: Icons.alarm_off,
};

class LogIcon extends StatelessWidget {
  final Log log;
  final double? size;

  const LogIcon({
    required this.log,
    this.size,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, __) {
        if (log.type == LogType.taskStatusChanged) {
          return Icon(
            log.taskStatusChangeData.active ? Icons.play_arrow : Icons.pause,
            size: size,
          );
        }

        return Icon(
          TYPE_ICON_MAP_MATERIAL[log.type],
          size: size,
        );
      },
      cupertino: (_, __) {
        if (log.type == LogType.taskStatusChanged) {
          return Icon(
            log.taskStatusChangeData.active ? CupertinoIcons.play : CupertinoIcons.pause,
            size: size,
          );
        }

        return Icon(
          TYPE_ICON_MAP_CUPERTINO[log.type],
          size: size,
        );
      },
    );
  }
}
