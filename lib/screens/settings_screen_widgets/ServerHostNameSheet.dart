import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/ModalSheet.dart';

class ServerHostNameSheet extends StatefulWidget {
  const ServerHostNameSheet({super.key});

  @override
  State<ServerHostNameSheet> createState() => _ServerHostNameSheetState();
}

class _ServerHostNameSheetState extends State<ServerHostNameSheet> {
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
          children: <Widget>[
            Text(
              l10n.settingsScreen_settings_serverHostName_label,
              style: getTitle2TextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              l10n.settingsScreen_settings_serverHostName_description,
              style: getBodyTextTextStyle(context),
            ),
            const SizedBox(height: LARGE_SPACE),
            PlatformTextFormField(
              controller: nameController,
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
                      .settingsScreen_settings_serverHostName_error_invalid;
                }

                return null;
              },
            ),
            const SizedBox(height: MEDIUM_SPACE),
            PlatformElevatedButton(
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.check_rounded),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final uri = Uri.parse(nameController.text);
                  Navigator.pop(context, uri.host);
                }
              },
              child: Text(l10n.closePositiveSheetAction),
            ),
          ],
        ),
      ),
    );
  }
}
