import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/api/nostr-fetch.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/cryptography.dart';
import 'package:nostr/nostr.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../api/get-locations.dart' as getLocationsAPI;
import '../constants/values.dart';
import 'location_alarm_service.dart';
import 'location_base.dart';
import 'location_point_service.dart';

const storage = FlutterSecureStorage();
const KEY = "view_service";

class ViewServiceLinkParameters {
  final SecretKey password;
  final String nostrPublicKey;
  final String nostrMessageID;
  final List<String> relays;

  const ViewServiceLinkParameters({
    required this.password,
    required this.nostrPublicKey,
    required this.nostrMessageID,
    required this.relays,
  });
}

class TaskView extends ChangeNotifier with LocationBase {
  final SecretKey _encryptionPassword;
  final String nostrPublicKey;
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
  })  : _encryptionPassword = encryptionPassword,
        alarms = alarms ?? [],
        lastAlarmCheck = lastAlarmCheck ?? DateTime.now(),
        id = id ?? const Uuid().v4();

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

  factory TaskView.fromJSON(final Map<String, dynamic> json) => TaskView(
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
              case LocationAlarmType.radiusBasedRegion:
                return RadiusBasedRegionLocationAlarm.fromJSON(alarm);
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

  static Future<TaskView> fetchFromNostr(
    final AppLocalizations l10n,
    final ViewServiceLinkParameters parameters,
  ) async {
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

  Future<String?> validate(
    final AppLocalizations l10n, {
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

  VoidCallback getLocations({
    required void Function(LocationPointService) onLocationFetched,
    required void Function() onEnd,
    int? limit,
    DateTime? from,
  }) =>
      getLocationsAPI.getLocations(
        encryptionPassword: _encryptionPassword,
        nostrPublicKey: nostrPublicKey,
        relays: relays,
        onLocationFetched: onLocationFetched,
        onEnd: onEnd,
        from: from,
        limit: limit,
      );

  Future<List<LocationPointService>> getLocationsAsFuture({
    int? limit,
    DateTime? from,
  }) =>
      getLocationsAPI.getLocationsAsFuture(
        encryptionPassword: _encryptionPassword,
        nostrPublicKey: nostrPublicKey,
        relays: relays,
        from: from,
        limit: limit,
      );

  @override
  void dispose() {
    _encryptionPassword.destroy();

    super.dispose();
  }

  Future<void> checkAlarm({
    required final void Function(
            LocationAlarmServiceBase alarm,
            LocationPointService previousLocation,
            LocationPointService nextLocation)
        onTrigger,
    required final void Function(
            LocationAlarmServiceBase alarm,
            LocationPointService previousLocation,
            LocationPointService nextLocation)
        onMaybeTrigger,
  }) async {
    final locations = await getLocationsAsFuture(
      from: lastAlarmCheck,
    );

    lastAlarmCheck = DateTime.now();

    if (locations.isEmpty) {
      return;
    }

    locations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    LocationPointService oldLocation = locations.first;

    // Iterate over each location but the first one
    for (final location in locations.skip(1)) {
      for (final alarm in alarms) {
        final checkResult = alarm.check(oldLocation, location);

        if (checkResult == LocationAlarmTriggerType.yes) {
          onTrigger(alarm, oldLocation, location);
          break;
        } else if (checkResult == LocationAlarmTriggerType.maybe) {
          onMaybeTrigger(alarm, oldLocation, location);
          break;
        }
      }

      oldLocation = location;
    }
  }

  void addAlarm(final LocationAlarmServiceBase alarm) {
    alarms.add(alarm);
    notifyListeners();
  }

  void removeAlarm(final LocationAlarmServiceBase alarm) {
    alarms.remove(alarm);
    notifyListeners();
  }
}

class ViewService extends ChangeNotifier {
  final List<TaskView> _views;

  ViewService({
    required List<TaskView> views,
  }) : _views = views;

  UnmodifiableListView<TaskView> get views => UnmodifiableListView(_views);

  UnmodifiableListView<TaskView> get viewsWithAlarms =>
      UnmodifiableListView(_views.where((view) => view.alarms.isNotEmpty));

  TaskView getViewById(final String id) =>
      _views.firstWhere((view) => view.id == id);

  static Future<ViewService> restore() async {
    final rawViews = await storage.read(key: KEY);

    if (rawViews == null) {
      return ViewService(
        views: [],
      );
    }

    return ViewService(
      views: List<TaskView>.from(
        List<Map<String, dynamic>>.from(
          jsonDecode(rawViews),
        ).map(
          TaskView.fromJSON,
        ),
      ).toList(),
    );
  }

  Future<void> save() async {
    final data = jsonEncode(
      List<Map<String, dynamic>>.from(
        await Future.wait(
          _views.map(
            (view) => view.toJSON(),
          ),
        ),
      ),
    );

    await storage.write(key: KEY, value: data);
  }

  void add(final TaskView view) {
    _views.add(view);

    notifyListeners();
  }

  void remove(final TaskView view) {
    _views.remove(view);

    notifyListeners();
  }

  Future<void> update(final TaskView view) async {
    final index = _views.indexWhere((element) => element.id == view.id);

    _views[index] = view;

    notifyListeners();
    await save();
  }
}
