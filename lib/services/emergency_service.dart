import 'package:flutter_sms/flutter_sms.dart';
import 'package:locus/services/SettingsService/settings_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'SettingsService/contacts.dart';

class EmergencyService {
  final List<Contact> contacts;
  final SettingsService settings;
  final AppLocalizations l10n;

  EmergencyService({
    required this.l10n,
    required this.contacts,
    required this.settings,
  });

  Future<void> sendTestMessage() async {
    final message = l10n.emergency_message_test;

    for (final contact in contacts) {
      await sendSMS(
        message: message,
        recipients: [contact.phoneNumber],
      );
    }
  }
}
