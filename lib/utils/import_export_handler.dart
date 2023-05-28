import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<Map<String, dynamic>> exportToJSON(
  final TaskService taskService,
  final ViewService viewService,
  final SettingsService settings,
) async =>
    {
      "version": 1,
      "data": {
        "tasks": await Future.wait(taskService.tasks.map((task) => task.toJSON()).toList()),
        "views": await Future.wait(viewService.views.map((view) => view.toJSON()).toList()),
        "settings": settings.toJSON(),
      }
    };

Future<String> getBluetoothServiceID() async {
  // We use a different service id for each version of the app, so that the user has the same version on both devices
  final packageInfo = await PackageInfo.fromPlatform();

  return "locus-import-export-transfer-${packageInfo.version}";
}
