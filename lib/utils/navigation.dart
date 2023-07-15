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

/// Pushes a route to the navigator. If the current platform is iOS, it will
/// push a `MaterialWithModalsPageRoute`. If the current platform is Android, it will
/// push a `NativePageRoute`.
Future<dynamic> pushRoute(
  final BuildContext context,
  final Widget Function(BuildContext context) builder,
) {
  if (isCupertino(context)) {
    return Navigator.of(context).push(
      MaterialWithModalsPageRoute(builder: builder),
    );
  } else {
    return Navigator.of(context).push(
      NativePageRoute(
        context: context,
        builder: builder,
      ),
    );
  }
}
