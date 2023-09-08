import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:locus/services/settings_service/index.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin TaskLinkGenerationMixin {
  BuildContext get context;

  bool get mounted;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      taskLinkGenerationSnackbar;

  Map<TaskLinkPublishProgress?, String> getProgressTextMap() {
    final l10n = AppLocalizations.of(context);

    return {
      TaskLinkPublishProgress.encrypting:
          l10n.taskAction_generateLink_process_encrypting,
      TaskLinkPublishProgress.publishing:
          l10n.taskAction_generateLink_process_publishing,
      TaskLinkPublishProgress.creatingURI:
          l10n.taskAction_generateLink_process_creatingURI,
    };
  }

  Future<String?> shareTask(final Task task) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsService>();

    final url = await task.publisher.generateLink(
      settings.getServerHost(),
      onProgress: (progress) {
        if (taskLinkGenerationSnackbar != null) {
          try {
            taskLinkGenerationSnackbar!.close();
          } catch (e) {
            // ignore
          }
        }

        if (progress != TaskLinkPublishProgress.done && Platform.isAndroid) {
          final scaffold = ScaffoldMessenger.of(context);

          taskLinkGenerationSnackbar = scaffold.showSnackBar(
            SnackBar(
              content: Text(getProgressTextMap()[progress] ?? ""),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.indigoAccent,
            ),
          );
        }
      },
    );

    await Clipboard.setData(ClipboardData(text: url));
    await Share.share(
      url,
      subject: l10n.taskAction_generateLink_shareTextSubject,
    );

    if (!mounted) {
      return null;
    }

    if (isMaterial(context)) {
      final scaffold = ScaffoldMessenger.of(context);

      scaffold.showSnackBar(
        SnackBar(
          content: Text(l10n.linkCopiedToClipboard),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }

    return url;
  }
}
