import 'dart:ui';

import 'package:locus/api/nostr-events.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';

const TASK_EXECUTION_KEY = "tasks_manager";
const TASK_SCHEDULE_KEY = "tasks_schedule";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    TaskService? taskService;
    Task? task;

    try {
      DartPluginRegistrant.ensureInitialized();

      switch (taskName) {
        case TASK_EXECUTION_KEY:
          final taskID = inputData!["taskID"]!;
          taskService = await TaskService.restore();
          task = taskService.getByID(taskID);

          final eventManager = NostrEventsManager.fromTask(task);

          final locationPoint =
              await LocationPointService.createUsingCurrentLocation();
          final message = await locationPoint.toEncryptedMessage(
            signPrivateKey: task.signPGPPrivateKey,
            signPublicKey: task.signPGPPublicKey,
            viewPublicKey: task.viewPGPPublicKey,
          );

          await eventManager.publishMessage(message);

          if (!task.shouldRunNow()) {
            await task.stopExecutionImmediately();
          }

          break;
        case TASK_SCHEDULE_KEY:
          final taskID = inputData!["taskID"]!;
          final taskService = await TaskService.restore();
          final task = taskService.getByID(taskID);

          task.startExecutionImmediately();
          break;
      }
    } catch (error) {
      Logger().e(error.toString());
      throw Exception(error);
    } finally {
      if (taskService != null) {
        await taskService.checkup();
      }
    }

    return true;
  });
}
