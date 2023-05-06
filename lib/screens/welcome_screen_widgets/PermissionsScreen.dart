import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatelessWidget {
  final void Function() onGranted;

  const PermissionsScreen({
    required this.onGranted,
    Key? key,
  }) : super(key: key);

  Future<PermissionStatus> _checkPermission({bool withoutRequest = false}) async {
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                l10n.welcomeScreen_permissions_title,
                style: getTitleTextStyle(context),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.welcomeScreen_permissions_description,
                style: getBodyTextTextStyle(context),
              ),
              const SizedBox(height: LARGE_SPACE),
              Container(
                constraints: BoxConstraints(
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
            ],
          ),
        ),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: () async {
            final permission = await _checkPermission();
            if (permission.isGranted) {
              onGranted();
            } else {
              await openAppSettings();
            }
          },
          child: Text(l10n.welcomeScreen_permissions_allow),
        ),
      ],
    );
  }
}
