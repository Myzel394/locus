import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/settings_service.dart';
import 'package:provider/provider.dart';

enum MIUIBehavior {
  usesCupertino,
  usesMaterial,
}

class PlatformFlavorWidget extends StatelessWidget {
  final PlatformBuilder<Widget> material;
  final PlatformBuilder<Widget> cupertino;
  final PlatformBuilder<Widget>? miui;

  final MIUIBehavior miuiBehavior;

  const PlatformFlavorWidget({
    required this.material,
    required this.cupertino,
    this.miui,
    this.miuiBehavior = MIUIBehavior.usesCupertino,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return PlatformWidget(
      material: (context, platform) {
        if (settings.isMIUI()) {
          if (miui != null) {
            return miui!(context, platform);
          }

          if (miuiBehavior == MIUIBehavior.usesCupertino) {
            return cupertino(context, platform);
          }
        }

        return material(context, platform);
      },
      cupertino: cupertino,
    );
  }
}
