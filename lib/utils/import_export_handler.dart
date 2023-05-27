import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/view_service.dart';

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
