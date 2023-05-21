import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/screens/welcome_screen_widgets/SimpleContinuePage.dart';
import 'package:locus/utils/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionScreen extends StatelessWidget {
  final void Function() onGranted;

  const LocationPermissionScreen({
    required this.onGranted,
    Key? key,
  }) : super(key: key);

  Future<PermissionStatus> _checkPermission(
      {bool withoutRequest = false}) async {
    var alwaysPermission = await Permission.locationAlways.status;

    // We first need to request locationWhenInUse, because it is required to request locationAlways
    if (alwaysPermission.isGranted == false) {
      var whenInUsePermission = await Permission.locationWhenInUse.status;
      if (whenInUsePermission.isGranted == false && !withoutRequest) {
        whenInUsePermission = await Permission.locationWhenInUse.request();
        if (whenInUsePermission.isGranted == false) {
          return whenInUsePermission;
        }
      }
    }

    if (alwaysPermission.isGranted == false && !withoutRequest) {
      alwaysPermission = await Permission.locationAlways.request();

      if (alwaysPermission.isGranted == false) {
        return alwaysPermission;
      }
    }

    return alwaysPermission;
  }

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);
    final l10n = AppLocalizations.of(context);

    return SimpleContinuePage(
      title: l10n.welcomeScreen_permissions_title,
      description: l10n.welcomeScreen_permissions_description,
      continueLabel: l10n.welcomeScreen_permissions_allow,
      header: Container(
        constraints: const BoxConstraints(
          maxWidth: 250,
        ),
        child: Lottie.asset(
          "assets/lotties/location-pointer.json",
          repeat: false,
          frameRate: FrameRate.max,
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(
                ["Path 3306", "Path 3305", "Fill 1"],
                value: shades[0],
              ),
              ValueDelegate.color(
                ["Path 3305", "Path 3305", "Fill 1"],
                value: shades[0],
              )
            ],
          ),
        ),
      ),
      onContinue: () async {
        final permission = await _checkPermission();
        if (permission.isGranted) {
          onGranted();
        } else {
          await openAppSettings();
        }
      },
    );
  }
}
