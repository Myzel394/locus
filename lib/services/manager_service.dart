import 'dart:ui';

import 'package:locus/api/nostr-events.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';

const WORKMANAGER_KEY = "tasks_manager";

void callbackDispatcher() {
  Workmanager().executeTask((_, inputData) async {
    try {
      DartPluginRegistrant.ensureInitialized();
      final taskID = inputData!["taskID"]!;

      final task = await TaskService.getTask(taskID);
      final eventManager = NostrEventsManager.fromTask(task);

      final locationPoint = await LocationPointService.createUsingCurrentLocation();
      final message = await locationPoint.toEncryptedMessage(
        signPrivateKey: task.signPGPPrivateKey,
        signPublicKey: task.signPGPPublicKey,
        viewPublicKey: task.viewPGPPublicKey,
      );

      await eventManager.publishMessage(message);
    } catch (error) {
      Logger().e(error.toString());
      throw Exception(error);
    }

    return true;
  });
}
