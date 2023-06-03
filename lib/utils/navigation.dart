import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../screens/SettingsScreen.dart';

Future<void> showSettings(final BuildContext context) async {
  if (isCupertino(context)) {
    showCupertinoModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsScreen(),
    );
  } else {
    Navigator.push(
      context,
      NativePageRoute(
        context: context,
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
