import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/ModalSheet.dart';

class ServerOriginSheet extends StatefulWidget {
  const ServerOriginSheet({super.key});

  @override
  State<ServerOriginSheet> createState() => _ServerOriginSheetState();
}

class _ServerOriginSheetState extends State<ServerOriginSheet> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: formKey,
      child: ModalSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.settingsScreen_settings_serverOrigin_label,
              style: getTitle2TextStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              l10n.settingsScreen_settings_serverOrigin_description,
              style: getBodyTextTextStyle(context),
            ),
            const SizedBox(height: LARGE_SPACE),
            PlatformTextFormField(
              controller: nameController,
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
              keyboardType: TextInputType.text,
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
            ),
            const SizedBox(height: MEDIUM_SPACE),
            PlatformElevatedButton(
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.check_rounded),
              ),
              padding: const EdgeInsets.symmetric(vertical: MEDIUM_SPACE),
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(context, "https://" + nameController.text);
              },
              child: Text(l10n.closePositiveSheetAction),
            ),
          ],
        ),
      ),
    );
  }
}
