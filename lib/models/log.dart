import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:locus/services/task_service.dart';
import 'package:uuid/uuid.dart';

part 'log.g.dart';

const LOG_HIVE_BOX = "v1_hive_logs";
const uuid = Uuid();

@HiveType(typeId: 1)
enum LogType {
  @HiveField(0)
  taskCreated,
  @HiveField(1)
  taskDeleted,
  @HiveField(2)
  taskStarted,
  @HiveField(3)
  taskStopped,
  @HiveField(4)
  updatedLocation,
}

@HiveType(typeId: 2)
enum LogInitiator {
  @HiveField(0)
  user,
  @HiveField(1)
  system,
}

@HiveType(typeId: 3)
class Log extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final LogType type;

  @HiveField(3)
  final LogInitiator initiator;

  @HiveField(4)
  // Arbitrary payload that can be used for specific LogTypes
  final String payload;

  Log({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.initiator,
    required this.payload,
  });

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
  }) =>
      Log.create(
        type: LogType.taskCreated,
        initiator: initiator,
        payload: jsonEncode(
          CreateTaskData(
            id: taskId,
            name: taskName,
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
    // No reference to the id, since its deleted
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

  factory Log.startTask({
    required LogInitiator initiator,
    required String taskId,
    required String taskName,
  }) =>
      Log.create(
        type: LogType.taskStarted,
        initiator: initiator,
        payload: jsonEncode(
          StartTaskData(
            id: taskId,
            name: taskName,
          ).toJSON(),
        ),
      );

  StartTaskData get startTaskData {
    if (type != LogType.taskStarted) {
      throw Exception("Log is not of type taskStarted");
    }
    return StartTaskData.fromJSON(jsonDecode(payload));
  }

  factory Log.stopTask({
    required LogInitiator initiator,
    required String taskId,
    required String taskName,
  }) =>
      Log.create(
        type: LogType.taskStopped,
        initiator: initiator,
        payload: jsonEncode(
          StopTaskData(
            id: taskId,
            name: taskName,
          ).toJSON(),
        ),
      );

  StopTaskData get stopTaskData {
    if (type != LogType.taskStopped) {
      throw Exception("Log is not of type taskStopped");
    }
    return StopTaskData.fromJSON(jsonDecode(payload));
  }

  factory Log.updateLocation({
    required LogInitiator initiator,
    required String taskId,
    required String taskName,
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
          List<Map<String, String>>.from(json["t"]).map(
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

class CreateTaskData {
  final String id;
  final String name;

  const CreateTaskData({
    required this.id,
    required this.name,
  });

  factory CreateTaskData.fromJSON(Map<String, dynamic> json) =>
      CreateTaskData(
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

class StartTaskData {
  final String id;
  final String name;

  const StartTaskData({
    required this.id,
    required this.name,
  });

  factory StartTaskData.fromJSON(Map<String, dynamic> json) =>
      StartTaskData(
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