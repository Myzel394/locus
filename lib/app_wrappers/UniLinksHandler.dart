import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/ImportTaskSheet.dart';
import 'package:uni_links/uni_links.dart';

// l10n
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants/values.dart';

class UniLinksHandler extends StatefulWidget {
  const UniLinksHandler({super.key});

  @override
  State<UniLinksHandler> createState() => _UniLinksHandlerState();
}

class _UniLinksHandlerState extends State<UniLinksHandler> {
  late final StreamSubscription<String?> _stream;

  @override
  void initState() {
    super.initState();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Uni Links",
      "Initiating uni links...",
    );
    _stream = linkStream.listen((final String? link) {
      if (link != null) {
        _importLink(link);
      }
    });

    _initInitialLink();
  }

  @override
  void dispose() {
    _stream.cancel();
    super.dispose();
  }

  Future<void> _importLink(final String url) {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Uni Links",
      "Importing new uni link",
    );

    return showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        isScrollControlled: true,
        isDismissible: true,
        backgroundColor: Colors.transparent,
      ),
      builder: (context) => ImportTaskSheet(initialURL: url),
    );
  }

  void _initInitialLink() async {
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(
      LOG_TAG,
      "Uni Links",
      "Checking initial link",
    );

    try {
      // Only fired when the app was in background
      final initialLink = await getInitialLink();

      if (initialLink == null) {
        FlutterLogs.logInfo(
          LOG_TAG,
          "Uni Links",
          "----> but it is null, so skipping it.",
        );
        return;
      }

      await _importLink(initialLink);
    } on PlatformException catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Uni Links",
        "Error initializing uni links: $error",
      );

      showPlatformDialog(
        context: context,
        builder: (_) => PlatformAlertDialog(
          title: Text(l10n.uniLinksOpenError),
          content: Text(error.message ?? l10n.unknownError),
          actions: [
            PlatformDialogAction(
              child: Text(l10n.closeNeutralAction),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
