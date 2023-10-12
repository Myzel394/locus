import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import "./constants.dart";
import '../location_point_service.dart';

class LocationHistory extends ChangeNotifier {
  late final List<Position> locations;

  LocationHistory(
    final List<Position>? locations,
  ) : locations = locations ?? [];

  factory LocationHistory.fromJSON(final Map<String, dynamic> data) =>
      LocationHistory(
        data["locations"] != null
            ? List<Position>.from(
                data["locations"].map(
                  (location) =>
                      Position.fromMap(location as Map<String, dynamic>),
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
  bool _canAdd(final Position position) {
    if (position.timestamp == null) {
      return false;
    }

    if (locations.isEmpty) {
      return true;
    }

    return locations.last.timestamp!
            .difference(position.timestamp!)
            .inMinutes
            .abs() >
        1;
  }

  void add(final Position position) {
    if (!_canAdd(position)) {
      return;
    }

    locations.add(position);
    notifyListeners();
  }

  void clear() {
    locations.clear();
    notifyListeners();
  }

  Map<String, dynamic> toJSON() => {
        "locations": locations.map((location) => location.toJson()).toList(),
      };

  Future<void> save() async {
    await storage.write(
      key: KEY,
      value: jsonEncode(toJSON()),
    );
  }
}
