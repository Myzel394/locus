import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/api/get-locus-verification.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/locus-verification.dart';
import 'package:locus/utils/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/ModalSheetContent.dart';

import '../../constants/values.dart';
import '../../widgets/ModalSheet.dart';

class ServerOriginSheet extends StatefulWidget {
  const ServerOriginSheet({super.key});

  @override
  State<ServerOriginSheet> createState() => _ServerOriginSheetState();
}

class _ServerOriginSheetState extends State<ServerOriginSheet> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  bool isLoading = false;
  bool isInvalid = false;
  bool isError = false;

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  Future<void> checkServerOrigin() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        isInvalid = false;
        isError = false;
      });

      FlutterLogs.logInfo(
        LOG_TAG,
        "Server Origin",
        "Checking server origin.",
      );

      final origin = "https://" + nameController.text;

      try {
        final isOriginValid = await verifyServerOrigin(origin);

        if (!mounted) {
          return;
        }

        if (isOriginValid) {
          FlutterLogs.logInfo(
            LOG_TAG,
            "Server Origin",
            "Server origin is valid.",
          );

          Navigator.of(context).pop(origin);
        } else {
          FlutterLogs.logError(
            LOG_TAG,
            "Server Origin",
            "Server origin is invalid.",
          );

          setState(() {
            isInvalid = true;
          });
        }
      } catch (error) {
        FlutterLogs.logError(
          LOG_TAG,
          "Server Origin",
          "Failed to check server origin: $error",
        );

        setState(() {
          isError = true;
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: formKey,
      child: ModalSheet(
        child: ModalSheetContent(
          title: l10n.settingsScreen_settings_serverOrigin_label,
          description: l10n.settingsScreen_settings_serverOrigin_description,
          submitLabel: l10n.closePositiveSheetAction,
          onSubmit: isLoading ? null : checkServerOrigin,
          children: [
            PlatformTextFormField(
              controller: nameController,
              enabled: !isLoading,
              material: (_, __) => MaterialTextFormFieldData(
                decoration: InputDecoration(
                  labelText: l10n.settingsScreen_settings_serverOrigin_label,
                  hintText: l10n.settingsScreen_settings_serverOrigin_hint,
                  prefixText: "https://",
                ),
              ),
              cupertino: (_, __) => CupertinoTextFormFieldData(
                placeholder: l10n.settingsScreen_settings_serverOrigin_hint,
                prefix: const Text("https://"),
              ),
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.url],
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fields_errors_isEmpty;
                }

                if (Uri.tryParse(value) == null) {
                  return l10n
                      .settingsScreen_settings_serverOrigin_error_invalid;
                }

                return null;
              },
              onEditingComplete: checkServerOrigin,
            ),
            if (isLoading) ...[
              const SizedBox(height: MEDIUM_SPACE),
              const Center(
                child: LinearProgressIndicator(),
              ),
            ],
            if (isInvalid) ...[
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.settingsScreen_settings_serverOrigin_error_serverInvalid,
                style: getBodyTextTextStyle(context).copyWith(
                  color: getErrorColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (isError) ...[
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.unknownError,
                style: getBodyTextTextStyle(context).copyWith(
                  color: getErrorColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
