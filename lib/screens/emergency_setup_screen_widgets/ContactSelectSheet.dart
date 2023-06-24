import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/SettingsService/contacts.dart';

class ContactSelectSheet extends StatefulWidget {
  final List<Contact> contacts;

  const ContactSelectSheet({
    required this.contacts,
    super.key,
  });

  @override
  State<ContactSelectSheet> createState() => _ContactSelectSheetState();
}

class _ContactSelectSheetState extends State<ContactSelectSheet> {
  final List<String> selectedContacts = [];

  @override
  void initState() {
    super.initState();

    selectedContacts.addAll(
      widget.contacts.map((contact) => contact.phoneNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) => ModalSheet(
        miuiIsGapless: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: <Widget>[
                Text(
                  l10n.emergency_message_test_select_title,
                  style: getTitle2TextStyle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SMALL_SPACE),
                Text(
                  l10n.emergency_message_test_select_message,
                  style: getCaptionTextStyle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MEDIUM_SPACE),
                ListView.builder(
                  shrinkWrap: true,
                  controller: controller,
                  itemCount: widget.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = widget.contacts[index];

                    return PlatformWidget(
                      material: (context, _) => CheckboxListTile(
                        title: Text(contact.name),
                        subtitle: Text(contact.phoneNumber),
                        value: selectedContacts.contains(contact.phoneNumber),
                        onChanged: (newValue) {
                          if (newValue == null) {
                            return;
                          }

                          setState(() {
                            if (newValue) {
                              selectedContacts.add(contact.phoneNumber);
                            } else {
                              selectedContacts.remove(contact.phoneNumber);
                            }
                          });
                        },
                      ),
                      cupertino: (context, _) => CupertinoListTile(
                        title: Text(contact.name),
                        trailing: CupertinoSwitch(
                          value: selectedContacts.contains(contact.phoneNumber),
                          onChanged: (newValue) {
                            setState(() {
                              if (newValue) {
                                selectedContacts.add(contact.phoneNumber);
                              } else {
                                selectedContacts.remove(contact.phoneNumber);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            PlatformElevatedButton(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.check_rounded),
              ),
              onPressed: () {
                final contacts = widget.contacts
                    .where(
                      (contact) =>
                          selectedContacts.contains(contact.phoneNumber),
                    )
                    .toList();
                Navigator.of(context).pop(contacts);
              },
              child: Text(l10n.closePositiveSheetAction),
            ),
          ],
        ),
      ),
    );
  }
}
