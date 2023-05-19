import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformSelect<T> extends StatefulWidget {
  final T value;
  final void Function(T?)? onChanged;

  // items
  final List<DropdownMenuItem<T>> items;

  const PlatformSelect({
    required this.value,
    required this.items,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<PlatformSelect<T>> createState() => _PlatformSelectState<T>();
}

class _PlatformSelectState<T> extends State<PlatformSelect<T>> {
  int _selectedIndex = 0;

  Widget get previewChild =>
      widget.items.firstWhere((item) => item.value == widget.value).child;

  @override
  void didUpdateWidget(covariant PlatformSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _selectedIndex =
        widget.items.indexWhere((item) => item.value == widget.value);
  }

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return CupertinoButton(
        child: previewChild,
        onPressed: () async {
          await showCupertinoModalPopup(
            context: context,
            builder: (context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: widget.items,
                ),
              ),
            ),
          );
          widget.onChanged?.call(widget.items[_selectedIndex].value);
        },
      );
    } else {
      return DropdownButton<T>(
        value: widget.value,
        onChanged: widget.onChanged,
        items: widget.items,
        underline: Container(),
        selectedItemBuilder: (context) => widget.items,
      );
    }
  }
}
