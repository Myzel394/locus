import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:locus/screens/welcome_screen_widgets/SimpleContinuePage.dart';
import 'package:locus/utils/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;

  const NotificationPermissionScreen({
    required this.onGranted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return SimpleContinuePage(
      title: l10n.welcomeScreen_notificationPermission_title,
      description: l10n.welcomeScreen_notificationPermission_description,
      continueLabel: l10n.welcomeScreen_permissions_allow,
      header: Lottie.asset(
        "assets/lotties/notification.json",
        reverse: true,
        frameRate: FrameRate.max,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.strokeColor(
              ["Shape Layer 5", "Ellipse 1", "Stroke 1"],
              value: shades[300],
            ),
            ValueDelegate.strokeColor(
              ["Shape Layer 6", "Shape 1", "Stroke 1"],
              value: shades[700],
            ),
            ValueDelegate.strokeColor(
              ["Shape Layer 6", "Shape 2", "Stroke 1"],
              value: shades[700],
            ),
            ValueDelegate.strokeColor(
              ["Shape Layer 4", "Shape 1", "Stroke 1"],
              value: shades[700],
            ),
            ValueDelegate.strokeColor(
              ["Shape Layer 4", "Shape 2", "Stroke 1"],
              value: shades[700],
            ),
            ValueDelegate.strokeColor(
              ["bell", "Shape 1", "Stroke 1"],
              value: shades[500],
            ),
          ],
        ),
      ),
      onContinue: () async {
        final flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
        final granted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()!
            .requestPermission();

        if (granted == true) {
          onGranted();
          return;
        }

        await openAppSettings();
      },
    );
  }
}
