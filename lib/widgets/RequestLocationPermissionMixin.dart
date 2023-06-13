import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/settings_service.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../utils/theme.dart';

mixin RequestLocationPermissionMixin {
  BuildContext get context;

  bool get mounted;

  Future<bool> showLocationPermissionDialog({
    final bool askForAlways = false,
  }) async {
    final settings = context.read<SettingsService>();
    final permissionStatus = await Geolocator.checkPermission();

    if ((permissionStatus == LocationPermission.always) ||
        (permissionStatus == LocationPermission.whileInUse && !askForAlways)) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final l10n = AppLocalizations.of(context);

    // Ask for permission
    final hasGranted = await showPlatformDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PlatformAlertDialog(
        title: Text(l10n.permissions_location_askPermission_title),
        material: (_, __) => MaterialAlertDialogData(
          icon: settings.isMIUI() ? const Icon(CupertinoIcons.location_fill) : const Icon(Icons.location_on_rounded),
        ),
        content: Text(
          askForAlways
              ? l10n.permissions_location_askPermission_message_always
              : l10n.permissions_location_askPermission_message_whileInUse,
        ),
        actions: createCancellableDialogActions(
          context,
          [
            PlatformDialogAction(
              material: (_, __) => MaterialDialogActionData(
                icon: settings.isMIUI() ? null : const Icon(Icons.check_circle_outline_rounded),
              ),
              child: Text(l10n.permissions_location_askPermission_action_grant_label),
              onPressed: () async {
                final newPermission = await Geolocator.requestPermission();

                if (!context.mounted) {
                  return;
                }

                if ((newPermission == LocationPermission.always) ||
                    (newPermission == LocationPermission.whileInUse && !askForAlways)) {
                  Navigator.of(context).pop(true);
                  return;
                }

                if (newPermission == LocationPermission.denied) {
                  // Like the user cancelled
                  Navigator.of(context).pop("");
                  return;
                }

                final alwaysPermission = await Geolocator.requestPermission();

                if (!context.mounted) {
                  return;
                }

                if (alwaysPermission == LocationPermission.always) {
                  Navigator.of(context).pop(true);
                  return;
                }

                Navigator.of(context).pop(false);
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
        content: Text(l10n.permissions_location_permissionDenied_message),
        actions: createCancellableDialogActions(
          context,
          [
            PlatformDialogAction(
              material: (_, __) => MaterialDialogActionData(
                icon: settings.isMIUI() ? null : const Icon(Icons.settings),
              ),
              child: Text(l10n.permissions_openSettings_label),
              onPressed: () async {
                final openedSettingsSuccessfully = await Geolocator.openAppSettings();

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
          content: Text(l10n.permissions_location_permissionDenied_settingsNotOpened_message),
          actions: [
            PlatformDialogAction(
              child: Text(l10n.closeNeutralAction),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }

    final newPermission = await Geolocator.checkPermission();

    if (newPermission == LocationPermission.always ||
        (newPermission == LocationPermission.whileInUse && !askForAlways)) {
      return true;
    }

    return false;
  }
}
