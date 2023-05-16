import 'package:collection/collection.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart' as Enough;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  const PlatformPopup({
    Key? key,
    this.child,
    required this.items,
    this.type = PlatformPopupType.longPress,
    this.cupertinoCancellable = true,
  }) : super(key: key);

  @override
  State<PlatformPopup> createState() => _PlatformPopupState<T>();
}

class _PlatformPopupState<T> extends State<PlatformPopup> {
  Offset _tapPosition = Offset.zero;

  List<CupertinoActionSheetAction> get cupertinoActions {
    final l10n = AppLocalizations.of(context);

    final items = widget.items
        .map(
          (item) => CupertinoActionSheetAction(
            onPressed: item.onPressed,
            isDefaultAction: item.isDefaultAction,
            isDestructiveAction: item.isDestructiveAction,
            child: item.label,
          ),
        )
        .toList();

    if (widget.cupertinoCancellable) {
      return [
        ...items,
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
      ];
    }

    return items;
  }

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
        Rect.fromLTWH(0, 0, overlay.paintBounds.size.width,
            overlay.paintBounds.size.height),
      ),
      items: materialActions,
    );
  }

  void showCupertinoActionSheet() async {
    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoActionSheet(
        actions: cupertinoActions,
      ),
    );
  }

  Widget getChild() => Padding(
        padding: const EdgeInsets.all(SMALL_SPACE),
        child: PlatformWidget(
          material: (_, __) =>
              widget.child ?? const Icon(Icons.more_horiz_rounded),
          cupertino: (_, __) =>
              widget.child ?? const Icon(CupertinoIcons.ellipsis_vertical),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Enough.PlatformPopupMenuButton(
      itemBuilder: (context) => List.from(
        widget.items.mapIndexed(
          (index, item) => Enough.PlatformPopupMenuItem(
            child: item.label,
            value: index,
          ),
        ),
      ),
      onSelected: (index) {
        final element = widget.items[index as int];

        element.onPressed();
      },
      child: getChild(),
    );
  }
}
