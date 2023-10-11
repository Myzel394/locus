import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/manager_service/background_locator.dart';
import 'package:locus/services/manager_service/index.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:provider/provider.dart';

class RegisterBackgroundListeners extends StatefulWidget {
  const RegisterBackgroundListeners({super.key});

  @override
  State<RegisterBackgroundListeners> createState() =>
      _RegisterBackgroundListenersState();
}

class _RegisterBackgroundListenersState
    extends State<RegisterBackgroundListeners> {
  late final SettingsService _settings;
  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();

    _settings = context.read<SettingsService>();
    _taskService = context.read<TaskService>();

    _settings.addListener(_updateListeners);
    _taskService.addListener(_updateListeners);

    _updateListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_updateListeners);
    _taskService.removeListener(_updateListeners);

    super.dispose();
  }

  void _updateListeners() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Register Background Listeners",
      "Updating listeners...",
    );
    final shouldCheckLocation = (await _taskService.hasRunningTasks()) ||
        (await _taskService.hasScheduledTasks());

    if (!shouldCheckLocation) {
      FlutterLogs.logInfo(LOG_TAG, "Register Background Listeners",
          "---> but no tasks are running or scheduled, so unregistering everything.");

      await removeBackgroundLocator();
      removeBackgroundFetch();

      return;
    }

    FlutterLogs.logInfo(
      LOG_TAG,
      "Register Background Listeners",
      "Registering BackgroundFetch",
    );

    // Always use background fetch as a fallback
    await configureBackgroundFetch();
    registerBackgroundFetch();

    if (_settings.useRealtimeUpdates) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Register Background Listeners",
        "Should use realtime updates; Registering background locator",
      );

      await configureBackgroundLocator();
      await registerBackgroundLocator(context);
    } else {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Register Background Listeners",
        "Not using realtime updates; Removing background locator",
      );
      removeBackgroundLocator();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
