import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

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
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              RotationTransition(
                turns: _animation,
                child: Icon(context.platformIcons.settingsSolid, size: 120),
              ),
              const SizedBox(height: HUGE_SPACE),
              Text(
                l10n.welcomeScreen_battery_title,
                style: getTitleTextStyle(context),
              ),
              const SizedBox(height: SMALL_SPACE),
              Text(
                l10n.welcomeScreen_battery_description,
                style: getBodyTextTextStyle(context),
              ),
            ],
          ),
        ),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: () async {
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
          child: Text(l10n.welcomeScreen_battery_openSettings),
        ),
      ],
    );
  }
}
