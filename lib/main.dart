import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/App.dart';
import 'package:locus/services/manager_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final futures = await Future.wait<dynamic>([
    Permission.locationAlways.isGranted,
    TaskService.restore(),
    ViewService.restore(),
    DisableBatteryOptimization.isAllBatteryOptimizationDisabled,
  ]);
  final bool hasLocationAlwaysGranted = futures[0];
  final TaskService taskService = futures[1];
  final ViewService viewService = futures[2];
  final bool isIgnoringBatteryOptimizations = futures[3];

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskService>(create: (_) => taskService),
        ChangeNotifierProvider<ViewService>(create: (_) => viewService),
      ],
      child: App(
        hasLocationAlwaysGranted: hasLocationAlwaysGranted,
        isIgnoringBatteryOptimizations: isIgnoringBatteryOptimizations,
      ),
    ),
  );
}
