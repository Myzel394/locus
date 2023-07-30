import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'PlatformPopupMenuButton.dart' as popup_menu;

enum PlatformPopupType {
  longPress,
  tap,
}

class PlatformPopupMenuItem<T> {
  final Widget label;
  final IconData? icon;
  final void Function() onPressed;
  final bool isDefaultAction;
  final bool isDestructiveAction;

  const PlatformPopupMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });
}

class PlatformPopup<T> extends StatefulWidget {
  final Widget? child;
  final List<PlatformPopupMenuItem<T>> items;
  final PlatformPopupType type;

  final bool cupertinoCancellable;
  final EdgeInsets? cupertinoButtonPadding;

  const PlatformPopup({
    Key? key,
    this.child,
    required this.items,
    this.type = PlatformPopupType.longPress,
    this.cupertinoCancellable = true,
    this.cupertinoButtonPadding,
  }) : super(key: key);

  @override
  State<PlatformPopup> createState() => _PlatformPopupState<T>();
}

class _PlatformPopupState<T> extends State<PlatformPopup> {
  Widget getChild() => PlatformWidget(
        material: (_, __) =>
            widget.child ?? const Icon(Icons.more_horiz_rounded),
        cupertino: (_, __) =>
            widget.child ?? const Icon(CupertinoIcons.ellipsis_vertical),
      );

  @override
  Widget build(BuildContext context) {
    return popup_menu.PlatformPopupMenuButton<int>(
      cupertinoButtonPadding: widget.cupertinoButtonPadding,
      itemBuilder: (context) => List.from(
        widget.items.mapIndexed(
          (index, item) => popup_menu.PlatformPopupMenuItem<int>(
            value: index,
            child: item.label,
          ),
        ),
      ),
      onSelected: (index) {
        widget.items[index].onPressed();
      },
      child: getChild(),
    );
  }
}
