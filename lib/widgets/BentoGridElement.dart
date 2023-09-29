import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/extensions/string.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:provider/provider.dart';

enum BentoType {
  primary,
  secondary,
  tertiary,
  disabled,
}

class BentoGridElement extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final BentoType type;
  final VoidCallback? onTap;

  const BentoGridElement({
    required this.title,
    required this.description,
    required this.icon,
    this.type = BentoType.primary,
    this.onTap,
    super.key,
  });

  @override
  State<BentoGridElement> createState() => _BentoGridElementState();
}

class _BentoGridElementState extends State<BentoGridElement> {
  bool isPressing = false;

  Color getBackgroundColor(final BuildContext context) {
    final settings = context.read<SettingsService>();

    if (settings.primaryColor != null) {
      return settings.primaryColor!.withOpacity(.2);
    }

    return platformThemeData(
      context,
      material: (data) => {
        BentoType.primary: data.colorScheme.primaryContainer,
        BentoType.secondary: data.colorScheme.secondaryContainer,
        BentoType.tertiary: data.colorScheme.tertiaryContainer,
        BentoType.disabled: data.disabledColor,
      }[widget.type]!,
      cupertino: (data) => data.primaryColor.withOpacity(.2),
    );
  }

  Color getTitleColor(final BuildContext context) {
    final settings = context.read<SettingsService>();

    if (settings.primaryColor != null) {
      return settings.primaryColor!;
    }

    return platformThemeData(
      context,
      material: (data) => data.textTheme.bodyLarge!.color!,
      cupertino: (data) => data.textTheme.navTitleTextStyle.color!,
    );
  }

  Color getDescriptionColor(final BuildContext context) {
    return platformThemeData(
      context,
      material: (data) => {
        BentoType.primary: data.textTheme.bodySmall!.color!,
        BentoType.secondary: data.textTheme.bodySmall!.color!,
        BentoType.tertiary: data.textTheme.bodySmall!.color!,
        BentoType.disabled: data.disabledColor,
      }[widget.type]!,
      cupertino: (data) => data.textTheme.navTitleTextStyle.color!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: LARGE_SPACE,
            cornerSmoothing: 1,
          ),
        ),
        color: getBackgroundColor(context),
      ),
      padding: const EdgeInsets.all(MEDIUM_SPACE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.title.capitalize(),
              // Uppercase first letter
              textScaleFactor: 1,
              style: TextStyle(
                color: getTitleColor(context),
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                color: getDescriptionColor(context),
                size: 16,
              ),
              const SizedBox(width: TINY_SPACE),
              Flexible(
                child: Text(
                  widget.description,
                  style: TextStyle(
                    color: getDescriptionColor(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => isPressing = true),
        onTapUp: (_) => setState(() => isPressing = false),
        onTapCancel: () => setState(() => isPressing = false),
        child: AnimatedScale(
          scale: isPressing ? .93 : 1,
          duration: isPressing
              ? const Duration(milliseconds: 60)
              : const Duration(milliseconds: 200),
          child: child,
        ),
      );
    }

    return child;
  }
}
