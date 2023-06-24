import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'SettingsService/contacts.dart';

class EmergencyService {
  final List<Contact> contacts;
  final AppLocalizations l10n;

  EmergencyService({
    required this.l10n,
    required this.contacts,
  });

  Future<void> sendTestMessage() async {
    final message = l10n.emergency_message_test;

    for (final contact in contacts) {
      await sendSMS(
        message: message,
        recipients: [contact.phoneNumber],
        sendDirect: true,
      );
    }
  }
}
