import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/SwapElementAnimation.dart';
import 'package:settings_ui/settings_ui.dart';

import '../constants/spacing.dart';
import 'PlatformListTile.dart';

class ColorDialogPicker extends StatefulWidget {
  const ColorDialogPicker({Key? key}) : super(key: key);

  @override
  State<ColorDialogPicker> createState() => _ColorDialogPickerState();
}

class _ColorDialogPickerState extends State<ColorDialogPicker> {
  Color? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.settingsScreen_setting_primaryColor_label),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: value ?? Colors.black,
          onColorChanged: (color) {
            setState(() {
              value = color;
            });
          },
          enableAlpha: false,
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text(l10n.closePositiveSheetAction),
          onPressed: () {
            Navigator.of(context).pop(value);
          },
        ),
      ],
    );
  }
}

class SettingsColorPickerWidgetRaw extends StatefulWidget {
  final String title;
  final Color? value;
  final void Function(Color? value) onUpdate;

  final bool enabled;
  final Widget? leading;
  final Widget? description;

  const SettingsColorPickerWidgetRaw({
    required this.title,
    required this.value,
    required this.onUpdate,
    required this.enabled,
    this.leading,
    this.description,
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsColorPickerWidgetRaw> createState() =>
      _SettingsColorPickerWidgetRawState();
}

class _SettingsColorPickerWidgetRawState
    extends State<SettingsColorPickerWidgetRaw> with TickerProviderStateMixin {
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

  Widget buildElement(final Color? value, final GlobalKey key) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presetColors = getPresetColors(context);

    return SwapElementAnimation<Color?>(
      value: widget.value,
      items: presetColors.toList(),
      builder: (swapElement, renderElement) => PlatformListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: widget.leading ?? Container(),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.only(left: SMALL_SPACE),
                    child: Text(
                      widget.title,
                      style: getSubTitleTextStyle(context).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                swapElement,
              ],
            ),
            const SizedBox(height: LARGE_SPACE),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: SMALL_SPACE,
                direction: Axis.horizontal,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                      PlatformTextButton(
                        child: Text(l10n
                            .settingsScreen_setting_primaryColor_systemDefault),
                        onPressed: () {
                          widget.onUpdate(null);
                        },
                      )
                    ] +
                    presetColors
                        .mapIndexed(
                          (index, _) => GestureDetector(
                            onTap: () {
                              widget.onUpdate(presetColors.elementAt(index));
                            },
                            child: renderElement(index),
                          ),
                        )
                        .cast<Widget>()
                        .toList(),
              ),
            ),
          ],
        ),
      ),
      elementBuilder: buildElement,
      swapElementBuilder: (value, key) => GestureDetector(
        onTap: () async {
          final color = await showPlatformDialog(
            context: context,
            builder: (context) => const ColorDialogPicker(),
          );

          if (!mounted) {
            return;
          }

          widget.onUpdate(color);
        },
        child: buildElement(value, key),
      ),
    );
  }
}

class SettingsColorPicker extends AbstractSettingsTile {
  final String title;
  final Color? value;
  final void Function(Color? value) onUpdate;

  final bool enabled;
  final Widget? leading;
  final Widget? description;

  const SettingsColorPicker({
    super.key,
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
