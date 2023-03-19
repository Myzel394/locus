import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              PlatformElevatedButton(
                child: Text(
                  "Allow",
                ),
                onPressed: () async {
                  await Permission.location.request();

                  await Permission.locationAlways.request();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
