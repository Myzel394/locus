import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';

class LongPressPopupMenuItem<T> {
  final Widget label;
  final IconData? icon;
  final void Function() onPressed;
  final bool isDefaultAction;
  final bool isDestructiveAction;

  const LongPressPopupMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });
}

class LongPressPopup<T> extends StatefulWidget {
  final Widget child;
  final List<LongPressPopupMenuItem> items;

  const LongPressPopup({
    Key? key,
    required this.child,
    required this.items,
  }) : super(key: key);

  @override
  State<LongPressPopup> createState() => _LongPressPopupState<T>();
}

class _LongPressPopupState<T> extends State<LongPressPopup> {
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
            onTap: item.onPressed,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    color: item.isDestructiveAction
                        ? Colors.red
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

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoContextMenu(
        actions: cupertinoActions,
        child: widget.child,
      );
    } else {
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
        onLongPress: () async {
          final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

          await showMenu<int>(
            context: context,
            position: RelativeRect.fromRect(
              Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 10, 10),
              Rect.fromLTWH(0, 0, overlay.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: materialActions,
          );
        },
        child: widget.child,
      );
    }
  }
}
