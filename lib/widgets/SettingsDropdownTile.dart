import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/widgets/PlatformSelect.dart';
import 'package:settings_ui/settings_ui.dart';

const IN_DURATION = Duration(seconds: 1);
const OUT_DURATION = Duration(milliseconds: 300);

class DropdownTile extends StatefulWidget {
  final Widget title;
  final Iterable values;
  final dynamic value;
  final Map<dynamic, String> textMapping;
  final void Function(dynamic newValue) onUpdate;

  final bool enabled;
  final Widget? leading;
  final Widget? description;

  const DropdownTile({
    Key? key,
    required this.title,
    required this.values,
    required this.value,
    required this.textMapping,
    required this.onUpdate,
    this.enabled = true,
    this.leading,
    this.description,
  }) : super(key: key);

  @override
  State<DropdownTile> createState() => _DropdownTileState();
}

class _DropdownTileState<T> extends State<DropdownTile>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  bool get isExpanding =>
      animation.status == AnimationStatus.forward ||
      animation.status == AnimationStatus.completed;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: IN_DURATION,
      vsync: this,
    );
    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  expand() {
    controller.forward();
  }

  contract() {
    controller.animateBack(
      0.0,
      duration: OUT_DURATION,
      curve: Curves.decelerate,
    );
  }

  toggleContainer() {
    if (isExpanding) {
      contract();
    } else {
      expand();
    }

    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SettingsTile(
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          title: widget.title,
          value: Text(widget.textMapping[widget.value]!),
          trailing: AnimatedRotation(
            duration: kThemeChangeDuration,
            turns: isExpanding ? .5 : 0,
            child: const Icon(Icons.arrow_drop_down),
          ),
          onPressed: (_) => toggleContainer(),
        ),
        SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          child: Column(
            children: widget.values
                .map(
                  (value) => RadioListTile<dynamic>(
                    title: Text(widget.textMapping[value]!),
                    value: value,
                    groupValue: widget.value,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      widget.onUpdate(value);

                      contract();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class SettingsDropdownTile<T> extends AbstractSettingsTile {
  final Widget title;
  final Iterable<T> values;
  final T value;
  final Map<T, String> textMapping;
  final void Function(T newValue) onUpdate;

  final bool enabled;
  final Widget? leading;
  final Widget? description;

  const SettingsDropdownTile({
    Key? key,
    required this.title,
    required this.values,
    required this.value,
    required this.textMapping,
    required this.onUpdate,
    this.enabled = true,
    this.leading,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMaterial(context)) {
      return DropdownTile(
        title: title,
        values: values,
        value: value,
        textMapping: textMapping,
        onUpdate: (value) => onUpdate(value as T),
        enabled: enabled,
        leading: leading,
        description: description,
      );
    } else {
      return SettingsTile(
        title: title,
        description: description,
        leading: leading,
        trailing: PlatformSelect<T>(
          value: value,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            onUpdate(value);
          },
          items: values
              .map(
                (value) => DropdownMenuItem<T>(
                  value: value,
                  child: Center(
                    child: Text(
                      textMapping[value]!,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
  }
}
