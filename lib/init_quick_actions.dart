import 'dart:ffi';

import 'package:locus/services/task_service.dart';
import 'package:quick_actions/quick_actions.dart';

enum ShortcutType {
  createOneHour,
  shareNow,
}

void initQuickActions() {
  const actions = QuickActions();

  actions.initialize((type) async {
    final taskService = await TaskService.restore();
    await taskService.checkup();

    if (type == ShortcutType.createOneHour.name) {
    } else if (type == ShortcutType.shareNow.name) {
      final tasks = await taskService.getRunningTasks().toList();
      final runners = await Future.wait(
        tasks.map((task) => task.publishCurrentLocationNow()),
      );
    }
  });

  actions.setShortcutItems([
    ShortcutItem(
      type: ShortcutType.createOneHour.name,
      localizedTitle: "Create One-Hour Task",
      icon: "ic_quick_actions_create_one_hour_task",
    ),
    ShortcutItem(
      type: ShortcutType.shareNow.name,
      localizedTitle: "Share current location now",
      icon: "ic_quick_actions_share_now",
    ),
  ]);
}
