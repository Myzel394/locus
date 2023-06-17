import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum LogType {
  taskCreated,
  taskDeleted,
  taskStatusChanged,
  updatedLocation,
  alarmCreated,
  alarmDeleted,
}

enum LogInitiator {
  user,
  system,
}

class Log {
  final String id;

  final DateTime createdAt;

  final LogType type;

  final LogInitiator initiator;

  // Arbitrary payload that can be used for specific LogTypes
  final String payload;

  Log({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.initiator,
    required this.payload,
  });

  String getTitle(final BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (type) {
      case LogType.taskCreated:
        return l10n.log_title_taskCreated(createTaskData.name);
      case LogType.taskDeleted:
        return l10n.log_title_taskDeleted(deleteTaskData.name);
      case LogType.taskStatusChanged:
        return l10n.log_title_taskStatusChanged(
          taskStatusChangeData.active.toString(),
          taskStatusChangeData.name,
        );
      case LogType.updatedLocation:
        return l10n.log_title_updatedLocation(updateLocationData.tasks.length);
      case LogType.alarmCreated:
        return l10n.log_title_alarmCreated(createAlarmData.viewName);
      case LogType.alarmDeleted:
        return l10n.log_title_alarmDeleted(deleteAlarmData.viewName);
    }
  }

  factory Log.create({
    required LogType type,
    required LogInitiator initiator,
    String payload = "",
  }) =>
      Log(
        id: uuid.v4(),
        createdAt: DateTime.now(),
        type: type,
        initiator: initiator,
        payload: payload,
      );

  factory Log.createTask({
    required LogInitiator initiator,
    required String taskId,
    required String taskName,
    required TaskCreationContext creationContext,
  }) =>
      Log.create(
        type: LogType.taskCreated,
        initiator: initiator,
        payload: jsonEncode(
          CreateTaskData(
            id: taskId,
            name: taskName,
            creationContext: creationContext,
          ).toJSON(),
        ),
      );

  CreateTaskData get createTaskData {
    if (type != LogType.taskCreated) {
      throw Exception("Log is not of type taskCreated");
    }
    return CreateTaskData.fromJSON(jsonDecode(payload));
  }

  factory Log.deleteTask({
    required LogInitiator initiator,
    // No reference to the id, since it's deleted
    required String taskName,
  }) =>
      Log.create(
        type: LogType.taskDeleted,
        initiator: initiator,
        payload: jsonEncode(
          DeleteTaskData(
            name: taskName,
          ).toJSON(),
        ),
      );

  DeleteTaskData get deleteTaskData {
    if (type != LogType.taskDeleted) {
      throw Exception("Log is not of type taskDeleted");
    }
    return DeleteTaskData.fromJSON(jsonDecode(payload));
  }

  factory Log.taskStatusChanged({
    required LogInitiator initiator,
    required String taskId,
    required String taskName,
    required bool active,
  }) =>
      Log.create(
        type: LogType.taskStatusChanged,
        initiator: initiator,
        payload: jsonEncode(
          TaskStatusChangeData(
            id: taskId,
            name: taskName,
            active: active,
          ).toJSON(),
        ),
      );

  TaskStatusChangeData get taskStatusChangeData {
    if (type != LogType.taskStatusChanged) {
      throw Exception("Log is not of type taskStatusChanged");
    }
    return TaskStatusChangeData.fromJSON(jsonDecode(payload));
  }

  factory Log.updateLocation({
    required LogInitiator initiator,
    required double latitude,
    required double longitude,
    required double accuracy,
    required List<UpdatedTaskData> tasks,
  }) =>
      Log.create(
        type: LogType.updatedLocation,
        initiator: initiator,
        payload: jsonEncode(
          UpdateLocationData(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            tasks: tasks,
          ).toJSON(),
        ),
      );

  UpdateLocationData get updateLocationData {
    if (type != LogType.updatedLocation) {
      throw Exception("Log is not of type updatedLocation");
    }
    return UpdateLocationData.fromJSON(jsonDecode(payload));
  }

  factory Log.deleteAlarm({
    required LogInitiator initiator,
    required String viewID,
    required String viewName,
  }) =>
      Log.create(
        type: LogType.alarmDeleted,
        initiator: initiator,
        payload: jsonEncode(
          DeleteAlarmData(
            viewID: viewID,
            viewName: viewName,
          ).toJSON(),
        ),
      );

  DeleteAlarmData get deleteAlarmData {
    if (type != LogType.alarmDeleted) {
      throw Exception("Log is not of type alarmDeleted");
    }
    return DeleteAlarmData.fromJSON(jsonDecode(payload));
  }

  factory Log.createAlarm({
    required LogInitiator initiator,
    required String viewID,
    required String viewName,
    required String id,
    required LocationAlarmType alarmType,
  }) =>
      Log.create(
        type: LogType.alarmCreated,
        initiator: initiator,
        payload: jsonEncode(
          CreateAlarmData(
            id: id,
            type: alarmType,
            viewID: viewID,
            viewName: viewName,
          ).toJSON(),
        ),
      );

  CreateAlarmData get createAlarmData {
    if (type != LogType.alarmCreated) {
      throw Exception("Log is not of type alarmCreated");
    }
    return CreateAlarmData.fromJSON(jsonDecode(payload));
  }

  factory Log.fromJSON(Map<String, dynamic> json) =>
      Log(
        id: json["i"],
        createdAt: DateTime.parse(json["c"]),
        type: LogType.values[json["t"]],
        initiator: LogInitiator.values[json["o"]],
        payload: json["p"],
      );

  Map<String, dynamic> toJSON() =>
      {
        "i": id,
        "c": createdAt.toIso8601String(),
        "t": type.index,
        "o": initiator.index,
        "p": payload,
      };
}

class UpdatedTaskData {
  final String id;
  final String name;

  const UpdatedTaskData({
    required this.id,
    required this.name,
  });
}

class UpdateLocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final List<UpdatedTaskData> tasks;

  const UpdateLocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.tasks,
  });

  factory UpdateLocationData.fromJSON(Map<String, dynamic> json) =>
      UpdateLocationData(
        latitude: json["a"],
        longitude: json["o"],
        accuracy: json["c"],
        tasks: List<UpdatedTaskData>.from(
          List<Map<String, dynamic>>.from(json["t"]).map(
                (task) =>
                UpdatedTaskData(
                  id: task["i"]!,
                  name: task["n"]!,
                ),
          ),
        ),
      );

  Map<String, dynamic> toJSON() =>
      {
        "o": latitude,
        "a": longitude,
        "c": accuracy,
        "t": List<Map<String, String>>.from(
          tasks.map(
                (task) =>
            {
              "i": task.id,
              "n": task.name,
            },
          ),
        ),
      };
}

enum TaskCreationContext {
  inApp,
  quickAction,
}

class CreateTaskData {
  final String id;
  final String name;
  final TaskCreationContext creationContext;

  const CreateTaskData({
    required this.id,
    required this.name,
    required this.creationContext,
  });

  factory CreateTaskData.fromJSON(Map<String, dynamic> json) =>
      CreateTaskData(
        id: json["i"],
        name: json["n"],
        creationContext: TaskCreationContext.values[json["c"]],
      );

  Map<String, dynamic> toJSON() =>
      {
        "i": id,
        "n": name,
        "c": creationContext.index,
      };

  Task getTask(final TaskService taskService) => taskService.getByID(id);
}

class DeleteTaskData {
  final String name;

  const DeleteTaskData({
    required this.name,
  });

  factory DeleteTaskData.fromJSON(Map<String, dynamic> json) =>
      DeleteTaskData(
        name: json["n"],
      );

  Map<String, dynamic> toJSON() =>
      {
        "n": name,
      };
}

class TaskStatusChangeData {
  final String id;
  final String name;
  final bool active;

  const TaskStatusChangeData({
    required this.id,
    required this.name,
    required this.active,
  });

  factory TaskStatusChangeData.fromJSON(Map<String, dynamic> json) =>
      TaskStatusChangeData(
        id: json["i"],
        name: json["n"],
        active: json["s"],
      );

  Map<String, dynamic> toJSON() =>
      {
        "i": id,
        "n": name,
        "s": active,
      };

  Task getTask(final TaskService taskService) => taskService.getByID(id);
}

class StopTaskData {
  final String id;
  final String name;

  const StopTaskData({
    required this.id,
    required this.name,
  });

  factory StopTaskData.fromJSON(Map<String, dynamic> json) =>
      StopTaskData(
        id: json["i"],
        name: json["n"],
      );

  Map<String, dynamic> toJSON() =>
      {
        "i": id,
        "n": name,
      };

  Task getTask(final TaskService taskService) => taskService.getByID(id);
}

class CreateAlarmData {
  final String id;
  final LocationAlarmType type;
  final String viewID;
  final String viewName;

  const CreateAlarmData({
    required this.id,
    required this.type,
    required this.viewID,
    required this.viewName,
  });

  factory CreateAlarmData.fromJSON(Map<String, dynamic> json) =>
      CreateAlarmData(
        id: json["i"],
        type: LocationAlarmType.values[json["t"]],
        viewID: json["v"],
        viewName: json["n"],
      );

  Map<String, dynamic> toJSON() =>
      {
        "i": id,
        "v": viewID,
        "t": type.index,
        "n": viewName,
      };
}

class DeleteAlarmData {
  final String viewID;
  final String viewName;

  const DeleteAlarmData({
    required this.viewID,
    required this.viewName,
  });

  factory DeleteAlarmData.fromJSON(Map<String, dynamic> json) =>
      DeleteAlarmData(
        viewID: json["v"],
        viewName: json["n"],
      );

  Map<String, dynamic> toJSON() =>
      {
        "v": viewID,
        "n": viewName,
      };
}
