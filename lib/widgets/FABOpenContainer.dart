import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    // Most colors and values here are taken from `floating_action_button.dart`.
    // Normally they _should_ be defined in the theme, but they aren't.
    // That's why we resort to the defaults.
    final theme = Theme.of(context);

    return OpenContainer<T>(
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: onTap,
      closedBuilder: (context, action) =>
          InkWell(
            onTap: action,
            child: Padding(
              // `16.0` is taken from `floating_action_button.dart`.
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onPrimaryContainer,
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
      closedColor: theme.colorScheme.primaryContainer,
    );
  }
}
