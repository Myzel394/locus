import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

const LOG_HIVE_BOX = "v1_hive_logs";
const uuid = Uuid();

@HiveType(typeId: 0)
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

@HiveType(typeId: 1)
enum LogInitiator {
  @HiveField(0)
  user,
  @HiveField(1)
  system,
}

@HiveType(typeId: 0)
class Log {
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

  const Log({
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
}
