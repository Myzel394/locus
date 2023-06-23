import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/permission.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/SettingsService/settings_service.dart';
import '../utils/theme.dart';

mixin RequestNotificationPermissionMixin {
  BuildContext get context;

  bool get mounted;

  Future<bool> showNotificationPermissionDialog() async {
    if (await hasGrantedNotificationPermission()) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final notificationsPlugins = FlutterLocalNotificationsPlugin();
    final settings = context.read<SettingsService>();
    final l10n = AppLocalizations.of(context);

    // Ask for permission
    final hasGranted = await showPlatformDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PlatformAlertDialog(
        title: Text(l10n.permissions_notification_askPermission_title),
        material: (_, __) => MaterialAlertDialogData(
          icon: settings.isMIUI()
              ? const Icon(CupertinoIcons.bell_fill)
              : const Icon(Icons.notifications_rounded),
        ),
        content: Text(l10n.permissions_notification_askPermission_message),
        actions: createCancellableDialogActions(
          context,
          [
            PlatformDialogAction(
              material: (_, __) => MaterialDialogActionData(
                icon: settings.isMIUI()
                    ? null
                    : const Icon(Icons.check_circle_outline_rounded),
              ),
              child: Text(
                  l10n.permissions_location_askPermission_action_grant_label),
              onPressed: () async {
                late final bool? success;

                if (Platform.isAndroid) {
                  success = await notificationsPlugins
                      .resolvePlatformSpecificImplementation<
                          AndroidFlutterLocalNotificationsPlugin>()
                      ?.requestPermission();
                } else {
                  success = await notificationsPlugins
                      .resolvePlatformSpecificImplementation<
                          IOSFlutterLocalNotificationsPlugin>()
                      ?.requestPermissions(
                        alert: true,
                        badge: true,
                        sound: true,
                      );
                }

                if (!context.mounted) {
                  return;
                }

                if (success == true) {
                  Navigator.of(context).pop(true);
                  return;
                } else {
                  Navigator.of(context).pop(false);
                  return;
                }
              },
            )
          ],
        ),
      ),
    );

    if (hasGranted == true) {
      return true;
    }

    // Cancel
    if (hasGranted == "") {
      return false;
    }

    if (!mounted) {
      return false;
    }

    // Open app settings
    final settingsResult = await showPlatformDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PlatformAlertDialog(
        material: (_, __) => MaterialAlertDialogData(
          icon: settings.getAndroidTheme() == AndroidTheme.miui
              ? const Icon(CupertinoIcons.exclamationmark_triangle_fill)
              : const Icon(Icons.warning_rounded),
        ),
        title: Text(l10n.permissions_openSettings_failed_title),
        content: Text(l10n.permissions_notification_permissionDenied_message),
        actions: createCancellableDialogActions(
          context,
          [
            PlatformDialogAction(
              material: (_, __) => MaterialDialogActionData(
                icon: settings.isMIUI() ? null : const Icon(Icons.settings),
              ),
              child: Text(l10n.permissions_openSettings_label),
              onPressed: () async {
                final openedSettingsSuccessfully = await openAppSettings();

                if (!context.mounted) {
                  return;
                }

                Navigator.of(context).pop(openedSettingsSuccessfully);
              },
            )
          ],
        ),
      ),
    );

    if (!mounted) {
      return false;
    }

    // Cancel
    if (settingsResult == "") {
      return false;
    }

    // Settings could not be opened
    if (settingsResult == false) {
      await showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlertDialog(
          title: Text(l10n.permissions_openSettings_failed_title),
          content: Text(l10n
              .permissions_notification_permissionDenied_settingsNotOpened_message),
          actions: [
            PlatformDialogAction(
              child: Text(l10n.closeNeutralAction),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }

    return hasGrantedNotificationPermission();
  }
}
