import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/color.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

class FABOpenContainer<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final OpenContainerBuilder<T> onTap;

  const FABOpenContainer({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    // Most colors and values here are taken from `floating_action_button.dart`.
    // Normally they _should_ be defined in the theme, but they aren't.
    // That's why we resort to the defaults.
    final theme = Theme.of(context);

    final foreground = (() {
      if (settings.primaryColor != null) {
        final color = createMaterialColor(settings.primaryColor!);
        return getIsDarkMode(context) ? color.shade50 : color.shade900;
      }

      return theme.colorScheme.onPrimaryContainer;
    })();
    final background = (() {
      if (settings.primaryColor != null) {
        final color = createMaterialColor(settings.primaryColor!);
        return getIsDarkMode(context) ? color.shade900 : color.shade50;
      }

      return theme.colorScheme.primaryContainer;
    })();

    return OpenContainer<T>(
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: onTap,
      closedBuilder: (context, action) => InkWell(
        onTap: action,
        child: Padding(
          // `16.0` is taken from `floating_action_button.dart`.
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: foreground,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
      closedElevation: 2.0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(16.0),
        ),
      ),
      openColor: Colors.transparent,
      closedColor: background,
    );
  }
}
