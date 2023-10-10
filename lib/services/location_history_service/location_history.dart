import 'package:flutter/cupertino.dart';

import "./constants.dart";
import '../location_point_service.dart';

class LocationHistory extends ChangeNotifier {
  late final List<LocationPointService> locations;

  LocationHistory(
    final List<LocationPointService>? locations,
  ) : locations = locations ?? [];

  factory LocationHistory.fromJSON(final Map<String, dynamic> data) =>
      LocationHistory(
        data["locations"] != null
            ? List<LocationPointService>.from(
                data["locations"].map(
                  (location) => LocationPointService.fromJSON(location),
                ),
              )
            : null,
      );

  static Future<LocationHistory> restore() async {
    final data = await storage.read(key: KEY);

    if (data == null) {
      return LocationHistory(null);
    }

    return LocationHistory.fromJSON(data as Map<String, dynamic>);
  }

  // To avoid too many crumbled locations, we only save locations that are at
  // least one minute apart
  bool _canAdd(final LocationPointService location) {
    if (locations.isEmpty) {
      return true;
    }

    return locations.last.createdAt
            .difference(location.createdAt)
            .inMinutes
            .abs() >
        1;
  }

  void add(final LocationPointService location) {
    if (!_canAdd(location)) {
      return;
    }

    locations.add(location);
    notifyListeners();
  }

  void clear() {
    locations.clear();
    notifyListeners();
  }

  void toJSON() => {
        "locations": locations.map((location) => location.toJSON()).toList(),
      };
}
