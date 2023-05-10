import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/widgets/SwapElementAnimation.dart';
import 'package:settings_ui/settings_ui.dart';

import '../constants/spacing.dart';

class SettingsColorPickerWidgetRaw extends StatefulWidget {
  final Widget title;
  final Color? value;
  final void Function(Color? value) onUpdate;

  final bool enabled;
  final Widget? leading;
  final Widget? description;

  const SettingsColorPickerWidgetRaw(
      {required this.title,
      required this.value,
      required this.onUpdate,
      required this.enabled,
      this.leading,
      this.description,
      Key? key})
      : super(key: key);

  @override
  State<SettingsColorPickerWidgetRaw> createState() => _SettingsColorPickerWidgetRawState();
}

class _SettingsColorPickerWidgetRawState extends State<SettingsColorPickerWidgetRaw> with TickerProviderStateMixin {
  late final AnimationController controller;
  Animation<Offset>? animation;
  Color? oldColor;
  Color? animationColor;
  Offset? animationPosition;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          animation = null;
          animationColor = null;
          animationPosition = null;
          oldColor = null;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _startAnimation(final Offset offset, final Color color, final Offset position) {
    animation = Tween<Offset>(
      begin: Offset.zero,
      end: offset,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.linearToEaseOut,
      ),
    );

    controller.forward(
      from: 0,
    );

    setState(() {
      oldColor = widget.value;
      animationColor = color;
      animationPosition = position;
    });
  }

  Iterable<Color> getPresetColors(final BuildContext context) {
    if (isCupertino(context)) {
      return [
        CupertinoColors.systemRed,
        CupertinoColors.systemGreen,
        CupertinoColors.systemBlue,
        CupertinoColors.systemOrange,
        CupertinoColors.systemYellow,
        CupertinoColors.systemPink,
        CupertinoColors.systemPurple,
        CupertinoColors.systemTeal,
      ];
    }

    return [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.yellow,
      Colors.pink,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.lime,
    ];
  }

  final selectKey = GlobalKey();
  final positionAnchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final presetColors = getPresetColors(context);

    return SwapElementAnimation<Color?>(
      value: widget.value,
      items: presetColors.toList(),
      builder: (swapElement, renderElement) => SettingsTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.title,
                swapElement,
              ],
            ),
            const SizedBox(height: LARGE_SPACE),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presetColors
                    .mapIndexed(
                      (index, _) => Container(
                        margin: const EdgeInsets.only(right: SMALL_SPACE),
                        child: GestureDetector(
                          onTap: () {
                            widget.onUpdate(presetColors.elementAt(index));
                          },
                          child: renderElement(index),
                        ),
                      ),
                    )
                    .cast<Widget>()
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      elementBuilder: (value, key) => Container(
        key: key,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: oldColor ?? value ?? Colors.black,
          borderRadius: BorderRadius.circular(SMALL_SPACE),
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class SettingsColorPicker extends AbstractSettingsTile {
  final Widget title;
  final Color? value;
  final void Function(Color? value) onUpdate;

  final bool enabled;
  final Widget? leading;
  final Widget? description;

  const SettingsColorPicker({
    required this.title,
    required this.value,
    required this.onUpdate,
    this.enabled = true,
    this.leading,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsColorPickerWidgetRaw(
      title: title,
      value: value,
      onUpdate: onUpdate,
      enabled: enabled,
      leading: leading,
      description: description,
    );
  }
}
