import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/welcome_screen_widgets/SimpleContinuePage.dart';
import 'package:locus/utils/theme.dart';

class BatteryOptimizationsScreen extends StatefulWidget {
  final void Function() onDone;

  const BatteryOptimizationsScreen({
    required this.onDone,
    Key? key,
  }) : super(key: key);

  @override
  State<BatteryOptimizationsScreen> createState() => _BatteryOptimizationsScreenState();
}

class _BatteryOptimizationsScreenState extends State<BatteryOptimizationsScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);
    final l10n = AppLocalizations.of(context);

    return SimpleContinuePage(
      title: l10n.welcomeScreen_battery_title,
      description: l10n.welcomeScreen_battery_description,
      continueLabel: l10n.welcomeScreen_battery_openSettings,
      header: RotationTransition(
        turns: _animation,
        child: Icon(
          context.platformIcons.settingsSolid,
          size: 120,
          color: shades[0],
        ),
      ),
      onContinue: () async {
        await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
        await DisableBatteryOptimization.showDisableManufacturerBatteryOptimizationSettings(
          l10n.welcomeScreen_battery_disableManufacturerOptimization_title,
          l10n.welcomeScreen_battery_disableManufacturerOptimization_description,
        );
        final isIgnoringBatteryOptimizations =
            await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false;

        if (isIgnoringBatteryOptimizations) {
          widget.onDone();
        }
      },
    );
  }
}
