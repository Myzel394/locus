import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../constants/spacing.dart';

class BluetoothPermissionRequiredScreen extends StatelessWidget {
  final VoidCallback onRequest;

  const BluetoothPermissionRequiredScreen({
    required this.onRequest,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.bluetooth_audio_rounded, size: 60),
        const SizedBox(height: MEDIUM_SPACE),
        Text(l10n.grantBluetoothPermission),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          onPressed: onRequest,
          child: Text(l10n.grantPermission),
        ),
      ],
    );
  }
}
