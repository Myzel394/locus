import 'dart:convert';

import 'package:locus/api/nostr-events.dart';
import 'package:locus/services/task_service.dart';
import 'package:workmanager/workmanager.dart';

const WORKMANAGER_KEY = "tasks_manager";

void callbackDispatcher() {
  Workmanager().executeTask((taskID, inputData) async {
    final task = await TaskService.getTask(taskID);
    final eventManager = NostrEventsManager.fromTask(task);

    final event = "Hello Wereld!";
    eventManager.publishMessage(jsonEncode(event));

    return Future.value(true);
  });
}
