import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import 'MainScreen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  void _goToMainScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      platformPageRoute(
        context: context,
        builder: (_) => MainScreen(),
      ),
    );
  }

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

    return PlatformScaffold(
      body: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Permission",
                style: getTitleTextStyle(context),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                "We need the permission to access your location in the background in order to store your location history.",
                style: getBodyTextTextStyle(context),
              ),
              const SizedBox(height: LARGE_SPACE),
              Lottie.asset(
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
              const SizedBox(height: LARGE_SPACE),
              PlatformElevatedButton(
                child: Text(
                  "Allow",
                ),
                onPressed: () async {
                  final permission = await _checkPermission();
                  if (permission.isGranted) {
                    _goToMainScreen(context);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
