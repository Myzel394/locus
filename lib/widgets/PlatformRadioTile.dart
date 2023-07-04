import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformRadioTile<T> extends StatelessWidget {
  final Widget title;
  final T value;
  final T groupValue;
  final void Function(T?) onChanged;

  const PlatformRadioTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return CupertinoListTile(
        leading: CupertinoRadio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        title: title,
      );
    }

    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: title,
    );
  }
}
