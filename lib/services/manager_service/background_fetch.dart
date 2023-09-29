import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/manager_service/helpers.dart';
import 'package:locus/services/manager_service/task.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Running headless task with ID $taskId",
  );

  if (isTimeout) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Background Fetch",
      "Task $taskId timed out.",
    );

    BackgroundFetch.finish(taskId);
    return;
  }

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Starting headless task with ID $taskId now...",
  );

  await runBackgroundTask();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Starting headless task with ID $taskId now... Done!",
  );

  BackgroundFetch.finish(taskId);
}

Future<void> configureBackgroundFetch() async {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Configuring background fetch...",
  );

  try {
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
        // We only use one taskId to update the location for all tasks,
        // so we don't need to check the taskId.
        await runBackgroundTask();

        BackgroundFetch.finish(taskId);
      },
          (taskId) {
        // Timeout, we need to finish immediately.
        BackgroundFetch.finish(taskId);
      },
    );

    FlutterLogs.logInfo(
      LOG_TAG,
      "Background Fetch",
      "Configuring background fetch. Configuring... Done!",
    );
  } catch (error) {
    FlutterLogs.logError(
      LOG_TAG,
      "Background Fetch",
      "Configuring background fetch. Configuring... Failed! $error",
    );
    return;
  }
}

void registerBackgroundFetch() {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Registering headless task...",
  );

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Registering headless task... Done!",
  );
}

void removeBackgroundFetch() {
  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Removing headless task...",
  );

  BackgroundFetch.stop();

  FlutterLogs.logInfo(
    LOG_TAG,
    "Background Fetch",
    "Removing headless task... Done!",
  );
}
