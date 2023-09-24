import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_alarm_service/LocationAlarmServiceBase.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/services/location_fetcher_service/Fetcher.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';
import 'package:nostr/nostr.dart';

class AlarmHandler {
  final TaskView view;

  const AlarmHandler(this.view);

  Future<
      (LocationAlarmTriggerType, LocationAlarmServiceBase?, LocationPointService?)> checkAlarm(
      final LocationPointService userLocation,) async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task; Check View Alarms",
      "Checking view ${view.name} from ${view.lastAlarmCheck}...",
    );

    final fetcher = Fetcher(view);
    await fetcher.fetchCustom(
      Request(
        generate64RandomHexChars(),
        [
          NostrSocket.createNostrRequestDataFromTask(
            view,
            from: view.lastAlarmCheck,
          ),
        ],
      ),
    );
    final locations = fetcher.sortedLocations;

    view.lastAlarmCheck = DateTime.now();

    FlutterLogs.logInfo(
      LOG_TAG,
      "Headless Task; Check View Alarms",
      "    -> ${locations.length} locations",
    );

    if (locations.isEmpty) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "Headless Task; Check View Alarms",
        "    -> No locations",
      );

      return (LocationAlarmTriggerType.no, null, null);
    }

    locations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    LocationPointService oldLocation = locations.first;

    // Iterate over each location but the first one
    // Iterating backwards to check the last locations first,
    // if we miss an old location, it's not that bad, newer data
    // is more important
    // Return on first found to not spam the user with multiple alarms
    for (final location in locations
        .skip(1)
        .toList()
        .reversed) {
      for (final alarm in view.alarms) {
        final checkResult = alarm.check(
          location,
          oldLocation,
          userLocation: userLocation,
        );

        if (checkResult == LocationAlarmTriggerType.yes) {
          return (LocationAlarmTriggerType.yes, alarm, location);
        } else if (checkResult == LocationAlarmTriggerType.maybe) {
          return (LocationAlarmTriggerType.maybe, alarm, location);
        }
      }

      oldLocation = location;
    }

    return (LocationAlarmTriggerType.no, null, null);
  }
}
