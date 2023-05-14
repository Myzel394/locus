import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';

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

  const PlatformPopup({
    Key? key,
    this.child,
    required this.items,
    this.type = PlatformPopupType.longPress,
  }) : super(key: key);

  @override
  State<PlatformPopup> createState() => _PlatformPopupState<T>();
}

class _PlatformPopupState<T> extends State<PlatformPopup> {
  Offset _tapPosition = Offset.zero;

  List<CupertinoContextMenuAction> get cupertinoActions => widget.items
      .map(
        (item) => CupertinoContextMenuAction(
          trailingIcon: item.icon,
          onPressed: () {
            Navigator.pop(context);
            item.onPressed();
          },
          isDefaultAction: item.isDefaultAction,
          isDestructiveAction: item.isDestructiveAction,
          child: item.label,
        ),
      )
      .toList();

  List<PopupMenuItem<int>> get materialActions => List<PopupMenuItem<int>>.from(
        widget.items.mapIndexed(
          (index, item) => PopupMenuItem(
            value: index,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    color: item.isDestructiveAction
                        ? getErrorColor(context)
                        : item.isDefaultAction
                            ? Colors.blue
                            : null,
                  ),
                  const SizedBox(width: TINY_SPACE),
                ],
                item.label,
              ],
            ),
          ),
        ),
      );

  void showMaterialPopupMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 10, 10),
        Rect.fromLTWH(0, 0, overlay.paintBounds.size.width, overlay.paintBounds.size.height),
      ),
      items: materialActions,
    );
  }

  void showCupertinoActionSheet() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: cupertinoActions,
      ),
    );
  }

  Widget getChild() => Padding(
        padding: const EdgeInsets.all(SMALL_SPACE),
        child: PlatformWidget(
          material: (_, __) => widget.child ?? const Icon(Icons.more_horiz_rounded),
          cupertino: (_, __) => widget.child ?? const Icon(CupertinoIcons.ellipsis_vertical),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return GestureDetector(
        onTap: widget.type == PlatformPopupType.tap ? showCupertinoActionSheet : null,
        onLongPress: widget.type == PlatformPopupType.longPress ? showCupertinoActionSheet : null,
        child: getChild(),
      );
    } else {
      switch (widget.type) {
        case PlatformPopupType.longPress:
          return GestureDetector(
            onTapDown: (position) {
              final renderBox = context.findRenderObject() as RenderBox;
              final offset = renderBox.globalToLocal(position.globalPosition);

              // Change dy to globalPosition
              final newOffset = Offset(
                offset.dx,
                position.globalPosition.dy,
              );

              setState(() {
                _tapPosition = newOffset;
              });
            },
            onLongPress: showMaterialPopupMenu,
            child: getChild(),
          );
        case PlatformPopupType.tap:
          return PopupMenuButton(
            itemBuilder: (_) => materialActions,
            child: getChild(),
            onSelected: (index) => widget.items[index].onPressed(),
          );
      }
    }
  }
}