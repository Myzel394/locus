import 'package:background_fetch/background_fetch.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';

const TASK_EXECUTION_KEY = "tasks_manager";
const TASK_SCHEDULE_KEY = "tasks_schedule";

Future<void> updateLocation() async {
  final locationData = await LocationPointService.createUsingCurrentLocation();
  final taskService = await TaskService.restore();
  final runningTasks = taskService.getRunningTasks();

  await for (final task in runningTasks) {
    await task.publishCurrentLocationNow(locationData.copyWithDifferentId());
  }
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  await updateLocation();

  BackgroundFetch.finish(taskId);
}

void configureBackgroundFetch() {
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      requiresCharging: false,
      enableHeadless: true,
      requiredNetworkType: NetworkType.ANY,
      requiresBatteryNotLow: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
      startOnBoot: true,
      stopOnTerminate: false,
    ),
    (taskId) async {
      // We only use one taskId to update the location for all tasks.
      await updateLocation();

      BackgroundFetch.finish(taskId);
    },
    (taskId) {
      // Timeout, we need to finish immediately.
      BackgroundFetch.finish(taskId);
    },
  );
}
