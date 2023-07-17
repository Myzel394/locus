import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/App.dart';
import 'package:locus/services/app_update_service.dart';
import 'package:locus/services/log_service.dart';
import 'package:locus/services/manager_service.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:provider/provider.dart';

const storage = FlutterSecureStorage();

final StreamController<
    NotificationResponse> selectedNotificationsStream = StreamController
    .broadcast();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await FlutterLogs.initLogs(
    logLevelsEnabled: [
      LogLevel.INFO,
      LogLevel.WARNING,
      LogLevel.ERROR,
      LogLevel.SEVERE
    ],
    timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
    directoryStructure: DirectoryStructure.FOR_DATE,
    logTypesEnabled: ["device", "network", "errors"],
    logFileExtension: LogFileExtension.LOG,
    logsWriteDirectoryName: "LocusLogs",
    logsExportDirectoryName: "LocusLogs/Exported",
    debugFileOperations: true,
    isDebuggable: kDebugMode,
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings("ic_launcher_foreground"),
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (notification) {
      selectedNotificationsStream.add(notification);
    },
  );

  final futures = await Future.wait<dynamic>([
    TaskService.restore(),
    ViewService.restore(),
    SettingsService.restore(),
    LogService.restore(),
    AppUpdateService.restore(),
  ]);
  final TaskService taskService = futures[0];
  final ViewService viewService = futures[1];
  final SettingsService settingsService = futures[2];
  final LogService logService = futures[3];
  final AppUpdateService appUpdateService = futures[4];

  await logService.deleteOldLogs();

  appUpdateService.checkForUpdates(force: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskService>(create: (_) => taskService),
        ChangeNotifierProvider<ViewService>(create: (_) => viewService),
        ChangeNotifierProvider<SettingsService>(create: (_) => settingsService),
        ChangeNotifierProvider<LogService>(create: (_) => logService),
        ChangeNotifierProvider<AppUpdateService>(
            create: (_) => appUpdateService),
      ],
      child: const App(),
    ),
  );

  registerBackgroundFetch();
}
