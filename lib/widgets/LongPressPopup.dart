import 'package:flutter/material.dart';

class LongPressPopup<T> extends StatefulWidget {
  final Widget child;
  final List<PopupMenuEntry<T>> items;
  final void Function(T value)? onSelected;

  const LongPressPopup({
    Key? key,
    required this.child,
    required this.items,
    this.onSelected,
  }) : super(key: key);

  @override
  State<LongPressPopup> createState() => _LongPressPopupState<T>();
}

class _LongPressPopupState<T> extends State<LongPressPopup> {
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
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

        final result = await showMenu<T>(
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 10, 10),
            Rect.fromLTWH(0, 0, overlay.paintBounds.size.width, overlay.paintBounds.size.height),
          ),
          items: widget.items as List<PopupMenuEntry<T>>,
        );

        widget.onSelected?.call(result as T);
      },
      child: widget.child,
    );
  }
}
