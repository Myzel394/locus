import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/emergency_setup_screen_widgets/AddContactSheet.dart';
import 'package:locus/services/SettingsService/settings_service.dart';
import 'package:locus/utils/show_message.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/SettingsService/contacts.dart' as contacts;

class EmergencySetupScreen extends StatefulWidget {
  const EmergencySetupScreen({super.key});

  @override
  State<EmergencySetupScreen> createState() => _EmergencySetupScreenState();
}

class _EmergencySetupScreenState extends State<EmergencySetupScreen> {
  bool showHint = true;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();

    settings.addListener(rebuild);

    showHint = settings
        .getEmergencyContacts()
        .isEmpty;
  }

  @override
  void dispose() {
    final settings = context.read<SettingsService>();

    settings.removeListener(rebuild);

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  void importContact(final contacts.Contact contact) async {
    final settings = context.read<SettingsService>();

    settings.addEmergencyContact(contact);
    settings.save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    final emergencyContacts = settings.getEmergencyContacts();

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.emergencySetup_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: showHint
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.warning_sharp,
                  color: Colors.yellow,
                  size: 120,
                ),
                const SizedBox(height: LARGE_SPACE),
                Text(l10n.emergencySetup_hint),
                const SizedBox(height: LARGE_SPACE),
                PlatformTextButton(
                  onPressed: () {
                    setState(() {
                      showHint = false;
                    });
                  },
                  child: Text(l10n.emergencySetup_hint_understoodLabel),
                )
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (emergencyContacts.isNotEmpty)
                  ListView.builder(
                    itemCount: emergencyContacts.length,
                    shrinkWrap: true,
                    itemBuilder: (_, index) {
                      final contact = emergencyContacts[index];

                      return PlatformListTile(
                        title: Text(contact.name),
                        subtitle: Text(contact.phoneNumber),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirm = await showPlatformDialog(
                              context: context,
                              builder: (_) =>
                                  PlatformAlertDialog(
                                    material: (_, __) =>
                                        MaterialAlertDialogData(
                                          icon: const Icon(Icons.delete),
                                        ),
                                    title: Text(
                                      l10n.emergencySetup_deleteContact_title,
                                    ),
                                    content: Text(
                                      l10n.emergencySetup_deleteContact_message,
                                    ),
                                    actions: createCancellableDialogActions(
                                      context,
                                      [
                                        PlatformDialogAction(
                                          child: Text(
                                            l10n.deleteLabel,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                            );

                            if (confirm == true) {
                              settings.removeEmergencyContact(contact);
                              settings.save();
                            }
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: HUGE_SPACE),
                Paper(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MEDIUM_SPACE,
                      vertical: LARGE_SPACE,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        PlatformElevatedButton(
                          onPressed: () async {
                            final contacts.Contact? contact =
                            await showPlatformModalSheet(
                              context: context,
                              material: MaterialModalSheetData(
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                isDismissible: true,
                              ),
                              builder: (_) => const AddContactScreen(),
                            );

                            if (contact == null) {
                              return;
                            }

                            importContact(contact);
                          },
                          material: (_, __) =>
                              MaterialElevatedButtonData(
                                icon: const Icon(Icons.add_circle_rounded),
                              ),
                          child:
                          Text(l10n.emergencySetup_addContact_label),
                        ),
                        const SizedBox(height: LARGE_SPACE),
                        Row(
                          children: <Widget>[
                            const Expanded(child: Divider()),
                            const SizedBox(width: MEDIUM_SPACE),
                            Text(
                              l10n.alternativeDividerLabel.toUpperCase(),
                            ),
                            const SizedBox(width: MEDIUM_SPACE),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: LARGE_SPACE),
                        PlatformElevatedButton(
                          onPressed: () async {
                            PhoneContact rawContact;

                            try {
                              rawContact =
                              await FlutterContactPicker
                                  .pickPhoneContact();
                            } catch (error) {
                              FlutterLogs.logError(
                                'EmergencySetupScreen',
                                'pickPhoneContact',
                                "Error while picking contact: $error",
                              );

                              showMessage(
                                context,
                                l10n.unknownError,
                                type: MessageType.error,
                              );
                              return;
                            }

                            if (!mounted) {
                              return;
                            }

                            if (rawContact.fullName == null ||
                                rawContact.phoneNumber != null) {
                              showMessage(
                                context,
                                l10n
                                    .emergencySetup_pickContact_error_contactInvalid,
                              );
                            }

                            final contact = contacts.Contact(
                              name: rawContact.fullName!,
                              phoneNumber:
                              rawContact.phoneNumber!.number!,
                            );

                            importContact(contact);
                          },
                          material: (_, __) =>
                              MaterialElevatedButtonData(
                                icon: const Icon(Icons.person),
                              ),
                          child:
                          Text(l10n.emergencySetup_pickContact_label),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
