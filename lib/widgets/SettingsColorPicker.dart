import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/utils/position.dart';
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

    return Stack(
      key: positionAnchorKey,
      children: <Widget>[
        SettingsTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  widget.title,
                  Container(
                    key: selectKey,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: oldColor ?? widget.value ?? Colors.black,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LARGE_SPACE),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presetColors.map((color) {
                    final key = GlobalKey();

                    if (color == widget.value) {
                      // Fake element
                      return Container(
                        width: MEDIUM_SPACE + 30,
                        height: 30,
                      );
                    }

                    return Container(
                      key: key,
                      margin: const EdgeInsets.only(right: MEDIUM_SPACE),
                      child: PlatformInkWell(
                        onTap: () {
                          widget.onUpdate(color);

                          // Get position relative to `anchorKey`
                          final positionAnchor = (positionAnchorKey.currentContext!.findRenderObject() as RenderBox)
                              .localToGlobal(Offset.zero);
                          final offsetAnchor = getPositionTopLeft(positionAnchorKey, selectKey);
                          final position = (key.currentContext!.findRenderObject() as RenderBox)
                              .localToGlobal(Offset.zero)
                              .translate(-positionAnchor.dx, -positionAnchor.dy);
                          final offset = Offset(
                            offsetAnchor.dx - position.dx,
                            offsetAnchor.dy - position.dy,
                          );

                          _startAnimation(offset, color, position);
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          enabled: widget.enabled,
          leading: widget.leading,
          description: widget.description,
        ),
        animationColor == null
            ? SizedBox.shrink()
            : Positioned(
                left: animationPosition!.dx,
                top: animationPosition!.dy,
                child: AnimatedBuilder(
                  animation: animation!,
                  builder: (context, child) => Transform.translate(
                    offset: animation!.value,
                    child: child,
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: animationColor,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              )
      ],
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
