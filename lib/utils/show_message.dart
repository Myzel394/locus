import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _oldSnackBar;

enum MessageType {
  success,
  error,
}

final Map<MessageType, Color> MESSAGE_TYPE_COLOR_MAP = {
  MessageType.success: Colors.green,
  MessageType.error: Colors.red,
};

Future<void> showMessage(
  final BuildContext context,
  final String message, {
  final MessageType type = MessageType.success,
}) async {
  final l10n = AppLocalizations.of(context);

  if (isMaterial(context)) {
    try {
      _oldSnackBar?.close();
    } catch (_) {
      // Seems to be closed already
    }

    _oldSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MESSAGE_TYPE_COLOR_MAP[type],
      ),
    );
  } else {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text(
              l10n.closeNeutralAction,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
