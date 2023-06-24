import 'dart:math';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/SettingsService/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/services/view_service.dart';

import '../api/nostr-relays.dart';
import '../utils/cache.dart';
import 'SettingsService/contacts.dart';

final EMERGENCY_TASK_TIMERS = [
  DurationTimer(
    duration: const Duration(days: 14),
  ),
];

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

  Future<List<String>> _getRandomRelays(final int amount) async {
    final relaysData = await withCache(getNostrRelays, "relays")();
    final relays = List<String>.from(relaysData["relays"] as List<dynamic>);

    relays.shuffle();

    return relays.take(amount).toList();
  }

  Future<List<String>> _getRelaysForEmergencyTask(
      final SettingsService settings) async {
    final defaultRelays = settings.getRelays();

    if (defaultRelays.isEmpty) {
      return _getRandomRelays(10);
    }

    try {
      final extraRelays =
          await _getRandomRelays(min(5, 10 - defaultRelays.length));

      return defaultRelays + extraRelays;
    } catch (_) {
      return defaultRelays;
    }
  }

  Future<Task> createEmergencyTask({
    required final SettingsService settings,
    required final TaskService taskService,
  }) async {
    final name = l10n.emergency_task_name(DateTime.now());
    final relays = await _getRelaysForEmergencyTask(settings);
    final task = await Task.create(
      name,
      relays,
      timers: EMERGENCY_TASK_TIMERS,
    );

    taskService.add(task);
    await taskService.save();

    await task.startExecutionImmediately();

    return task;
  }

  Future<void> deleteEverything({
    required final SettingsService settings,
    required final TaskService taskService,
    required final ViewService viewService,
  }) async {
    await Future.wait([
      settings.emergencyDelete(),
      taskService.emergencyDelete(),
      viewService.emergencyDelete(),
    ]);
  }
}
