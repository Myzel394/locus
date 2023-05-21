// https://github.com/Enough-Software/enough_platform_widgets/blob/main/lib/src/platform/platform_dialog_action_button.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A platform aware dialog action
class PlatformDialogActionButton extends StatelessWidget {
  final Widget child;
  final Function()? onPressed;
  final bool isDestructiveAction;
  final bool isDefaultAction;

  /// Creates a new platform aware dialog action.
  ///
  /// Translates to a `TextButton` on material and a `CupertinoDialogAction` on cupertino.
  /// Default actions will have bold text but only on cupertino.
  /// Destructive actions will be rendered in red text on cupertino and with a red filled background on material.
  const PlatformDialogActionButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (context, platform) {
        if (isDestructiveAction) {
          return Theme(
            data: Theme.of(context).copyWith(brightness: Brightness.dark),
            child: ButtonTheme(
              buttonColor: Colors.red,
              child: TextButton(
                onPressed: onPressed,
                child: child,
              ),
            ),
          );
        }
        return TextButton(
          onPressed: onPressed,
          child: child,
        );
      },
      cupertino: (context, platform) => CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: isDestructiveAction,
        isDefaultAction: isDefaultAction,
        child: child,
      ),
    );
  }
}
