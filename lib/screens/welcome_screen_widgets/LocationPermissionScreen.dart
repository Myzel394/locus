import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<bool> _checkPermission() async {
    final alwaysPermission = await Geolocator.checkPermission();

    // We first need to request locationWhenInUse, because it is required to request locationAlways
    if (alwaysPermission != LocationPermission.always) {
      final whenInUse = await Geolocator.requestPermission();

      if (whenInUse != LocationPermission.whileInUse) {
        return false;
      }

      final always = await Geolocator.requestPermission();

      if (always != LocationPermission.always) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);
    final l10n = AppLocalizations.of(context);

    return SimpleContinuePage(
      title: l10n.welcomeScreen_locationPermission_title,
      description: l10n.welcomeScreen_locationPermission_description,
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
        if (permission) {
          onGranted();
        } else {
          await openAppSettings();
        }
      },
    );
  }
}
