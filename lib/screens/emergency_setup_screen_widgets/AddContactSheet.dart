import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/SettingsService/contacts.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.emergencySetup_addContact_title,
              style: getTitle2TextStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LARGE_SPACE),
            PlatformTextFormField(
              material: (_, __) =>
                  MaterialTextFormFieldData(
                    decoration: InputDecoration(
                      labelText: l10n.emergencySetup_addContact_name_label,
                      prefixIcon: const Icon(Icons.text_format),
                    ),
                  ),
              cupertino: (_, __) =>
                  CupertinoTextFormFieldData(
                    prefix: const Icon(Icons.text_format),
                    placeholder: l10n.emergencySetup_addContact_name_hint,
                  ),
              controller: nameController,
              autofocus: true,
              autofillHints: const <String>[AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fields_errors_isEmpty;
                }

                if (!StringUtils.isAscii(value)) {
                  return l10n.fields_errors_invalidCharacters;
                }

                return null;
              },
              hintText: l10n.emergencySetup_addContact_name_hint,
            ),
            const SizedBox(height: MEDIUM_SPACE),
            PlatformTextFormField(
              material: (_, __) =>
                  MaterialTextFormFieldData(
                    decoration: InputDecoration(
                      labelText: l10n.emergencySetup_addContact_phone_label,
                      prefixIcon: const Icon(Icons.numbers_rounded),
                    ),
                  ),
              cupertino: (_, __) =>
                  CupertinoTextFormFieldData(
                    prefix: const Icon(Icons.numbers_rounded),
                    placeholder: l10n.emergencySetup_addContact_phone_hint,
                  ),
              controller: phoneController,
              autofillHints: const <String>[AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fields_errors_isEmpty;
                }

                return null;
              },
              hintText: l10n.emergencySetup_addContact_phone_hint,
            ),
            const SizedBox(height: LARGE_SPACE),
            PlatformElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final contact = Contact(
                    name: nameController.value.text,
                    // Remove whitespace
                    phoneNumber: phoneController.value.text.replaceAll(
                      RegExp(r"\s+"),
                      "",
                    ),
                  );

                  Navigator.of(context).pop(contact);
                }
              },
              material: (_, __) =>
                  MaterialElevatedButtonData(
                    icon: const Icon(Icons.check),
                  ),
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              child: Text(l10n.emergencySetup_addContact_addLabel),
            )
          ],
        ),
      ),
    );
  }
}
