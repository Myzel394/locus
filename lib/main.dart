import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/App.dart';
import 'package:locus/services/app_update_service.dart';
import 'package:locus/services/log_service.dart';
import 'package:locus/services/manager_service.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/permission.dart';
import 'package:provider/provider.dart';

const storage = FlutterSecureStorage();

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

  final futures = await Future.wait<dynamic>([
    Geolocator.checkPermission(),
    TaskService.restore(),
    ViewService.restore(),
    Platform.isAndroid
        ? DisableBatteryOptimization.isBatteryOptimizationDisabled
        : Future.value(true),
    SettingsService.restore(),
    hasGrantedNotificationPermission(),
    LogService.restore(),
    AppUpdateService.restore(),
  ]);
  final bool hasLocationAlwaysGranted = futures[0] == LocationPermission.always;
  final TaskService taskService = futures[1];
  final ViewService viewService = futures[2];
  final bool isIgnoringBatteryOptimizations = futures[3];
  final SettingsService settingsService = futures[4];
  final bool hasNotificationGranted = futures[5];
  final LogService logService = futures[6];
  final AppUpdateService appUpdateService = futures[7];

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
      child: App(
        hasLocationAlwaysGranted: hasLocationAlwaysGranted,
        hasNotificationGranted: hasNotificationGranted,
        isIgnoringBatteryOptimizations: isIgnoringBatteryOptimizations,
      ),
    ),
  );

  configureBackgroundFetch();
}
