import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/notifications.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/main.dart';
import 'package:locus/screens/ViewDetailsScreen.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HandleNotifications extends StatefulWidget {
  const HandleNotifications({super.key});

  @override
  State<HandleNotifications> createState() => _HandleNotificationsState();
}

class _HandleNotificationsState extends State<HandleNotifications> {
  late final StreamSubscription<NotificationResponse> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        selectedNotificationsStream.stream.listen(_handleNotification);
  }

  @override
  void dispose() {
    _subscription.cancel();

    super.dispose();
  }

  void _handleNotification(final NotificationResponse notification) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Notification",
      "Notification received: ${notification.payload}",
    );

    if (notification.payload == null) {
      FlutterLogs.logWarn(
        LOG_TAG,
        "Notification",
        "----> but no payload, so ignoring.",
      );
      return;
    }

    try {
      final data = jsonDecode(notification.payload!);
      final type = NotificationActionType.values[data["type"]];

      FlutterLogs.logInfo(
          LOG_TAG,
          "Notification",
          "Type is $type."
      );

      switch (type) {
        case NotificationActionType.openTaskView:
          final viewService = context.read<ViewService>();

          Navigator.of(context).push(
            NativePageRoute(
              context: context,
              builder: (_) =>
                  ViewDetailsScreen(
                    view: viewService.getViewById(data["taskViewID"]),
                  ),
            ),
          );
          break;
        case NotificationActionType.openPermissionsSettings:
          openAppSettings();

          break;
      }
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Notification",
        "Error handling notification: $error",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
