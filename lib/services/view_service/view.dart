import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/api/nostr-fetch.dart';
import 'package:locus/services/location_fetcher_service/Fetcher.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/services/view_service/alarm_handler.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/cryptography/decrypt.dart';
import 'package:locus/utils/nostr_fetcher/LocationPointDecrypter.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';
import 'package:nostr/nostr.dart';
import 'package:uuid/uuid.dart';

import '../../constants/values.dart';
import '../location_alarm_service/GeoLocationAlarm.dart';
import '../location_alarm_service/LocationAlarmServiceBase.dart';
import '../location_alarm_service/ProximityLocationAlarm.dart';
import '../location_alarm_service/enums.dart';
import '../location_point_service.dart';
import '../task_service/mixins.dart';

class TaskView extends ChangeNotifier with LocationBase {
  final SecretKey _encryptionPassword;
  @override
  final String nostrPublicKey;
  @override
  final List<String> relays;
  final List<LocationAlarmServiceBase> alarms;
  final String id;
  Color color;
  DateTime lastAlarmCheck;
  DateTime? lastMaybeTrigger;
  String name;

  TaskView({
    required final SecretKey encryptionPassword,
    required this.nostrPublicKey,
    required this.relays,
    required this.name,
    required this.color,
    this.lastMaybeTrigger,
    String? id,
    DateTime? lastAlarmCheck,
    List<LocationAlarmServiceBase>? alarms,
  })
      : _encryptionPassword = encryptionPassword,
        alarms = alarms ?? [],
        lastAlarmCheck = lastAlarmCheck ?? DateTime.now(),
        id = id ?? const Uuid().v4();

  AlarmHandler get alarmHandler => AlarmHandler(this);

  static ViewServiceLinkParameters parseLink(final String url) {
    final uri = Uri.parse(url);
    final fragment = uri.fragment;

    final rawParameters =
    const Utf8Decoder().convert(base64Url.decode(fragment));
    final parameters = jsonDecode(rawParameters);

    return ViewServiceLinkParameters(
      password: SecretKey(List<int>.from(parameters['p'])),
      nostrPublicKey: parameters['k'],
      nostrMessageID: parameters['i'],
      // Add support for old links
      relays: parameters["r"] is List
          ? List<String>.from(parameters['r'])
          : [parameters["r"]],
    );
  }

  factory TaskView.fromJSON(final Map<String, dynamic> json) =>
      TaskView(
        encryptionPassword:
        SecretKey(List<int>.from(json["encryptionPassword"])),
        nostrPublicKey: json["nostrPublicKey"],
        relays: List<String>.from(json["relays"]),
        name: json["name"] ?? "Unnamed Task",
        // Required for migration
        id: json["id"] ?? const Uuid().v4(),
        alarms: List<LocationAlarmServiceBase>.from(
          (json["alarms"] ?? []).map((alarm) {
            final identifier = LocationAlarmType.values
                .firstWhere((element) => element.name == alarm["_IDENTIFIER"]);

            switch (identifier) {
              case LocationAlarmType.geo:
                return GeoLocationAlarm.fromJSON(alarm);
              case LocationAlarmType.proximity:
                return ProximityLocationAlarm.fromJSON(alarm);
            }
          }),
        ),
        lastAlarmCheck: json["lastAlarmCheck"] != null
            ? DateTime.parse(json["lastAlarmCheck"])
            : DateTime.now(),
        lastMaybeTrigger: json["lastMaybeTrigger"] != null
            ? DateTime.parse(json["lastMaybeTrigger"])
            : null,
        color: json["color"] != null
            ? Color(json["color"])
            : Colors.primaries[Random().nextInt(Colors.primaries.length)],
      );

  static Future<TaskView> fetchFromNostr(final AppLocalizations l10n,
      final ViewServiceLinkParameters parameters,) async {
    final completer = Completer<TaskView>();

    final request = Request(generate64RandomHexChars(), [
      Filter(
        ids: [parameters.nostrMessageID],
      ),
    ]);

    final nostrFetch = NostrFetch(
      relays: parameters.relays,
      request: request,
    );

    nostrFetch.fetchEvents(
        onEvent: (event, _) async {
          try {
            final rawMessage = await decryptUsingAES(
              event.message.content,
              parameters.password,
            );

            final data = jsonDecode(rawMessage);

            if (data["nostrPublicKey"] != parameters.nostrPublicKey) {
              completer.completeError("Invalid Nostr public key");
              return;
            }

            if (completer.isCompleted) {
              return;
            }

            completer.complete(
              TaskView(
                encryptionPassword: SecretKey(
                  List<int>.from(data["encryptionPassword"]),
                ),
                nostrPublicKey: data['nostrPublicKey'],
                relays: List<String>.from(data['relays']),
                name: l10n.longFormattedDate(DateTime.now()),
                color:
                Colors.primaries[Random().nextInt(Colors.primaries.length)],
              ),
            );
          } catch (error) {
            FlutterLogs.logError(
              LOG_TAG,
              "Import TaskView",
              "Error while fetching importing view: $error",
            );

            completer.completeError(error);
          }
        },
        onEnd: () {});

    return completer.future;
  }

  void update({
    final String? name,
    final Color? color,
  }) {
    if (name != null) {
      this.name = name;
    }

    if (color != null) {
      this.color = color;
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> toJSON() async {
    return {
      "encryptionPassword": await _encryptionPassword.extractBytes(),
      "nostrPublicKey": nostrPublicKey,
      "relays": relays,
      "name": name,
      "id": id,
      "alarms": alarms.map((alarm) => alarm.toJSON()).toList(),
      "lastAlarmCheck": lastAlarmCheck.toIso8601String(),
      "lastMaybeTrigger": lastMaybeTrigger?.toIso8601String(),
      "color": color.value,
    };
  }

  Future<String?> validate(final AppLocalizations l10n, {
    required final TaskService taskService,
    required final ViewService viewService,
  }) async {
    if (relays.isEmpty) {
      return l10n.taskImport_error_no_relays;
    }

    final sameTask = taskService.tasks.firstWhereOrNull(
            (element) => element.nostrPublicKey == nostrPublicKey);

    if (sameTask != null) {
      return l10n.taskImport_error_sameTask(sameTask.name);
    }

    final sameView = viewService.views.firstWhereOrNull(
            (element) => element.nostrPublicKey == nostrPublicKey);

    if (sameView != null) {
      return l10n.taskImport_error_sameView(sameView.name);
    }

    return null;
  }

  @override
  void dispose() {
    _encryptionPassword.destroy();

    super.dispose();
  }

  void addAlarm(final LocationAlarmServiceBase alarm) {
    alarms.add(alarm);
    notifyListeners();
  }

  void removeAlarm(final LocationAlarmServiceBase alarm) {
    alarms.remove(alarm);
    notifyListeners();
  }

  Future<LocationPointService> decryptFromNostrMessage(final Message message) =>
      LocationPointDecrypter(
        _encryptionPassword,
      ).decryptFromNostrMessage(message);
}
