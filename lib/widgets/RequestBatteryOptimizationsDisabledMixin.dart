import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:locus/utils/repeatedly-check.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

mixin RequestBatteryOptimizationsDisabledMixin {
  BuildContext get context;

  bool get mounted;

  Future<bool> showDisableBatteryOptimizationsDialog() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final settings = context.read<SettingsService>();

    final status =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    final autoStart = await DisableBatteryOptimization.isAutoStartEnabled;

    if (status == true && autoStart == true) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final l10n = AppLocalizations.of(context);

    final firstDialogResponse = await showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text(l10n.permissions_batteryOptimizations_askPermission_title),
        content:
            Text(l10n.permissions_batteryOptimizations_askPermission_message),
        material: (_, __) => MaterialAlertDialogData(
          icon: const Icon(Icons.battery_std_rounded),
        ),
        actions: createCancellableDialogActions(
          context,
          [
            PlatformDialogAction(
              material: (_, __) => MaterialDialogActionData(
                icon: settings.isMIUI()
                    ? null
                    : const Icon(Icons.check_circle_outline_rounded),
              ),
              onPressed: () async {
                await DisableBatteryOptimization
                    .showDisableBatteryOptimizationSettings();
                await DisableBatteryOptimization
                    .showDisableManufacturerBatteryOptimizationSettings(
                  l10n.permissions_batteryOptimizations_disableManufacturerOptimization_title,
                  l10n.permissions_batteryOptimizations_disableManufacturerOptimization_message,
                );
                await DisableBatteryOptimization.showEnableAutoStartSettings(
                  l10n.permissions_autoStart_title,
                  l10n.permissions_autoStart_message,
                );

                final isIgnoring = await repeatedlyCheckForSuccess(() async {
                  final isIgnoringBatteryOptimizations =
                      (await DisableBatteryOptimization
                          .isBatteryOptimizationDisabled);
                  final isAutoStartEnabled =
                      (await DisableBatteryOptimization.isAutoStartEnabled);

                  if (isIgnoringBatteryOptimizations == null ||
                      isAutoStartEnabled == null) {
                    return null;
                  }

                  return isIgnoringBatteryOptimizations && isAutoStartEnabled;
                });

                if (!context.mounted) {
                  return;
                }

                if (isIgnoring == true) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text(l10n
                  .permissions_batteryOptimizations_askPermission_action_label),
            )
          ],
        ),
      ),
    );

    // We can't properly determine if the user actually has disabled battery optimization, so we won't show
    // the "Open Settings" dialog
    if (firstDialogResponse == true) {
      return true;
    }

    return false;
  }
}
