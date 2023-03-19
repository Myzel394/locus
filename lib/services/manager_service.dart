import 'package:workmanager/workmanager.dart';

const WORKMANAGER_KEY = "tasks_manager";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background Isolate Callback: task ($task)");
    return Future.value(true);
  });
}
